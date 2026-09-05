-- Atualizador seguro da Custom Shazam.
--
-- Fluxo:
--   1. verifica o commit mais recente do branch alguns segundos depois de
--      abrir o OTCv8 (qualquer push novo no GitHub ja conta, nao precisa
--      editar nenhum numero de versao manualmente);
--   2. baixa os arquivos para uma area separada;
--   3. aplica somente na proxima inicializacao da custom.
--
-- Dados pessoais nunca entram na lista de arquivos permitidos.

ShazamUpdater = ShazamUpdater or {}

local COMMITS_URL = "https://api.github.com/repos/ShazamScripts/Custom-NTO/commits/main"
local TREE_URL = "https://api.github.com/repos/ShazamScripts/Custom-NTO/git/trees/main?recursive=1"
local RAW_BASE_URL = "https://raw.githubusercontent.com/ShazamScripts/Custom-NTO/main/"
local CHECK_DELAY = 4000
local MAX_FILE_SIZE = 20 * 1024 * 1024
local MAX_FILES = 500

local profileName = tostring(configDir or "Custom Shazam"):match("/bot/(.+)$") or "Custom Shazam"
local profileKey = profileName:gsub("[^%w_%-]", "_")
local UPDATE_ROOT = "/shazam_scripts/updater/" .. profileKey
local PENDING_FILE = UPDATE_ROOT .. "/pending.json"

-- Onde fica salvo o hash do ultimo commit instalado nesta pasta. E um
-- arquivo local, nao vem do GitHub (nao esta na whitelist de download).
local COMMIT_FILE = (configDir or "") .. "/.shazam_commit"

-- A identificacao fica no modulo global do cliente, que sobrevive a um simples
-- refresh/troca de aba, mas e recriada quando o processo do OTCv8 reinicia.
local sessionOwner = type(modules) == "table" and modules or nil
if sessionOwner and type(modules.game_bot) == "table" then
    sessionOwner = modules.game_bot
end
if sessionOwner and not sessionOwner.shazamUpdaterSession then
    sessionOwner.shazamUpdaterSession = tostring(os.time()) .. ":" .. tostring({})
end
local SESSION_ID = sessionOwner and sessionOwner.shazamUpdaterSession
    or (tostring(os.time()) .. ":" .. tostring({}))

local ROOT_FILES = {
    ["00_FREE_UNIVERSAL.lua"] = true,
    ["README.md"] = true,
    ["VERSION"] = true,
    ["update.json"] = true,
}

local ALLOWED_PREFIXES = {
    "cavebot/",
    "cavebot_configs/",
    "docs/",
    "extras/",
    "free_core/",
    "free_modules/",
    "Img/",
    "sounds/",
    "targetbot/",
    "targetbot_configs/",
}

local ALLOWED_EXTENSIONS = {
    ["cfg"] = true,
    ["gif"] = true,
    ["jpeg"] = true,
    ["jpg"] = true,
    ["json"] = true,
    ["lua"] = true,
    ["md"] = true,
    ["ogg"] = true,
    ["otui"] = true,
    ["png"] = true,
    ["ui"] = true,
    ["wav"] = true,
}

local function log(message)
    local text = "[Shazam Updater] " .. tostring(message)
    if type(print) == "function" then
        print(text)
    end
end

local function notify(message)
    local text = "[Shazam Updater] " .. tostring(message)
    if type(warn) == "function" then
        warn(text)
    elseif type(print) == "function" then
        print(text)
    end
end

-- Hash de commit do git: hexadecimal, entre 7 (short sha) e 40 (full sha)
-- caracteres. Qualquer coisa fora disso e tratada como resposta invalida.
local function validSha(value)
    value = tostring(value or "")
    return #value >= 7 and #value <= 40 and value:match("^%x+$") ~= nil
end

