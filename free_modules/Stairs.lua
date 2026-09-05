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
configData["stairs"] = {};


local range = {};
for x = -15, 15 do
	for y = -15, 15 do
		table["insert"](range, {x=x, y=y});
	end
end

local delayTime;
local actualPos;
local actualTile;
local displayTime;
local scanIndex = 1;
local ignoreCreatures = false;
local addEvent = modules["_G"]["addEvent"];
local isMobile = modules["_G"]["g_app"]["isMobile"]();
local scheduleEvent = modules["_G"]["scheduleEvent"];
local isKeyPressed = modules["corelib"]["g_keyboard"]["isKeyPressed"];
local displayGameMessage = modules["game_textmessage"]["displayGameMessage"];

local flags = {
	ignoreNonWalkable=false, 
	ignoreNonPathable=true, 
	ignoreStairs=true, 
	
};


local FREE_VERSION = false; -- UNIVERSAL: nao aplica limitacoes da versao free.

local isStair = function(tile)
    if (tile == nil) then
		return;
	end
	local tilePos = tile:getPosition();
	if (tilePos == nil) then
		return false;
	end
	
	local foundStair;
	local foundAnyItem;
	local items = tile:getItems();
	for _, item in ipairs(items) do
		local itemId = item:getId();
		if (excludeIds[itemId]) then
			return false;
		end
		
		if (stairsIds[itemId]) then
			foundStair = true;
		end
		foundAnyItem = true;
	end
	
	if (foundStair) then
		return true;
	end
	
	if (not foundAnyItem) then
		return false;
	end

    local minimap_color = g_map["getMinimapColor"](tilePos);
	if (minimap_color >= 210 and minimap_color <= 213) then
		if (tile:isWalkable(true)) then
			local isPathable = tile:isPathable();
			if (not isPathable) then
				return true;
			end
			
			for x = -1, 1 do
				for y = -1, 1 do
					if (x ~= 0 or y ~= 0) then
						local currentPos = {x=tilePos["x"]+x,y=tilePos["y"]+y,z=tilePos["z"]};
						local currentColor = g_map["getMinimapColor"](currentPos);
						if (currentColor >= 210 and currentColor <= 213) then
							return false;
						end
					end
				end
			end
			return true;
		end
	end
	
	return false;
end

local everyPath;
local newFindPath = function(startPos, destPos, maxDist, params)
    if (not destPos or startPos["z"] ~= destPos["z"]) then return; end
    if (type(maxDist) ~= "number") then
        maxDist = 100;
    end
    if (type(params) ~= "table") then
        params = {};
    end
	
    local destPosStr = destPos["x"] .. "," .. destPos["y"] .. "," .. destPos["z"];
	if (everyPath == nil) then
		everyPath = findAllPaths(startPos, maxDist, params);
	end
    local paths = everyPath;
    if (paths[destPosStr] == nil) then
        local bestCandidate = nil;
        local bestCandidatePos = nil;
        for x = -1, 1 do
			for y = -1, 1 do
				local dest = (destPos["x"] + x) .. "," .. (destPos["y"] + y) .. "," .. destPos["z"];
				local node = paths[dest];
				if (node and (not bestCandidate or bestCandidate[2] > node[2])) then
					bestCandidate = node;
					bestCandidatePos = dest;
				end
			end
        end
        if bestCandidate then
			
				
				
			
			
			
			return bestCandidate[2] + 1;
        end
        return nil;
    end

    
	local candidate = paths[destPosStr];
	return candidate[2];
end

local getDistance = function(p1, p2)

    local distx = math["abs"](p1["x"] - p2["x"]);
    local disty = math["abs"](p1["y"] - p2["y"]);

    return math["sqrt"](distx * distx + disty * disty);
end

local getDistanceFromPlayer = function(playerPos, position)

	local tileDistance = newFindPath(playerPos, position, FREE_VERSION and 6 or 20, flags);
	return tileDistance or -1;
end

