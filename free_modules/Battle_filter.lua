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
local FREE_VERSION = false; -- UNIVERSAL: nao aplica limitacoes da versao free.
local battleFilter = {};
modules["game_battle"] = modules["_G"]["modules"]["game_battle"];

local friendList = tyrBot and tyrBot["friendList"] or {isFriend=function() return true end};
local isFriend = friendList["isFriend"];




local checkBoxWidget = "CheckBox\n  id: checkBox\n";

storage["checkBoxs"] = storage["checkBoxs"] or {};
local addCheckBox = function(id, name, callback)
	local checkBox = setupUI(checkBoxWidget);
	checkBox:setText(name);
	checkBox["onCheckChange"] = function(widget, checked)
		storage["checkBoxs"][id] = checked;
		if (callback) then
			callback(widget, checked);
		end
	end
	schedule(0, function()
		checkBox:setChecked(storage["checkBoxs"][id]);
		checkBox:onCheckChange(storage["checkBoxs"][id]);
	end);
	return checkBox;
end

battleFilter["checkBox"] = addCheckBox("battleFilter", "Filtrar Battle", function(widget, checked)
	if (battleFilter["main"]) then
		battleFilter["main"]();
	end
	for key, widget in pairs(battleFilter) do
		if (type(widget) ~= "userdata" or key == "checkBox") then
			goto continue;
		end
		if (not FREE_VERSION and checked) then
			widget:show();
		else
			widget:hide();
		end
		::continue::
	end
	if (FREE_VERSION and checked) then
		return widget:setChecked(false);
	end
end)

storage["battleFilter"] = storage["battleFilter"] or {
	hideFriends = false,
	hidePlayers = false,
	hideMonsters = false,
	hideSkulls = false,
	hideNPCs = false
};

battleFilter["config"] = storage["battleFilter"];
local config = battleFilter["config"];


battleFilter["checkBoxPanel"] = setupUI("Panel\n  id: mainPanel\n  size: 120 20\n  image-source: /images/ui/panel_flat\n  image-border: 6\n  \n  BattlePlayers\n    id: hidePlayers\n    !tooltip: tr('Hide players')\n    anchors.top: parent.top\n    anchors.left: parent.left\n\n  BattleNPCs\n    id: hideNPCs\n    !tooltip: tr('Hide Npcs')\n    anchors.top: parent.top\n    anchors.left: prev.right\n\n  BattleMonsters\n    id: hideMonsters\n    !tooltip: tr('Hide monsters')\n    anchors.top: parent.top\n    anchors.left: prev.right\n\n  BattleSkulls\n    id: hideSkulls\n    !tooltip: tr('Hide non-skull players')\n    anchors.top: parent.top\n    anchors.left: prev.right\n\n  BattleParty\n    id: hideFriends\n    !tooltip: tr('Hide party members')\n    anchors.top: parent.top\n    anchors.left: prev.right\n");

local mainPanel = battleFilter["checkBoxPanel"];

local battlePanel = g_ui["getRootWidget"]():recursiveGetChildById("battlePanel");
battleFilter["childs"] = {};
local childs = battleFilter["childs"]; 
for index, child in ipairs(battlePanel:getChildren()) do
	table["insert"](childs, child);
end


local enableButton = g_ui["getRootWidget"]():recursiveGetChildById("enableButton");

isBotOn = function()
	return enableButton:getText() == "On";
end


modules["game_battle"]["creature_filter"] = modules["game_battle"]["creature_filter"] or modules["game_battle"]["doCreatureFitFilters"];


battleFilter["doFilter"] = function(creature)
	if (FREE_VERSION) then return; end
	
	
	if (not isBotOn()) then
		modules["game_battle"]["doCreatureFitFilters"] = modules["game_battle"]["creature_filter"];
		return modules["game_battle"]["doCreatureFitFilters"](creature);
	end
	
	if (type(creature) ~= "userdata") then
		return false;
	end
	
	local creatureId = creature:getId();
	if (not tonumber(creatureId)) then
		return false;
	end
	
	local playerPos = player:getPosition();
	local creaturePos = creature:getPosition();
	if (creaturePos == nil or playerPos["z"] ~= creaturePos["z"]) then
		return false;
	end
	
	if (creature:isLocalPlayer()) then
		return false;
	end
	
	local creatureHp = creature:getHealthPercent();
	if (not creatureHp or creatureHp <= 0) then
		return false;
	end
	
	if (config["hidePlayers"] and creature:isPlayer()) then
		return false;
	end
	
	if (config["hideMonsters"] and creature:isMonster()) then
		return false;
	end
	
	if (config["hideNPCs"] and creature:isNpc()) then
		return false;
	end
	
	if (config["hideSkulls"] and creature:isPlayer() and creature:getSkull() == 0) then
		return false;
	end
	
	if (config["hideFriends"] and (creature:getShield() >= 3 or creature:getEmblem() == 1 or creature:getEmblem() == 4) or isFriend(creature)) then
		return false;
	end
	
	return true;
end

battleFilter["main"] = function()
	if (FREE_VERSION) then return; end
	modules["game_battle"]["doCreatureFitFilters"] = modules["game_battle"]["creature_filter"];
	if (not storage["checkBoxs"]["battleFilter"]) then return; end
	modules["game_battle"]["doCreatureFitFilters"] = battleFilter["doFilter"];
end;


local hideButtons = {mainPanel["hidePlayers"], mainPanel["hideNPCs"], mainPanel["hideMonsters"], mainPanel["hideSkulls"], mainPanel["hideFriends"]};

local hidePartyText = mainPanel["hideFriends"]:getTooltip() or "Hide friends";
hidePartyText = hidePartyText:gsub("do", "");
hidePartyText = hidePartyText:split(" ");
table["insert"](hidePartyText, "& guild & friend list");
hidePartyText = table["concat"](hidePartyText, " ");
mainPanel["hideFriends"]:setTooltip(hidePartyText);

for _, button in ipairs(hideButtons) do
	local buttonId = button:getId();
	button["onCheckChange"] = function(widget, checked)
		config[buttonId] = checked;
		battleFilter["main"]();
	end;
	button:setChecked(config[buttonId]);
	button:setMarginLeft(8);
	local imageSource = button:getStyle()["image-source"];
	if (not imageSource) then
		local newId = buttonId:lower();
		newId = newId:gsub("hide", "");
		newId = newId == "friends" and "party" or newId;
		imageSource = "/images/game/battle/battle_" .. newId;
		pcall(button["setImageSource"], button, imageSource);
	end
end


macro(storage["scrollBars"] and storage["scrollBars"]["macroDelay"] or 1, battleFilter["main"]);

if (FREE_VERSION) then
	battleFilter["checkBox"]:setTooltip("Essa script est\225 desativada para a custom free.");
end