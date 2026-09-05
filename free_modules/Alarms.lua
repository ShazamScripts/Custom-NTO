setDefaultTab("Cave");

local panelName = "alarms";
local ui = setupUI("Panel\n  height: 25\n\n  BotSwitch\n    id: title\n    anchors.top: parent.top\n    anchors.left: parent.left\n    anchors.right: parent.right\n    text-align: center\n    !text: tr('Alarms')\n\n    image-source:\n\n    $on:\n      color: green\n\n    $!on:\n      color: white\n");

local alarmsWindow = setupUI("MainWindow\n  !text: tr('Alarms')\n  size: 270 200\n  @onEscape: self:hide()\n\n  BotSwitch\n    id: playerAttack\n    anchors.left: parent.left\n    anchors.right: parent.right\n    anchors.top: parent.top\n    text-align: center\n    text: Player Attack\n\n  BotSwitch\n    id: playerDetected\n    anchors.left: parent.left\n    anchors.right: parent.horizontalCenter\n    anchors.top: prev.bottom\n    margin-top: 4\n    text-align: center\n    text: Player Detected\n\n  CheckBox\n    id: playerDetectedLogout\n    anchors.top: playerDetected.top\n    anchors.left: parent.horizontalCenter\n    anchors.right: parent.right\n    margin-top: 3\n    margin-left: 4\n    text: Logout\n\n  BotSwitch\n    id: creatureDetected\n    anchors.left: parent.left\n    anchors.right: parent.right\n    anchors.top: playerDetected.bottom\n    margin-top: 4\n    text-align: center\n    text: Creature Detected\n\n  BotSwitch\n    id: healthBelow\n    anchors.left: parent.left\n    anchors.top: prev.bottom\n    anchors.right: parent.horizontalCenter\n    text-align: center\n    margin-top: 4\n    text: Health < 50%\n\n  HorizontalScrollBar\n    id: healthValue\n    anchors.left: parent.horizontalCenter\n    anchors.right: parent.right\n    anchors.top: healthBelow.top\n    margin-left: 3\n    margin-top: 2\n    minimum: 1\n    maximum: 100\n    step: 1\n\n  BotSwitch\n    id: manaBelow\n    anchors.left: parent.left\n    anchors.top: healthBelow.bottom\n    anchors.right: parent.horizontalCenter\n    text-align: center\n    margin-top: 4\n    text: Mana < 50%\n\n  HorizontalScrollBar\n    id: manaValue\n    anchors.left: parent.horizontalCenter\n    anchors.right: parent.right\n    anchors.top: manaBelow.top\n    margin-left: 3\n    margin-top: 2\n    minimum: 1\n    maximum: 100\n    step: 1\n\n  BotSwitch\n    id: privateMessage\n    anchors.left: parent.left\n    anchors.top: manaBelow.bottom\n    anchors.right: parent.right\n    text-align: center\n    margin-top: 4\n    text: Private Message\n\n  Button\n    id: closeButton\n    !text: tr('Close')\n    font: cipsoftFont\n    anchors.right: parent.right\n    anchors.bottom: parent.bottom\n    size: 45 21\n    margin-top: 15\n    margin-right: 5\n", g_ui["getRootWidget"]());

if (storage[panelName] == nil) then
	storage[panelName] = {
		enabled = false,
		playerAttack = false,
		playerDetected = false,
		playerDetectedLogout = false,
		creatureDetected = false,
		healthBelow = false,
		healthValue = 40,
		manaBelow = false,
		manaValue = 50,
		privateMessage = false
	}
end

local config = storage[panelName];

ui["title"]:setOn(config["enabled"]);
ui["title"]["onClick"] = function()
	config["enabled"] = not config["enabled"];
	ui["title"]:setOn(config["enabled"]);
end

alarmsWindow["closeButton"]["onClick"] = function(widget)
	alarmsWindow:hide();
end

-- Config agora abre com botao direito em qualquer parte da linha (painel, nao so o switch)
ui["onMouseRelease"] = function(self, mousePos, mouseButton)
	if mouseButton == 2 then
		alarmsWindow:show();
	end
end

alarmsWindow:hide();

