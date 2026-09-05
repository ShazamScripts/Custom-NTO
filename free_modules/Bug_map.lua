setDefaultTab("Main")
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
if (tyrBot == nil) then
	tyrBot = {};
end
if (tyrBot["configData"] == nil) then
	tyrBot["configData"] = {};
end
local configData = tyrBot["configData"];
configData["bugMap"] = {};

local FREE_VERSION = false; -- UNIVERSAL: nao aplica limitacoes da versao free.
local SUB_ZERO = table["find"](TYR_EXTRAS or {}, "SUB_ZERO", true);



local game_console = modules["game_console"];
local g_keyboard = modules["corelib"]["g_keyboard"];
local rootPanel = g_ui["getRootWidget"]():recursiveGetChildById("gameRootPanel");


storage["scrollBars"] = storage["scrollBars"] or {};

local holding_keys = {};
local pressed_data = {};


local isKeyHold = function(key)	
	if (g_keyboard["isKeyPressed"](key) and table["size"](holding_keys) > 0) then
		return true;
	end
	
	return false;
end


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

local isMobile = modules["_G"]["g_app"]["isMobile"]();

local bugMap = {};

if (not g_game["getWorldName"]():lower():find("db")) then
	bugMap["icon"] = addIcon("bugMapKunai", {text="Dash Sunshin", item={id=storage["kunaiId"] or 7382}}, function(icon, isOn)
		bugMap["status"] = isOn;
	end)
end



TILE_METHODS = modules["_G"]["Tile_mt"]["methods"];

TILE_METHODS["clearText"] = function(self, delay)
	delay = delay or 0;
	local clearTime = now + delay;
	self["clearTime"] = clearTime;
	schedule(delay, function()
		if (self["clearTime"] ~= clearTime) then return; end
		self:setText("");
	end)
end

local isStair = function(self, ignoreCreatures)
	if (not self) then return; end
    local tilePos = self:getPosition();
    if (not tilePos) then return; end
	
    local color = g_map["getMinimapColor"](tilePos);
	return color >= 210 and color <= 213 and not self:isPathable() and self:isWalkable(ignoreCreatures);	
end



bugMap["correctDirection"] = function()
	local dir = player:getDirection();
	return dir <= 3 and dir or dir < 6 and 1 or 3;
end

bugMap["nextPosition"] = {
    {x = 0, y = -1},
    {x = 1, y = 0},
    {x = 0, y = 1},
    {x = -1, y = 0},
    {x = 1, y = -1},
    {x = 1, y = 1},
    {x = -1, y = 1},
    {x = -1, y = -1}
}

bugMap["getNextDirection"] = function(pos, dir)
	local offSet = bugMap["nextPosition"][dir + 1];
	
	pos["x"] = pos["x"] + offSet["x"];
	pos["y"] = pos["y"] + offSet["y"];
	
	return pos;
end

bugMap["positions"] = {
	[0] = {x = 0, y = -5},
	[1] = {x = 5, y = 0},
	[2] = {x = 0, y = 5},
	[3] = {x = -5, y = 0}
}

bugMap["getIteration"] = function(dir)
	local base = bugMap["positions"][dir];
	
	local val = {};
	
	local x, y = base["x"], base["y"];
	val["x"] = {startIter = x < 0 and x or 0, endIter = x > 0 and x or 0};
	val["y"] =	{startIter = y < 0 and y or 0, endIter = y > 0 and y or 0};
	
	
	return val["x"], val["y"];
end
	
bugMap["getDistance"] = function(p1, p2)

    local distx = math["abs"](p1["x"] - p2["x"]);
    local disty = math["abs"](p1["y"] - p2["y"]);

    return math["sqrt"](distx * distx + disty * disty);
end

