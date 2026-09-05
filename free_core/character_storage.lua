-- ============================================================
-- STORAGE SEPARADO POR PERSONAGEM (tudo, exceto Jump)
-- ============================================================
-- Problema: o "storage" nativo do vBot fica preso ao PERFIL do bot
-- selecionado no client (ex.: profile_1.json), nao ao personagem logado.
-- Se dois personagens usam o mesmo perfil, ambos leem/escrevem no MESMO
-- arquivo -> toda configuracao (Combo, Especiais, Mystic, Stack, treinador,
-- CaveBot, TargetBot, etc.) aparece repetida entre contas diferentes.
--
-- Este modulo isola TODO o storage por personagem (arquivo proprio por
-- nick), EXCETO as chaves na lista EXCLUDED_KEYS abaixo, que sao
-- gerenciadas pelo proprio client/bot e nao devem ser mexidas:
--   - "DIST_ID" / "CLOSE_ID": parecem ser identificadores internos do
--      bot/licenca, nao configuracao do personagem — mais seguro nao
--      duplicar/mexer nisso.
--   - "tyrFriendlist": ver comentario ao lado da chave, mais abaixo.
--
-- O storage do Jump (pontos salvos de Jump Up/Down) continua GLOBAL,
-- compartilhado entre todos os personagens do mesmo mundo — o proprio
-- Jump_with_mark.lua le/grava isso direto num arquivo separado (nao
-- dentro de "storage"), entao este modulo nao encosta nele.
--
-- FIX (macros ligadas/desligadas vazando entre bonecos e resetando apos
-- queda de conexao): "_macros" (Attack Target, Escadas, Sense, Push, Bug
-- Map, Follow RTS, Follow Normal, Aceitar/Invitar PT) TAMBEM e isolado por
-- personagem agora -- ver ensureMacrosTable/forceReloadMacroStates mais
-- abaixo.
--
-- Roda DEPOIS do On_exit.lua (que cria onExitRegister) e ANTES de
-- qualquer modulo (Combo, Especiais, Mystic, Stack, CaveBot, TargetBot,
-- etc.) ler "storage".
--
-- FIX (personagem "vindo com a cave/target de outro boneco" apos queda/
-- relog): a versao anterior deste arquivo so detectava o personagem
-- logado UMA VEZ, no instante em que o proprio arquivo era lido (dofile).
-- Isso funciona para o primeiro login, mas o client so carrega os scripts
-- da custom UMA VEZ por sessao -- se a conexao cai e o client reloga
-- sozinho (ou troca de personagem/conta sem reiniciar o client), o jogo
-- muda de personagem SEM os scripts recarregarem. O "storage" em memoria
-- (e, por consequencia, storage._configs.cavebot_configs.selected e
-- storage._configs.targetbot_configs.selected, que e onde fica gravado
-- QUAL cave/target esta ativo) continuava sendo o do personagem anterior.
-- Agora, alem da carga inicial, tambem escutamos o evento onGameStart
-- (disparado pelo client toda vez que uma sessao de jogo comeca -- login
-- inicial OU reconexao automatica) e reconferimos quem esta logado. Se o
-- personagem mudou: salvamos o storage do boneco anterior, carregamos o
-- storage do personagem novo e forcamos o CaveBot/TargetBot a descartar o
-- que tinham em memoria e reler a config (cave/target selecionado +
-- ligado/desligado) que pertence a ESTE personagem.
-- ============================================================

if CHARACTER_STORAGE_BOOTSTRAPPED == true then
    return
end
CHARACTER_STORAGE_BOOTSTRAPPED = true

local storageDir = "/shazam_scripts/storage"

-- Preenchidos por switchToCharacter() -- comecam vazios porque, quando
-- este arquivo carrega, o personagem pode ainda nem estar logado.
local characterName = nil
local worldName = nil
local worldDir = nil
local characterFile = nil
local migrationFlagFile = nil
local migrateNowFile = nil

local EXCLUDED_KEYS = {
    ["DIST_ID"] = true,
    ["CLOSE_ID"] = true,
    -- "tyrFriendlist" precisa ficar de fora do isolamento por personagem:
    -- ela vive dentro do mesmo objeto "storage" (global_storage aponta pra
    -- ele), entao sem essa excecao ela era apagada por clearCharacterKeys()
    -- logo no boot, antes do Friend_list.lua conseguir usa-la (erro
    -- "bad argument #1 to 'ipairs' (table expected, got nil)").
    ["tyrFriendlist"] = true,
    -- NOTE: "_macros" costumava ficar de fora do isolamento, tratada como
    -- "estado interno do bot". Na pratica isso significa que, quando 2
    -- bonecos usam o mesmo profile_N.json, o ligado/desligado das macros
    -- de um vaza pro outro -- e quando a conexao cai e reconecta, se o
    -- engine desliga alguma macro por seguranca, essa mudanca fica salva
    -- pra sempre no arquivo compartilhado, ligado ou nao originalmente.
    -- Agora "_macros" e isolado por personagem igual ao resto (ver
    -- ensureMacrosTable/forceReloadMacroStates mais abaixo).
}

