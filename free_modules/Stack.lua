local stackOnMonsters = {};


storage["stackConfig"] = storage["stackConfig"] or {
	maxDistance = 5,
	stackSpell = "Corrupt Chidori"
};


stackOnMonsters["getDistance"] = function(p1, p2)

    local distx = math["abs"](p1["x"] - p2["x"]);
    local disty = math["abs"](p1["y"] - p2["y"]);

    return math["sqrt"](distx * distx + disty * disty);
end


stackOnMonsters["directions"] = {
	["W"] = function(fromPos, toPos)
		return fromPos["y"] > toPos["y"];
	end,
	["D"] = function(fromPos, toPos)
		return fromPos["x"] < toPos["x"];
	end,
	["S"] = function(fromPos, toPos)
		return fromPos["y"] < toPos["y"];
	end,
	["A"] = function(fromPos, toPos)
		return fromPos["x"] > toPos["x"];
	end,
	["Q"] = function(fromPos, toPos)
		return fromPos["x"] > toPos["x"] and fromPos["y"] > toPos["y"];
	end,
	["E"] = function(fromPos, toPos)
		return fromPos["x"] < toPos["x"] and fromPos["y"] > toPos["y"];
	end,
	["C"] = function(fromPos, toPos)
		return fromPos["x"] < toPos["x"] and fromPos["y"] < toPos["y"];
	end,
	["Z"] = function(fromPos, toPos)
		return fromPos["x"] > toPos["x"] and fromPos["y"] < toPos["y"];
	end
};

stackOnMonsters["canStack"] = function(fromPos, toPos, dir)

	local func = stackOnMonsters["directions"][dir];

	return func(fromPos, toPos);
end

stackOnMonsters["getSpectators"] = function(multifloor)
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

stackOnMonsters["doStack"] = function(dir)


	local stackMonster;
	local specs = stackOnMonsters["getSpectators"](true);
	local pos = pos();
	for _, spec in ipairs(specs) do
		if (spec:isMonster()) then
			local specPos = spec:getPosition();
			if (specPos ~= nil and pos ~= nil) then
				local distance = getDistanceBetween(specPos, pos);
				local preciseDistance = stackOnMonsters["getDistance"](specPos, pos);

				if (distance <= storage["stackConfig"]["maxDistance"] and stackOnMonsters["canStack"](pos, specPos, dir) and spec:canShoot(storage["stackConfig"]["maxDistance"])) then
					if (
						not stackMonster or
						stackMonster["distance"] < distance or
						(stackMonster["distance"] == distance and stackMonster["preciseDistance"] < preciseDistance)
					) then
						stackMonster = {
							creature = spec,
							distance = distance,
							preciseDistance = preciseDistance
						}
					end
				end
			end
		end
	end

	if (stackMonster) then
		g_game["attack"]();
		g_game["attack"](stackMonster["creature"]);
		schedule(200, function()
			say(storage["stackConfig"]["stackSpell"]);
			schedule(300, g_game["attack"]);
		end)
	end
	return delay(500);
end

stackOnMonsters["baseUI"] = setupUI("Panel\n  height: 17\n  BotSwitch\n    id: macro\n    anchors.top: parent.top\n    anchors.left: parent.left\n    anchors.right: parent.right\n    text-align: center\n    !text: tr(\"Stack\")\n\n    image-source:\n\n    $on:\n      color: green\n\n    $!on:\n      color: white\n");

stackOnMonsters["baseUI"]["macro"]["onClick"] = function(self)
	storage["stackConfig"]["macroActive"] = not storage["stackConfig"]["macroActive"];
	local status = storage["stackConfig"]["macroActive"];
	self:setOn(status);
	stackOnMonsters["executeMacro"]["setOn"](status);
end

storage["stackConfig"]["macroActive"] = not storage["stackConfig"]["macroActive"];

gameRootPanel = "gameRootPanel = g_ui.getRootWidget():%s('gameRootPanel')";

