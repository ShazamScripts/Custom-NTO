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
local horizontalScrollBar = "Panel\n  height: 15\n\n  Label\n    id: text\n    anchors.left: parent.left\n    anchors.right: parent.right\n    anchors.top: parent.top\n    text-align: center\n\n  HorizontalScrollBar\n    id: scroll\n    anchors.left: parent.left\n    anchors.right: parent.right\n    anchors.top: prev.top\n    minimum: 0\n    maximum: 10\n    step: 1\n";

storage["scrollBars"] = storage["scrollBars"] or {};
local addScrollBar = function(id, title, min, max, defaultValue)
    local widget = setupUI(horizontalScrollBar);
    widget["scroll"]:setRange(min, max);
    if max-min > 1000 then
        widget["scroll"]:setStep(100);
    elseif max-min > 100 then
        widget["scroll"]:setStep(10);
    end
    widget["scroll"]:setValue(storage["scrollBars"][id] or defaultValue);
    widget["scroll"]["onValueChange"] = function(scroll, value)
		storage["scrollBars"][id] = value;
        widget["scroll"]:setText(title .. ": " .. value);
    end
    widget["scroll"]["onValueChange"](widget["scroll"], widget["scroll"]:getValue());
	return widget;
end

local checkBoxWidget = "CheckBox\n  id: checkBox\n";

storage["checkBoxs"] = storage["checkBoxs"] or {};
addCheckBox = function(id, name, callback)
	local checkBox = setupUI(checkBoxWidget);
	checkBox:setText(name);
	checkBox["onCheckChange"] = function(widget, checked)
		widget:setChecked(checked);
		storage["checkBoxs"][id] = checked;
		if (callback) then
			callback(widget, checked);
		end
	end
	schedule(0, function()
		checkBox:onCheckChange(storage["checkBoxs"][id]);
	end);
	return checkBox;
end


setDefaultTab("User");

UI["Label"]("CONFIG"):setColor("white");


local macroDelay = addScrollBar("macroDelay", "Macro delay", 10, 1000, 50);
macroDelay["scroll"]:setTooltip("Funciona ap\243s o restart do bot.");

local customIP = {
	["54.39.77.216:7172"] = "DBO GAME",
	["167.114.28.13:7172"] = "DBO GOLD",
	["54.39.77.220:7172"] = "NTO REVERSE"
};

local worldIp = FREE_GET_WORLD_IP();
local worldName = customIP[worldIp] or tyrBot["getWorldName"]();
local loweredWorld = worldName:lower():trim();
local isDBO = loweredWorld:find("db");

UI["Label"]("Haste");

local hasteSpell = storage["hasteSpell"] or isDBO and "Speed Up" or "Concentrate Chakra Feet";

addTextEdit("hasteSpell", storage["hasteSpell"] or hasteSpell, function(widget, text)
	storage["hasteSpell"] = text;
end)

addCheckBox("antiLyze", "Heal Paralyze");


UI["Label"]("Regeneration");
storage["regenSpell"] = storage["regenSpell"] or "Big Regeneration";
local regenerationSpells;

local regenRefactor = function()
	regenerationSpells = storage["regenSpell"]:split(",");
	for index, spell in ipairs(regenerationSpells) do
		regenerationSpells[index] = spell:trim();
	end
end


regenRefactor();


addTextEdit("regenSpell", table["concat"](regenerationSpells, ", "), function(widget, text)
	widget:setTooltip("Se tiver mais de um regen, separe por v\237rgula. ex: 'Big Regeneration, Regeneration'");
	storage["regenSpell"] = text;
	regenRefactor();
end)

UI["Separator"]();

addScrollBar("regenPercent", "Regeneration %", 1, 100, 100);
speedDelay = 0;
local maxSpeed;
macro(100, function()
	
	local isSealed = storage["sealedTypes"] and storage["sealedTypes"]["speed"] and storage["sealedTypes"]["speed"] > os["time"]();
	if (not isSealed) then
		local playerSpeed = player:getSpeed();
		if (hasHaste() and (maxSpeed == nil or maxSpeed < playerSpeed)) then
			maxSpeed = playerSpeed;
		end
		local cast_haste;
		if (speedDelay < now) then
			if (not maxSpeed or playerSpeed < (maxSpeed - 10)) then
				if (not isParalyzed() and not hasHaste()) then
					speedDelay = now + 500;
					cast_haste = true;
				end
			end
		end
		if (storage["checkBoxs"] and storage["checkBoxs"]["antiLyze"] and isParalyzed()) then
			cast_haste = true;
		end
		if (cast_haste) then
			say(storage["hasteSpell"]);
		end
	end

	
	local regenPercent, healthPercent = storage["scrollBars"]["regenPercent"] or 100, player:getHealthPercent();
	if (healthPercent < regenPercent) then
		if (
			not isDBO and
			storage["bijuuRegen"] and
			storage["checkBoxs"]["useBijuu"] and
			player:getOutfit()["type"] == storage["bijuuOutfit"]
		) then
			say(storage["bijuuRegen"]);
		else
			for _, spell in ipairs(regenerationSpells) do
				say(spell, -1);
			end
		end
	end
	
		
	
end);


