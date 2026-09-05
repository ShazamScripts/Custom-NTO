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
configData["push"] = {};

local FREE_VERSION = false; -- UNIVERSAL: nao aplica limitacoes da versao free.
local pushPlayer = {};
pushPlayer["flags"] = {precision=0,ignoreCreatures=false,ignoreNonPathable=false,ignoreNonWalkable=false};

local rec_ch_by_id = {"r", "e", "c", "u", "r", "s", "i", "v", "e", "G", "e", "t", "C", "h", "i", "l", "d", "B", "y", "I", "d"};
rec_ch_by_id = table["concat"](rec_ch_by_id);

pushPlayer["getAttackingCreature"] = tyrBot and tyrBot["getAttackingCreature"] or g_game["getAttackingCreature"];



pushPlayer["positions"] = {
	["W"] = {x = 0, y = -1},
	["A"] = {x = -1, y = 0},
	["S"] = {x = 0, y = 1},
	["D"] = {x = 1, y = 0},
	["Q"] = {x = -1, y = -1},
	["E"] = {x = 1, y = -1},
	["C"] = {x = 1, y = 1},
	["Z"] = {x = -1, y = 1}
};

pushPlayer["nextPosition"] = {
    {x = 0, y = -1},
    {x = 1, y = 0},
    {x = 0, y = 1},
    {x = -1, y = 0},
    {x = 1, y = -1},
    {x = 1, y = 1},
    {x = -1, y = 1},
    {x = -1, y = -1}
};

pushPlayer["getNextDirection"] = function(pos, dir)
	if (not pos) then return; end
	
	local offSet = pushPlayer["nextPosition"][dir + 1];

	pos["x"] = pos["x"] + offSet["x"];
	pos["y"] = pos["y"] + offSet["y"];

	return pos;
end

pushPlayer["getPushingPos"] = function()
	local pos;
	local path = pushPlayer["path"];
	local targetPos = pushPlayer["target"]:getPosition();
	if (targetPos ~= nil) then
		if (table["equal"](targetPos, pushPlayer["mousePos"])) then
			return;
		end
	end
	if (path ~= nil) then
		local path = findPath(targetPos, pushPlayer["mousePos"], 20, pushPlayer["flags"]);
		if (path ~= nil) then
			local next_direction = path[1];
			if (next_direction ~= nil) then
				pushPlayer["direction"] = next_direction;
				pos = pushPlayer["getNextDirection"](pushPlayer["target"]:getPosition(), next_direction);
				if (not pos) then return; end
				local tile = g_map["getTile"](pos);
				if (not tile) then return; end
				if (not tile:isWalkable(true) or not tile:isPathable()) then
					pushPlayer["path"] = nil;
					return pushPlayer["getPushingPos"]();
				end
			end
		end
	end
	return pos;
end

pushPlayer["withMouse"] = function()
	
	local mousePos = pushPlayer["mousePos"];
	if (not mousePos) then
		return;
	end
	
	local pushPos = pushPlayer["getPushingPos"]();
	if (not pushPos) then
		pushPlayer["thing"]:setMarked("");
		pushPlayer["mousePos"] = nil;
		return
	end
	
	if (modules["corelib"]["g_keyboard"]["isKeyPressed"]("Escape")) then
		pushPlayer["mousePos"] = nil;
		return;
	end
	
	local targetPos = pushPlayer["target"]:getPosition();
	local distance = getDistanceBetween(targetPos, player:getPosition());
	if (distance <= 1) then	
		pushPlayer["getAway"](targetPos);
		return true;
	end
	
	
	g_game["move"](pushPlayer["target"], pushPos);
	pushPlayer["waitingPosition"] = pushPos;
	pushPlayer["waitTill"] = now + 300;

	return true;
end



pushPlayer["getAway"] = function(targetPos)
	local playerPos = player:getPosition();
	if (playerPos["x"] < targetPos["x"]) then
		playerPos["x"] = playerPos["x"] - 2;
	elseif (playerPos["y"] < targetPos["y"]) then
		playerPos["y"] = playerPos["y"] - 2;
	elseif (playerPos["y"] > targetPos["y"]) then
		playerPos["y"] = playerPos["y"] + 2;
	elseif (playerPos["x"] > targetPos["x"]) then
		playerPos["x"] = playerPos["x"] + 2;
	end
	local tile = g_map["getTile"](playerPos);
	if (tile) then
		g_game["use"](tile:getTopThing());
		pushPlayer["waitTill"] = now + 100;
	end
