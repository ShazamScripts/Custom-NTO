-- Shazam Loader (GitHub direto)
--
-- Coloque este arquivo sozinho numa pasta de perfil vazia e ative-o no
-- OTCv8. Na primeira execucao ele baixa a custom inteira direto do
-- repositorio publico no GitHub (lista de pastas/extensoes permitidas,
-- nada de dados pessoais). Depois de instalado, quem assume as proximas
-- atualizacoes e o updater normal (free_core/updater.lua), que ja vem
-- dentro do pacote baixado.
--
-- Depois da primeira instalacao, este arquivo pode continuar na pasta sem
-- problema: se detectar que a custom ja foi instalada, ele so chama o
-- 00_FREE_UNIVERSAL.lua e sai.

do
    -- Se a custom ja foi instalada nesta pasta, so inicia normalmente.
    if g_resources.fileExists((configDir or "") .. "/00_FREE_UNIVERSAL.lua") then
        dofile("/00_FREE_UNIVERSAL.lua")
        return
    end
end


-- ==== Configuracao ====
-- Repositorio publico no GitHub. Se um dia precisar trocar de dono/nome/
-- branch, so mexer nessas 3 linhas.
local GITHUB_OWNER = "ShazamScripts"
local GITHUB_REPO = "Custom-NTO"
local GITHUB_BRANCH = "main" -- troque para "master" se o repo usar esse nome

local TREE_URL = "https://api.github.com/repos/" .. GITHUB_OWNER .. "/" .. GITHUB_REPO
    .. "/git/trees/" .. GITHUB_BRANCH .. "?recursive=1"
local RAW_BASE_URL = "https://raw.githubusercontent.com/" .. GITHUB_OWNER .. "/" .. GITHUB_REPO
    .. "/" .. GITHUB_BRANCH .. "/"

local MAX_FILE_SIZE = 20 * 1024 * 1024
local MAX_FILES = 500

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
    local text = "[Shazam Loader] " .. tostring(message)
    if type(print) == "function" then print(text) end
end

local function notify(message)
    local text = "[Shazam Loader] " .. tostring(message)
    if type(warn) == "function" then warn(text) else print(text) end
end

-- ==== Caixa de progresso na tela ====
local progressWindow = nil
local progressLabel = nil

local function destroyProgressUI()
    if progressWindow then
        pcall(function() progressWindow:destroy() end)
        progressWindow = nil
        progressLabel = nil
    end
end

local function createProgressUI()
    if progressWindow then return end
    if type(g_ui) ~= "table" or rootWidget == nil then return end

    local ok, window = pcall(g_ui.createWidget, "UIWidget", rootWidget)
    if not ok or not window then return end

    progressWindow = window
    pcall(function()
        window:setId("shazamLoaderProgress")
        window:setWidth(380)
        window:setHeight(70)
        window:setBackgroundColor("#000000DD")
        window:centerIn("parent")
    end)

    local labelOk, label = pcall(g_ui.createWidget, "UIWidget", window)
    if labelOk and label then
        progressLabel = label
        pcall(function()
            label:fill("parent")
            label:setMargin(8)
            label:setColor("#FFFFFF")
            label:setTextAlign(AlignCenter)
            label:setTextWrap(true)
        end)
    end
end

local UI_INIT_RETRY_MS = 300
local MAX_UI_INIT_ATTEMPTS = 30

local function ensureProgressUI(callback)
    local attempts = 0
    local function attempt()
        createProgressUI()
        attempts = attempts + 1
        if progressWindow and progressLabel then
            callback()
        elseif attempts >= MAX_UI_INIT_ATTEMPTS then
            log("Nao foi possivel abrir a janela de progresso, continuando so pelo console/titulo.")
            callback()
        elseif type(schedule) == "function" then
            schedule(UI_INIT_RETRY_MS, attempt)
        else
            callback()
        end
    end
    attempt()
end

local function setProgressText(text, shortText)
    if progressLabel then
        pcall(function() progressLabel:setText(tostring(text)) end)
    end
    if not progressLabel then
        log(text)
    end
    if type(g_window) == "table" and type(g_window.setTitle) == "function" then
        pcall(function() g_window.setTitle("Shazam Loader - " .. tostring(shortText or text)) end)
    end
end

