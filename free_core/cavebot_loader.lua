-- FREE: carregador unico e compativel de CaveBot/TargetBot para Custom TF.
if (FREE_CAVE_TARGET_BOOTSTRAPPED == true) then
    return;
end
FREE_CAVE_TARGET_BOOTSTRAPPED = true;

-- Compatibilidade segura para executar sem o loader tyrBot original.
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
-- getNearTiles() e distanceFromPlayer() sao definidos pelo proprio
-- CaveBot em actions.lua. Nao os duplicamos aqui para evitar sobrescritas.

if (table.recursivecopy == nil) then
	table.recursivecopy = function(t)
		local res = {};
		for k,v in pairs(t) do
			if type(v) == "table" then
				res[k] = table.recursivecopy(v);
			else
				res[k] = v;
			end
		end
		return res;
	end
end

local main = function()
	local cavebotTab = "Cave"
	local targetingTab = "Target"

	setDefaultTab(cavebotTab)
	CaveBot = {} -- global namespace
	CaveBot.Extensions = {}
	importStyle("/cavebot/cavebot.otui")
	importStyle("/cavebot/config.otui")
	importStyle("/cavebot/editor.otui")
	importStyle("/cavebot/supply.otui")

	dofile("/cavebot/tyrConfig.lua")

	dofile("/cavebot/actions.lua")
	dofile("/cavebot/config.lua")
	dofile("/cavebot/editor.lua")
	dofile("/cavebot/example_functions.lua")
	dofile("/cavebot/recorder.lua")
	dofile("/cavebot/walking.lua")
	-- dofile("/cavebot/minimap.lua")
	-- in this section you can add extensions, check extension_template.lua
	--dofile("/cavebot/extension_template.lua")
	dofile("/cavebot/sell_all.lua")
	dofile("/cavebot/depositor.lua")
	dofile("/cavebot/supply.lua")
	dofile("/cavebot/d_withdraw.lua")
	dofile("/cavebot/travel.lua")
	dofile("/cavebot/doors.lua")
	dofile("/cavebot/pos_check.lua")
	dofile("/cavebot/withdraw.lua")
	dofile("/cavebot/inbox_withdraw.lua")
	dofile("/cavebot/lure.lua")
	dofile("/cavebot/bank.lua")
	dofile("/cavebot/clear_tile.lua")
	dofile("/cavebot/tasker.lua")
	dofile("/cavebot/imbuing.lua")
	dofile("/cavebot/stand_lure.lua")

	-- main cavebot file, must be last
	dofile("/cavebot/cavebot.lua")

	setDefaultTab(targetingTab)
	TargetBot = {} -- global namespace
	importStyle("/targetbot/looting.otui")
	importStyle("/targetbot/target.otui")
	importStyle("/targetbot/creature_editor.otui")
	dofile("/targetbot/creature.lua")
	dofile("/targetbot/creature_attack.lua")
	dofile("/targetbot/creature_editor.lua")
	dofile("/targetbot/creature_priority.lua")
	dofile("/targetbot/looting.lua")
	dofile("/targetbot/walking.lua")
	-- main targetbot file, must be last
	dofile("/targetbot/target.lua")


	CaveBotList = function()
		return CaveBot.actionList
	end

	CaveBot.getCurrentProfile = function()
		return tyrBot.storage._configs.cavebot_configs.selected
	end

	CaveBot.profileExists = function(name)
		return type(name) == "string" and name ~= ""
			and g_resources.fileExists(configDir .. "/cavebot_configs/" .. name .. ".cfg")
	end

	CaveBot.missingProfileWarnings = CaveBot.missingProfileWarnings or {}
	CaveBot.setCurrentProfile = function(name)
		if not CaveBot.profileExists(name) then
			local profileName = tostring(name or "<vazio>")
			if not CaveBot.missingProfileWarnings[profileName] then
				CaveBot.missingProfileWarnings[profileName] = true
				warn("[Shazam Scripts] Perfil CaveBot ausente: " .. profileName)
			end
			return false
		end
		CaveBot.setOff()
		tyrBot.storage._configs.cavebot_configs.selected = name
		CaveBot.setOn()
		return true
	end
end


cavebot_main = function()
	if (tyrBot ~= nil and tyrBot.storage ~= nil) then
		main();
		return;
	end
	schedule(1, cavebot_main);
end

cavebot_main();