local doHighlightTile = function(tile, color)
	if (tile == nil) then
		return;
	end

	
	local item;
	local items = tile:getItems();
	for _, _item in ipairs(items) do
		item = _item;
	end

	
	if (item ~= nil and item["setMarked"]) then
		item:setMarked(color);
		return;
	end
	
	local text = "AQUI";
	if (color == nil) then
		text = "";
	end
	tile:setText(text, color);
end

table["sort"](range, function(a, b)
	local _playerPos = {x=0,y=0};
	local axisA = getDistance(_playerPos, a);
	local axisB = getDistance(_playerPos, b);
	
	return axisA < axisB;
end)

local verifyTiles = function()
	local ret = {};
	local checkedTiles = 0;
	if (range[scanIndex] == nil) then
		scanIndex = 1;
		everyPath = nil;
		
		if (actualTile == nil or ignoreCreatures) then
			ignoreCreatures = not ignoreCreatures;
		end
	end
	
	flags["ignoreCreatures"] = ignoreCreatures;
	
	local playerPos = player:getPosition();
	
	if (actualTile ~= nil and isStair(actualTile)) then
		local tilePos = actualTile:getPosition();
		local currentDistance = getDistanceFromPlayer(playerPos, tilePos);
		if (currentDistance ~= -1 or not flags["ignoreCreatures"]) then
			ret["tile"] = actualTile;
			ret["tilePos"] = tilePos;
			ret["distance"] = currentDistance;
		end
	end
	
	while (range[scanIndex] ~= nil and checkedTiles < 30) do
		local offs = range[scanIndex];
		local tilePos = { x = playerPos["x"] + offs["x"], y = playerPos["y"] + offs["y"], z = playerPos["z"] };
		local distance = getDistanceFromPlayer(playerPos, tilePos);

		scanIndex = scanIndex + 1;
		checkedTiles = checkedTiles + 1;
		
		if (distance ~= -1) then
			if (ret["distance"] == nil or ret["distance"] == -1 or distance < ret["distance"]) then
				local tile = g_map["getTile"](tilePos);
				if (tile ~= nil and isStair(tile)) then
					ret["tile"] = tile;
					ret["tilePos"] = tilePos;
					ret["distance"] = distance;
				end
			end
		end
	end
	
	if (actualTile ~= ret["tile"]) then
		doHighlightTile(actualTile);
	end
	
	if (ret["tile"] == nil) then
		actualPos = nil;
		actualTile = nil;
	end
	
	if (ret["tile"] ~= nil) then
		actualTile = ret["tile"];
		actualPos = ret["tilePos"];
	end
end

local function getNearestTile(pos)
    local nearestTile = nil;
    local nearestDist = math["huge"];
    local playerPos = player:getPosition();

    for x = -1, 1 do
        for y = -1, 1 do
            local tmpPos = { x = pos["x"] + x, y = pos["y"] + y, z = pos["z"] };
            local tile = g_map["getTile"](tmpPos);
            if (tile and tile:isWalkable(true) and tile:isPathable()) then
                local d = getDistance(tmpPos, playerPos);
                if (d < nearestDist) then
                    nearestDist = d;
                    nearestTile = tile;
                end
            end
        end
    end

    return nearestTile;
end