end

storage["scrollBars"] = storage["scrollBars"] or {};
pushPlayer["macro"] = macro(storage["scrollBars"]["macroDelay"] or 1, "Push", function(self)
	if (FREE_VERSION) then
		return self:setOff();
	end
	
	local waitTill = pushPlayer["waitTill"];
	if (waitTill and waitTill > now) then
		return;
	end
	
	if (pushPlayer["withMouse"]()) then
		return;
	end
	
	if (not modules["corelib"]["g_keyboard"]["isShiftPressed"]()) then return; end
	local currentConsole = game_console or modules["game_console"] or modules["game_chat"];
	if (currentConsole and type(currentConsole["isChatEnabled"]) == "function" and currentConsole["isChatEnabled"]()) then
		return modules["game_textmessage"]["displayFailureMessage"]("Desative o chat para usar o Push.");
	end
	
	
	local target = (pushPlayer["getAttackingCreature"]() or pushPlayer["lastTarget"]);
	if (not target) then
		pushPlayer["mousePos"] = nil;
		return; 
	end
	pushPlayer["lastTarget"] = target;
	local targetPos = target:getPosition();
	if (not targetPos) then
		pushPlayer["mousePos"] = nil;
		return; 
	end
	
	
	local tile_under_cursor = getTileUnderCursor();
	if (tile_under_cursor ~= nil) then
		local tile = tile_under_cursor;
		local tilePos = tile:getPosition();
		if (tilePos ~= nil) then
			if (g_mouse["isPressed"](1)) then
				if (findPath(targetPos, tilePos, 20, pushPlayer["flags"])) then
					local ground = tile:getGround() or tile:getTopUseThing();
					if (ground ~= nil) then
						if (pushPlayer["thing"] ~= nil) then
							pushPlayer["thing"]:setMarked("");
						end
						ground:setMarked("#7600bc");
						pushPlayer["thing"] = ground;
						pushPlayer["mousePos"] = tilePos;
						pushPlayer["target"] = target;
						pushPlayer["path"] = nil;
					end
				end
			end
		end
	end
	
	
	local sumPos;
	for key, sum in pairs(pushPlayer["positions"]) do
		if (modules["corelib"]["g_keyboard"]["isKeyPressed"](key)) then
			sumPos = sum;
			break
		end
	end
	
	if (not sumPos) then return; end
	
	local pos = pos();
	local distance = getDistanceBetween(pos, targetPos);
	if (distance > 1) then
		local newPos = targetPos;
		newPos["x"] = newPos["x"] + sumPos["x"];
		newPos["y"] = newPos["y"] + sumPos["y"];
		local tile = g_map["getTile"](newPos);
		if (tile and tile:isWalkable() and tile:isPathable()) then
			g_game["move"](target, newPos);
			pushPlayer["waitTill"] = now + 500;
			pushPlayer["waitingPosition"] = newPos;
		end
	else
		pushPlayer["getAway"](targetPos);
	end
end)

onCreaturePositionChange(function(creature, newPos, oldPos)
	
	local pos = pushPlayer["waitingPosition"];
	if (pos ~= nil) then
		if (table["equal"](newPos, pos) or creature == pushPlayer["target"]) then
			if (pushPlayer["path"] and creature == pushPlayer["target"] and table["equal"](newPos, pos)) then
				local size = table["size"](pushPlayer["path"]);
				if (size > 1) then
					table["remove"](pushPlayer["path"], 1);
				else
					if (pushPlayer["thing"] ~= nil) then
						pushPlayer["thing"]:setMarked("");
						pushPlayer["thing"] = nil;	
					end
					pushPlayer["mousePos"] = nil;
					pushPlayer["path"] = nil;
					pushPlayer["target"] = nil;
				end
			end
			pushPlayer["waitingPosition"] = nil;
			pushPlayer["waitTill"] = nil;
		end
	end
 
end)

if (FREE_VERSION) then
	pushPlayer["macro"]["switch"]:setTooltip("Essa script est\225 desativada para a custom free.");
	pushPlayer["macro"]["switch"]["onClick"] = nil;
	return nil;
end

configData["push"]["macro"] = pushPlayer["macro"];
