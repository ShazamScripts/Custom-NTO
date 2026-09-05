-- FREE: compatibilidade segura para executar sem o loader tyrBot original.
if (type(tyrBot) ~= "table") then
    tyrBot = {};
end

if (type(FREE_ENSURE_TYRBOT_COMPAT) ~= "function") then
    FREE_ENSURE_TYRBOT_COMPAT = function()
        if (type(tyrBot) ~= "table") then
            tyrBot = {};
        end

        tyrBot["configData"] = tyrBot["configData"] or {};
        tyrBot["storage"] = tyrBot["storage"] or storage or {};

        local compatStorage = tyrBot["storage"];
        compatStorage["task"] = compatStorage["task"] or {};
        compatStorage["taskData"] = compatStorage["taskData"] or {};
        compatStorage["widgetPos"] = compatStorage["widgetPos"] or {};
        compatStorage["checkBoxs"] = compatStorage["checkBoxs"] or {};
        compatStorage["_configs"] = compatStorage["_configs"] or {};
        compatStorage["_configs"]["cavebot_configs"] = compatStorage["_configs"]["cavebot_configs"] or {};
        compatStorage["_configs"]["targetbot_configs"] = compatStorage["_configs"]["targetbot_configs"] or {};

        tyrBot["getAttackingCreature"] = tyrBot["getAttackingCreature"] or function()
            local game = g_game or (modules and modules["_G"] and modules["_G"]["g_game"]);
            if (game and type(game["getAttackingCreature"]) == "function") then
                return game["getAttackingCreature"]();
            end
            return nil;
        end;

        tyrBot["doAttack"] = tyrBot["doAttack"] or function(creature)
            if (not creature) then return false; end
            local game = g_game or (modules and modules["_G"] and modules["_G"]["g_game"]);
            if (game and type(game["attack"]) == "function") then
                game["attack"](creature);
                return true;
            end
            return false;
        end;

        tyrBot["getSpectators"] = tyrBot["getSpectators"] or function(...)
            if (type(getSpectators) == "function") then
                return getSpectators(...);
            end
            return {};
        end;

        tyrBot["getWorldName"] = tyrBot["getWorldName"] or function()
            local game = g_game or (modules and modules["_G"] and modules["_G"]["g_game"]);
            local worldName = game and type(game["getWorldName"]) == "function" and game["getWorldName"]() or "";
            return tostring(worldName):gsub("[^%w%s]", "");
        end;

        tyrBot["saveStorage"] = tyrBot["saveStorage"] or function()
            if (type(saveConfig) == "function") then
                return saveConfig();
            end
        end;

        tyrBot["friendList"] = tyrBot["friendList"] or {};
        tyrBot["friendList"]["isFriend"] = tyrBot["friendList"]["isFriend"] or function(name)
            if (type(name) ~= "string" and name and type(name.getName) == "function") then
                name = name:getName();
            end
            name = tostring(name or ""):lower():gsub("^%s+", ""):gsub("%s+$", "");
            local names = global_storage and global_storage["tyrFriendlist"] or storage and storage["tyrFriendlist"] or {};
            for _, friendName in ipairs(names) do
                local normalized = tostring(friendName):lower():gsub("^%s+", ""):gsub("%s+$", "");
                if (normalized == name) then
                    return true;
                end
            end
            return false;
        end;
        tyrBot["friendList"]["window"] = tyrBot["friendList"]["window"] or {
            show = function() end
        };
    end
end

FREE_ENSURE_TYRBOT_COMPAT();
autoTrainer = {};

trainerIcon = setupUI("Panel\n  height: 17\n  BotSwitch\n    id: title\n    anchors.top: parent.top\n    anchors.left: parent.left\n    text-align: center\n    width: 130\n    text: Auto Trainer \n    image-source:\n\n    $on:\n      color: green\n\n    $!on:\n      color: white\n\n  Button\n    id: settings\n    anchors.top: prev.top\n    anchors.left: prev.right\n    anchors.right: parent.right\n    margin-left: 3\n    height: 17\n    text: Setup\n");