local function ensureDir(dir)
    if not g_resources.directoryExists(dir) then
        g_resources.makeDir(dir)
    end
end

-- "_macros" precisa sempre existir como tabela (e o que o engine nativo
-- espera), mesmo para um personagem que ainda nao tem nenhuma macro salva.
local function ensureMacrosTable()
    if type(storage["_macros"]) ~= "table" then
        storage["_macros"] = {}
    end
end

-- Remove do storage global todas as chaves que sao "do personagem"
-- (tudo, menos as excluidas), para nao vazar dados de outro boneco.
local function clearCharacterKeys()
    for key in pairs(storage) do
        if not EXCLUDED_KEYS[key] then
            storage[key] = nil
        end
    end
    ensureMacrosTable()
end

local function saveCharacterStorage()
    if not characterFile then
        return -- ainda nao sabemos quem esta logado, nao ha o que salvar
    end

    local snapshot = {}
    for key, value in pairs(storage) do
        if not EXCLUDED_KEYS[key] then
            snapshot[key] = value
        end
    end

    local ok, encoded = pcall(function()
        return json.encode(snapshot)
    end)

    if ok then
        g_resources.writeFileContents(characterFile, encoded)
    else
        print("[Shazam Scripts] Aviso: falha ao salvar storage de " .. tostring(characterName) .. ": " .. tostring(encoded))
    end
end

local function loadCharacterStorage()
    if not g_resources.fileExists(characterFile) then
        if g_resources.fileExists(migrateNowFile) and not g_resources.fileExists(migrationFlagFile) then
            -- Voce mesmo pediu explicitamente pra migrar o storage
            -- compartilhado atual (profile_N.json) para este personagem.
            -- Uso tipico: voce esta atualizando esse fix no SEU proprio
            -- boneco e quer manter o que ja tinha configurado.
            g_resources.writeFileContents(migrationFlagFile, "1")
            g_resources.deleteFile(migrateNowFile)
            saveCharacterStorage()
            return
        end

        -- Sem pedido explicito de migracao: SEMPRE comeca limpo. Isso
        -- cobre tanto "personagem realmente novo" quanto "custom
        -- compartilhada com outra pessoa" -- em ambos os casos, ninguem
        -- deve herdar dados de outro boneco por padrao.
        clearCharacterKeys()
        return
    end

    local ok, data = pcall(function()
        return json.decode(g_resources.readFileContents(characterFile))
    end)

    if not ok or type(data) ~= "table" then
        print("[Shazam Scripts] Aviso: nao foi possivel ler o storage de " .. tostring(characterName) .. ": " .. tostring(data))
        return
    end

    clearCharacterKeys()
    for key, value in pairs(data) do
        if not EXCLUDED_KEYS[key] then
            storage[key] = value
        end
    end
    ensureMacrosTable()
end

-- Forca um bot (CaveBot ou TargetBot) a descartar o que tem em memoria e
-- reler do "storage" qual config esta selecionada + se deve estar ligado.
-- Usa so a API publica (CaveBot.isOn/setOn/setOff, TargetBot.isOn/setOn/
-- setOff), entao NAO precisa mexer em cavebot.lua/target.lua.
local function forceReloadBotConfig(bot, desiredOn)
    if type(bot) ~= "table" or type(bot.isOn) ~= "function" then
        return
    end

    -- setOn()/setOff() so disparam o "refresh" (que rele a config do
    -- disco) quando o estado realmente muda. Garante pelo menos 1 troca
    -- de estado, seja qual for o estado atual, pra forcar esse refresh.
    if bot.isOn() then
        bot.setOff()
    else
        bot.setOn()
    end

    -- Agora deixa no estado que este personagem realmente tinha salvo.
    if desiredOn then
        bot.setOn()
    else
        bot.setOff()
    end
end