local function isAllowedPath(path)
    if type(path) ~= "string" or path == "" then return false end
    if path:sub(1, 1) == "/" or path:find("\\", 1, true)
        or path:find("..", 1, true) or path:find(":", 1, true) then
        return false
    end
    if ROOT_FILES[path] then return true end

    local allowedPrefix = false
    for _, prefix in ipairs(ALLOWED_PREFIXES) do
        if path:sub(1, #prefix) == prefix then
            allowedPrefix = true
            break
        end
    end
    if not allowedPrefix then return false end

    local extension = path:match("%.([%w]+)$")
    return extension ~= nil and ALLOWED_EXTENSIONS[extension:lower()] == true
end

local function ensureDirectory(path)
    if g_resources.directoryExists(path) then return true end
    local parent = tostring(path):match("^(.*)/[^/]+$")
    if parent and parent ~= "" and parent ~= path and not g_resources.directoryExists(parent) then
        if not ensureDirectory(parent) then return false end
    end
    local ok = pcall(g_resources.makeDir, path)
    return ok and g_resources.directoryExists(path)
end

local function ensureParent(path)
    local directory = tostring(path):match("^(.*)/[^/]+$")
    if not directory or directory == "" then return true end
    local current = ""
    for part in directory:gmatch("[^/]+") do
        current = current .. "/" .. part
        if not ensureDirectory(current) then return false end
    end
    return true
end

local function writeFile(path, contents)
    if type(contents) ~= "string" or not ensureParent(path) then return false end
    local ok = pcall(g_resources.writeFileContents, path, contents)
    return ok and g_resources.fileExists(path)
end

local function decodeJson(contents)
    if type(contents) ~= "string" or contents == "" then return nil end
    local ok, result = pcall(json.decode, contents)
    if not ok or type(result) ~= "table" then return nil end
    return result
end

local function encodedPath(path)
    local parts = {}
    for part in path:gmatch("[^/]+") do
        parts[#parts + 1] = part:gsub("([^%w%-%_%.~])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
    end
    return table.concat(parts, "/")
end

local function collectFiles(tree)
    if type(tree) ~= "table" then return nil end
    local files = {}
    for _, entry in ipairs(tree) do
        if type(entry) == "table" and entry.type == "blob" and isAllowedPath(entry.path) then
            local size = tonumber(entry.size) or 0
            if size > MAX_FILE_SIZE then return nil end
            if size > 0 then
                files[#files + 1] = { path = entry.path, size = size }
                if #files > MAX_FILES then return nil end
            end
        end
    end
    if #files < 5 then return nil end
    table.sort(files, function(a, b) return a.path < b.path end)
    return files
end

local function alreadyDownloaded(target, expectedSize)
    if not g_resources.fileExists(target) then return false end
    local ok, contents = pcall(g_resources.readFileContents, target)
    return ok and type(contents) == "string" and #contents == expectedSize
end

local REQUEST_TIMEOUT_MS = 15000
local MAX_ATTEMPTS = 3
local RETRY_DELAY_MS = 1500
local CONCURRENT_DOWNLOADS = 9

local function downloadFiles(files)
    local total = #files
    local skipped = 0
    local completed = 0
    local nextIndex = 1
    local failed = {}
    local finished = false

    local function updateProgress(currentPath, suffix)
        local percent = math.floor((completed / total) * 100)
        local text = string.format("Shazam Loader\nBaixando %d/%d (%d%%)", completed, total, percent)
        if currentPath then text = text .. "\n" .. currentPath end
        if suffix then text = text .. "\n" .. suffix end
        setProgressText(text, string.format("%d/%d (%d%%)", completed, total, percent))
    end

    local worker

    local function finishAll()
        if finished then return end
        finished = true
        local finishText
        if #failed > 0 then
            finishText = "Instalado, mas " .. #failed .. " arquivo(s) falharam: " ..
                table.concat(failed, ", ") .. ". Reabra o OTCv8 para tentar so esses."
        else
            finishText = "Instalacao concluida! (" .. total .. " arquivos, " .. skipped .. " ja existiam)\nIniciando a custom..."
        end
        notify(finishText)
        setProgressText("Shazam Loader\n" .. finishText, "concluido")

        local function launch()
            destroyProgressUI()
            dofile("/00_FREE_UNIVERSAL.lua")
        end
        if type(schedule) == "function" then
            schedule(1500, launch)
        else
            launch()
        end
    end

    local function onEntryDone()
        completed = completed + 1
        updateProgress()
        if completed >= total then
            finishAll()
        else
            worker()
        end
    end

    local function downloadEntry(entry, target)
        local attempt = 1
        local entryFinished = false

        local function tryDownload()
            local timedOut = false
            if type(schedule) == "function" then
                schedule(REQUEST_TIMEOUT_MS, function()
                    if entryFinished then return end
                    timedOut = true
                    log("Timeout em " .. entry.path .. " (tentativa " .. attempt .. "/" .. MAX_ATTEMPTS .. ")")
                    attempt = attempt + 1
                    if attempt > MAX_ATTEMPTS then
                        entryFinished = true
                        failed[#failed + 1] = entry.path
                        onEntryDone()
                    else
                        updateProgress(entry.path, string.format("Tentativa %d/%d (timeout)...", attempt, MAX_ATTEMPTS))
                        tryDownload()
                    end
                end)
            end

            HTTP.get(RAW_BASE_URL .. encodedPath(entry.path) .. "?loader=" .. tostring(os.time()), function(data, err)
                if entryFinished or timedOut then return end
                entryFinished = true

                if err or type(data) ~= "string" or #data == 0 or #data > MAX_FILE_SIZE then
                    attempt = attempt + 1
                    if attempt > MAX_ATTEMPTS then
                        failed[#failed + 1] = entry.path
                        onEntryDone()
                    else
                        entryFinished = false
                        updateProgress(entry.path, string.format("Tentativa %d/%d...", attempt, MAX_ATTEMPTS))
                        if type(schedule) == "function" then
                            schedule(RETRY_DELAY_MS, tryDownload)
                        else
                            tryDownload()
                        end
                    end
                    return
                end

                if not writeFile(target, data) then
                    failed[#failed + 1] = entry.path
                    onEntryDone()
                    return
                end

                onEntryDone()
            end)
        end

        tryDownload()
    end

    worker = function()
        local idx = nextIndex
        nextIndex = nextIndex + 1
        if idx > total then return end

        local entry = files[idx]
        local target = (configDir or "") .. "/" .. entry.path

        if alreadyDownloaded(target, entry.size) then
            skipped = skipped + 1
            onEntryDone()
            return
        end

        updateProgress(entry.path)
        log(string.format("Baixando (%d/%d ja concluidos): %s", completed, total, entry.path))
        downloadEntry(entry, target)
    end

    log("Instalando a custom (" .. total .. " arquivos, ate " .. CONCURRENT_DOWNLOADS .. " em paralelo)...")
    setProgressText(string.format("Shazam Loader\n%d arquivos encontrados no GitHub\nIniciando o download...", total),
        string.format("0/%d", total))

    local workersToStart = math.min(CONCURRENT_DOWNLOADS, total)
    for _ = 1, workersToStart do
        worker()
    end
end

local function fail(message)
    notify(message)
    setProgressText("Shazam Loader\n" .. message)
end

local function fetchTree()
    setProgressText("Shazam Loader\nConsultando lista de arquivos...", "consultando lista")

    if type(HTTP) ~= "table" or type(HTTP.get) ~= "function" then
        fail("HTTP indisponivel. Feche e reabra o OTCv8 para tentar novamente.")
        return
    end

    log("Consultando lista de arquivos...")
    HTTP.get(TREE_URL .. "&loader=" .. tostring(os.time()), function(data, err)
        if err or type(data) ~= "string" or data == "" then
            fail("Nao foi possivel consultar os arquivos. Verifique sua internet e reabra o OTCv8.")
            return
        end

        local response = decodeJson(data)
        if response and type(response.message) == "string" and response.message:find("rate limit", 1, true) then
            fail("Limite de consultas do GitHub atingido. Aguarde alguns minutos antes de reabrir o OTCv8.")
            return
        end

        local files = response and response.truncated ~= true and collectFiles(response.tree) or nil
        if not files then
            fail("Lista de arquivos invalida. Nada foi instalado.")
            return
        end
        downloadFiles(files)
    end)
end

ensureProgressUI(fetchTree)
