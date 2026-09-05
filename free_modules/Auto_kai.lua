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
if (tyrBot["configData"] == nil) then
	tyrBot["configData"] = {};
end
local configData = tyrBot["configData"];
configData["antiTrap"] = {};


local FREE_VERSION = false; -- UNIVERSAL: nao aplica limitacoes da versao free.
local kaiSpell = "kai"
local kaiExhaust = 1;

if (g_game["getWorldName"]():upper() == "NTOLOST") then
	kaiSpell = "jyuu no jutsu";
	kaiExhaust = 60;
end

autoKaiUI = setupUI("Panel\n  height: 17\n  BotSwitch\n    id: macro\n    anchors.top: parent.top\n    anchors.left: parent.left\n    anchors.right: parent.right\n    text-align: center\n    !text: tr('Anti Trap')\n\n    image-source:\n\n    $on:\n      color: green\n\n    $!on:\n      color: white\n");

storage["autoKaiConfig"] = storage["autoKaiConfig"] or {};

local config = storage["autoKaiConfig"];

local autoKaiCaster = {};

autoKaiCaster["rootWidget"] = g_ui["getRootWidget"]();
function string:append(str)
	return self .. str;
end

function string:ucwords()
    
    local cases = {" ", ":", ""};
    for index, case in ipairs(cases) do
        cases[case] = true;
        cases[index] = nil;
    end
    local newStr = "";
    
    for i = 1, #self do
        local str = self:sub(i, i):lower();
        local previous = self:sub(i - 1, i - 1);
        if (cases[previous]) then
            str = str:upper();
        end
        newStr = newStr .. str;
    end
    
    return newStr:trim();
end

kaiSpell = kaiSpell:ucwords();

autoKaiCaster["spellEntry"] = "Label\n  background-color: alpha\n  text-offset: 18 1\n  focusable: true\n  height: 16\n  font: verdana-11px-rounded\n\n  CheckBox\n    id: enabled\n    anchors.left: parent.left\n    anchors.verticalCenter: parent.verticalCenter\n    width: 15\n    height: 15\n    margin-top: 2\n    margin-left: 3\n\n  $focus:\n    background-color: #00000055\n\n  Button\n    id: remove\n    !text: tr('x')\n    anchors.right: parent.right\n    margin-right: 15\n    text-offset: 1 0\n    width: 15\n    height: 15\n"