local function doUseWalk(tilePos)
    local currentPos = player:getPosition();
    local path = findPath(tilePos, currentPos, FREE_VERSION and 6 or 20);
    if (not path) then return; end

    local size = table["size"](path);
    local stopIndex = math["max"](1, size - 5); 

    for index = size, stopIndex, -1 do
        local direction = path[index];
        if (direction == 0) then
            currentPos["y"] = currentPos["y"] + 1; 
        elseif (direction == 1) then
            currentPos["x"] = currentPos["x"] - 1; 
        elseif (direction == 2) then
            currentPos["y"] = currentPos["y"] - 1; 
        elseif (direction == 3) then
            currentPos["x"] = currentPos["x"] + 1; 
        elseif (direction == 4) then
            currentPos["x"] = currentPos["x"] - 1; 
            currentPos["y"] = currentPos["y"] + 1; 
        elseif (direction == 5) then
            currentPos["x"] = currentPos["x"] - 1; 
            currentPos["y"] = currentPos["y"] - 1; 
        elseif (direction == 6) then
            currentPos["x"] = currentPos["x"] + 1; 
            currentPos["y"] = currentPos["y"] - 1; 
        elseif (direction == 7) then
            currentPos["x"] = currentPos["x"] + 1; 
            currentPos["y"] = currentPos["y"] - 1; 
        end
    end

    local tile = g_map["getTile"](currentPos);
    local topThing = tile and tile:getTopUseThing();
    if (topThing) then
        if (topThing:isMultiUse()) then
            useWith(topThing, player);
        else
            use(topThing);
        end
        return true;
    end
end

onPlayerPositionChange(function(newPos, oldPos)
	if (actualTile ~= nil and delayTime ~= nil) then
		delayTime = nil;
	end
	
	scanIndex = 1;
	everyPath = nil;
	ignoreCreatures = nil;
end)


storage["checkBoxs"] = storage["checkBoxs"] or {};
storage["scrollBars"] = storage["scrollBars"] or {};
local lastWalkPosition = nil;
local function samePos(a, b)
    return a and b and a["x"] == b["x"] and a["y"] == b["y"] and a["z"] == b["z"];
end

local mainMacro = macro(20, "Escadas", function()
    if (isKeyPressed(configData and configData["stairs"]["actionKey"] or "Space")) then
        if (actualTile ~= nil) then
            displayTime = nil;
            local playerPos = player:getPosition();
            local tilePos = actualTile:getPosition();
            if (tilePos ~= nil and tilePos["z"] == playerPos["z"]) then
				player:lockWalk(50);
                doHighlightTile(actualTile, "green");
                local neighborTile = getNearestTile(tilePos);
                local useThing = neighborTile and neighborTile:getTopThing();
                local distance = getDistanceBetween(tilePos, playerPos);

                
                if (not isMobile and useThing and distance > 2 and storage["checkBoxs"]["useKunai"] and storage["kunaiId"] and neighborTile:canShoot(6)) then
                    g_game["stop"]();
                    potExhaust = now + 100;
                    return useWith(storage["kunaiId"], useThing);
                end

                
                if (distance == 1 and actualTile:isWalkable() and (delayTime or 0) < now) then
					delayTime = now + 200
					if (not samePos(lastWalkPosition, tilePos) and autoWalk(tilePos, 1)) then
						lastWalkPosition = { x = tilePos["x"], y = tilePos["y"], z = tilePos["z"] };
					else
						lastWalkPosition = nil;
					end
                end

                
                if (distance <= 1) then
                    local isWalkable = actualTile:isWalkable(true);
                    if (isWalkable and actualTile:isPathable()) then
                        potExhaust = now + 100;
                    end

                    if (not isWalkable) then
                        if ((delayTime or 0) >= now) then
                            return
                        end
                        delayTime = now + 300;
                        potExhaust = now + 300;
                    end

                    return g_game["use"](actualTile:getTopUseThing());
                end

                if (doUseWalk(tilePos)) then return; end
            end
        end

        if (displayTime == nil) then
            displayTime = now + 300;
        elseif (displayTime < now) then
            displayTime = now + 3000;
            displayGameMessage("Sem escadas/portais/portas por perto.");
        end
    end

    if (actualTile ~= nil) then
        doHighlightTile(actualTile, "red");
    end
end)

macro(20, function()
	if (mainMacro["isOff"]()) then return; end
	
	if (putOnQueue == nil) then
		return addEvent(verifyTiles);
	end
	
	putOnQueue(verifyTiles);
end)["timeout"] = 1;

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
	8367
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

configData["stairs"]["actionKey"] = isMobile and "F1" or "Space";
configData["stairs"]["macro"] = mainMacro;
