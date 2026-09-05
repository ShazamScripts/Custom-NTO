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
tyrBot.Config = table.recursivecopy(Config);
local Config = tyrBot.Config;


Config.setup = function(dir, widget, configExtension, callback)
    if type(dir) ~= 'string' or dir:len() == 0 then
        return error("Invalid config dir")
    end
    if not Config.exist(dir) and not Config.create(dir) then
        return error("Can't create config dir: " .. dir)
    end
    if type(tyrBot.storage._configs) ~= "table" then
        tyrBot.storage._configs = {}
    end
    if type(tyrBot.storage._configs[dir]) ~= "table" then
        tyrBot.storage._configs[dir] = {
            enabled = false,
            selected = ""
        }
    else
        widget.switch:setOn(tyrBot.storage._configs[dir].enabled)
    end

    local isRefreshing = false
    local refresh = function()
        isRefreshing = true
        local configs = Config.list(dir)
        local configIndex = 1
        widget.list:clear()
        for v,k in ipairs(configs) do
            widget.list:addOption(k)
            if k == tyrBot.storage._configs[dir].selected then
                configIndex = v
            end
        end
        local data = nil
        if #configs > 0 then
            widget.list:setCurrentIndex(configIndex)
            tyrBot.storage._configs[dir].selected = widget.list:getCurrentOption().text
            data = Config.load(dir, configs[configIndex])
        else
            tyrBot.storage._configs[dir].selected = nil
        end
        tyrBot.storage._configs[dir].enabled = widget.switch:isOn()
        isRefreshing = false
        callback(tyrBot.storage._configs[dir].selected, widget.switch:isOn(), data)
    end

    widget.list.onOptionChange = function(widget)
        if not isRefreshing then
            tyrBot.storage._configs[dir].selected = widget:getCurrentOption().text
            refresh()
        end
    end

    widget.switch.onClick = function()
        widget.switch:setOn(not widget.switch:isOn())
        refresh()
    end

    widget.add.onClick = function()
        UI.SinglelineEditorWindow("config_name", {title="Enter config name"}, function(name)
            name = name:gsub("%s+", "_")
            if name:len() == 0 or name:len() >= 30 or name:find("/") or name:find("\\") then
                return error("Invalid config name")
            end
            local file = configDir .. "/" .. dir .. "/" .. name .. "." .. configExtension
            if g_resources.fileExists(file) then
                return error("Config " .. name .. " already exist")
            end
            if configExtension == "json" then
                g_resources.writeFileContents(file, json.encode({}))
            else
                g_resources.writeFileContents(file, "")
            end
            tyrBot.storage._configs[dir].selected = name
            widget.switch:setOn(false)
            refresh()
        end)
    end

    widget.edit.onClick = function()
        local name = tyrBot.storage._configs[dir].selected
        if not name then return end
        UI.MultilineEditorWindow(Config.loadRaw(dir, name), {title="Config editor - " .. name .. " in " .. dir}, function(newValue)
            local data = Config.parse(newValue)
            Config.save(dir, name, data, configExtension)
            refresh()
        end)
    end

    widget.remove.onClick = function()
        local name = tyrBot.storage._configs[dir].selected
        if not name then return end
        UI.ConfirmationWindow("Config removal", "Do you want to remove config " .. name .. " from " .. dir .. "?", function()
            Config.remove(dir, name)
            widget.switch:setOn(false)
            refresh()
        end)
    end

    refresh()

    return {
        isOn = function()
            return widget.switch:isOn()
        end,
        isOff = function()
            return not widget.switch:isOn()
        end,
        setOn = function(val)
            if val == false then
                if widget.switch:isOn() then
                    widget.switch:onClick()
                end
                return
            end
            if not widget.switch:isOn() then
                widget.switch:onClick()
            end
        end,
        setOff = function(val)
            if val == false then
                if not widget.switch:isOn() then
                    widget.switch:onClick()
                end
                return
            end
            if widget.switch:isOn() then
                widget.switch:onClick()
            end
        end,
        save = function(data)
            Config.save(dir, tyrBot.storage._configs[dir].selected, data, configExtension)
        end,
        refresh = refresh,
        reload = refresh,
        getActiveConfigName = function()
            return tyrBot.storage._configs[dir].selected
        end
    }
end