autoKaiCaster["refreshSpells"] = function()

	for _, child in ipairs(autoKaiCaster["window"]["mainPanel"]["spellsList"]:getChildren()) do
		child:destroy();
	end
	
	for spellName, value in pairs(config) do
		
		if (type(value) == "table") then
			
			local children = setupUI(autoKaiCaster["spellEntry"], autoKaiCaster["window"]["mainPanel"]["spellsList"]);
			children["enabled"]:setChecked(value["enabled"]);
			local sealType = value["sealType"];
			local split = sealType:split(",");
			if (#split > 2) then	
				for index, val in ipairs(split) do
					split[index] = val:trim():sub(1, 1);
				end
				sealType = table["concat"](split, ", ");
			end
			
			local spellName = value["spell"];
			local split = spellName:split(" ")
			if (#split > 2) then
				spellName = split[1] .. " " .. split[2];
			end
			local formattedText = spellName .. ": " .. sealType .. " by " .. value["sealedTime"] .. "s";
			
			children:setText(formattedText);
			
			children["onDoubleClick"] = function()
				config[spellName] = nil;
				autoKaiCaster["window"]["mainPanel"]["spellName"]:setText(value["spell"]);
				autoKaiCaster["window"]["mainPanel"]["sealType"]:setText(value["sealType"]);
				autoKaiCaster["window"]["mainPanel"]["sealedTime"]:setText(value["sealedTime"]);
				autoKaiCaster["refreshSpells"]();
			end
			children["remove"]["onClick"] = children["onDoubleClick"];
			
			children["enabled"]["onClick"] = function()
				value["enabled"] = not value["enabled"];
				autoKaiCaster["refreshSpells"]();
			end
		end
	end
end
				
				
		

storage["scrollBars"] = storage["scrollBars"] or {};
autoKaiCaster["executionMacro"] = macro(storage["scrollBars"]["macroDelay"] or 1, function(self)
	if (FREE_VERSION) then
		return self:setOff();
	end

	if (not config["requestKai"]) then return; end
	
	if (isInPz()) then return; end
	
	if (config["kaiExhaust"] and config["kaiExhaust"] >= os["time"]()) then return; end
	tyrBot["comboDelay"] = now + 300;
	say(kaiSpell);
end)


if (config["macroActive"] == nil) then
	config["macroActive"] = false;
end

config["macroActive"] = not config["macroActive"];

autoKaiUI["macro"]["onClick"] = function()
	if (FREE_VERSION) then
		autoKaiUI["macro"]:setOn(false);
		return;
	end
	config["macroActive"] = not config["macroActive"];
	local enabled = config["macroActive"];
	
	autoKaiUI["macro"]:setOn(enabled);
	autoKaiCaster["executionMacro"]["setOn"](enabled);
end

autoKaiUI["macro"]:onClick();

local rec_ch_by_id = {"r", "e", "c", "u", "r", "s", "i", "v", "e", "G", "e", "t", "C", "h", "i", "l", "d", "B", "y", "I", "d"};
rec_ch_by_id = table["concat"](rec_ch_by_id);
gameRoot = "gameRoot = g_ui.getRootWidget():%s('gameRootPanel')";
gameRoot = gameRoot:format(rec_ch_by_id);
loadstring(gameRoot)();

local function toggleAntiTrapWindow()
	local window = autoKaiCaster["window"];
	if (window:isHidden()) then
		
		window:show();
		window:raise();
		window:focus();
		
	else
		window:hide();
		gameRoot:focus();
		
	end
end

-- Config agora abre com botao direito em qualquer parte da linha (painel, nao so o switch)
autoKaiUI["onMouseRelease"] = function(self, mousePos, mouseButton)
	if mouseButton == 2 then
		toggleAntiTrapWindow();
	end
end

local exitAction = toggleAntiTrapWindow;

local uiText = "Anti Trap by Shazam Scripts";

autoKaiCaster["window"] = setupUI("MainWindow\n  size: 450 225\n\n  Panel\n    id: mainPanel\n    image-source: /images/ui/panel_flat\n    anchors.top: parent.top\n    anchors.left: parent.left\n    anchors.right: parent.right\n    anchors.bottom: parent.bottom\n    image-border: 6\n\n    TextList\n      id: spellsList\n      anchors.top: parent.top\n      anchors.left: parent.left\n      size: 200 165\n      image-border: 3\n      padding: 3\n      image-source: /images/ui/textedit\n      vertical-scrollbar: spellsListScroll\n\n    VerticalScrollBar\n      id: spellsListScroll\n      anchors.top: spellsList.top\n      anchors.bottom: spellsList.bottom\n      anchors.right: spellsList.right\n      step: 10\n      pixels-scroll: true\n\n    TextEdit\n      id: spellName\n      anchors.top: spellsList.top\n      anchors.left: spellsList.right\n      margin-left: 30\n      margin-top: 10\n      width: 150\n\n    Label\n      id: spellNameLabel\n      !text: tr(\"Spell name\")\n      anchors.centerIn: prev\n      margin-bottom: 18\n\n    TextEdit\n      id: sealedTime\n      anchors.top: spellName.bottom\n      anchors.left: spellName.left\n      anchors.right: spellName.right\n      margin-top: 20\n\n    Label\n      id: sealedTimeLabel\n      !text: tr(\"Sealed time\")\n      anchors.left: spellNameLabel.left\n      anchors.bottom: prev.top\n      margin-bottom: 2\n      margin-right: 2\n\n    TextEdit\n      id: sealType\n      anchors.top: sealedTime.bottom\n      anchors.left: sealedTime.left\n      anchors.right: sealedTime.right\n      margin-top: 20\n\n    Button\n      id: sealType_tip\n      !text: tr(\"?\")\n      !tooltip: tr(\"Options: Buff, Speed, Kai\")\n      anchors.top: prev.top\n      anchors.left: prev.right\n      size: 30 20\n      margin-left: 5\n\n    Label\n      id: sealTypeLabel\n      !text: tr(\"Seal type\")\n      anchors.left: sealedTimeLabel.left\n      anchors.bottom: prev.top\n      margin-bottom: 2\n      margin-right: 2\n\n    Button\n      id: addButton\n      !text: tr(\"Add\")\n      anchors.top: sealType.bottom\n      anchors.left: spellName.left\n      anchors.right: spellName.right\n      margin-top: 10\n      height: 25\n\n    Label\n      id: infoDisplay\n      !text: tr(\"\")\n      -- anchors.right: parent.right\n      anchors.left: addButton.left\n      anchors.bottom: parent.bottom\n      margin-left: 10\n      text-auto-resize: true\n\n  Button\n    id: closeButton\n    !text: tr('x')\n    tooltip: Close\n    anchors.right: parent.right\n    anchors.top: parent.top\n    margin-top: 5\n    margin-right: 5\n    size: 25 20\n", autoKaiCaster["rootWidget"]);

autoKaiCaster["window"]:hide();


autoKaiCaster["window"]:setText(uiText);
autoKaiCaster["window"]["setText"] = function() end

autoKaiCaster["window"]["onEscape"] = exitAction;
autoKaiCaster["window"]["closeButton"]["onClick"] = exitAction;

function string:extractNumbers()
	
	local str = "";
	
	for i = 1, #self do
		local indexVal = self:sub(i, i);
		if (tonumber(indexVal)) then
			str = str .. indexVal;
		end
	end
	
	return str;
end

autoKaiCaster["window"]["mainPanel"]["sealedTime"]["onTextChange"] = function(widget, text)
	local extractedNumbers = text:extractNumbers();
	if (text ~= extractedNumbers) then
		widget:setText(extractedNumbers);
	end
end

autoKaiCaster["displaySucces"] = function(text)

	local widget = autoKaiCaster["window"]["mainPanel"]["infoDisplay"];
	local excludeText = now + 1500;
	widget["time"] = excludeText;
	widget:setText(text);
	widget:setColor("green");
	
	schedule(1500, function()
		if (widget["time"] ~= excludeText) then return; end
		widget:clearText();
	end)
end

autoKaiCaster["displayError"] = function(text)

	local widget = autoKaiCaster["window"]["mainPanel"]["infoDisplay"];
	local excludeText = now + 1500;
	widget["time"] = excludeText;
	widget:setText(text);
	widget:setColor("red");
	
	schedule(1500, function()
		if (widget["time"] ~= excludeText) then return; end
		widget:clearText();
	end)
end

autoKaiCaster["window"]["mainPanel"]["addButton"]["onClick"] = function()
	if (FREE_VERSION) then return; end
	
	local spellName = autoKaiCaster["window"]["mainPanel"]["spellName"]:getText():ucwords();
	local sealedTime = tonumber(autoKaiCaster["window"]["mainPanel"]["sealedTime"]:getText():extractNumbers()) or 0;
	local sealType = autoKaiCaster["window"]["mainPanel"]["sealType"]:getText():trim();

	if (sealType:len() == 0) then
		sealType = "None";
	else
		local split = sealType:split(",");
		for index, val in ipairs(split) do
			split[index] = val:ucwords();
		end
		sealType = table["concat"](split, ", ");
	end

	if (#spellName == 0) then
		return autoKaiCaster["displayError"]("Insira o nome da magia.");
	end
	
	if (config[spellName]) then
		return autoKaiCaster["displayError"]("A magia j\225 existe.");
	end
	
	config[spellName] = {
		spell = spellName,
		sealedTime = sealedTime,
		sealType = sealType,
		enabled = true
	};
	autoKaiCaster["displaySucces"]("A magia foi adicionada.");
	
	autoKaiCaster["window"]["mainPanel"]["spellName"]:clearText();
	autoKaiCaster["window"]["mainPanel"]["sealType"]:clearText();
	autoKaiCaster["window"]["mainPanel"]["sealedTime"]:clearText();
	autoKaiCaster["refreshSpells"]();
end


autoKaiCaster["refreshSpells"]();


storage["attackingPlayers"] = storage["attackingPlayers"] or {};

macro(100, function()
	for name, time in pairs(storage["attackingPlayers"]) do
		if (os["time"]() >= time) then
			storage["attackingPlayers"][name] = nil;
		end
	end
end)

autoKaiCaster["getSpectators"] = function(multifloor)
	local specs = getSpectators(multifloor);
	if (#specs == 0) then
		-- FIX (Slow macro): antes escaneava g_map.getTiles(posz()), ou seja o
		-- andar INTEIRO, toda vez que nao havia ninguem visivel. Agora fica
		-- limitado a uma area ao redor do jogador.
		local playerPos = pos();
		if playerPos then
			local scanRadius = 8;
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
		end
	end
	return specs;
end

onTextMessage(function(mode, text)
	if (not text:find("attack by")) then return; end
	text = text:sub(9);
	
	for _, spec in ipairs(autoKaiCaster["getSpectators"]()) do
		if (spec:isPlayer()) then
			local specName = spec:getName();
			if (text:find(specName)) then
				storage["attackingPlayers"][specName] = os["time"]() + 1;
				break
			end
		end
	end
end)

storage["sealedTypes"] = storage["sealedTypes"] or {};

autoKaiCaster["setExhaust"] = function(value)

	if (value["sealType"] == "None") then return; end
	
	for _, val in ipairs(value["sealType"]:split(",")) do
		val = val:lower():trim();
		if (val ~= "kai") then
			storage["sealedTypes"][val] = os["time"]() + value["sealedTime"];
		else
			config["kaiExhaust"] = os["time"]() + value["sealedTime"];
		end
	end
end

onTalk(function(name, level, mode, text)
	if (mode ~= 44) then return; end
	if (storage["attackingPlayers"][name]) then
		
		text = text:ucwords();
		
		local index = config[text];
		if (not index) then return; end
		
		autoKaiCaster["setExhaust"](index);
		config["requestKai"] = true;
	elseif (player:getName() == name) then
		text = text:ucwords();
		if (text == kaiSpell) then
			config["kaiExhaust"] = os["time"]() + kaiExhaust;
			config["requestKai"] = false;
		end
	end
end)

if (FREE_VERSION) then
	autoKaiUI["macro"]:setTooltip("Essa script est\225 desativada para a custom free.");
	return nil;
end


configData["antiTrap"]["macro"] = autoKaiUI["macro"];