GLOBAL_CHECKBOX = addCheckBox;
GLOBAL_SCROLL_BAR = addScrollBar;

local potScript = "local storage = tyrBot.storage;\nlocal healthPotion = {};\nlocal manaPotion = {};\n\n\nlocal use_item = function(id, time)\n\tif (potExhaust and potExhaust >= now) then\n\t\treturn;\n\tend\n\tdelay(time);\n\tlocal item = Item.create(id);\n\tif (item:isMultiUse()) then\n\t\tuseWith(id, player);\n\t\treturn;\n\tend\n\tuse(id);\nend\n\nhealthPotion.checkBox = GLOBAL_CHECKBOX(\"healthPotion\", \"Health Potion\", function(widget, checked)\n\tfor key, child in pairs(healthPotion) do\n\t\tif (type(child) ~= \"userdata\" or key == \"checkBox\") then\n\t\t\tgoto continue;\n\t\tend\n\t\tif (checked) then\n\t\t\tchild:show();\n\t\telse\n\t\t\tchild:hide();\n\t\tend\n\t\t::continue::\n\tend\n\t-- manaPotion.checkBox:setMarginTop(checked and 10 or 0);\nend)\n\nhealthPotion.uiLabel = UI.Label(\"Id:\");\n\nhealthPotion.uiTextEdit = addTextEdit(\"healthPotion\", storage.healthPotionId or \"11863\", function(widget, text)\n\tlocal ID = tonumber(text);\n\tif (not ID) then\n\t\twidget:setText(widget.text);\n\t\treturn error(\"Insira um id v\225lido\");\n\tend\n\twidget.text = ID;\n\tstorage.healthPotionId = ID;\nend)\n\nhealthPotion.lifescrollBar = GLOBAL_SCROLL_BAR(\"healthPotion\", \"Life %\", 1, 100, 100);\n\nhealthPotion.delayscrollBar = GLOBAL_SCROLL_BAR(\"delayHealth\", \"Delay\", 0, 1000, 300);\n\nhealthPotion.Separator = UI.Separator();\n\nmanaPotion.checkBox = GLOBAL_CHECKBOX(\"manaPotion\", \"Mana Potion\", function(widget, checked)\n\tfor key, child in pairs(manaPotion) do\n\t\tif (type(child) ~= \"userdata\" or key == \"checkBox\") then\n\t\t\tgoto continue;\n\t\tend\n\t\tif (checked) then\n\t\t\tchild:show();\n\t\telse\n\t\t\tchild:hide();\n\t\tend\n\t\t::continue::\n\tend\nend)\n\nmanaPotion.uiLabel = UI.Label(\"Id:\");\n\nmanaPotion.uiTextEdit = addTextEdit(\"manaPotion\", storage.manaPotionId or \"11863\", function(widget, text)\n\tlocal ID = tonumber(text);\t\n\tif (not ID) then\n\t\twidget:setText(widget.text);\n\t\treturn error(\"Insira um id v\225lido\");\n\tend\n\twidget.text = ID;\n\tstorage.manaPotionId = ID;\nend)\n\nmanaPotion.scrollBar = GLOBAL_SCROLL_BAR(\"manaPotion\", \"Mana %\", 1, 100, 100);\nmanaPotion.delayscrollBar = GLOBAL_SCROLL_BAR(\"delayMana\", \"Delay\", 0, 1000, 300);\nmanaPotion.Separator = UI.Separator();\n\n\nmacro(storage.scrollBars.macroDelay or 1, function()\n\tif (storage.checkBoxs.healthPotion) then\n\t\tlocal hpToUse, idPot = storage.scrollBars.healthPotion, storage.healthPotionId;\n\t\tif (idPot and hpToUse and player:getHealthPercent() < hpToUse) then\n\t\t\tuse_item(idPot, storage.scrollBars.delayHealth);\n\t\tend\n\tend\nend)\n\nmacro(storage.scrollBars.macroDelay or 1, function()\n\tif (storage.checkBoxs.manaPotion) then\n\t\tlocal manaToUse, idPot = storage.scrollBars.manaPotion, storage.manaPotionId;\n\t\tif (idPot and manaToUse and manapercent() < manaToUse) then\n\t\t\tuse_item(idPot, storage.scrollBars.delayMana);\n\t\tend\n\tend\nend)\n\n";

if (isDBO) then
	local changeValues = {"Potion", "potion", "Pot"};
	for _, value in ipairs(changeValues) do
		potScript = potScript:gsub(value, "Senzu");
	end
end


load(potScript)();



