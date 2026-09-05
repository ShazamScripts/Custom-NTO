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
configData["mystic"] = {};

local worldName = tyrBot["getWorldName"]():lower():trim();
local worldNameBr = {"DBOBR", "DBOGT", "DBO1", "DBO2"};

local botUI = setupUI("Panel\n  height: 17\n\n  BotSwitch\n    id: switch\n    anchors.top: parent.top\n    anchors.left: parent.left\n    anchors.right: parent.right\n    text-align: center\n    !text: tr(\"Mystic\")\n\n    image-source:\n\n    $on:\n      color: green\n\n    $!on:\n      color: white\n");

local mainUI = setupUI("MainWindow\n  size: 200 225\n  color: #A020F0\n  !text: tr(\"Mystic - Shazam Scripts\")\n  @onEscape: self:hide();\n  \n  Panel\n    id: mainPanel\n    image-source: /images/ui/panel_flat\n    anchors.top: parent.top\n    anchors.bottom: parent.bottom\n    anchors.left: parent.left\n    anchors.right: parent.right\n    image-border: 6\n\n    Label\n      !text: tr(\"Defense\")\n      id: defenseLabel\n      anchors.left: parent.left\n      anchors.top: parent.top\n      margin-top: 5\n\n    HorizontalScrollBar\n      id: defenseScroll\n      anchors.top: prev.bottom\n      anchors.right: parent.right\n      anchors.left: prev.left\n      margin-top: 5\n\n    HorizontalScrollBar\n      id: defenseCooldown\n      anchors.top: prev.bottom\n      anchors.right: parent.right\n      anchors.left: prev.left\n      margin-top: 5\n\n    TextEdit\n      id: defenseTextEdit\n      anchors.top: prev.bottom\n      anchors.left: prev.left\n      anchors.right: prev.right\n      margin-top: 5\n      height: 20\n\n    Label\n      !text: tr(\"Kai\")\n      id: kaiLabel\n      anchors.left: parent.left\n      anchors.top: defenseTextEdit.bottom\n      margin-top: 5\n\n    CheckBox\n      id: enabledKai\n      !tooltip: tr(\"Disable\")\n      anchors.top: kaiLabel.top\n      anchors.left: kaiLabel.right\n      margin-left: 2\n\n    HorizontalScrollBar\n      id: kaiScroll\n      anchors.top: kaiLabel.bottom\n      anchors.right: parent.right\n      anchors.left: kaiLabel.left\n      margin-top: 5\n      width: 100\n\n    HorizontalScrollBar\n      id: kaiCooldown\n      anchors.top: prev.bottom\n      anchors.right: parent.right\n      anchors.left: prev.left\n      margin-top: 5\n      width: 100\n\n    TextEdit\n      id: kaiTextEdit\n      anchors.top: prev.bottom\n      anchors.left: prev.left\n      anchors.right: parent.right\n      margin-top: 5\n      height: 20\n\n    Button\n      id: closeButton\n      !text: tr(\"Close\")\n      anchors.right: parent.right\n      anchors.left: parent.left\n      anchors.bottom: parent.bottom\n      margin-top: 2\n      height: 20\n", g_ui["getRootWidget"]());

if (type(storage["configMystic"]) ~= "table") then
	storage["configMystic"] = {
		macroActive = false;
		defenseCast = 50;
		defenseCooldown = 1000;
		defenseTime = 0;
		defenseSpell = "Mystic Defense";
		
		kaiCast = 80;
		kaiCooldown = 1000;
		kaiTime = 0;
		kaiSpell = "Mystic Kai";
		enabledKai = false;
	};
end

local config = storage["configMystic"];

local defenseScroll = mainUI["mainPanel"]["defenseScroll"];
local defenseCooldownScroll = mainUI["mainPanel"]["defenseCooldown"];
local defenseTextEdit = mainUI["mainPanel"]["defenseTextEdit"];

local kaiScroll = mainUI["mainPanel"]["kaiScroll"];
local kaiCooldownScroll = mainUI["mainPanel"]["kaiCooldown"];
local kaiTextEdit = mainUI["mainPanel"]["kaiTextEdit"];
local enabledKaiCheckBox = mainUI["mainPanel"]["enabledKai"];

botUI["switch"]["onClick"] = function()
	local status = not config["macroActive"];
	botUI["switch"]:setOn(status);
	config["macroActive"] = status;
end

-- Config agora abre com botao direito em qualquer parte da linha (painel, nao so o switch)
botUI["onMouseRelease"] = function(self, mousePos, mouseButton)
	if mouseButton == 2 then
		mainUI:show();
	end