-- Mapeamento "nome salvo em storage._macros" -> funcao que acha o objeto de
-- macro "ao vivo" (o que a UI realmente liga/desliga quando voce clica no
-- switch). So existem depois que os respectivos modulos (Target.lua,
-- Stairs.lua, Sense.lua, Push.lua, Bug_map.lua, Macros.lua) carregarem --
-- por isso cada entrada e uma funcao, avaliada so na hora de reaplicar.
-- Pra adicionar mais macros aqui: ache como o modulo expoe o objeto que
-- macro(...) retornou (normalmente em tyrBot.configData.<algo>.macro, ou
-- direto como variavel global).
local MACRO_LIVE_REFS = {
    ["Attack Target"] = function()
        return tyrBot and tyrBot["configData"] and tyrBot["configData"]["keepTarget"]
            and tyrBot["configData"]["keepTarget"]["macro"]
    end,
    ["Escadas"] = function()
        return tyrBot and tyrBot["configData"] and tyrBot["configData"]["stairs"]
            and tyrBot["configData"]["stairs"]["macro"]
    end,
    ["Sense"] = function()
        return tyrBot and tyrBot["configData"] and tyrBot["configData"]["sense"]
            and tyrBot["configData"]["sense"]["macro"]
    end,
    ["Push"] = function()
        return tyrBot and tyrBot["configData"] and tyrBot["configData"]["push"]
            and tyrBot["configData"]["push"]["macro"]
    end,
    ["Bug Map"] = function()
        return tyrBot and tyrBot["configData"] and tyrBot["configData"]["bugMap"]
            and tyrBot["configData"]["bugMap"]["macro"]
    end,
    ["Follow RTS"] = function()
        return type(ultimateFollow) == "table" and ultimateFollow or nil
    end,
    ["Follow Normal"] = function()
        return type(followNormalMacro) == "table" and followNormalMacro or nil
    end,
    ["Aceitar PT"] = function()
        return type(aceitarPTMacro) == "table" and aceitarPTMacro or nil
    end,
    ["Invitar PT"] = function()
        return type(invitarPTMacro) == "table" and invitarPTMacro or nil
    end,
}

-- Forca os switches de macro "ao vivo" a assumirem o ligado/desligado que
-- acabamos de carregar do arquivo deste personagem. So e necessario numa
-- troca em pleno jogo (reconexao) -- no boot inicial os proprios modulos
-- ainda vao carregar e ja vao ler storage._macros sozinhos, na ordem certa.
local function forceReloadMacroStates()
    local savedMacros = storage["_macros"]
    if type(savedMacros) ~= "table" then return end

    for macroName, getLiveMacro in pairs(MACRO_LIVE_REFS) do
        local ok, liveMacro = pcall(getLiveMacro)
        if ok and type(liveMacro) == "table" and type(liveMacro["setOn"]) == "function" then
            local desiredOn = savedMacros[macroName] == true
            pcall(function() liveMacro["setOn"](desiredOn) end)
        end
    end
end

local function switchToCharacter(newCharacterName)
    if type(newCharacterName) ~= "string" or newCharacterName == "" then
        return -- ainda nao logado
    end

    if newCharacterName == characterName then
        return -- mesmo personagem de antes, nada a fazer
    end

    local isFirstSwitch = (characterName == nil)

    -- Salva o boneco anterior antes de trocar os caminhos de arquivo.
    if not isFirstSwitch then
        saveCharacterStorage()
    end

    characterName = newCharacterName
    worldName = tyrBot.getWorldName()
    worldDir = storageDir .. "/" .. worldName
    characterFile = worldDir .. "/" .. characterName .. "_bot_storage.json"
    migrationFlagFile = worldDir .. "/_shared_storage_migrated.flag"
    migrateNowFile = worldDir .. "/_migrate_now.flag"

    ensureDir(storageDir)
    ensureDir(worldDir)

    loadCharacterStorage()

    if isFirstSwitch then
        print("[Shazam Scripts] Storage isolado por personagem ativo para " .. characterName .. " (" .. worldName .. ").")
    else
        -- CaveBot/TargetBot ja estavam carregados na memoria com os dados
        -- do personagem anterior -- forca os dois a relerem a cave/target
        -- (nome + ligado/desligado) que acabamos de carregar pra ESTE
        -- personagem. Sem isso, o storage ja estaria certo mas a engine
        -- continuaria rodando os waypoints/criaturas antigos ate alguem
        -- mexer manualmente no switch do CaveBot/TargetBot.
        if type(CaveBot) == "table" then
            local cfg = storage["_configs"] and storage["_configs"]["cavebot_configs"]
            forceReloadBotConfig(CaveBot, cfg ~= nil and cfg["enabled"] == true)
        end
        if type(TargetBot) == "table" then
            local cfg = storage["_configs"] and storage["_configs"]["targetbot_configs"]
            forceReloadBotConfig(TargetBot, cfg ~= nil and cfg["enabled"] == true)
        end
        forceReloadMacroStates()
        print("[Shazam Scripts] Personagem trocado para " .. characterName .. " (" .. worldName .. ") -- storage, cave, target e macros recarregados.")
    end