if (not isDBO) then
	
	local kunaiConfig = {
		baseId = 7382
	};

	kunaiConfig["checkBox"] = addCheckBox("useKunai", "Kunai Dash & Jump", function(widget, checked)
		if (FREE_VERSION and checked) then
			return widget:setChecked(false);
		end
		for key, widget in pairs(kunaiConfig) do
			if (type(widget) ~= "userdata" or key == "checkBox") then
				goto continue;
			end
			local callback = widget["hide"];
			if (FREE_VERSION) then
				kunaiConfig[key] = nil;
				callback = widget["destroy"];
			elseif (checked) then
				callback = widget["show"];
			end
			callback(widget);
			::continue::
		end
	end)
	if (FREE_VERSION) then
		kunaiConfig["checkBox"]:setTooltip("Essa script est\225 desativada para a custom free.");
	end


	kunaiConfig["idLabel"] = UI["Label"]("Id da Kunai");
	kunaiConfig["idTextEdit"] = addTextEdit("KUNAI ID", storage["kunaiId"] or kunaiConfig["baseId"], function(widget, text)
		local ID = tonumber(text);
		if (not ID) then
			return error("Insira um id v\225lido.");
		end
		storage["kunaiId"] = ID;
	end)
	
	kunaiConfig["distanceScrollBar"] = addScrollBar("distanceKunai", "Distance", 2, 15, 10);

	kunaiConfig["crossHairKunaiKeyLabel"] = UI["Label"]("Tecla para crosshair");
	kunaiConfig["crossHairKunaiKey"] = addTextEdit("keyKunai", storage["kunaiKey"] or "F2", function(widget, text)
		text = modules["corelib"]["retranslateKeyComboDesc"](text);
		if (not text) then
			return error("Insira uma tecla v\225lida");
		end
		storage["kunaiKey"] = text;
	end)

	game_interface = modules["_G"]["package"]["loaded"]["game_interface"];
	onKeyDown(function(key)
		if (not storage["checkBoxs"]["useKunai"]) then return; end
		if (key ~= storage["kunaiKey"]) then return; end
		game_interface["startUseWith"](Item["create"](storage["kunaiId"]));
	end)


	local bijuuConfig = {};
	bijuuConfig["checkBox"] = addCheckBox("useBijuu", "Bijuu Configs", function(widget, checked)
		if (FREE_VERSION and checked) then
			return widget:setChecked(false);
		end
		for key, widget in pairs(bijuuConfig) do
			if (type(widget) ~= "userdata" or key == "checkBox") then
				goto continue;
			end
			local callback = widget["hide"];
			if (FREE_VERSION) then
				bijuuConfig[key] = nil;
				callback = widget["destroy"];
			elseif (checked) then
				callback = widget["show"];
			end
			callback(widget);
			::continue::
		end
	end)
	if (not FREE_VERSION) then
		bijuuConfig["checkBox"]:setTooltip("Feito com base no NTO ULTIMATE.");
	else
		bijuuConfig["checkBox"]:setTooltip("Essa script est\225 desativada para a custom free.");
	end


	bijuuConfig["outfitLabel"] = UI["Label"]("Bijuu outfit");
	bijuuConfig["outfitTextEdit"] = addTextEdit("bijuuOutfit", storage["bijuuOutfit"] or "0", function(widget, text)
		local ID = tonumber(text);
		if (not ID) then
			return error("Insira um outfit v\225lido.");
		end
		storage["bijuuOutfit"] = ID;
	end)

	bijuuConfig["regenLabel"] = UI["Label"]("Bijuu regen spell");
	bijuuConfig["regenTextEdit"] = addTextEdit("bijuuRegen", storage["bijuuRegen"] or "Bijuu Regeneration", function(widget, text)
		storage["bijuuRegen"] = text:lower():trim();
	end)

	bijuuConfig["buffLabel"] = UI["Label"]("Bijuu buff spell");
	bijuuConfig["buffTextEdit"] = addTextEdit("bijuuBuff", storage["bijuuBuff"] or "Bijuu Yaiba", function(widget, text)
		storage["bijuuBuff"] = text:lower():trim();
	end)
	
	bijuuConfig["Separator"] = UI["Separator"]();
	macro(storage["scrollBars"]["macroDelay"] or 1, function(self)
		if (FREE_VERSION) then
			return self:setOff();
		end
		if (not storage["checkBoxs"]["useBijuu"]) then return; end
		if (storage["bijuuOutfit"] ~= player:getOutfit()["type"]) then
			if (worldName == "NtoUltimate" and storage["castedYaiba"] ~= nil) then
				storage["castedYaiba"] = nil;
			end
			return; 
		end
		if (worldName == "NtoUltimate") then
			local config = storage["especiaisConfig"]["spells"]["Buffs"];
			for _, entry in pairs(config) do
				entry["cooldownTime"] = os["time"]() + 1;
			end
			
			if ((storage["castedYaiba"] or 0) >= 2) then return; end
		end
		if (storage["bijuuBuffExhaust"] and storage["bijuuBuffExhaust"] >= os["time"]()) then return; end

		if (isInPz()) then return; end

		say(storage["bijuuBuff"]);
	end)

	onTalk(function(name, level, mode, text)
		if (FREE_VERSION) then return; end
		if (name ~= player:getName()) then return; end

		if (mode ~= 44) then return; end
		
		text = text:trim():lower();
		if (text == storage["bijuuBuff"]) then
			storage["bijuuBuffExhaust"] = os["time"]() + 15;
			storage["castedYaiba"] = (storage["castedYaiba"] or 0) + 1;
		end
	end)

	local pillConfig = {
		baseId = 11821
	};

	pillConfig["checkBox"] = addCheckBox("usePill", "Usar Pill", function(widget, checked)
		if (FREE_VERSION and checked) then
			return widget:setChecked(false);
		end
		for key, widget in pairs(pillConfig) do
			if (type(widget) ~= "userdata" or key == "checkBox") then
				goto continue;
			end
			local callback = widget["hide"];
			if (FREE_VERSION) then
				pillConfig[key] = nil;
				callback = widget["destroy"];
			elseif (checked) then
				callback = widget["show"];
			end
			callback(widget);
			::continue::
		end
	end)
	
	if (FREE_VERSION) then
		pillConfig["checkBox"]:setTooltip("Essa script est\225 desativada para a custom free.");
	end

	pillConfig["idLabel"] = UI["Label"]("Pill Id");
	pillConfig["idTextEdit"] = addTextEdit("pillId", global_storage["pillId"] or pillConfig["baseId"], function(widget, text)
		local ID = tonumber(text);
		if (not ID) then
			return error("Insira um id v\225lido");
		end
		global_storage["pillId"] = ID;
	end)


	global_storage["pillContent"] = global_storage["pillContent"] or "Nhack Nhack";
	pillConfig["refactor"] = function()
		pillConfig["contents"] = global_storage["pillContent"]:split(",");
		for index, value in pairs(pillConfig["contents"]) do
			pillConfig["contents"][index] = value:lower():trim();
		end
	end
	pillConfig["refactor"]();
	pillConfig["textLabel"] = UI["Label"]("Pill Text");
	pillConfig["contentTextEdit"] = addTextEdit("pillContent", storage["pillContent"], function(widget, text)
		widget:setTooltip("Se tiver mais de um texto, separe por v\237rgula. ex: 'Nhack Nhack, Crock Crock!'");
		global_storage["pillContent"] = text;
		pillConfig["refactor"]();
	end)

	pillConfig["Separator"] = UI["Separator"]();

	local rec_ch_by_id = {"r", "e", "c", "u", "r", "s", "i", "v", "e", "G", "e", "t", "C", "h", "i", "l", "d", "B", "y", "I", "d"};
	rec_ch_by_id = table["concat"](rec_ch_by_id);

	storage["pillDelay"] = storage["pillDelay"] or 0;

	macro(storage["scrollBars"]["macroDelay"] or 1, function(self)
		if (FREE_VERSION) then
			return self:setOff();
		end
		if (not storage["checkBoxs"]["usePill"]) then return; end
		local target = tyrBot["getAttackingCreature"]();
		if (not target) then return; end
		if (not target:isPlayer()) then return; end
		local sealedKai = storage["autoKaiConfig"];
		sealedKai = sealedKai and sealedKai["kaiExhaust"];
		if (not sealedKai or sealedKai < os["time"]()) then
			if (storage["pillDelay"] < os["time"]()) then
				if (pillConfig["triedToUse"]) then
					useWith(global_storage["pillId"], player);
					pillConfig["triedToUse"] = false;
				else
					use(global_storage["pillId"]);
					pillConfig["triedToUse"] = true;
				end
				delay(500);
				return;
			end
			pillConfig["triedToUse"] = nil;
		end
	end)

	onTalk(function(name, level, mode, text)
		if (FREE_VERSION) then return; end
		if (mode ~= 44) then return; end
		if (name ~= player:getName()) then return; end

		text = text:trim();
		if (not table["find"](pillConfig["contents"], text, true)) then return; end
		storage["pillDelay"] = os["time"]() + 60;
	end)
