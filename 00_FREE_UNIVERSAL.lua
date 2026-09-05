-- Shazam Scripts - inicializador local para OTCv8/vBot.
-- Todos os modulos deste pacote sao carregados da propria pasta do perfil.

-- O atualizador roda antes dos demais modulos: aplica somente o pacote que ja
-- foi baixado na abertura anterior e depois agenda uma nova verificacao.
do
    local ok, err = pcall(dofile, "/free_core/updater.lua")
    if ok and type(ShazamUpdater) == "table" and type(ShazamUpdater.run) == "function" then
        local started, startError = pcall(ShazamUpdater.run)
        if not started then
            local text = "[Shazam Updater] Falha ao iniciar: " .. tostring(startError)
            if type(warn) == "function" then warn(text) else print(text) end
        end
    elseif not ok then
        local text = "[Shazam Updater] Falha ao carregar: " .. tostring(err)
        if type(warn) == "function" then warn(text) else print(text) end
    end
end

if FREE_UNIVERSAL_BOOTSTRAPPED == true then
    return
end
FREE_UNIVERSAL_BOOTSTRAPPED = true

-- Camada de seguranca deve entrar antes do CaveBot/TargetBot e das macros.
do
    local ok, err = pcall(dofile, "/free_core/safety.lua")
    if not ok then
        local text = "[Shazam Scripts] Falha ao carregar safety.lua: " .. tostring(err)
        if type(warn) == "function" then warn(text) else print(text) end
    end
end

-- Mantem explicitamente liberados os recursos antes separados por edicao.
FREE_VERSION = false
CHRONIC_VERSION = true
SHZ_CUSTOM_BUILD = "2.4.0"

-- ============================================================
-- Filtro de aviso "Slow macro"
-- ============================================================
-- Essas mensagens indicam que alguma macro demorou mais que o normal
-- pra rodar (pode ser um engasgo real do bot naquele instante). Filtrar
-- so esconde a mensagem, nao resolve a causa -- se aparecer de novo com
-- muita frequencia, desligue esse filtro (checkbox na aba "User") pra
-- voltar a ver os avisos e investigar.
if (type(warn) == "function" and not FREE_SLOW_MACRO_FILTER_APPLIED) then
    FREE_SLOW_MACRO_FILTER_APPLIED = true;
    local nativeWarnForSlowMacroFilter = warn;
    warn = function(message, ...)
        storage["checkBoxs"] = storage["checkBoxs"] or {};
        if (storage["checkBoxs"]["hideSlowMacroWarnings"] == true and type(message) == "string" and message:find("^Slow macro")) then
            return;
        end
        return nativeWarnForSlowMacroFilter(message, ...);
    end
end

schedule(500, function()
    if (type(addCheckBox) ~= "function") then return; end
    setDefaultTab("User");
    local hideSlowMacroCheckBox = addCheckBox("hideSlowMacroWarnings", "Esconder avisos de Slow macro", function() end);
    if (hideSlowMacroCheckBox) then
        hideSlowMacroCheckBox:setTooltip("So esconde a MENSAGEM. Se a macro continuar realmente lenta, o atraso no jogo continua acontecendo -- isso so tira o aviso da tela.");
    end
end)

if not string.ucwords then
    function string.ucwords(value)
        return tostring(value or ""):gsub("(%a)([%w_']*)", function(first, rest)
            return first:upper() .. rest:lower()
        end)
    end
end

-- A protecao de getDistanceBetween/findPath fica centralizada em safety.lua.

-- Estilo global "limpo" do BotSwitch (texto branco quando desligado, verde
-- quando ligado, sem a barra de fundo vermelha/verde). Precisa ser importado
-- ANTES de qualquer modulo/macro ser criado, para valer para todas as
-- macros da custom -- inclusive as criadas com macro() e as que forem
-- adicionadas depois.
do
    local ok, err = pcall(importStyle, "/extras/basic_shazam.otui")
    if not ok then
        local text = "[Shazam Scripts] Falha ao carregar basic_shazam.otui: " .. tostring(err)
        if type(warn) == "function" then warn(text) else print(text) end
    end
end

modules = modules or {}
game_console = game_console or modules.game_console or modules.game_chat

if type(tyrBot) ~= "table" then
    tyrBot = {}
end

