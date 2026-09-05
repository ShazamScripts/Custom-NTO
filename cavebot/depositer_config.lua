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
setDefaultTab("Cave")
local panelName = "specialDeposit"
local depositerPanel

UI.Button("Stashing Settings", function()
    depositerPanel:show()
    depositerPanel:raise()
    depositerPanel:focus()
end)

if not tyrBot.storage[panelName] then
    tyrBot.storage[panelName] = {
        items = {},
        height = 380
    }
end

local config = tyrBot.storage[panelName]

depositerPanel = UI.createWindow('DepositerPanel', rootWidget)
depositerPanel:hide()
-- basic one
depositerPanel.CloseButton.onClick = function()
    depositerPanel:hide()
end

depositerPanel:setHeight(config.height or 380)
depositerPanel.onGeometryChange = function(widget, old, new)
    if old.height == 0 then return end
    config.height = new.height
end

function arabicToRoman(n)
    local t = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XI", "XII", "XIV", "XV", "XVI", "XVII"}
    return t[n]
end

local function refreshEntries()
    depositerPanel.DepositerList:destroyChildren()
    for _, entry in ipairs(config.items) do
      local panel = g_ui.createWidget("StashItem", depositerPanel.DepositerList)
      panel.name:setText(Item.create(entry.id):getMarketData().name)
      for i, child in ipairs(panel:getChildren()) do
          if child:getId() ~= "slot" then
            child:setTooltip("Clear item or double click to remove entry.")
            child.onDoubleClick = function(widget)
              table.remove(config.items, table.find(entry))
              panel:destroy()
            end
          end
      end
      panel.item:setItemId(entry.id)
      if entry.id > 0 then
        panel.item:setImageSource('')
      end
      panel.item.onItemChange = function(widget)
        local id = widget:getItemId()
        if id < 100 then
            table.remove(config.items, table.find(entry))
            panel:destroy()
        else
            for i, data in ipairs(config.items) do
                if data.id == id then
                    warn("[Depositer Panel] Item already added!")
                    return
                end
            end
            entry.id = id
            panel.item:setImageSource('')
            panel.name:setText(Item.create(entry.id):getMarketData().name)
            if entry.index == 0 then
                local window = modules.client_textedit.show(panel.slot, {
                    title = "Set depot for "..panel.name:getText(),
                    description = "Select depot to which item should be stashed, choose between 3 and 17",
                    validation = [[^([3-9]|1[0-7])$]]
                })
                window.text:setText(entry.index)
                schedule(50, function()
                  window:raise()
                  window:focus()
                end)
            end
        end
      end
      if entry.id > 0 then
        panel.slot:setText("Stash to depot: ".. entry.index)
      end
      panel.slot:setTooltip("Click to set stashing destination.")
      panel.slot.onClick = function(widget)
        local window = modules.client_textedit.show(widget, {
            title = "Set depot for "..panel.name:getText(),
            description = "Select depot to which item should be stashed, choose between 3 and 17",
            validation = [[^([3-9]|1[0-7])$]]
        })
        window.text:setText(entry.index)
        schedule(50, function()
          window:raise()
          window:focus()
        end)
      end
      panel.slot.onTextChange = function(widget, text)
        local n = tonumber(text)
        if n then
            entry.index = n
            widget:setText("Stash to depot: "..entry.index)
        end
      end
    end
end
refreshEntries()

depositerPanel.title.onDoubleClick = function(widget)
    table.insert(config.items, {id=0, index=0})
    refreshEntries()
end

function getStashingIndex(id)
    for _, v in pairs(config.items) do
        if v.id == id then
            return v.index - 1
        end
    end
end

UI.Separator()
UI.Label("Sell Exeptions")

if type(tyrBot.storage.cavebotSell) ~= "table" then
  tyrBot.storage.cavebotSell = {23544, 3081}
end

local sellContainer = UI.Container(function(widget, items)
  tyrBot.storage.cavebotSell = items
end, true)
sellContainer:setHeight(35)
sellContainer:setItems(tyrBot.storage.cavebotSell)