end
local eatFood = {
	fullCheck = 0,	
	tryingToEat = 0
};


eatFood["isFull"] = function()
	return eatFood["fullCheck"] >= now;
end
eatFood["checkBox"] = addCheckBox("eatFood", "Eat Food", function(widget, checked)
	for key, widget in pairs(eatFood) do
		if (type(widget) ~= "userdata" or key == "checkBox") then
			goto continue;
		end
		if (checked) then
			widget:show();
		else
			widget:hide();
		end
		::continue::
	end
	if (not checked) then
		tyrBot["storage"]["castFood"] = false;
	end
	local self = eatFood["castCheckBox"];
	self:onCheckChange(tyrBot["storage"]["castFood"]);
end)

eatFood["itemsLabel"] = UI["Label"]("Items:");
if (type(tyrBot["storage"]["foodItems"]) ~= "table") then
	tyrBot["storage"]["foodItems"] = {3577};
end

eatFood["itemsContainer"] = UI["Container"](function(widget, items)
	tyrBot["storage"]["foodItems"] = items;
end, true);
eatFood["itemsContainer"]:setHeight(35);
eatFood["itemsContainer"]:setItems(storage["foodItems"]);

eatFood["castCheckBox"] = addCheckBox("castFood", "Cast Food", function(widget, checked)
	for _, widget in ipairs({eatFood["foodCasting"], eatFood["foodCastingSeparator"]}) do
		if (checked) then
			widget:show();
		else
			widget:hide();
		end
	end
end)