if type(FREE_ENSURE_TYRBOT_COMPAT) ~= "function" then
    FREE_ENSURE_TYRBOT_COMPAT = function()
        if type(tyrBot) ~= "table" then
            tyrBot = {}
        end

        tyrBot.configData = tyrBot.configData or {}
        tyrBot.storage = tyrBot.storage or storage or {}

        local compatStorage = tyrBot.storage
        compatStorage.task = compatStorage.task or {}
        compatStorage.taskData = compatStorage.taskData or {}
        compatStorage.widgetPos = compatStorage.widgetPos or {}
        compatStorage.checkBoxs = compatStorage.checkBoxs or {}
        compatStorage._configs = compatStorage._configs or {}
        compatStorage._configs.cavebot_configs = compatStorage._configs.cavebot_configs
            or {enabled = false, selected = ""}
        compatStorage._configs.targetbot_configs = compatStorage._configs.targetbot_configs
            or {enabled = false, selected = ""}
        if compatStorage._configs.cavebot_configs.enabled == nil then
            compatStorage._configs.cavebot_configs.enabled = false
        end
        if compatStorage._configs.cavebot_configs.selected == nil then
            compatStorage._configs.cavebot_configs.selected = ""
        end
        if compatStorage._configs.targetbot_configs.enabled == nil then
            compatStorage._configs.targetbot_configs.enabled = false
        end
        if compatStorage._configs.targetbot_configs.selected == nil then
            compatStorage._configs.targetbot_configs.selected = ""
        end

        tyrBot.getAttackingCreature = tyrBot.getAttackingCreature or function()
            local game = g_game or (modules._G and modules._G.g_game)
            if game and type(game.getAttackingCreature) == "function" then
                return game.getAttackingCreature()
            end
            return nil
        end

        tyrBot.doAttack = tyrBot.doAttack or function(creature)
            if not creature then return false end
            local game = g_game or (modules._G and modules._G.g_game)
            if game and type(game.attack) == "function" then
                game.attack(creature)
                return true
            end
            return false
        end

        tyrBot.getSpectators = tyrBot.getSpectators or function(...)
            if type(getSpectators) == "function" then
                return getSpectators(...)
            end
            return {}
        end

        tyrBot.getWorldName = tyrBot.getWorldName or function()
            local game = g_game or (modules._G and modules._G.g_game)
            local name = game and type(game.getWorldName) == "function" and game.getWorldName() or ""
            return tostring(name):gsub("[^%w%s]", "")
        end

        tyrBot.saveStorage = tyrBot.saveStorage or function()
            if type(saveConfig) == "function" then
                return saveConfig()
            end
        end

        tyrBot.friendList = tyrBot.friendList or {}
        tyrBot.friendList.isFriend = tyrBot.friendList.isFriend or function(name)
            if type(name) ~= "string" and name and type(name.getName) == "function" then
                name = name:getName()
            end
            name = tostring(name or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
            local names = (global_storage and global_storage.tyrFriendlist)
                or (storage and storage.tyrFriendlist) or {}
            for _, friendName in ipairs(names) do
                local normalized = tostring(friendName):lower():gsub("^%s+", ""):gsub("%s+$", "")
                if normalized == name then return true end
            end
            return false
        end
        tyrBot.friendList.window = tyrBot.friendList.window or {show = function() end}
    end
end

FREE_ENSURE_TYRBOT_COMPAT()

-- A custom original criava este alias antes das macros. Em uma instalacao
-- nova ele pode nao existir ainda, entao inicializamos de forma compativel.
storage = storage or tyrBot.storage or {}
global_storage = global_storage or storage
global_storage.tyrFriendlist = global_storage.tyrFriendlist or {}

-- Precisa rodar ANTES de QUALQUER modulo (incluindo o proprio motor do
-- CaveBot/TargetBot) ler/criar chaves no "storage", senao alguem cria a
-- config padrao ANTES da separacao por personagem, e ela acaba sendo
-- apagada depois por engano.
do
    local ok, err = pcall(dofile, "/free_core/character_storage.lua")
    if not ok then
        local text = "[Shazam Scripts] Falha ao carregar character_storage.lua: " .. tostring(err)
        if type(warn) == "function" then warn(text) else print(text) end
    end
end

FREE_GET_WORLD_IP = FREE_GET_WORLD_IP or function()
    local game = g_game or (modules._G and modules._G.g_game)
    if not game or type(game.getWorldIp) ~= "function" then
        return ""
    end
    local ok, value = pcall(game.getWorldIp)
    return ok and tostring(value or "") or ""
end

local function reportLoadError(path, message)
    local text = "[Shazam Scripts] Falha ao carregar " .. path .. ": " .. tostring(message)
    if type(warn) == "function" then
        warn(text)
    elseif type(print) == "function" then
        print(text)
    end
end

local function safeLoad(path)
    local ok, result = pcall(dofile, path)
    if not ok then
        reportLoadError(path, result)
    end
    return ok
end

-- O Main ja existe no vBot. As demais abas sao criadas nesta ordem antes
-- do CaveBot/TargetBot para manter a barra sempre organizada.
for _, tabName in ipairs({"Main", "User", "UTI", "Others", "Cave", "Target"}) do
    setDefaultTab(tabName)
end

-- O loader original iniciava o motor antes dos modulos opcionais. Isso garante
-- que qualquer macro possa consultar CaveBot/TargetBot durante sua inicializacao.
safeLoad("/free_core/cavebot_loader.lua")

-- Registra cada arquivo carregado pelas listas manuais abaixo, pra que a
-- auto-deteccao no final do arquivo (autoLoadNewModules) nao carregue o
-- mesmo arquivo duas vezes.
local loadedFreeModules = {}

local function loadInTab(tabName, file)
    setDefaultTab(tabName)
    safeLoad("/free_modules/" .. file)
    loadedFreeModules[file] = true
end

-- On_exit.lua primeiro (define onExitRegister).
loadInTab("Main", "On_exit.lua")

-- O character_storage.lua ja carregou la no inicio (antes do CaveBot).
-- Agora que o On_exit.lua existe, registramos o salvamento automatico ao sair.
if type(onExitRegister) == "function" and type(ShazamSaveCharacterStorage) == "function" then
    onExitRegister(ShazamSaveCharacterStorage)
end

-- Dependencias compartilhadas, sem botoes proprios.
for _, file in ipairs({
    "Config_key.lua",
    "Attack.lua",
    "Getattackingcreature.lua",
    "Order_say.lua",
    "Queue_call.lua"
}) do
    loadInTab("Main", file)
end

-- Misc mantem configuracoes em User, Treinar em UTI e somente o editor
-- In-game scripts em Others.
loadInTab("User", "Misc.lua")

-- Utilidades reunidas na nova aba UTI.
for _, file in ipairs({
    "Auto_trainer.lua",
    "Travel_system.lua",
    "UTI_tools.lua",
    "Macros.lua",
    "barrinha.lua",
}) do
    loadInTab("UTI", file)
end

-- ============================================================
-- CARREGAR O CABEÇALHO "Shazam Scripts" AGORA (antes dos módulos)
-- ============================================================
safeLoad("/extras/icon.lua")   -- opcional, mas pode ficar antes
safeLoad("/extras/main.lua")   -- este cria o label no topo

-- ============================================================
-- MODULOS PRINCIPAIS (aba Main), organizados por categoria.
-- ============================================================
setDefaultTab("Main")
for _, file in ipairs({
    "Combo.lua",
    "ComboUP.lua",
    "enemytimespell.lua",
    "Especiais.lua",
    "Mystic.lua",
    "Target.lua",          -- Attack Target
}) do
    loadInTab("Main", file)
end

setDefaultTab("Main")
for _, file in ipairs({
    "Stairs.lua",          -- Escadas
    "Jump_with_mark.lua",  -- Jump on Walk / Auto Jump / Salvar Jumps
    "Push.lua",
    "AtalhosTeclasMouse.lua",
    "Sense.lua",
    "Stack.lua",
    "Auto_kai.lua",        -- Anti Trap
    "Friend_list.lua",     -- Janela de amigos
    "Follow_target.lua",
}) do
    loadInTab("Main", file)
end

setDefaultTab("Main")
for _, file in ipairs({
    "Battle_filter.lua",
    -- "Storage.lua" e "Follow_friend.lua"/"Retroverse_spy_discord.lua"/
    -- "Reconnect_recover.lua" foram REMOVIDOS DE VERDADE da pasta
    -- free_modules/ (nao so tirados desta lista). Antes eles ainda
    -- existiam como arquivo e acabavam sendo recarregados escondidos
    -- na aba "Others" pelo auto-detector la embaixo (autoLoadNewModules).
}) do
    loadInTab("Main", file)
end

-- Cave mantem somente o motor manual e seus alarmes.
loadInTab("Cave", "Alarms.lua")

-- Target mantem somente recursos ligados ao alvo/loot manual.
-- (Target.lua foi movido para Main)
setDefaultTab("Main")
for _, file in ipairs({
    "Enemy.lua",
    "Bug_map.lua",
    "Combo_leader.lua",
    "Better_looting.lua"
}) do
    loadInTab("Target", file)
end

-- ============================================================
-- AUTO-DETECCAO DE MACROS NOVAS
-- Qualquer arquivo .lua novo colocado em free_modules/ que NAO esteja em
-- nenhuma das listas manuais acima e carregado automaticamente aqui, sem
-- precisar editar este arquivo. Cai na aba "Others" por padrao; se quiser
-- que uma macro nova apareca numa aba especifica (Main/UTI/Cave/Target) ou
-- numa ordem especifica (ex: um modulo que depende de outro carregar
-- antes), e so adicionar o nome numa das listas manuais acima como sempre
-- - isso tem prioridade sobre a auto-deteccao.
--
-- Limitacao: os arquivos pegos aqui carregam em ordem alfabetica, DEPOIS
-- de tudo que ja esta nas listas manuais. Se uma macro nova depender de
-- outra macro nova, cure manualmente a ordem numa lista acima.
-- ============================================================
local function autoLoadNewModules()
    local ok, files = pcall(g_resources.listDirectoryFiles, "/free_modules")
    if not ok or type(files) ~= "table" then
        return
    end

    table.sort(files)
    for _, file in ipairs(files) do
        local isLuaFile = file:sub(-4) == ".lua"
        local isHidden = file:sub(1, 1) == "."
        if isLuaFile and not isHidden and not loadedFreeModules[file] then
            if type(print) == "function" then
                print("[Shazam Scripts] Macro nova detectada em free_modules/: " .. file .. " (carregada na aba Others)")
            end
            loadInTab("Others", file)
        end
    end
end
autoLoadNewModules()

if type(print) == "function" then
    print("[Shazam Scripts] Custom local carregada.")
end