bugMap["verifyTiles"] = function(dir)
	if (FREE_VERSION) then return; end
	local x, y = bugMap["getIteration"](dir);

	local nearest = {};
	local playerPos = player:getPosition();
	local playerTile = player:getTile();
	for x = x["startIter"], x["endIter"] do
		for y = y["startIter"], y["endIter"] do
			local newPos = {x = playerPos["x"] + x, y = playerPos["y"] + y, z = playerPos["z"]};
			local tile = g_map["getTile"](newPos);
			if (tile and tile ~= playerTile) then
				
				
				
				
					
					
				
				local distance = bugMap["getDistance"](newPos, playerPos);
				if (not nearest["distance"] or distance < nearest["distance"]) then
					if (isStair(tile)) then
						nearest["pos"] = newPos;
						nearest["isWalkable"] = true;
						nearest["distance"] = distance;
					elseif 	(
								not tile:isWalkable() 
							) 
					then
						nearest["pos"] = nil;
						nearest["isWalkable"] = false;
						nearest["distance"] = distance;
					end
				end
			end
		end
	end
	
	return nearest["isWalkable"];
end


bugMap["handleUse"] = function(x, y, dir)
	
	if (bugMap["correctDirection"]() ~= dir) then
		g_game["turn"](dir);
	end
	
	if (x == 0 or y == 0) then
		if (bugMap["verifyTiles"](dir)) then return; end
	elseif (x ~= 0 and y ~= 0) then
		x = x > 0 and 4 or -4;
		y = y > 0 and 4 or -4;
	end

	local playerPos = player:getPosition();
	
	
	if (storage["checkBoxs"] and storage["checkBoxs"]["useKunai"] and storage["kunaiId"] and not isInPz() and bugMap["status"]) then
		local newX = x;
		local newY = y;
		local newDistance = storage["scrollBars"] and storage["scrollBars"]["distanceKunai"] or 6;
		if (x == 0 and y ~= 0) then
			newY = newDistance * (y < 0 and -1 or 1);
		elseif (y == 0 and x ~= 0) then
			newX = newDistance * (x < 0 and -1 or 1);
		end
		playerPos["x"] = playerPos["x"] + newX;
		playerPos["y"] = playerPos["y"] + newY;
		local tile = g_map["getTile"](playerPos);
		if (tile) then
			local topThing = tile:getTopUseThing();
			if (topThing and tile:isWalkable(true) and tile:isPathable() and tile:canShoot(newDistance)) then
				g_game["stop"]();
				useWith(storage["kunaiId"] or 7382, topThing);
			end
		end
	end
	
	playerPos = player:getPosition();
	
	local walkPos = table["copy"](playerPos);
	walkPos["x"] = walkPos["x"] + x;
	walkPos["y"] = walkPos["y"] + y;
	
	local stopAt = 7;
	local path = findPath(playerPos, walkPos, 15, {precision=3});
	if (path ~= nil) then
		for index, value in ipairs(path) do
			if (index > stopAt) then break; end
			
			if (value > West) then
				stopAt = stopAt - 2;
			end
			
			playerPos = bugMap["getNextDirection"](playerPos, value);
		end
	end
	
	if (path == nil) then
		playerPos = walkPos;
	end
	
	local tile = g_map["getTile"](playerPos);
	if (tile == nil) then return; end
	
	local topThing = (tile:getTopUseThing() or tile:getTopThing());
	if (topThing == nil) then return; end
	if (topThing:isMultiUse()) then
		return g_game["useWith"](topThing, player);
	end
	g_game["use"](topThing);
end


bugMap["basis"] = {
	Up = {
		dir = 0,
		sum = {x = 0, y = -6}
	},

	Left = {
		dir = 3,
		sum = {x = -6, y = 0}
	},

	Down = {
		dir = 2,
		sum = {x = 0, y = 6}
	},

	Right = {
		dir = 1,
		sum = {x = 6, y = 0}
	},
};




	
	
	
	
	
	
	
	


local getWalkKeys = function()
	local ret = {};
	for key, value in pairs(configData["bugMap"]["extra"]) do
		local walkData = table["recursivecopy"](bugMap["basis"][key]);
		
		walkData["key"] = value;
		table["insert"](ret, walkData);
	end
	
	return ret;
end



	
		
			
		
	
	
	
		
	




	
	



	