end

-- Carga inicial (o proprio dofile deste arquivo). Cobre o caso comum de
-- o personagem ja estar logado quando a custom e ativada.
do
    local ok, name = pcall(function()
        return g_game.getCharacterName() and g_game.getCharacterName():trim():gsub("[^%w%s]", "") or ""
    end)
    switchToCharacter(ok and name or "")
end

-- A partir daqui, toda vez que uma sessao de jogo comecar (login inicial,
-- queda de conexao com relogin automatico, ou troca manual de conta no
-- mesmo client) reconferimos o personagem logado. E o que faltava para
-- cobrir "o jogo caiu e relogou com outro boneco" sem depender de reiniciar
-- o client / recarregar a custom inteira.
--
-- FIX (crash "attempt to call global 'connect' (a nil value)"): este
-- arquivo carrega bem cedo no boot (antes da maioria dos modulos), e nesse
-- momento o global "connect" nem sempre esta pronto ainda. O resto da
-- custom busca funcoes assim direto de modules["_G"] (ex.: addEvent,
-- scheduleEvent em Stairs.lua) -- fazemos o mesmo aqui, com fallback
-- seguro caso realmente nao esteja disponivel.
local connectFn = (type(connect) == "function" and connect)
    or (modules and modules["_G"] and modules["_G"]["connect"])

if type(connectFn) == "function" then
    connectFn(g_game, {
        onGameStart = function()
            local ok, name = pcall(function()
                return g_game.getCharacterName() and g_game.getCharacterName():trim():gsub("[^%w%s]", "") or ""
            end)
            if ok then
                switchToCharacter(name)
            end
        end,
        onGameEnd = function()
            -- Salva imediatamente ao desconectar/deslogar, sem depender so do
            -- On_exit.lua (que cobre fechar o client, nao uma queda de conexao
            -- no meio da sessao seguida de relogin).
            saveCharacterStorage()
        end,
    })
else
    print("[Shazam Scripts] Aviso: 'connect' indisponivel no boot; deteccao automatica de relogin desativada (storage por personagem continua funcionando no login inicial).")
end

-- Intercepta o saveConfig nativo: toda vez que o bot salva (o que ja
-- acontece o tempo todo ao editar qualquer modulo), tambem gravamos a
-- copia isolada por personagem.
--
-- FIX (storage saindo so pelo shazam_scripts): o saveConfig nativo grava o
-- "storage" atual inteiro no profile_N.json do client (o mesmo arquivo que
-- viaja dentro da pasta da custom quando ela e compartilhada). Antes disso
-- rodar, escondemos temporariamente do "storage" tudo que e "do
-- personagem" (Especiais, Combo, Mystic, ptSystem, pvpPanel, mwPos, cave/
-- target selecionados, macros ligadas/desligadas, etc.), deixando so o que
-- o motor realmente precisa (DIST_ID, CLOSE_ID). Assim o profile_N.json
-- nativo nunca mais grava nada pessoal -- so o nosso arquivo dentro de
-- /shazam_scripts/storage tem os dados de verdade. Logo depois devolvemos
-- tudo pro "storage" em memoria, pra o jogo continuar funcionando
-- normalmente na sessao atual.
local nativeSaveConfig = type(saveConfig) == "function" and saveConfig or nil
saveConfig = function(...)
    local result

    if nativeSaveConfig then
        local hidden = {}
        for key, value in pairs(storage) do
            if not EXCLUDED_KEYS[key] then
                hidden[key] = value
                storage[key] = nil
            end
        end

        result = nativeSaveConfig(...)

        for key, value in pairs(hidden) do
            storage[key] = value
        end
    end

    saveCharacterStorage()
    return result
end

-- Garante que salva tambem ao fechar o client / trocar de personagem.
-- Exposto como global porque o On_exit.lua ainda nao existe neste ponto
-- (esse arquivo agora carrega bem no inicio, antes de tudo); o proprio
-- 00_FREE_UNIVERSAL.lua registra isso depois, assim que o On_exit.lua
-- estiver disponivel.
ShazamSaveCharacterStorage = saveCharacterStorage