eatFood["foodCasting"] = addTextEdit("foodCasting", tyrBot["storage"]["castFoodSpell"] or "shokuji no jutsu", function(widget, text)
	tyrBot["storage"]["castFoodSpell"] = text:trim();
end)

eatFood["foodCasting"]:setTooltip("Spell to cast food");

local markAttacking = {};
markAttacking["checkBox"] = addCheckBox("markAttacking", "Marcar criaturas");

local _G = modules["_G"];
local g_map = _G["g_map"];
local g_clock = _G["g_clock"];
local protocol = _G["ProtocolGame"];
local scheduleEvent = _G["scheduleEvent"];


local opcode_callbacks = {};


setCreatureMarked = function(creature, color)
	if (not tyrBot["storage"]["checkBoxs"]["markAttacking"]) then return; end
	if not (creature ~= nil and creature:isMonster()) then
		return;
	end
	creature:setMarked(color or "red");
	
	local time = g_clock["millis"]();
	creature["markTime"] = time;
	scheduleEvent(function()
		if (creature["markTime"] == time) then
			creature:setMarked("");
		end
	end, 2000)
end

opcode_callbacks[134] = function(self, msg) 
	local id = msg:getU32();
	local color = msg:getU8();
	
	local creature = g_map["getCreatureById"](id);
	if (color == 0) then
		setCreatureMarked(creature);
	end
end

opcode_callbacks[147] = function(self, msg) 
	local len;
	if (g_game["getProtocolVersion"]() >= 1035) then
		len = 1;
	else
		len = msg:getU8();
	end
	
	for i = 1, len do
        local id = msg:getU32();
		local isPermanent = msg:getU8() ~= 1;
		local color = msg:getU8();
		local creature = g_map["getCreatureById"](id);
		if (isPermanent) then
			if (color == 0xff) then
				setCreatureMarked(creature, "");
			elseif (color == 0) then
				setCreatureMarked(creature);
			end
		elseif (color == 0) then
			setCreatureMarked(creature);
		end
	end
end

protocol["sendCallbacks"] = function(self, opcode, msg)
	local callback = opcode_callbacks[opcode];
	if not callback then return; end
	callback(self, msg);
end

opCode = function(self, opcode, msg)
	self:sendCallbacks(opcode, msg);
end

_G["oldOpcode"] = _G["oldOpcode"] or protocol["onOpcode"];
protocol["onOpcode"] = function(...)
	opCode(...);
	return _G["oldOpcode"](...);
end

macro(500, function()
	if (not tyrBot["storage"]["checkBoxs"]["eatFood"]) then return; end
	if (eatFood["isFull"]()) then return; end
	
	eatFood["tryingToEat"] = eatFood["tryingToEat"] or now
	for _, item in ipairs(tyrBot["storage"]["foodItems"]) do
		use(item["id"])
	end
	local eatTime = eatFood["tryingToEat"];
	if (eatTime and now - eatTime >= 1500 and storage["castFood"]) then
		say(tyrBot["storage"]["castFoodSpell"]);
	end
end)

onTextMessage(function(mode, text)
	if (text == "You are full." or text:find("Voc. est. cheio")) then
		eatFood["fullCheck"] = now + 20000;
		eatFood["tryingToEat"] = nil;
	end
end)


excludeIds = excludeIds or {
	12099,
	17393
};

stairsIds = stairsIds or {
	1666,
	6207,
	1948,
	435,
	7771,
	5542,
	8657,
	6264,
	1646,
	1648,
	1678,
	5291,
	1680,
	6905,
	6262,
	1664,
	13296,
	1067,
	13861,
	11931,
	1949,
	6896,
	6205,
	13926,
	1947,
	12097,
	615,
	1678, 
	8367, 
};

updateIds = function()
	excludeIds = {};
	stairsIds = {};
	
	
	for _, value in ipairs(storage["stairsIds"]) do
		stairsIds[value["id"]] = true;
	end
	
	for _, value in ipairs(storage["excludeIds"]) do
		excludeIds[value["id"]] = true;
	end
	
	
end

if (not stairsIdContainer) then
	UI["Label"]("Escadas & Portas")
	
	local stairsCallback = function(widget, items)
		storage["stairsIds"] = items;
		updateIds();
	end
	
	stairsIdContainer = UI["Container"](stairsCallback, true);


	storage["stairsIds"] = storage["stairsIds"] or stairsIds;
	stairsIdContainer:setItems(storage["stairsIds"]);
	stairsIdContainer:setHeight(35);
	UI["Separator"]();
end

if (not excludeIdsContainer) then
	UI["Label"]("Ids exclu\237dos");
	
	local excludeCallback = function(widget, items)
		storage["excludeIds"] = items;
		updateIds();
	end
	
	excludeIdsContainer = UI["Container"](excludeCallback, true);
	
	storage["excludeIds"] = storage["excludeIds"] or excludeIds;
	excludeIdsContainer:setItems(storage["excludeIds"]);
	excludeIdsContainer:setHeight(35);
	UI["Separator"]();
end

updateIds();