trainerInterface = setupUI("MainWindow\n  text: Auto Trainer Panel\n  size: 200 400\n\n  Label\n    id: spellTrainLabel\n    anchors.horizontalCenter: parent.horizontalCenter\n    anchors.top: parent.top\n    text: Train Spell\n    margin-top: 10\n\n  TextEdit\n    id: spellTrain\n    anchors.horizontalCenter: parent.horizontalCenter\n    anchors.top: parent.top\n    margin-top: 30\n    width: 100\n\n  Label\n    id: spellRecoverLabel\n    anchors.horizontalCenter: parent.horizontalCenter\n    anchors.top: parent.top\n    text: Recover Spell\n    margin-top: 60\n\n  TextEdit\n    id: spellRecover\n    anchors.horizontalCenter: parent.horizontalCenter\n    anchors.top: parent.top\n    margin-top: 80\n    width: 100\n\n  BotItem\n    id: itemRecover\n    anchors.horizontalCenter: parent.horizontalCenter\n    anchors.top: parent.top\n    margin-top: 76\n\n  CheckBox\n    id: changeItemOrSpell\n    anchors.left: spellRecoverLabel.left\n    anchors.top: parent.top\n    margin-top: 85\n    margin-left: 95\n\n  Label\n    id: percentTrainLabel\n    anchors.horizontalCenter: parent.horizontalCenter\n    anchors.top: parent.top\n    text: Percent Train\n    margin-top: 110\n\n  HorizontalScrollBar\n    id: percentTrain\n    anchors.horizontalCenter: parent.horizontalCenter\n    anchors.top: parent.top\n    margin-top: 130\n    width: 125\n    minimum: 0\n    maximum: 100\n    step: 1\n\n  Label\n    id: trainerNameLabel\n    anchors.horizontalCenter: parent.horizontalCenter\n    anchors.top: parent.top\n    text: Trainer Name\n    margin-top: 160\n\n  TextEdit\n    id: trainerName\n    anchors.horizontalCenter: parent.horizontalCenter\n    anchors.top: parent.top\n    margin-top: 180\n    width: 100\n\n  Label\n    id: trainerPhraseLabel\n    anchors.horizontalCenter: parent.horizontalCenter\n    anchors.top: parent.top\n    text: Phrase Trainer\n    margin-top: 210\n\n  TextEdit\n    id: trainerPhrase\n    anchors.horizontalCenter: parent.horizontalCenter\n    anchors.top: parent.top\n    margin-top: 230\n    width: 100\n\n  BotSwitch\n    id: modeTrainer\n    anchors.top: parent.top\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-top: 260\n    text-align: center\n    width: 150\n    !text: tr('Trainer Mode')\n\n  BotSwitch\n    id: modeHunt\n    anchors.top: parent.top\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-top: 280\n    text-align: center\n    width: 150\n    !text: tr('Hunt Mode')\n\n  HorizontalSeparator\n    id: separator\n    anchors.right: parent.right\n    anchors.left: parent.left\n    anchors.bottom: closeButton.top\n    margin-bottom: 5\n\n\n  Panel\n    id: settingsPanel\n    image-source: /images/ui/panel_flat\n    anchors.right: parent.right\n    anchors.left: parent.left\n    anchors.top: parent.top\n    anchors.bottom: separator.top\n    margin: 5 5 5 5\n    image-border: 6\n    padding: 3\n    size: 320 235\n\n  HorizontalSeparator\n    id: sep2\n    anchors.right: parent.right\n    anchors.left: parent.left\n    anchors.bottom: closeButton.top\n    margin-bottom: 150\n    margin-left: 5\n    margin-right: 5\n\n  Label\n    id: labelGerais\n    anchors.horizontalCenter: parent.horizontalCenter\n    anchors.top: parent.top\n    text: Ativaveis Gerais\n    margin-top: 20\n\n  BotSwitch\n    id: activateChannel\n    anchors.top: labelGerais.bottom\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-top: 10\n    text-align: center\n    width: 150\n    !text: tr('Ativar Canal de Skills')\n\n  BotSwitch\n    id: activateWebhook\n    anchors.top: labelGerais.bottom\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-top: 30\n    text-align: center\n    width: 150\n    !text: tr('Ativar Notify Discord')\n    tooltip: Necessita de um WebHook.\n\n  TextEdit\n    id: webhookLink\n    anchors.top: labelGerais.bottom\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-top: 50\n    width: 100\n\n  BotSwitch\n    id: attackTrainer\n    anchors.top: labelGerais.bottom\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-top: 75\n    text-align: center\n    width: 150\n    !text: tr('Attack Trainer')\n\n  BotSwitch\n    id: lowCPU\n    anchors.top: labelGerais.bottom\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-top: 95\n    text-align: center\n    width: 150\n    !text: tr('Low CPU Usage')\n    tooltip: Ira diminuir o uso da CPU do jogo.\n\n  BotSwitch\n    id: showSkills\n    anchors.top: labelGerais.bottom\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-top: 115\n    text-align: center\n    width: 150\n    !text: tr('Show Skills')\n\n  Label\n    id: labelEspecificos\n    anchors.horizontalCenter: parent.horizontalCenter\n    anchors.top: sep2.bottom\n    text: Ativaveis Mode\n    margin-top: 10\n\n  BotSwitch\n    id: autoWalk\n    anchors.top: labelEspecificos.bottom\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-top: 10\n    text-align: center\n    width: 150\n    !text: tr('Andar Automaticamente')\n\n  BotSwitch\n    id: playersScreen\n    anchors.top: labelEspecificos.bottom\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-top: 10\n    text-align: center\n    width: 150\n    !text: tr('Parar Treino')\n    tooltip: Parar treino se aparecer player na tela.\n\n  Button\n    id: closeButton\n    !text: tr('Close')\n    font: cipsoftFont\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-left: 45\n    anchors.bottom: parent.bottom\n    width: 80\n    margin-bottom: 5\n\n  Button\n    id: settingsButton\n    !text: tr('More Settings')\n    font: cipsoftFont\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-right: 45\n    width: 80\n    anchors.bottom: parent.bottom\n    margin-bottom: 5\n      \n", g_ui["getRootWidget"]());

-- MainWindow nasce visivel em algumas builds do OTCv8. Mantem o painel
-- fechado ao iniciar; ele so abre quando o usuario clica em Setup.
trainerInterface:hide();
trainerInterface["settingsPanel"]:hide();