if (isMobile) then
	
	
	bugMap["pointer"] = g_ui["getRootWidget"]():recursiveGetChildById("keypad");

	local North = {
		highest = {x = -16, y = 29},
		lowest = {x = -75, y = -30},
		info = {
			dir = 0,
			sum = {x = 0, y = -5}
		};
	};
	local East = {
		highest = {x = 29, y = 75},
		lowest = {x = -30, y = 15},
		info = {
			dir = 1,
			sum = {x = 5, y = 0}
		};
	};
	local South = {
		highest = {x = 75, y = 29},
		lowest = {x = 16, y = -30},
		info = {
			dir = 2,
			sum = {x = 0, y = 5}
		};
	};
	local West = {
		highest = {x = 29, y = -15},
		lowest = {x = -30, y = -75},
		info = {
			dir = 3,
			sum = {x = -5, y = 0}
		};
	};
	local SouthWest = {
		highest = {x = 69, y = -28},
		lowest = {x = 28, y = -69},
		info = {
			sum = {x = -3, y = 3}
		};
	};
	local NorthWest = {
		highest = {x = -28, y = -29},
		lowest = {x = -69, y = -69},
		info = {
			sum = {x = -3, y = -3}
		};
	};
	local SouthEast = {
		highest = {x = 70, y = 70},
		lowest = {x = 30, y = 30},
		info = {
			sum = {x = 3, y = 3}
		};
	};
	local NorthEast = {
		highest = {x = -29, y = 68},
		lowest = {x = -69, y = 29},
		info = {
			sum = {x = 3, y = -3}
		};
	};
	DIRS = {North, East, South, West, NorthEast, SouthEast, SouthWest, NorthWest};
end

bugMap["getPressedKeys"] = function()
	local pressedKeys = {};
	
	
	
	if (isMobile) then
		local marginTop, marginLeft = bugMap["pointer"]:getMarginTop(), bugMap["pointer"]:getMarginLeft();
		for index, value in ipairs(DIRS) do
			if (
				(marginTop >= value["lowest"]["x"] and marginTop <= value["highest"]["x"]) and
				(marginLeft >= value["lowest"]["y"] and marginLeft <= value["highest"]["y"])
			) then
				table["insert"](pressedKeys, value["info"]);
			end
		end
	end
	
	if (not isMobile) then
		for _, value in ipairs(getWalkKeys()) do
			if (isKeyHold(value["key"])) then
				table["insert"](pressedKeys, value);
			end
		end
	end
	return pressedKeys;
end

bugMap["macro"] = macro(storage["scrollBars"]["macroDelay"] or 1, "Bug Map", function(self)
	if (
		 
		g_keyboard["isCtrlPressed"]()
	) then return; end
	
 	
	local pressedKeys = bugMap["getPressedKeys"]();
	
	if (#pressedKeys == 0) then return; end
	
	local sumPos = {x = 0, y = 0};
	
	for index, value in ipairs(pressedKeys) do
		local val = value["sum"];
		if ((sumPos["x"] ~= 0 and val["x"] ~= 0) or (sumPos["y"] ~= 0 and val["y"] ~= 0)) then
			goto continue;
		end
		sumPos["x"] = sumPos["x"] + val["x"];
		sumPos["y"] = sumPos["y"] + val["y"];
		if (ultimateOT) then
			break;
		end
		
		::continue::
	end
	
	bugMap["handleUse"](sumPos["x"], sumPos["y"], pressedKeys[1]["dir"]);	
end)

macro(20, function()

	pressed_data = table["collect"](pressed_data, function(key, time)
		if (g_keyboard["isKeyPressed"](key) and table["find"](configData["bugMap"]["extra"], key)) then
			return key, time;
		end
	end)
	
	
	holding_keys = table["collect"](pressed_data, function(key, time)
		if (now - time >= 100) then
			return key, time;
		end
	end)
	
end)["timeout"] = 1;


onKeyDown(function(key)
	if (key:starts("Shift")) then
		key = key:split("+")[2];
	end
	pressed_data[key] = now;
end)

onKeyUp(function(key)
	if (key:starts("Shift")) then
		key = key:split("+")[2];
	end
	pressed_data[key] = nil;
end)


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
	UI["Label"]("Ids exclu?dos");
	
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

configData["bugMap"]["extra"] = {
	Up = "W";
	Down = "S";
	Right = "D";
	Left = "A";
};

configData["bugMap"]["macro"] = bugMap["macro"];