if (not UI["ConfirmationWindow"]) then
	UI["ConfirmationWindow"] = function(title, question, callback)
		local window;
		local closeWindow = function()
			window:destroy()
		end
		local onConfirm = function()
			closeWindow();
			callback();
		end
		window = displayGeneralBox(title, question, {
			{text=tr("Yes"), callback=onConfirm},
			{text=tr("No"), callback=closeWindow},
			anchor=AnchorHorizontalCenter}, onConfirm, closeWindow);
		window["botWidget"] = true;
		return window;
	end
end

UI["Button"]("Reiniciar Custom", function()
	UI["ConfirmationWindow"]("Reiniciar Custom", "Deseja reiniciar o client para recarregar a custom local?",
	function()
		g_app = modules["corelib"]["g_app"];
		g_app["restart"]();
		
	end)
end)


setDefaultTab("OTHERS");


UI["Button"]("In-game scripts", function(newText)
	UI["MultilineEditorWindow"](storage["scriptsArea"] or "", {title="Scripts Area", description="Coloque seus scripts aqui."}, function(text)
		storage["scriptsArea"] = text;
		schedule(100, reload);
	end)
end)

setDefaultTab("UTI");


TyrTrainer = {}

_G = modules["_G"]
context = _G["getfenv"]()
g_resources = _G["g_resources"]
listDirectoryFiles = g_resources["listDirectoryFiles"]
readFileContents = g_resources["readFileContents"]
fileExists = g_resources["fileExists"]
TyrTrainer["addEvent"] = _G["addEvent"];
TyrTrainer["rootWidget"] = g_ui["getRootWidget"]()

TyrTrainer["panelMacro"] = "tyrtrainer"
TyrTrainer["panelUI"] = setupUI("Panel\n  height: 17\n  BotSwitch\n    id: title\n    anchors.top: parent.top\n    anchors.left: parent.left\n    anchors.right: parent.right\n    text-align: center\n    !text: tr('Treinar')\n\n    image-source:\n\n    $on:\n      color: green\n\n    $!on:\n      color: white\n")
TyrTrainer["panelUI"]:setId(TyrTrainer["panelMacro"])

TyrTrainer["window"] = setupUI("MainWindow\n  id: MainWindow\n  size: 240 330\n  text: Treinar\n  anchors.centerIn: parent\n\n  Label\n    id: spellLabel\n    text: Magia de Treino\n    anchors.top: parent.top\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-top: 10\n    text-align: center\n\n  TextEdit\n    id: spellEntry\n    size: 120 20\n    anchors.top: spellLabel.bottom\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-top: 5\n\n  CheckBox\n    id: regenCheck\n    width: 150\n    anchors.top: spellEntry.bottom\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-top: 20\n    text: Mana Regeneration\n    !tooltip: tr(\"Se seu servidor tem regen de mana marque o checkbox e coloca a spell.\")\n\n  TextEdit\n    id: regenEntry\n    size: 120 20\n    anchors.top: regenCheck.bottom\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-top: 5\n\n  CheckBox\n    id: potionCheck\n    width: 150\n    anchors.top: regenEntry.bottom\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-top: 20\n    text: Mana Potion\n    !tooltip: tr(\"ativar potion de mana.\")\n\n  BotItem\n    id: potionEntry\n    anchors.top: potionCheck.bottom\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-top: 10\n    margin-right: 30\n\n  Label\n    id: potionId\n    text: \"ID: -\"\n    width: 150\n    anchors.top: potionEntry.top\n    anchors.left: potionEntry.right\n    margin-left: 3\n\n  Label\n    id: potionPercent\n    text: \"MP%: -\"\n    width: 150\n    anchors.top: potionEntry.top\n    anchors.left: potionEntry.right\n    margin-left: 3\n    margin-top: 20\n\n  Label\n    id: manaLabel\n    text: Porcentagem de Mana\n    anchors.top: potionEntry.bottom\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-top: 10\n\n  HorizontalScrollBar\n    id: manaPercent\n    width: 150\n    anchors.top: manaLabel.bottom\n    anchors.horizontalCenter: parent.horizontalCenter\n    margin-top: 5\n    minimum: 0\n    maximum: 100\n\n  Label\n    id: manaPercentText\n    text: \"50%\"\n    anchors.centerIn: manaPercent\n\n  Button\n    id: closeButton\n    text: Fechar\n    anchors.right: parent.right\n    anchors.left: parent.left\n    anchors.bottom: parent.bottom\n    margin-bottom: 10\n    size: 50 20\n", TyrTrainer["rootWidget"])

TyrTrainer["window"]:hide()

TyrTrainer["window"]["potionEntry"]:hide()
TyrTrainer["window"]["potionId"]:hide()
TyrTrainer["window"]["potionPercent"]:hide()
TyrTrainer["window"]["manaLabel"]:hide()
TyrTrainer["window"]["manaPercent"]:hide()
TyrTrainer["window"]["manaPercentText"]:hide()

if not storage["trainerData"] then
    storage["trainerData"] = {}
end

if not storage["trainerData"]["enabled"] then
    storage["trainerData"]["enabled"] = false
end

