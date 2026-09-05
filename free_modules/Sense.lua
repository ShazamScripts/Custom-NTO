if (tyrBot["configData"] == nil) then
	tyrBot["configData"] = {};
end
local configData = tyrBot["configData"];
configData["sense"] = {};

local senseMaintain = {
	senseRegex = "([a-z A-Z]*)is ([a-z -A-Z]*)to the ([a-z -A-Z]*)."
};


local http = {"H", "T", "T", "P"};
http = modules["corelib"][table["concat"](http)];

gameMapPanel = "gameMapPanel = g_ui.getRootWidget():%s('gameMapPanel')";

local rec_ch_by_id = {"r", "e", "c", "u", "r", "s", "i", "v", "e", "G", "e", "t", "C", "h", "i", "l", "d", "B", "y", "I", "d"};
rec_ch_by_id = table["concat"](rec_ch_by_id);
gameMapPanel = gameMapPanel:format(rec_ch_by_id);
loadstring(gameMapPanel)();

senseMaintain["widget"] = "Panel\n  image-source: /images/ui/panel_flat\n  size: 60 60\n  anchors.centerIn: parent\n";

local base64Encode = modules["corelib"]["base64"]["encode"];

senseMaintain["setupPointer"] = function()
	if (senseMaintain["pointer"]) then
		senseMaintain["pointer"]:destroy();
	end
	senseMaintain["pointer"] = setupUI(senseMaintain["widget"], gameMapPanel);
	
	-- Puxa a imagem da seta direto da pasta Img da custom (não baixa mais da internet)
	local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text;
	local imageFile = "/bot/" .. configName .. "/Img/seta_sense.png";
	senseMaintain["pointer"]:setImageSource(imageFile);

	storage["senseNames"] = storage["senseNames"] or {};
	senseMaintain["initialPosition"] = senseMaintain["pointer"]:getPosition();

	senseMaintain["pointer"]:breakAnchors();
	senseMaintain["pointer"]:hide();

	local initialPos = senseMaintain["initialPosition"];

	senseMaintain["positions"] = {
		
		north = {x = initialPos["x"], y = initialPos["y"] - 100, rotation = 0},
		
		south = {x = initialPos["x"], y = initialPos["y"] + 100, rotation = 180},
		
		west = {x = initialPos["x"] - 100, y = initialPos["y"], rotation = 270},

		east = {x = initialPos["x"] + 100, y = initialPos["y"], rotation = 90},

		["north-west"] = {x = initialPos["x"] - 100, y = initialPos["y"] - 100, rotation = 315},
		
		["north-east"] = {x = initialPos["x"] + 100, y = initialPos["y"] - 100, rotation = 45},
		
		["south-west"] = {x = initialPos["x"] - 100, y = initialPos["y"] + 100, rotation = 225},
		
		["south-east"] = {x = initialPos["x"] + 100, y = initialPos["y"] + 100, rotation = 135}
	}
end

senseMaintain["setupPointer"]();

if (gameMapPanel["sense_connection"]) then
	local disconnect = modules["_G"]["disconnect"];
	local func = gameMapPanel["sense_connection"];
	disconnect(gameMapPanel, {onGeometryChange = func});
end
local connect = modules["_G"]["connect"];
gameMapPanel["sense_connection"] = senseMaintain["setupPointer"];
connect(gameMapPanel, {onGeometryChange = gameMapPanel["sense_connection"]});


local isKeyPressed = modules["corelib"]["g_keyboard"]["isKeyPressed"];

function Creature:isNearby()
	local creaturePos = self:getPosition();
	local playerPos = player:getPosition();
	return creaturePos and creaturePos["z"] == playerPos["z"] and getDistanceBetween(playerPos, creaturePos) < 5;
end

local rec_ch_by_id = {"r", "e", "c", "u", "r", "s", "i", "v", "e", "G", "e", "t", "C", "h", "i", "l", "d", "B", "y", "I", "d"};
rec_ch_by_id = table["concat"](rec_ch_by_id);