storage["storageTrainer"] = storage["storageTrainer"] or {
    macroEnabled = false,
    spellTrain = "",
    spellRecover = "",
    trainerName = "",
    trainerPhrase = "",
    modeTrainer = false,
    modeHunt = false,
    enableChannel = false,
    enableWebHook = false,
    attackTrainer = false,
    playersScreen = false,
    changeItemOrSpell = false,
    lowCpu = false,
    showSkills = false,
    autoWalk = false,
    WebHookText = "",
    percentTrain = 90,
    itemId = 0
};

autoTrainer["controlSettings"] = storage["storageTrainer"];
autoTrainer["worldName"] = g_game["getWorldName"]():lower():trim();
autoTrainer["timeStand"] = os["time"]();

autoTrainer["widgetsInterface"] = {
    ["Main"] = {
        "spellTrainLabel", 
        "spellTrain", 
        "spellRecoverLabel", 
        "spellRecover", 
        "itemRecover", 
        "changeItemOrSpell", 
        "percentTrainLabel", 
        "percentTrain", 
        "trainerNameLabel", 
        "trainerName", 
        "trainerPhraseLabel", 
        "trainerPhrase", 
        "modeTrainer", 
        "modeHunt" 
    },
    ["GeralOptions"] = {
        "sep2", 
        "labelEspecificos", 
        "labelGerais", 
        "activateChannel", 
        "activateWebhook", 
        "webhookLink", 
        "attackTrainer", 
        "lowCPU", 
        "showSkills", 
    },
    ["TrainerMode"] = {
        "autoWalk", 
    },
    ["HuntMode"] = {
        "playersScreen"
    },
}

playerSkills  = {
    {name = "Level", level = player:getLevel(), lastTime = os["time"]()},
    {name = "Magic Level", level = player:getMagicLevel(), lastTime = os["time"]()},
    {name = "Fist", level = player:getSkillLevel(0), lastTime = os["time"]()},
    {name = "Club", level = player:getSkillLevel(1), lastTime = os["time"]()},
    {name = "Sword", level = player:getSkillLevel(2), lastTime = os["time"]()},
    {name = "Axe", level = player:getSkillLevel(3), lastTime = os["time"]()},
    {name = "Distance", level = player:getSkillLevel(4), lastTime = os["time"]()},
    {name = "Shielding", level = player:getSkillLevel(5), lastTime = os["time"]()},
    {name = "Fishing", level = player:getSkillLevel(6), lastTime = os["time"]()},
};


local tabName = "Skills Channel";
local console = game_console or (modules and (modules["game_console"] or modules["game_chat"]));

-- Compatibilidade entre clientes OTCv8 que expõem o console em locais diferentes.
-- Se nenhum módulo de console estiver disponível, somente o canal de skills é
-- ignorado; as demais funções do Auto Trainer continuam funcionando.
local callConsole = function(methodName, ...)
    if console and type(console[methodName]) == "function" then
        return console[methodName](...);
    end
    return nil;
end

local getTabSkills = callConsole("getTab", tabName);



local doAttack = tyrBot and tyrBot["doAttack"] or g_game["attack"];
local alreadyChecked;


autoTrainer["switchMacro"] = function(widget)
    autoTrainer["controlSettings"]["macroEnabled"] = not autoTrainer["controlSettings"]["macroEnabled"];
    widget:setOn(autoTrainer["controlSettings"]["macroEnabled"]);
    if autoTrainer["controlSettings"]["modeTrainer"] and autoTrainer["controlSettings"]["trainerPhrase"]:len() > 0 then
        local phrase = autoTrainer["controlSettings"]["trainerPhrase"]
        if not autoTrainer["controlSettings"]["macroEnabled"] then
            if worldName == "sekai" then
                phrase = phrase .. " off"
            end
            say(phrase)
            alreadyChecked = false;
        end
    end
end




autoTrainer["interfaceManagement"] = function()
    if not trainerInterface:isVisible() then
        trainerInterface:show();
        trainerInterface:raise();
        trainerInterface:focus();
    else
        trainerInterface:hide();
    end
end


autoTrainer["useItem"] = function(itemId)
    local itemToUse = findItem(itemId) or Item["create"](itemId);
    g_game["useWith"](itemToUse, player);
end


autoTrainer["changeCheckBox"] = function()
    autoTrainer["controlSettings"]["changeItemOrSpell"] = not autoTrainer["controlSettings"]["changeItemOrSpell"] ;
    if autoTrainer["controlSettings"]["changeItemOrSpell"]  then
        trainerInterface["changeItemOrSpell"]:setTooltip("Mudar regenera\195\167\195\163o de ML por item.");
        trainerInterface["spellRecover"]:hide();
        trainerInterface["itemRecover"]:show();
        trainerInterface["changeItemOrSpell"]:setMarginTop(83);
    else
        trainerInterface["changeItemOrSpell"]:setTooltip("Mudar regenera\195\167\195\163o de ML por spell.");
        trainerInterface["itemRecover"]:hide();
        trainerInterface["spellRecover"]:show();
        trainerInterface["changeItemOrSpell"]:setMarginTop(85);
    end
end

autoTrainer["controlMode"] = function()
    if autoTrainer["controlSettings"]["modeTrainer"] then
        autoTrainer["managementWidget"]("TrainerMode", "show");
    else
        autoTrainer["managementWidget"]("TrainerMode", "hide");
    end
    if autoTrainer["controlSettings"]["modeHunt"] then
        autoTrainer["managementWidget"]("HuntMode", "show");
    else
        autoTrainer["managementWidget"]("HuntMode", "hide");
    end