local baseHeight = 220
local regenHeight = 10
local potionHeight = 70

TyrTrainer["adjustWindow"] = function()
    if not TyrTrainer["window"] then return end

    local newHeight = baseHeight
    if TyrTrainer["window"]["regenCheck"]:isChecked() then
        newHeight = newHeight + regenHeight
    end
    if TyrTrainer["window"]["potionCheck"]:isChecked() then
        newHeight = newHeight + potionHeight
    end
    TyrTrainer["window"]:setHeight(newHeight + 30)

end

TyrTrainer["window"]["spellEntry"]:setText(storage["trainerData"]["spellTraining"] or "")
TyrTrainer["window"]["regenCheck"]:setChecked(storage["trainerData"]["checkRegen"] or false)
TyrTrainer["window"]["potionCheck"]:setChecked(storage["trainerData"]["checkPotion"] or false)
TyrTrainer["window"]["regenEntry"]:setText(storage["trainerData"]["spellRegen"] or "")
TyrTrainer["window"]["manaPercent"]:setValue(storage["trainerData"]["manaPercent"] or 50)
TyrTrainer["window"]["manaPercentText"]:setText(storage["trainerData"]["manaPercent"] and (storage["trainerData"]["manaPercent"] .. "%") or "50%")

TyrTrainer["saveConfig"] = function()
    storage["trainerData"]["spellTraining"] = TyrTrainer["window"]["spellEntry"]:getText()
    storage["trainerData"]["checkRegen"] = TyrTrainer["window"]["regenCheck"]:isChecked()
    storage["trainerData"]["checkPotion"] = TyrTrainer["window"]["potionCheck"]:isChecked()
    storage["trainerData"]["spellRegen"] = TyrTrainer["window"]["regenEntry"]:getText()
    storage["trainerData"]["manaPercent"] = TyrTrainer["window"]["manaPercent"]:getValue()
    TyrTrainer["adjustWindow"]()
end

if storage["trainerData"]["checkRegen"] then
    TyrTrainer["window"]["regenEntry"]:show()
else
    TyrTrainer["window"]["regenEntry"]:hide()
end


if storage["trainerData"]["checkPotion"] then
    TyrTrainer["window"]["potionEntry"]:show()
    TyrTrainer["window"]["potionId"]:show()
    TyrTrainer["window"]["potionPercent"]:show()
    TyrTrainer["window"]["manaLabel"]:show()
    TyrTrainer["window"]["manaPercent"]:show()
    TyrTrainer["window"]["manaPercentText"]:show()
else
    TyrTrainer["window"]["potionEntry"]:hide()
    TyrTrainer["window"]["potionId"]:hide()
    TyrTrainer["window"]["potionPercent"]:hide()
    TyrTrainer["window"]["manaLabel"]:hide()
    TyrTrainer["window"]["manaPercent"]:hide()
    TyrTrainer["window"]["manaPercentText"]:hide()
end

TyrTrainer["window"]["potionCheck"]["onCheckChange"] = function(widget, checked)
    if checked then
        TyrTrainer["window"]["potionEntry"]:show()
        TyrTrainer["window"]["potionId"]:show()
        TyrTrainer["window"]["potionPercent"]:show()
        TyrTrainer["window"]["manaLabel"]:show()
        TyrTrainer["window"]["manaPercent"]:show()
        TyrTrainer["window"]["manaPercentText"]:show()
    else
        TyrTrainer["window"]["potionEntry"]:hide()
        TyrTrainer["window"]["potionId"]:hide()
        TyrTrainer["window"]["potionPercent"]:hide()
        TyrTrainer["window"]["manaLabel"]:hide()
        TyrTrainer["window"]["manaPercent"]:hide()
        TyrTrainer["window"]["manaPercentText"]:hide()
    end
    storage["trainerData"]["checkPotion"] = checked
    TyrTrainer["saveConfig"]()
end


TyrTrainer["window"]["regenCheck"]["onCheckChange"] = function(widget, checked)
    if checked then
        TyrTrainer["window"]["regenEntry"]:show()
    else
        TyrTrainer["window"]["regenEntry"]:hide()
    end
    storage["trainerData"]["checkRegen"] = checked
    TyrTrainer["saveConfig"]()
end

TyrTrainer["adjustWindow"]()

TyrTrainer["window"]["manaPercent"]["onValueChange"] = function(scrollbar, value)
    TyrTrainer["window"]["manaPercentText"]:setText(value .. "%")
    TyrTrainer["window"]["potionPercent"]:setText("MP%: " .. value)
    storage["trainerData"]["manaPercent"] = value
    TyrTrainer["saveConfig"]()
end

TyrTrainer["window"]["potionEntry"]["onItemChange"] = function(widget)
    local item = widget:getItem()
    if item then
        local itemId = item:getId()
        TyrTrainer["window"]["potionId"]:setText("ID: " .. itemId)
        TyrTrainer["window"]["potionPercent"]:setText("MP%: " .. TyrTrainer["window"]["manaPercent"]:getValue()) 
        storage["trainerData"]["potionId"] = itemId
        TyrTrainer["saveConfig"]()
    else
        TyrTrainer["window"]["potionId"]:setText("ID: -")
        TyrTrainer["window"]["potionPercent"]:setText("MP%: -")
    end
