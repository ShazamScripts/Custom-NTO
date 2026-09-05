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
local _G = modules["_G"];
do
	local script = "local creature = _G.TYR_ATT;\nif (creature == nil) then\n\t_G.attacked_called = nil;\n\treturn;\nend\nlocal isMobile = g_app.isMobile();\nlocal keyboardModifiers = g_keyboard.getModifiers;\nlocal creatureId = creature:getId();\nlocal processMouseAction = _G.process;\n\n\nlocal keyBoardNoneModifiers = function() \n\treturn 0; \nend\n\n\nlocal getCreatureById = function(id)\n\tfor _, tile in ipairs(g_map.getTiles(g_game.getLocalPlayer():getPosition().z)) do\n\t\tfor _, spec in ipairs(tile:getCreatures()) do\n\t\t\tif (spec:getId() == id) then\n\t\t\t\treturn spec;\n\t\t\tend\n\t\tend\n\tend\nend\n\nlocal checkImageById = function(id)\n\tmodules.game_interface.resetLeftActions();\n\tmodules.game_interface.gameLeftActions:getChildById(id).image:setChecked(true);\nend\n\nif (processMouseAction == nil) then\n\tlocal scores = {\"autoWalk\", \"Sorry, not possible.\", \"tr\", \"displayFailureMessage\", \"game_textmessage\", \"isWalkable\", \"getTile\", \"g_map\", \"stopAutoWalk\", \"getLocalPlayer\", \"isPressed\", \"g_mouse\", \"isAltPressed\", \"KeyboardCtrlModifier\", \"KeyboardShiftModifier\", \"KeyboardNoModifier\", \"classicControl\", \"getOption\", \"client_options\", \"modules\", \"follow\", \"getPosition\", \"player\", \"attack\", \"startUseWith\", \"isMultiUse\", \"open\", \"getParentContainer\", \"isContainer\", \"use\", \"g_game\", \"resetLeftActions\", \"look\", \"getLeftAction\", \"MouseTouch3\", \"MouseTouch2\", \"MouseLeftButton\", \"createThingMenu\", \"MouseRightButton\", \"isMobile\", \"g_app\", \"getModifiers\", \"g_keyboard\"};\n\tlocal best_result = {func=nil, points=0};\n\t_rec = function(t, stack)\n\t\t\n\t\tif (modules._G.process) then return; end\n\n\t\tstack = stack or {};\n\t\tfor key, value in pairs(t) do\n\t\t\tlocal _type = type(value);\n\t\t\t\n\t\t\tif (_type == \"table\") then\n\t\t\t\tlocal __index = tostring(value);\n\t\t\t\tif (stack[__index]) then\n\t\t\t\t\tgoto continue;\n\t\t\t\tend\n\t\t\t\tstack[__index] = true;\n\t\t\t\t_rec(value, stack);\n\t\t\t\t::continue::\n\t\t\telseif (_type == \"function\") then\n\t\t\t\tlocal func = value;\n\t\t\t\tlocal status, dumped = pcall(string.dump, func);\n\t\t\t\tif (status) then\n\t\t\t\t\tlocal func_points = 0;\n\t\t\t\t\tfor _, score in ipairs(scores) do\n\t\t\t\t\t\tif (dumped:find(score)) then\n\t\t\t\t\t\t\tfunc_points = func_points + 1;\n\t\t\t\t\t\tend\n\t\t\t\t\tend\n\t\t\t\t\tif (func_points > 0) then\n\t\t\t\t\t\tlocal points = best_result.points;\n\t\t\t\t\t\tif (points < func_points) then\n\t\t\t\t\t\t\tbest_result.func = func;\n\t\t\t\t\t\t\tbest_result.points = func_points;\n\t\t\t\t\t\tend\n\t\t\t\t\tend\n\t\t\t\tend\n\t\t\tend\n\t\tend\n\tend\n\n\n\t_rec(modules);\n\t_rec = nil;\n\n\tif (best_result.func ~= nil) then\n\t\tlocal func = best_result.func;\n\t\t_G.process = func;\n\t\tprocessMouseAction = func;\n\tend\nend\n\n_G.TYR_ATT = nil;\ncreature = getCreatureById(creatureId);\n\nif (creature ~= nil) then\n\tlocal scheduleTime = 0;\n\tlocal creaturePos = creature:getPosition();\n\tif (g_game.getWorldName():lower() == \"ntoultimate\") then\n\t\tg_game.getProtocolGame():sendExtendedOpcode(ClientOpcodes.ClientSendClientVersion, creatureId);\n\t\tscheduleTime = 100;\n\tend\n\tscheduleEvent(function()\n\t\t_G.attacked_called = nil;\n\t\tlocal gameMapPanel = modules.game_interface.getMapPanel();\n\t\tlocal oldValue = gameMapPanel.allowNextRelease;\n\t\tgameMapPanel.allowNextRelease = true;\n\t\tgameMapPanel:onMouseRelease();\n\t\tgameMapPanel.allowNextRelease = oldValue;\n\t\tif (isMobile) then\n\t\t\tcheckImageById(\"attack\");\n\t\tend\n\t\t\n\t\tg_keyboard.getModifiers = keyBoardNoneModifiers;\n\t\tprocessMouseAction(\n\t\t\t{x = 0, y = 0},\n\t\t\tisMobile and 1 or 2,\n\t\t\tcreaturePos,\n\t\t\tcreature,\n\t\t\tcreature,\n\t\t\tcreature,\n\t\t\tcreature,\n\t\t\tfalse\n\t\t);\n\n\t\tg_keyboard.getModifiers = keyboardModifiers;\n\tend, scheduleTime);\n\treturn;\nend\n\n_G.attacked_called = nil;\n";
	
	local func, err = _G["loadstring"](script, "@");
	if (not func) then
		error(err);
		return;
	end
	_G["setfenv"](func, _G);
	
	_G["doAttack"] = function()
		local creature = _G["TYR_ATT"];
		if (not creature) then return; end
		
		
		if (_G["attacked_called"] and _G["attacked_called"] >= now) then return; end
		_G["attacked_called"] = now + 200;

		_G["addEvent"](function()
			local status = _G["pcall"](func);
			if (not status) then
				_G["attacked_called"] = nil;
			end
		end);
	end
end


tyrBot["doAttack"] = function(creature)
	if (not creature) then return; end
	if (tyrBot["getAttackingCreature"]() == creature) then return; end
	local creaturePos = creature:getPosition();
	if (creaturePos and creaturePos["z"] ~= player:getPosition()["z"]) then return; end
	
	
	if (g_game["getWorldName"]() == "Katon") then
		if (creature:isMonster()) then
			return g_game["attack"](creature);
		end
	end
	

	_G["TYR_ATT"] = creature;
	_G["doAttack"]();
	return true;
end