end


autoTrainer["toggleSettings"] = function()
    autoTrainer["settingsShowing"] = not autoTrainer["settingsShowing"];
    if autoTrainer["settingsShowing"] then
        trainerInterface["settingsPanel"]:show();
        autoTrainer["managementWidget"]("GeralOptions", "show");
        autoTrainer["managementWidget"]("Main", "hide");
        autoTrainer["managementWidget"]("TrainerMode", autoTrainer["controlSettings"]["modeTrainer"] and "show" or "hide");
        autoTrainer["managementWidget"]("HuntMode", autoTrainer["controlSettings"]["modeHunt"] and "show" or "hide");
    else
        trainerInterface["settingsPanel"]:hide();
        autoTrainer["managementWidget"]("GeralOptions", "hide");
        autoTrainer["managementWidget"]("Main", "show");
        autoTrainer["managementWidget"]("TrainerMode", "hide");
        autoTrainer["managementWidget"]("HuntMode", "hide");
    end
end


autoTrainer["modeTrainer"] = function(widget)
    if autoTrainer["controlSettings"]["modeHunt"] then return warn("Apenas um modo."); end
    autoTrainer["controlSettings"]["modeTrainer"] = not autoTrainer["controlSettings"]["modeTrainer"];
    widget:setOn(autoTrainer["controlSettings"]["modeTrainer"]);
end


autoTrainer["modeHunt"] = function(widget)
    if autoTrainer["controlSettings"]["modeTrainer"] then return warn("Apenas um modo."); end
    autoTrainer["controlSettings"]["modeHunt"] = not autoTrainer["controlSettings"]["modeHunt"];
    widget:setOn(autoTrainer["controlSettings"]["modeHunt"]);
end


autoTrainer["percentTrain"] = function(widget, value)
    autoTrainer["controlSettings"]["percentTrain"] = tonumber(value);
    widget:setText(value .. "%")
end


autoTrainer["spellTrain"] = function(widget, text)
    autoTrainer["controlSettings"]["spellTrain"] = text;
    widget:setText(text);
end


autoTrainer["itemRecover"] = function(widget, value)
    autoTrainer["controlSettings"]["itemId"] = widget:getItemId();
end


autoTrainer["spellRecover"] = function(widget, text)
    autoTrainer["controlSettings"]["spellRecover"] = text;
    widget:setText(text);
end


autoTrainer["trainerName"] = function(widget, text)
    autoTrainer["controlSettings"]["trainerName"] = text;
    widget:setText(text);
end


autoTrainer["trainerPhrase"] = function(widget, text)
    autoTrainer["controlSettings"]["trainerPhrase"] = text;
    widget:setText(text);
end


autoTrainer["enableChat"] = function(widget)
    autoTrainer["controlSettings"]["enableChannel"] = not autoTrainer["controlSettings"]["enableChannel"];
    widget:setOn(autoTrainer["controlSettings"]["enableChannel"]);
    local insertTab = callConsole("addTab", tabName, true);
    widget:setOn(autoTrainer["controlSettings"]["enableChannel"]);
    if autoTrainer["controlSettings"]["enableChannel"] then
        for i, skill in ipairs(playerSkills) do
            playerSkills[i]["lastTime"] = os["time"]();
        end
        callConsole("addText", "Shazam Scripts - Skills Channel.", console and console["SpeakTypesSettings"], tabName);
    else
        callConsole("removeTab", tabName);
    end
end


autoTrainer["enableWebHook"] = function(widget)
    local findWebhook = trainerInterface["webhookLink"]:getText();
    if (findWebhook:len() == 0 or not findWebhook:find("https://discord.com/api/webhooks/")) then
        return warn("Invalid WeebHook.");
    end
    autoTrainer["controlSettings"]["enableWebHook"] = not autoTrainer["controlSettings"]["enableWebHook"];
    widget:setOn(autoTrainer["controlSettings"]["enableWebHook"]);
    if autoTrainer["controlSettings"]["enableWebHook"] then
        warn("Notify Discord ON.")
    else
        warn("Notify Discord OFF.")
    end
end


autoTrainer["checkingWebHookText"] = function(widget, text)
    if text:len() == 0 or not text:find("https://discord.com/api/webhooks/") then
        autoTrainer["controlSettings"]["enableWebHook"] = false;
        return trainerInterface["activateWebhook"]:setOn(autoTrainer["controlSettings"]["enableWebHook"]);
    end
    autoTrainer["controlSettings"]["WebHookText"] = text;
end


autoTrainer["attackTrainer"] = function(widget)
    autoTrainer["controlSettings"]["attackTrainer"] = not autoTrainer["controlSettings"]["attackTrainer"];
    widget:setOn(autoTrainer["controlSettings"]["attackTrainer"]);
end


autoTrainer["playersScreen"] = function(widget)
    autoTrainer["controlSettings"]["playersScreen"] = not autoTrainer["controlSettings"]["playersScreen"];
    widget:setOn(autoTrainer["controlSettings"]["playersScreen"]);
end