end

if storage["trainerData"]["manaPercent"] then
    TyrTrainer["window"]["manaPercent"]:setValue(storage["trainerData"]["manaPercent"])
    TyrTrainer["window"]["manaPercentText"]:setText(storage["trainerData"]["manaPercent"] .. "%")
    TyrTrainer["window"]["potionPercent"]:setText("MP%: " .. storage["trainerData"]["manaPercent"])
end

TyrTrainer["window"]["spellEntry"]["onTextChange"] = function()
    TyrTrainer["saveConfig"]()
end

TyrTrainer["window"]["regenEntry"]["onTextChange"] = function()
    TyrTrainer["saveConfig"]()
end


if storage["trainerData"]["potionId"] then
    TyrTrainer["window"]["potionEntry"]:setItemId(storage["trainerData"]["potionId"])
end

TyrTrainer["panelUI"]["title"]:setOn(storage["trainerData"]["enabled"]);
TyrTrainer["panelUI"]["title"]["onClick"] = function(widget)
    storage["trainerData"]["enabled"] = not storage["trainerData"]["enabled"];
    widget:setOn(storage["trainerData"]["enabled"]);
    TyrTrainer["saveConfig"]();
end

-- Config agora abre com botao direito em qualquer parte da linha (painel, nao so o switch)
TyrTrainer["panelUI"]["onMouseRelease"] = function(self, mousePos, mouseButton)
    if mouseButton ~= 2 then return end
    if TyrTrainer["window"]:isVisible() then
        TyrTrainer["window"]:hide()
    else
        TyrTrainer["window"]:show()
    end
end

TyrTrainer["window"]["closeButton"]["onClick"] = function()
    TyrTrainer["window"]:hide()
    TyrTrainer["saveConfig"]()
end

local lastManaPotionTime = 0
local lastRegenTime = 0
local potionCooldown = 2
local regenCooldown = 1

macro(100, function()
    if (not TyrTrainer["panelUI"]["title"]:isOn()) then return end
    local manaPercent = manapercent()
    local regenSpell = storage["trainerData"]["spellRegen"]
    local regenEnabled = storage["trainerData"]["checkRegen"]
    local potionEnabled = storage["trainerData"]["checkPotion"]
    local potionId = storage["trainerData"]["potionId"]
    local spellTrain = storage["trainerData"]["spellTraining"]
    local minManaToUsePotion = storage["trainerData"]["manaPercent"] or 50
    local now = os["time"]()


    if manaPercent == 100 and spellTrain and spellTrain ~= "" then
        say(spellTrain)
        return
    end


    if potionEnabled and potionId and potionId ~= 0 and manaPercent <= minManaToUsePotion and now - lastManaPotionTime >= potionCooldown then
        useWith(potionId, player)
        lastManaPotionTime = os["time"]()
        return
    end

    if regenEnabled and regenSpell and regenSpell ~= "" and now - lastRegenTime >= regenCooldown then
        say(regenSpell)
        lastRegenTime = os["time"]()
        return
    end
end)

macro(100, function()
    if (not TyrTrainer["panelUI"]["title"]:isOn()) then return end
    turn(math["random"](0, 3))
end)



	
		
		
		
			
			
			
		
		
		
			
		
		
	



	
		
			
				
				
			
			
				
				
				
			
			
		
		
			
				
				
			
			
				
				
				
			
			
		
	

	
	
	

	
		
		
		
		
			
			
				
					
						
						
					
				
			
		
		
	

	
	
		
	

	
		
		
		
		
			
				
					
						
						
					
				
			
		
		
		 
			 
		
		
		
		
		
		
		
		
			
			
		
		
		
		
	




	

	
		
		
		
			
		
	
	
	

	
		
		
		
		
		
			
			
		
	


	
		
		
		
		
		
			
			
				
			
			
		
		
	
	
	

		
		

		
	
	
	
		
		
			
		
	
	
	
		
		
		
			
				
					
					
					
						
					
				
			
		
		
	
	

	
		
		
		
		
			
				
				
				
					
					
						
							
						
					
				
			
		
		
			
			
			
		
		
	

	
	
	
	
		
			
			
		
	

	
		
		
		
		
		
		
		
		
	


	
		
		
		
		

		
	


	
		
		
		
		
			
				
			
			
		
		
		
		
			
		
	

	
		
		
			
				
			
			
			
				
				
			
				
				
					
				
			
		
		
		
			
			
		
		
	


for _, scripts in pairs({storage["scriptsArea"]}) do
    if (type(scripts) == "string" and scripts:len() > 3) then
		schedule(5, function()
			local status, result = pcall(function()
				local call = {"setDefaultTab(\"Others\")", "local global_storage = storage; local storage = tyrBot.storage", scripts};
				call = table["concat"](call, "\n");
				load(call)();
			end)
			if (not status) then
				modules["_G"]["error"]("Erro na \225rea de scripts.\n" .. result);
			end
		end);
    end
end