local ids = {"playerAttack", "playerDetected", "creatureDetected", "healthBelow", "manaBelow", "privateMessage"};
for _, id in ipairs(ids) do
	local widget = alarmsWindow:getChildById(id);
	widget:setOn(config[id]);
	widget["onClick"] = function()
		config[id] = not config[id];
		widget:setOn(config[id]);
	end
end

alarmsWindow["playerDetectedLogout"]["onCheckChange"] = function(widget, checked)
	config["playerDetectedLogout"] = checked;
end

alarmsWindow["playerDetectedLogout"]:setChecked(config["playerDetectedLogout"]);
alarmsWindow["healthValue"]["onValueChange"] = function(scroll, value)
	config["healthValue"] = value;
	alarmsWindow["healthBelow"]:setText("Health < " .. config["healthValue"] .. "%");
end
alarmsWindow["healthValue"]:setValue(config["healthValue"]);

alarmsWindow["manaValue"]["onValueChange"] = function(scroll, value)
	config["manaValue"] = value;
	alarmsWindow["manaBelow"]:setText("Mana < " .. config["manaValue"] .. "%");
end
alarmsWindow["manaValue"]:setValue(config["manaValue"]);

if (playSound == nil) then
	getSoundChannel = function()
		local g_sounds = modules["_G"]["g_sounds"];
		if (not g_sounds) then
			return;
		end
		return g_sounds["getChannel"](4);
	end

	playSound = function(file)
		local botSoundChannel = getSoundChannel();
		if not botSoundChannel then
			return
		end
		botSoundChannel:setEnabled(true);
		botSoundChannel:stop(0);
		botSoundChannel:play(file, 0, 1);
		return botSoundChannel;
	end
end

local getAlarmFile = function(file)
	local dir = "/data/sounds";
	if (not g_resources["fileExists"](dir .. "/" .. file)) then
		local bundledDir = (configDir or "") .. "/sounds/alarms";
		if (g_resources["fileExists"](bundledDir .. "/" .. file)) then
			dir = bundledDir;
		else
			dir = "/sounds/alarms";
		end
	end
	return dir .. "/" .. file;
end

macro(100, function()
	if (not config["enabled"]) then
		return;
    end
	
	if (config["playerAttack"]) then
		if (table["size"](storage["especiaisConfig"]["attackers"]) > 0) then
			delay(1000);
			playSound(getAlarmFile("Player_Attack.ogg"));
			g_window["setTitle"](player:getName() .. " - Player attack");
			return;
		end
	end
	
	-- FIX (leve): antes chamava getSpectators() duas vezes por ciclo (uma pra
	-- playerDetected, outra pra creatureDetected). Agora busca uma vez so e
	-- reaproveita nos dois checks.
    local alarmSpecs = (config["playerDetected"] or config["creatureDetected"]) and getSpectators() or nil;

    if (config["playerDetected"]) then
		for _, spec in ipairs(alarmSpecs) do
			if (spec:isPlayer() and spec ~= player and spec:getEmblem() ~= 1) then
				delay(1500);
				playSound(getAlarmFile("Player_Detected.ogg"));
				g_window["setTitle"](player:getName() .. " - Player detected");
				
				if (config["playerDetectedLogout"]) then
					modules["game_interface"]["tryLogout"](false)
				end
				
				return;
			end
		end
	end

    if (config["creatureDetected"]) then
		for _, spec in ipairs(alarmSpecs) do
			if (not spec:isPlayer()) then
				delay(1500);
				playSound(getAlarmFile("Creature_Detected.ogg"));
				g_window["setTitle"](player:getName() .. " - Creature detected");
				return;
			end
		end
    end

    if (config["healthBelow"]) then
		if (player:getHealthPercent() <= config["healthValue"]) then
			delay(1500);
			playSound(getAlarmFile("Low_Health.ogg"));
			g_window["setTitle"](player:getName() .. " - Low health");
			return;
		end
    end

    if (config["manaBelow"]) then
		if (manapercent() <= config["manaValue"]) then
			delay(1500);
			playSound(getAlarmFile("Low_Mana.ogg"));
			g_window["setTitle"](player:getName() .. " - Low mana");
		end
	end
end)

onTalk(function(name, level, mode, text, channelId, pos)
	if (mode == 4 and config["enabled"] and config["privateMessage"]) then
		playSound(getAlarmFile("Private_Message.ogg"));
		g_window["setTitle"](player:getName() .. " - Private Message");
	end
end)
