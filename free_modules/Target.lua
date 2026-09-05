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
if (tyrBot["configData"] == nil) then
	tyrBot["configData"] = {};
end
local configData = tyrBot["configData"];
configData["keepTarget"] = {};

local FREE_VERSION = false; -- UNIVERSAL: nao aplica limitacoes da versao free.
keepTarget = {};

keepTarget["getSpectators"] = tyrBot["getSpectators"];

keepTarget["doAttack"] = tyrBot["doAttack"];

keepTarget["getAttackingCreature"] = tyrBot["getAttackingCreature"];

keepTarget["getCreatureById"] = getCreatureById;


function keepTarget:resetVariables()
	self["delayTime"] = nil;
	self["creatureId"] = nil;
	g_game["cancelAttack"]();
end

function keepTarget:setAttackingCreature(creature)
	self["creatureId"] = creature:getId();
end

function keepTarget:verifyAttackingCreature()
	local creatureId = self["creatureId"];
	local creature = getCreatureById(creatureId);
	return creature;
end


storage["scrollBars"] = storage["scrollBars"] or {};
local isKeyPressed = modules["corelib"]["g_keyboard"]["isKeyPressed"];
keepTarget["macro"] = macro(storage["scrollBars"]["macroDelay"] or 1, "Attack Target", function(self)
	if (FREE_VERSION) then
		return self:setOff();
	end
	if (keepTarget["isStacking"]) then
		return delay(300);
	end
	if (isKeyPressed(configData["keepTarget"]["actionKey"])) then
		return keepTarget:resetVariables();
	end
	local creature = keepTarget["getAttackingCreature"]();
	if (creature and creature:isPlayer()) then
		return keepTarget:setAttackingCreature(creature);
	end
	
	if (isInPz()) then return; end
	
	if (keepTarget["delayTime"] and keepTarget["delayTime"] >= now) then return; end
	
	local target = keepTarget:verifyAttackingCreature();
	if (target and keepTarget["doAttack"](target)) then
		keepTarget["delayTime"] = now + math["random"](200, 300);
	end
end)

if (FREE_VERSION) then
	keepTarget["macro"]["switch"]:setTooltip("Essa script est\225 desativada para a custom free.");
	return;
end


configData["keepTarget"]["actionKey"] = "Escape";
configData["keepTarget"]["macro"] = keepTarget["macro"];