autoTrainer["lowCPU"] = function(widget)
    autoTrainer["controlSettings"]["lowCpu"] = not autoTrainer["controlSettings"]["lowCpu"];
    widget:setOn(autoTrainer["controlSettings"]["lowCpu"]);
end


autoTrainer["showSkills"] = function(widget)
    autoTrainer["controlSettings"]["showSkills"] = not autoTrainer["controlSettings"]["showSkills"];
    widget:setOn(autoTrainer["controlSettings"]["showSkills"]);
end

autoTrainer["autoWalk"] = function(widget)
    autoTrainer["controlSettings"]["autoWalk"] = not autoTrainer["controlSettings"]["autoWalk"];
    widget:setOn(autoTrainer["controlSettings"]["autoWalk"]);
end


autoTrainer["standTime"] = function()
    return os["time"]() - autoTrainer["timeStand"];
end


autoTrainer["managementWidget"] = function(option, action)
    for _, widgetId in ipairs(autoTrainer["widgetsInterface"] [option]) do
        local widget = trainerInterface:getChildById(widgetId);
        if widget then
            if action == "hide" then
                widget:hide();
                autoTrainer["changeCheckBox"]();
            elseif action == "show" then
                autoTrainer["changeCheckBox"]();
                widget:show();
            end
        end
    end
end


local discordTimes = {};
local default_data = {
    username = "Shazam Scripts",
}
local embed = {
    color = 10038562,
    footer = {
        ["text"] = "Shazam Scripts.",
    },
}


autoTrainer["sendDiscordWebhook"] = function(data)
    local id = data["id"];
    if id then
        local dTime = discordTimes[id];
        if dTime and os["time"]() < dTime then return; end
        discordTimes[id] = os["time"]() + (data["delayed"] and data["delayed"] or 10);
    end

    local dEmbed = embed
    if data["color"] then dEmbed["color"] = data["color"] end
    dEmbed["title"] = "**".. data["title"] .."**"
    dEmbed["fields"] = {
        {
            name = "Name: ",
            value = data["name"],
        },
        {
            name = "Message",
            value = data["message"],
        }
    };
    local dataSend = default_data;
    dataSend["embeds"] = { dEmbed };
    HTTP["postJSON"](trainerInterface["webhookLink"]:getText(), dataSend, onHTTPResult);
end

autoTrainer["formatTime"] = function(seconds)
    local hours = math["floor"](seconds / 3600)
    local mins = math["floor"](seconds % 3600 / 60)
    local secs = seconds % 60
    return string["format"]("%02dh %02dm %02ds", hours, mins, secs)
end


autoTrainer["sendSkillUpdates"] = function()
    for i, skill in ipairs(playerSkills) do
        local currentLevel = i <= 2 and player["get" .. skill["name"]:gsub(" ", "")](player) or player:getSkillLevel(i-3);
        if currentLevel > skill["level"] then
            local time = os["time"]();
            local elapsedTime = time - skill["lastTime"];
            local message = string["format"]("%s - Voce avancou do nivel %d para o nivel %d em %s.", skill["name"], skill["level"], currentLevel, autoTrainer["formatTime"](elapsedTime));

            if autoTrainer["controlSettings"]["enableChannel"] then
                callConsole("addText", message, console and console["SpeakTypesSettings"], tabName);
            end

            if autoTrainer["controlSettings"]["enableWebHook"] then
                local data = {
                    title = "Skills Update",
                    name = player:getName(),
                    message = message,
                    id = "pd",
                    delayed = 1,
                }
                autoTrainer["sendDiscordWebhook"](data);
            end

            playerSkills[i]["level"] = currentLevel;
            playerSkills[i]["lastTime"] = time;
        end
    end
end