local function isAllowedPath(path)
    if type(path) ~= "string" or path == "" then
        return false
    end
    if path:sub(1, 1) == "/" or path:find("\\", 1, true)
        or path:find("..", 1, true) or path:find(":", 1, true) then
        return false
    end
    if ROOT_FILES[path] then
        return true
    end

    local allowedPrefix = false
    for _, prefix in ipairs(ALLOWED_PREFIXES) do
        if path:sub(1, #prefix) == prefix then
            allowedPrefix = true
            break
        end
    end
    if not allowedPrefix then
        return false
    end

    local extension = path:match("%.([%w]+)$")
    return extension ~= nil and ALLOWED_EXTENSIONS[extension:lower()] == true
end

local function ensureDirectory(path)
    if g_resources.directoryExists(path) then
        return true
    end

    local parent = tostring(path):match("^(.*)/[^/]+$")
    if parent and parent ~= "" and parent ~= path and not g_resources.directoryExists(parent) then
        if not ensureDirectory(parent) then
            return false
        end
    end

    local ok = pcall(g_resources.makeDir, path)
    return ok and g_resources.directoryExists(path)
end

local function ensureParent(path)
    local directory = tostring(path):match("^(.*)/[^/]+$")
    if not directory or directory == "" then
        return true
    end

    local current = ""
    for part in directory:gmatch("[^/]+") do
        current = current .. "/" .. part
        if not ensureDirectory(current) then
            return false
        end
    end
    return true
end

local function readFile(path)
    if not g_resources.fileExists(path) then
        return nil
    end
    local ok, contents = pcall(g_resources.readFileContents, path)
    if not ok or type(contents) ~= "string" then
        return nil
    end
    return contents
end

local function writeFile(path, contents)
    if type(contents) ~= "string" or not ensureParent(path) then
        return false
    end
    local ok = pcall(g_resources.writeFileContents, path, contents)
    return ok and g_resources.fileExists(path)
end

local function deletePath(path)
    if not g_resources.fileExists(path) and not g_resources.directoryExists(path) then
        return true
    end
    return pcall(g_resources.deleteFile, path)
end

local function decodeJson(contents)
    if type(contents) ~= "string" or contents == "" then
        return nil
    end
    local ok, result = pcall(json.decode, contents)
    if not ok or type(result) ~= "table" then
        return nil
    end
    return result
end

local function encodeJson(value)
    local ok, result = pcall(json.encode, value, 2)
    if not ok or type(result) ~= "string" then
        return nil
    end
    return result
end

-- Ultimo commit instalado nesta pasta (nil se o updater nunca rodou aqui).
local function getLocalCommit()
    local contents = readFile(COMMIT_FILE)
    if not contents then
        return nil
    end
    contents = contents:gsub("^%s+", ""):gsub("%s+$", "")
    if not validSha(contents) then
        return nil
    end
    return contents
end

local function setLocalCommit(sha)
    return writeFile(COMMIT_FILE, sha)
end

local function encodedPath(path)
    return (path:gsub("[^%w%-%._~/]", function(character)
        return string.format("%%%02X", string.byte(character))
    end))
end

local function orderedFiles(files)
    local normal = {}
    local hasVersion = false
    for _, path in ipairs(files) do
        if path == "VERSION" then
            hasVersion = true
        else
            normal[#normal + 1] = path
        end
    end
    table.sort(normal)
    if hasVersion then
        normal[#normal + 1] = "VERSION"
    end
    return normal
end

local function rollback(written, backupRoot, existed)
    for index = #written, 1, -1 do
        local path = written[index]
        local target = (configDir or "") .. "/" .. path
        if existed[path] then
            local backup = readFile(backupRoot .. "/" .. path)
            if backup then
                writeFile(target, backup)
            end
        else
            deletePath(target)
        end
    end
end

local function applyPending()
    local pendingContents = readFile(PENDING_FILE)
    if not pendingContents then
        return false
    end

    local pending = decodeJson(pendingContents)
    if not pending or not validSha(pending.sha) or type(pending.files) ~= "table"
        or #pending.files == 0 or #pending.files > MAX_FILES then
        notify("A atualizacao pendente e invalida e nao foi instalada.")
        return false
    end
    if type(pending.session) == "string" and pending.session == SESSION_ID then
        log("Atualizacao pronta; aguardando fechar e abrir o OTCv8.")
        return false
    end

    local stageRoot = UPDATE_ROOT .. "/staging/" .. pending.sha
    local backupRoot = UPDATE_ROOT .. "/backups/" .. (getLocalCommit() or "unknown")
    local files = orderedFiles(pending.files)

    -- Primeiro valida todos os caminhos e arquivos baixados. Nada e alterado
    -- enquanto o pacote ainda estiver incompleto.
    for _, path in ipairs(files) do
        if not isAllowedPath(path) or not g_resources.fileExists(stageRoot .. "/" .. path) then
            notify("Pacote incompleto. A instalacao foi cancelada: " .. tostring(path))
            return false
        end
    end

    -- Guarda uma copia dos arquivos atuais antes da primeira substituicao.
    local existed = {}
    for _, path in ipairs(files) do
        local target = (configDir or "") .. "/" .. path
        existed[path] = g_resources.fileExists(target)
        if existed[path] then
            local currentContents = readFile(target)
            if not currentContents or not writeFile(backupRoot .. "/" .. path, currentContents) then
                notify("Nao foi possivel criar o backup. A instalacao foi cancelada.")
                return false
            end
        end
    end

    local written = {}
    for _, path in ipairs(files) do
        local stagedContents = readFile(stageRoot .. "/" .. path)
        local target = (configDir or "") .. "/" .. path
        if not stagedContents or not writeFile(target, stagedContents) then
            rollback(written, backupRoot, existed)
            notify("Falha ao instalar. Os arquivos anteriores foram restaurados.")
            return false
        end
        written[#written + 1] = path
    end

    setLocalCommit(pending.sha)
    deletePath(PENDING_FILE)
    deletePath(stageRoot)
    -- O backup so serve para desfazer uma instalacao que falhou no meio do
    -- caminho. Uma vez que deu tudo certo, ele nao tem mais utilidade — entao
    -- e apagado aqui para nao acumular uma copia inteira da custom a cada
    -- commit novo (isso enchia a pasta de updates sem necessidade).
    deletePath(backupRoot)
    log("Atualizacao instalada com sucesso (commit " .. pending.sha:sub(1, 7) .. ").")
    return true
end

local function collectFiles(tree)
    if type(tree) ~= "table" then
        return nil
    end

    local files = {}
    for _, entry in ipairs(tree) do
        if type(entry) == "table" and entry.type == "blob" and isAllowedPath(entry.path) then
            local size = tonumber(entry.size) or 0
            if size > MAX_FILE_SIZE then
                return nil
            end
            -- Arquivos vazios nao precisam ser transferidos e algumas bases
            -- antigas mantem imagens vazias apenas como marcadores.
            if size > 0 then
                files[#files + 1] = entry.path
                if #files > MAX_FILES then
                    return nil
                end
            end
        end
    end

    if #files < 5 then
        return nil
    end
    return orderedFiles(files)
end

local function savePending(sha, files)
    local contents = encodeJson({
        sha = sha,
        downloadedAt = os.time(),
        session = SESSION_ID,
        files = files,
    })
    return contents ~= nil and writeFile(PENDING_FILE, contents)
end

local function downloadFiles(sha, files)
    local stageRoot = UPDATE_ROOT .. "/staging/" .. sha
    deletePath(stageRoot)
    if not ensureDirectory(stageRoot) then
        notify("Nao foi possivel preparar a pasta temporaria da atualizacao.")
        return
    end

    local index = 1
    local function downloadNext()
        local path = files[index]
        if not path then
            if not savePending(sha, files) then
                notify("Os arquivos foram baixados, mas nao foi possivel agendar a instalacao.")
                return
            end
            notify("Atualizacao (commit " .. sha:sub(1, 7) .. ") baixada. Feche e abra o OTCv8 para instalar com seguranca.")
            return
        end

        HTTP.get(RAW_BASE_URL .. encodedPath(path) .. "?shazam=" .. tostring(os.time()), function(data, err)
            if err or type(data) ~= "string" or #data == 0 or #data > MAX_FILE_SIZE then
                notify("Falha ao baixar " .. path .. ". Tentaremos novamente ao abrir o OTCv8.")
                return
            end
            if not writeFile(stageRoot .. "/" .. path, data) then
                notify("Falha ao salvar " .. path .. ". A atualizacao nao foi agendada.")
                return
            end

            if index % 20 == 0 then
                log("Baixando atualizacao: " .. index .. "/" .. #files)
            end
            index = index + 1
            downloadNext()
        end)
    end

    log("Novo commit " .. sha:sub(1, 7) .. " encontrado. Iniciando download seguro.")
    downloadNext()
end

local function fetchTree(sha)
    HTTP.get(TREE_URL .. "&shazam=" .. tostring(os.time()), function(data, err)
        if err or type(data) ~= "string" or data == "" then
            notify("Nao foi possivel consultar a lista de arquivos da atualizacao.")
            return
        end

        local response = decodeJson(data)
        local files = response and response.truncated ~= true and collectFiles(response.tree) or nil
        if not files then
            notify("A lista de arquivos recebida e invalida. Nada foi alterado.")
            return
        end
        downloadFiles(sha, files)
    end)
end

-- Retorna, dentre os arquivos permitidos da lista, apenas os que
-- nao existem mais na pasta local (ex: apagados por engano pelo usuario).
local function missingFiles(files)
    local missing = {}
    for _, path in ipairs(files) do
        local target = (configDir or "") .. "/" .. path
        if not g_resources.fileExists(target) then
            missing[#missing + 1] = path
        end
    end
    return missing
end

-- Restaura direto na pasta (sem staging/pending) apenas os arquivos que
-- estao faltando. Nunca sobrescreve um arquivo que ja existe, entao nao
-- interfere com o fluxo normal de atualizacao por commit novo.
local function downloadMissingFiles(files)
    if #files == 0 then
        return
    end

    local index = 1
    local function downloadNext()
        local path = files[index]
        if not path then
            notify("Arquivo(s) que estavam faltando foram restaurados.")
            return
        end

        HTTP.get(RAW_BASE_URL .. encodedPath(path) .. "?shazam=" .. tostring(os.time()), function(data, err)
            if err or type(data) ~= "string" or #data == 0 or #data > MAX_FILE_SIZE then
                notify("Falha ao restaurar " .. path .. ". Tentaremos novamente ao abrir o OTCv8.")
                return
            end

            local target = (configDir or "") .. "/" .. path
            if not writeFile(target, data) then
                notify("Falha ao salvar " .. path .. " ao restaurar.")
                return
            end

            log("Arquivo restaurado: " .. path)
            index = index + 1
            downloadNext()
        end)
    end

    log("Restaurando " .. #files .. " arquivo(s) que estavam faltando.")
    downloadNext()
end

-- Consulta a arvore do repositorio so para achar arquivos que sumiram da
-- pasta local (deletados manualmente), mesmo quando nao ha commit novo.
local function checkMissingFiles()
    HTTP.get(TREE_URL .. "&shazam=" .. tostring(os.time()), function(data, err)
        if err or type(data) ~= "string" or data == "" then
            return
        end

        local response = decodeJson(data)
        local files = response and response.truncated ~= true and collectFiles(response.tree) or nil
        if not files then
            return
        end

        local missing = missingFiles(files)
        if #missing > 0 then
            downloadMissingFiles(missing)
        end
    end)
end

local function checkForUpdates()
    if type(HTTP) ~= "table" or type(HTTP.get) ~= "function" then
        log("HTTP indisponivel; verificacao adiada para a proxima abertura.")
        return
    end
    if g_resources.fileExists(PENDING_FILE) then
        log("Existe uma atualizacao pronta para o proximo reinicio.")
        return
    end

    HTTP.get(COMMITS_URL .. "?shazam=" .. tostring(os.time()), function(data, err)
        if err or type(data) ~= "string" or data == "" then
            log("Nao foi possivel verificar atualizacoes agora.")
            return
        end

        local commit = decodeJson(data)
        local remoteSha = commit and tostring(commit.sha or "") or ""
        if not validSha(remoteSha) then
            log("Resposta de commit invalida do GitHub. Nada foi verificado.")
            return
        end

        local localSha = getLocalCommit()
        if not localSha then
            -- Primeira vez que o updater roda nesta pasta: assume que a
            -- instalacao atual (feita pelo loader) ja reflete o estado
            -- recente do repositorio e so registra a linha de base, sem
            -- baixar nada de novo.
            setLocalCommit(remoteSha)
            log("Linha de base de atualizacao definida (commit " .. remoteSha:sub(1, 7) .. ").")
            return
        end

        if remoteSha ~= localSha then
            fetchTree(remoteSha)
        else
            log("Custom atualizada (commit " .. localSha:sub(1, 7) .. ").")
            checkMissingFiles()
        end
    end)
end

function ShazamUpdater.run()
    if SHAZAM_UPDATER_STARTED then
        return
    end
    SHAZAM_UPDATER_STARTED = true

    applyPending()

    if type(schedule) == "function" then
        schedule(CHECK_DELAY, checkForUpdates)
    else
        checkForUpdates()
    end
end