local rec_ch_by_id = {"r", "e", "c", "u", "r", "s", "i", "v", "e", "G", "e", "t", "C", "h", "i", "l", "d", "B", "y", "I", "d"};
rec_ch_by_id = table["concat"](rec_ch_by_id);
gameRootPanel = gameRootPanel:format(rec_ch_by_id);
loadstring(gameRootPanel)();

local function toggleStackConfig()
	local self = stackOnMonsters["UI"];
	if (self:isHidden()) then
		self:show();
		self:focus();
	else
		self:hide();
		gameRootPanel:focus();
	end
end

-- Config agora abre com botao direito em qualquer parte da linha (painel, nao so o switch)
stackOnMonsters["baseUI"]["onMouseRelease"] = function(self, mousePos, mouseButton)
	if mouseButton == 2 then
		toggleStackConfig();
	end
end




stackOnMonsters["UI"] = setupUI("MainWindow\n  size: 250 250\n\n  Panel\n    id: mainPanel\n    image-source: /images/ui/panel_flat\n    anchors.top: parent.top\n    anchors.bottom: parent.bottom\n    anchors.right: parent.right\n    anchors.left: parent.left\n\n    Label\n      id: stackSpellLabel\n      !text: tr(\"Stack Spell:\")\n      anchors.top: parent.top\n      anchors.left: parent.left\n      margin-top: 25\n      margin-left: 65\n\n    TextEdit\n      id: stackSpell\n      !text: tr(\"Stack Spell\")\n      anchors.left: stackSpellLabel.left\n      anchors.top: prev.top\n      margin-top: 25\n      margin-left: -5\n\n    Label\n      id: distanceLabel\n      !text: tr(\"Max Distance:\")\n      anchors.top: stackSpellLabel.top\n      anchors.left: stackSpellLabel.left\n      margin-top: 60\n\n    HorizontalScrollBar\n      id: distanceScroll\n      anchors.left: prev.left\n      anchors.right: prev.right\n      anchors.top: prev.top\n      margin-top: 25\n      step: 1\n      maximum: 10\n      minimum: 1\n\n    Button\n      id: closeButton\n      !text: tr(\"Close\")\n      anchors.left: parent.left\n      anchors.bottom: parent.bottom\n      margin-bottom: 5\n      width: 50\n", g_ui["getRootWidget"]());


stackOnMonsters["UI"]:setText("Stack by Shazam Scripts.")
stackOnMonsters["UI"]:setColor("#7600bc");
stackOnMonsters["UI"]["setText"] = function() end
stackOnMonsters["UI"]["setColor"] = function() end

stackOnMonsters["UI"]["mainPanel"]["closeButton"]["onClick"] = toggleStackConfig;
stackOnMonsters["UI"]["onEscape"] = toggleStackConfig;
stackOnMonsters["UI"]:hide();

stackOnMonsters["UI"]["mainPanel"]["distanceScroll"]["onValueChange"] = function(widget, value)
	widget:setText(value);
	storage["stackConfig"]["maxDistance"] = tonumber(value);
end

stackOnMonsters["UI"]["mainPanel"]["distanceScroll"]:setValue(storage["stackConfig"]["maxDistance"]);

stackOnMonsters["UI"]["mainPanel"]["stackSpell"]["onTextChange"] = function(widget, text)
	storage["stackConfig"]["stackSpell"] = text:trim();
end

stackOnMonsters["UI"]["mainPanel"]["stackSpell"]:setText(storage["stackConfig"]["stackSpell"]);

stackOnMonsters["executeMacro"] = macro(20, function()

	if (not modules["corelib"]["g_keyboard"]["isAltPressed"]()) then return; end
	
	for dir, _ in pairs(stackOnMonsters["directions"]) do
	
		if (modules["corelib"]["g_keyboard"]["isKeyPressed"](dir)) then
			return stackOnMonsters["doStack"](dir);
		end
		
	end
end)

stackOnMonsters["baseUI"]["macro"]:onClick();
return stackOnMonsters["baseUI"]["macro"];