-- FIX (Slow macro - CRITICO): este bloco tinha "getSpectators = function() ... end"
-- SEM "local". Isso sobrescrevia a funcao GLOBAL getSpectators(), usada por
-- TODOS os outros arquivos da custom (Combo.lua, Especiais.lua, Enemy.lua,
-- Battle_filter.lua, Alarms.lua, etc). A condicao que disparava a troca era
-- "nao tem ninguem por perto agora" (#getSpectators(true) == 0), o que e
-- praticamente sempre verdade no exato momento em que voce loga sozinho.
-- Ou seja: toda vez que voce logava sem ninguem do lado, TODAS as macros do
-- bot inteiro passavam a rodar essa versao, que varre o ANDAR INTEIRO tile
-- por tile a cada chamada -- e ainda por cima tinha um bug (usava a variavel
-- errada "creature" em vez de "spec", inserindo lixo na lista). Isso explica
-- por que macros de arquivos diferentes ficavam lentas ao mesmo tempo.
-- Agora o fallback fica local a este arquivo (nao contamina o resto do bot),
-- so e usado se getSpectators realmente nao existir como funcao, escaneia
-- apenas uma area limitada ao redor do jogador (nao o andar inteiro), e usa
-- a variavel certa.
if (type(getSpectators) ~= "function") then
    local function localGetSpectators(multifloor)
        local specs = {};
        local playerPos = pos();
        if not playerPos then return specs; end

        local scanRadius = 8; -- suficiente pra maioria dos usos, evita varrer o mapa inteiro
        for dx = -scanRadius, scanRadius do
            for dy = -scanRadius, scanRadius do
                local tile = g_map["getTile"]({x = playerPos.x + dx, y = playerPos.y + dy, z = playerPos.z});
                if tile then
                    for _, spec in ipairs(tile:getCreatures()) do
                        table["insert"](specs, spec);
                    end
                end
            end
        end
        return specs;
    end

    getSpectators = localGetSpectators;
end


autoTrainer["getPlayersOnScreen"] = function()
    for _, creature in ipairs(getSpectators()) do
        if creature ~= player and creature:isPlayer() then
            return true;
        end
    end
    return false;
end


samePos = function(pos1, pos2)
    if pos1["x"] == pos2["x"] and pos1["y"] == pos2["y"] and pos1["z"] == pos2["z"] then
        return true;
    end
    return false;
end


autoTrainer["getCreatureInTile"] = function(spec)
    local specPos = spec:getPosition();
    local playerPos = player:getPosition();
    local closestPos = nil;
    local minDistance = math["huge"];

    for x = -1, 1 do
        for y = -1, 1 do
            local checkPos = {x = specPos["x"] + x, y = specPos["y"] + y, z = specPos["z"]};
            local tile = g_map["getTile"](checkPos);
            if tile and tile:isWalkable() and tile:isPathable() then
                local creatures = tile:getCreatures();
                if #creatures == 0 then
                    local distance = getDistanceBetween(playerPos, checkPos);
                    if distance < minDistance then
                        minDistance = distance;
                        closestPos = checkPos;
                    end
                end
            end
        end
    end
    if closestPos then
        return true, closestPos;
    else
        return false;
    end
end


autoTrainer["walkToTile"] = function(tile)
    schedule(400, function()
        player:autoWalk(tile);
    end);
end



local afkFPS = 5;
local activeFPS = 60;

autoTrainer["adjustDisplay"] = function(isAfk)
    if isAfk then
        modules["client_options"]["setOption"]("backgroundFrameRate", afkFPS);
        modules["game_interface"]["gameMapPanel"]:hide();
    else
        modules["client_options"]["setOption"]("backgroundFrameRate", activeFPS);
        modules["game_interface"]["gameMapPanel"]:show();
    end
end

autoTrainer["onLoading"] = function()
    trainerInterface["modeTrainer"]:setOn(autoTrainer["controlSettings"]["modeTrainer"]);
    trainerInterface["modeHunt"]:setOn(autoTrainer["controlSettings"]["modeHunt"]);
    trainerInterface["autoWalk"]:setOn(autoTrainer["controlSettings"]["autoWalk"]);
    if autoTrainer["controlSettings"]["enableChannel"] and not getTabSkills then
        callConsole("addText", "Shazam Scripts - Skills Channel.", console and console["SpeakTypesSettings"], tabName);
    end
    trainerInterface["percentTrain"]:setText(autoTrainer["controlSettings"]["percentTrain"] .. "%");
    trainerInterface["percentTrain"]:setValue(autoTrainer["controlSettings"]["percentTrain"]);
    trainerInterface["spellTrain"]:setText(autoTrainer["controlSettings"]["spellTrain"]);
    trainerInterface["itemRecover"]:setItemId(autoTrainer["controlSettings"]["itemId"]);
    trainerInterface["spellRecover"]:setText(autoTrainer["controlSettings"]["spellRecover"]);
    trainerInterface["trainerName"]:setText(autoTrainer["controlSettings"]["trainerName"]);
    trainerInterface["trainerPhrase"]:setText(autoTrainer["controlSettings"]["trainerPhrase"]);
    trainerInterface["activateChannel"]:setOn(autoTrainer["controlSettings"]["enableChannel"]);
    trainerInterface["activateWebhook"]:setOn(autoTrainer["controlSettings"]["enableWebHook"]);
    trainerInterface["activateChannel"]:setOn(autoTrainer["controlSettings"]["enableChannel"]);
    trainerInterface["activateWebhook"]:setOn(autoTrainer["controlSettings"]["enableWebHook"]);
    trainerInterface["changeItemOrSpell"]:setChecked(autoTrainer["controlSettings"]["changeItemOrSpell"]);
    trainerInterface["webhookLink"]:setText(autoTrainer["controlSettings"]["WebHookText"]);
    trainerInterface["attackTrainer"]:setOn(autoTrainer["controlSettings"]["attackTrainer"]);
    trainerInterface["playersScreen"]:setOn(autoTrainer["controlSettings"]["playersScreen"]);
    trainerInterface["lowCPU"]:setOn(autoTrainer["controlSettings"]["lowCpu"]);
    trainerInterface["showSkills"]:setOn(autoTrainer["controlSettings"]["showSkills"]);
    trainerIcon["title"]:setOn(autoTrainer["controlSettings"]["macroEnabled"]);
end


autoTrainer["managementWidget"]("GeralOptions", "hide");
autoTrainer["managementWidget"]("TrainerMode", "hide");
autoTrainer["managementWidget"]("HuntMode", "hide");
autoTrainer["onLoading"]();



storage["widgetPos"] = storage["widgetPos"] or {};

local widgetConfig = "UIWidget\n  background-color: black\n  opacity: 0.8\n  padding: 0 5\n  focusable: true\n  phantom: false\n  draggable: true\n  text-auto-resize: true\n  color: white\n  text-align: left \n\n"

local trainWidget = {};

trainWidget["widget"] = setupUI(widgetConfig, g_ui["getRootWidget"]());
trainWidget["widget"]:hide();

local isMobile = modules["_G"]["g_app"]["isMobile"]();
g_keyboard = g_keyboard or modules["corelib"]["g_keyboard"];

local isDragKeyPressed = function()
	return isMobile and g_keyboard["isKeyPressed"]("F2") or g_keyboard["isCtrlPressed"]();
end

local function attachSpellWidgetCallbacks(key)
    trainWidget[key]["onDragEnter"] = function(widget, mousePos)
        if (not isDragKeyPressed()) then return; end
        widget:breakAnchors()
        widget["movingReference"] = { x = mousePos["x"] - widget:getX(), y = mousePos["y"] - widget:getY() }
        return true;
    end

    trainWidget[key]["onDragMove"] = function(widget, mousePos, moved)
        local parentRect = widget:getParent():getRect()
        local x = math["min"](math["max"](parentRect["x"], mousePos["x"] - widget["movingReference"]["x"]), parentRect["x"] + parentRect["width"] - widget:getWidth())
        local y = math["min"](math["max"](parentRect["y"] - widget:getParent():getMarginTop(), mousePos["y"] - widget["movingReference"]["y"]), parentRect["y"] + parentRect["height"] - widget:getHeight())
        widget:move(x, y)
        return true;
    end

    trainWidget[key]["onDragLeave"] = function(widget, pos)
        storage["widgetPos"][key] = {}
        storage["widgetPos"][key]["x"] = widget:getX();
        storage["widgetPos"][key]["y"] = widget:getY();
        return true;
    end
end

for key, value in pairs(trainWidget) do
    attachSpellWidgetCallbacks(key)
    trainWidget[key]:setPosition(
        storage["widgetPos"][key] or {0, 50}
    );
end

local function showSkillLevel(skill, type)
    local Types = {
        Fist = 0,
        Club = 1,
        Sword = 2,
        Axe = 3,
        Distance = 4,
        Shielding = 5,
        Fishing = 6,
        CriticalChance = 7,
        CriticalDamage = 8,
        LifeLeechChance = 9,
        LifeLeechAmount = 10,
        ManaLeechChance = 11,
        ManaLeechAmount = 12
    };
    if type == "percent" then
        return player:getSkillLevelPercent(Types[skill]);
    elseif type == "level" then
        return player:getSkillLevel(Types[skill]);
    end
end

local function calcStamina()
    local stam = stamina()
    local hours = math["floor"](stam / 60)
    local minutes = stam % 60
    if minutes < 10 then
        minutes = "0" .. minutes
    end
    local percent = math["floor"](100 * stam / (42 * 60))
    return hours.. ":".. minutes, " ("..percent.."%)"
end

autoTrainer["showSkillsWidget"] = function(bool)
    local showSkills = autoTrainer["controlSettings"]["showSkills"];
    if showSkills then
        local widgetText = "~ Level: " .. player:getLevel() .. "/" .. (player:getLevel() + 1) .. " - " .. player:getLevelPercent() .. "%" ..
            "\n~ Magic Level: " .. player:getMagicLevel() .. "/" .. (player:getMagicLevel() + 1) .. " - " .. player:getMagicLevelPercent() .. "%" ..
            "\n~ Fist: " .. showSkillLevel("Fist", "level") .. "/" .. (showSkillLevel("Fist", "level") + 1) .. " - " .. showSkillLevel("Fist", "percent") .. "%" ..
            "\n~ Glove: " .. showSkillLevel("Club", "level") .. "/" .. (showSkillLevel("Club", "level") + 1) .. " - " .. showSkillLevel("Club", "percent") .. "%" ..
            "\n~ Axe: " .. showSkillLevel("Axe", "level") .. "/" .. (showSkillLevel("Axe", "level") + 1) .. " - " .. showSkillLevel("Axe", "percent") .. "%" ..
            "\n~ Sword: " .. showSkillLevel("Sword", "level") .. "/" .. (showSkillLevel("Sword", "level") + 1) .. " - " .. showSkillLevel("Sword", "percent") .. "%" ..
            "\n~ Distance: " .. showSkillLevel("Distance", "level") .. "/" .. (showSkillLevel("Distance", "level") + 1) .. " - " .. showSkillLevel("Distance", "percent") .. "%" ..
            "\n~ Shield: " .. showSkillLevel("Shielding", "level") .. "/" .. (showSkillLevel("Shielding", "level") + 1) .. " - " .. showSkillLevel("Shielding", "percent") .. "%" ..
            "\n~ Stamina: " .. calcStamina()
        trainWidget["widget"]:setText(widgetText);
        trainWidget["widget"]:setVisible(true);
    else
        trainWidget["widget"]:setVisible(false);
    end
end



trainerIcon["title"]["onClick"] = autoTrainer["switchMacro"];


trainerIcon["settings"]["onClick"] = autoTrainer["interfaceManagement"];


trainerInterface["changeItemOrSpell"]["onCheckChange"] = autoTrainer["changeCheckBox"];


trainerInterface["settingsButton"]["onClick"] = autoTrainer["toggleSettings"];


trainerInterface["closeButton"]["onClick"] = autoTrainer["interfaceManagement"];


trainerInterface["modeTrainer"]["onClick"] = autoTrainer["modeTrainer"];


trainerInterface["modeHunt"]["onClick"] = autoTrainer["modeHunt"];


trainerInterface["percentTrain"]["onValueChange"] = autoTrainer["percentTrain"];


trainerInterface["spellTrain"]["onTextChange"] = autoTrainer["spellTrain"];


trainerInterface["itemRecover"]["onItemChange"] = autoTrainer["itemRecover"];


trainerInterface["spellRecover"]["onTextChange"] = autoTrainer["spellRecover"];


trainerInterface["trainerName"]["onTextChange"] = autoTrainer["trainerName"];


trainerInterface["trainerPhrase"]["onTextChange"] = autoTrainer["trainerPhrase"];


trainerInterface["activateChannel"]["onClick"] = autoTrainer["enableChat"];


trainerInterface["activateWebhook"]["onClick"] = autoTrainer["enableWebHook"];


trainerInterface["webhookLink"]["onTextChange"] = autoTrainer["checkingWebHookText"];


trainerInterface["attackTrainer"]["onClick"] = autoTrainer["attackTrainer"];


trainerInterface["playersScreen"]["onClick"] = autoTrainer["playersScreen"];


trainerInterface["lowCPU"]["onClick"] = autoTrainer["lowCPU"];


trainerInterface["showSkills"]["onClick"] = autoTrainer["showSkills"];

trainerInterface["autoWalk"]["onClick"] = autoTrainer["autoWalk"];




macro(100, function()
    local trainerConfig = autoTrainer["controlSettings"];
    local creatureAttack;
    local target = g_game["getAttackingCreature"]();
    if not trainerConfig["macroEnabled"] then return; end
    local playerPos, playerMana = player:getPosition(), manapercent();
    local spellTrain, spellRecover, itemRecover = trainerConfig["spellTrain"], trainerConfig["spellRecover"], trainerConfig["itemId"];
    local isSpell = trainerConfig["changeItemOrSpell"];
    local percentTrain = trainerConfig["percentTrain"];
    local trainerName, trainerPhrase, attackTrainer = trainerConfig["trainerName"]:lower():trim(), trainerConfig["trainerPhrase"], trainerConfig["attackTrainer"];
    local modeTrainer, modeHunt = trainerConfig["modeTrainer"], trainerConfig["modeHunt"];
    local playersScreen = trainerConfig["playersScreen"];
    local lowCpu, autoWalk = trainerConfig["lowCpu"], trainerConfig["autoWalk"];
    if attackTrainer then
        for _, spec in ipairs(getSpectators()) do
            if spec:getName():lower() == trainerName then
                local specPos = spec:getPosition();
                if (not creatureAttack or getDistanceBetween(playerPos, creatureAttack:getPosition()) > getDistanceBetween(specPos, playerPos)) then
                    creatureAttack = spec;
                    break;
                end
            end
        end
        if creatureAttack then
            local checkDistance = getDistanceBetween(playerPos, creatureAttack:getPosition());
            if not target or target:getId() ~= creatureAttack:getId() then
                if autoWalk then
                    local isTileWalkable, posTile = autoTrainer["getCreatureInTile"](creatureAttack);
                    if isTileWalkable then
                        autoTrainer["walkToTile"](posTile);
                        creatureAttack:setText("Walking...")
                        if checkDistance == 1 then
                            creatureAttack:clearText();
                            doAttack(creatureAttack)
                            return;
                        end
                    end
                else
                    if checkDistance == 1 then
                        doAttack(creatureAttack)
                    end
                end
            end
        end
    end
    if playerMana <= percentTrain then
        if isSpell then
            if spellRecover:len() > 0 then
                say(spellRecover)
            end
        else
            if itemRecover ~= 0 then
                autoTrainer["useItem"](itemRecover)
            end
        end
    else
        if spellTrain:len() > 0 then
            if modeHunt then
                if playersScreen then
                    if not autoTrainer["getPlayersOnScreen"]() then
                        say(spellTrain)
                    end
                    return;
                end
            end
            say(spellTrain)
        end
    end
    if autoTrainer["standTime"]() >= 5 then
        if  lowCpu then
            autoTrainer["adjustDisplay"](true);
        else
            autoTrainer["adjustDisplay"](false);
        end
    else
        autoTrainer["adjustDisplay"](false);
    end
    if modeTrainer and not alreadyChecked then
        if trainerPhrase ~= "" then
            if autoTrainer["worldName"] == "sekai" then
                say(trainerPhrase .. " on")
            else
                say(trainerPhrase)
            end
        end
    end
    autoTrainer["showSkillsWidget"]();
    autoTrainer["sendSkillUpdates"]();
end);


if autoTrainer["worldName"] == "sekai" then
    onAnimatedText(function(thing, text)
        local playerPos = player:getPosition();
        local pos = thing:getPosition();
        if samePos(playerPos, pos) then
            if (text == "Treinando!") then
                alreadyChecked = true;
            end
        end
    end);
elseif autoTrainer["worldName"] == "ntoultimate" then
    onTalk(function(name, level, mode, text, channelId, pos)
        if name ~= player:getName() then return; end
        text = text:lower();
        if text:find("on") then
            alreadyChecked = true;
        elseif text:find("off") then
            alreadyChecked = false;
        end
    end);
end