end

mainUI["mainPanel"]["closeButton"]["onClick"] = function(widget)
	mainUI:hide();
end

local setupScroll = function(widget, id, step, minimum, maximum, ms)
	widget:setStep(step or 1);
	widget:setMinimum(minimum or 0);
	widget:setMaximum(maximum or 100);

	local eol = ms and "ms" or "%";
	widget["onValueChange"] = function(widget, value)
		widget:setValue(value);
		widget:setText(value .. eol);
		config[id] = value;
	end
	widget:onValueChange(config[id]);
end

local setupTextEdit = function(widget, id)
	widget["onTextChange"] = function(widget, text)
		widget:setText(text);
		config[id] = text;
	end
	widget:onTextChange(config[id]);
end

local setupCheckBox = function(widget, id, callback)
	widget["onCheckChange"] = function(widget, checked)
		widget:setChecked(checked);
		config[id] = checked;
		if (callback) then
			callback(widget, checked);
		end
	end
	widget:onCheckChange(config[id]);
end


botUI["switch"]:setOn(config["macroActive"]);
mainUI:hide();


setupScroll(defenseScroll, "defenseCast");
setupScroll(defenseCooldownScroll, "defenseCooldown", 500, 0, 30000, true);
setupScroll(kaiScroll, "kaiCast");
setupScroll(kaiCooldownScroll, "kaiCooldown", 500, 0, 30000, true);

setupTextEdit(defenseTextEdit, "defenseSpell");
setupTextEdit(kaiTextEdit, "kaiSpell");

setupCheckBox(enabledKaiCheckBox, "enabledKai", function(widget, checked)
	
	widget:setTooltip(checked and tr("Disable") or tr("Enable"));
	mainUI:setHeight(checked and 235 or 175);

	local widgets = {kaiScroll, kaiCooldownScroll, kaiTextEdit};
	local lib = widgets[1];
	local func = lib["show"];
	if (not checked) then
		func = lib["hide"];
	end
	for _, widget in ipairs(widgets) do
		func(widget);
	end
end)

local castSpell;
local mysticStatus;
local lockTime = 0;

local isDBOBR = table["find"](worldNameBr, worldName, true);
macro(20, function()
	if (not config["macroActive"]) then return; end
	
	if (isDBOBR) then
		castSpell = nil;
		mysticStatus = nil;
	end
	local healthPercent = player:getHealthPercent();
	local hasManaShield = hasManaShield();
	if (hasManaShield) then
		if (config["enabledKai"]) then
			if (healthPercent >= config["kaiCast"] and lockTime <= now) then
				if (config["kaiTime"] <= now or config["kaiTime"] - now > config["kaiCooldown"]) then
					castSpell = config["kaiSpell"];
					mysticStatus = false;
				end
			end
		end
	else
		if (healthPercent <= config["defenseCast"]) then
			if (config["defenseTime"] <= now or config["defenseTime"] - now > config["defenseCooldown"]) then
				castSpell = config["defenseSpell"];
				mysticStatus = true;
			end
		end
	end
	
	if (castSpell ~= nil) then
		if (hasManaShield == mysticStatus) then
			castSpell = nil;
			return;
		end
		
		say(castSpell, 1);
	end
end)

onTalk(function(name, level, mode, text)
	if (mode ~= 44) then return; end
	if (name ~= player:getName()) then return; end
	
	
	text = text:trim():lower();
	local texts = {config["defenseSpell"]:trim():lower(), config["kaiSpell"]:trim():lower()};
	
	if (config["enabledKai"]) then
		if (table["find"](texts, text)) then
			if (config["defenseCooldown"] == config["kaiCooldown"]) then
				config["kaiTime"] = now + config["kaiCooldown"];
				config["defenseTime"] = now + config["defenseCooldown"];
				return;
			end
		end
	end
	if (text == texts[1]) then
		config["defenseTime"] = now + config["defenseCooldown"];
	elseif (text == texts[2]) then
		config["kaiTime"] = now + config["kaiCooldown"];
	end
end)

if (isDBOBR) then
	local cancelKai = function(time)
		if (mysticStatus == false) then
			castSpell = nil;
			mysticStatus = nil;
		end
		local newTime = now + time;
		if (lockTime < newTime) then
			lockTime = newTime;
		end
	end
	onUse(function(pos)
		cancelKai(500);
	end);
	
	onUseWith(function(...)
		cancelKai(2000);
	end);
	
	onPlayerPositionChange(function(...)
		cancelKai(500);
	end);
end

configData["mystic"]["macro"] = botUI["switch"];