senseMaintain["getAttackingCreature"] = tyrBot["getAttackingCreature"];

local isMobile = modules["_G"]["g_app"]["isMobile"]();

storage["scrollBars"] = storage["scrollBars"] or {};
senseMaintain["macro"] = macro(storage["scrollBars"]["macroDelay"] or 1, "Sense", function()
	local target = senseMaintain["getAttackingCreature"]();
	
	if (target and target:isPlayer()) then
		local targetName = target:getName():trim();
		if (not table["find"](storage["senseNames"], targetName, true)) then
			storage["senseNames"]["targetName"] = targetName;
		end
	end
	
	
	
	for _, value in ipairs({
		{
			key = configData["sense"]["extra"]["senseTarget"],
			name = storage["senseNames"]["targetName"];
		},
		
		{
			key = configData["sense"]["extra"]["senseLast"],
			name = storage["senseNames"]["lastName"];
		}	
	}) do
		if (value["name"]) then
			if (isMobile or isKeyPressed(value["key"])) then
				local creature = getPlayerByName(value["name"]);
				if (not creature or not creature:isNearby()) then
					return say(storage["_sense_spell"] .. " \"" .. value["name"]);
				end
			end
		end
	end
end)

senseMaintain["getPositionByDir"] = function(dir)
	dir = dir:trim();
	
	return senseMaintain["positions"][dir];
end

onTextMessage(function(mode, text)
	if (mode ~= 20) then return; end
	local data = regexMatch(text, senseMaintain["senseRegex"])[1];

	if (not data or #data < 4) then return; end
	
	local position = senseMaintain["getPositionByDir"](data[4]);
	if (position == nil) then
		return;
	end
	senseMaintain["pointer"]["timeLapse"] = now + 5000;
	local senseName = (data[2] or ""):trim();
	if (not table["find"](storage["senseNames"], senseName, true)) then
		storage["senseNames"]["lastName"] = senseName;
	end
	senseMaintain["pointer"]:setPosition({x = position["x"], y = position["y"]});
	senseMaintain["pointer"]:setRotation(position["rotation"]);
	senseMaintain["lastName"] = senseName;
end)


macro(50, function()
	senseMaintain["pointer"]:hide();
	local timer = senseMaintain["pointer"]["timeLapse"];
	if (not timer or timer < now) then return; end
	
	local creature = getPlayerByName(senseMaintain["lastName"]);
	
	if (creature and creature:isNearby()) then return; end
	
	senseMaintain["pointer"]:show();
end)

if (not runBot) then
	setDefaultTab("UTI") -- muda pra aba "UTI" só pra criar esses widgets
	UI["Label"]("Sense Spell");
	UI["TextEdit"](storage["_sense_spell"] or "Sense", function(widget, text)
		storage["_sense_spell"] = text;
	end)

	-- Nome da imagem do header (pasta Img/, sem o ".png"). Cada pessoa que
	-- baixar a custom pode trocar aqui sem precisar mexer em nenhum arquivo.
	UI["Label"]("Imagem do Header (sem .png)");
	UI["TextEdit"](storage["_custom_img_name"] or "Minato", function(widget, text)
		text = text:trim();
		if (text == "") then
			widget:setText(storage["_custom_img_name"] or "Minato");
			return;
		end
		storage["_custom_img_name"] = text;

		-- Aplica na hora, sem precisar reiniciar o client.
		local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text;
		local newImage = "/bot/" .. configName .. "/Img/" .. text .. ".png";
		local rootWidget = g_ui.getRootWidget();
		local botWindow = rootWidget and rootWidget:recursiveGetChildById("botWindow");
		local contents = botWindow and botWindow:recursiveGetChildById("contentsPanel");
		if (contents) then
			contents:setImageSource(newImage);
		end
	end)
	setDefaultTab("Main") -- volta pro contexto padrão (Main)
end


configData["sense"]["extra"] = {
	senseTarget = "T";
	senseLast = "V";
};
configData["sense"]["macro"] = senseMaintain["macro"];