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
local AnchorTop = 1;
local AnchorBottom = 2;
local AnchorLeft = 3;
local AnchorRight = 4;

local AnchorHorizontalCenter = 6;

if (tyrBot["configData"] == nil) then
	tyrBot["configData"] = {};
end
local configData = tyrBot["configData"];

if (global_storage == nil) then
	global_storage = storage;
end

if (global_storage["config"] == nil) then
	global_storage["config"] = {};
end

local data = {};

local mainWindow = setupUI("MainWindow\n  size: 200 300\n  !text: tr(\"Atalho\")\n  color: white\n\n  BotPanel\n    id: mainPanel\n    anchors.top: parent.top\n    anchors.bottom: parent.bottom\n    anchors.left: parent.left\n    anchors.right: parent.right\n", g_ui["getRootWidget"]());

g_ui["loadUIFromString"]("\nUseItem < Panel\n  height: 40\n  \n  UIWidget\n    id: text\n    margin-left:35\n    anchors.verticalCenter: parent.verticalCenter\n    anchors.left: parent.left\n    anchors.top: parent.top\n\n  BotItem\n    id: item\n    anchors.left: parent.left\n    anchors.top: parent.top\n")

local convertName = function(name)
	local newName = {};
	
	for index = 1, name:len() do
		local char = name:sub(index, index);
		if (index ~= 1 and char:upper() == char) then
			table["insert"](newName, " ");
		end
		table["insert"](newName, char);
	end
	
	return table["concat"](newName);
end

local updateData = function()
	for name, value in pairs(global_storage["config"]) do
		configData[name] = value;
	end
end

local main = function()
	for name, values in pairs(tyrBot["configData"]) do
		local value = {
			name = name
		};
		for key, val in pairs(values) do
			value[key] = val;
		end
		table["insert"](data, value);
	end
	
	table["sort"](data, function(a, b)
		return a["name"] < b["name"];
	end)
	
	updateData();
	
	for name, value in pairs(configData) do
		if (global_storage["config"][name] == nil) then
			global_storage["config"][name] = {};
			for key, val in pairs(value) do
				if (key ~= "macro") then
					global_storage["config"][name][key] = val;
				end
			end
		end
	end
	
	for _, value in ipairs(data) do
		local firstExec = true;
		local current_data = global_storage["config"][value["name"]];
		local name = convertName(value["name"]);
		if (name["ucwords"] ~= nil) then
			name = name:ucwords();
		end

		local parent = mainWindow["mainPanel"]["content"];
		local main_label = UI["Label"](name, parent);
		
		local count = mainWindow["mainPanel"]:getChildCount();
		
		if (value["actionKey"] ~= nil) then
			
			UI["Label"]("Tecla de a\231\227o:", parent);
			local textEdit = UI["TextEdit"](current_data["actionKey"] or value["actionKey"], function(widget, value)
				current_data["actionKey"] = value;
				updateData();
			end, parent);
			
			
		end
		
		if (value["extra"] ~= nil) then
			if (current_data["extra"] == nil) then
				current_data["extra"] = {};
			end
			local extra = {};
			for name, val in pairs(value["extra"]) do
				local value = {
					name = name,
					val = val
				};
				table["insert"](extra, value);
			end
			
			table["sort"](extra, function(a, b)
				return a["name"] < b["name"];
			end)
			for _, value in ipairs(extra) do
				
				local name = convertName(value["name"]);
				if (name["ucwords"] ~= nil) then
					name = name:ucwords();
				end
				
				UI["Label"](name .. ":", parent);
				
				
				local textEdit = UI["TextEdit"](current_data["extra"][value["name"]] or value["val"], function(widget, text)
					current_data["extra"][value["name"]] = text;
					updateData();
				end, parent);
			
				
				
				textEdit:setMarginTop(5);
				
			end
		end
		

		local icon;
		local label;
		local itemEdit;
		local checkBox = UI["createWidget"]("CheckBox", parent);
		checkBox["onCheckChange"] = function(widget, checked)
			if (firstExec) then return; end
			if (icon) then
				icon:destroy();
				icon = nil;
			end
		
			if (not checked) then
				
				itemEdit:hide();
			end
			
			if (checked) then
				local widget = value["macro"]["switch"];
				if (widget == nil) then
					widget = value["macro"];
				end
				
				
				itemEdit:show();
				icon = addIcon(name, {item=current_data["iconId"], text=name}, function(icon, isOn)
					if (firstExec) then return; end
					if ((isOn and not widget:isOn()) or (not isOn and widget:isOn())) then
						widget:onClick();
					end
				
				end)
				
				local isMobile = (g_app or modules["_G"]["g_app"])["isMobile"]();
				icon["onDragEnter"] = function(widget, mousePos)
					if 	(
							isMobile and not modules["corelib"]["g_keyboard"]["isKeyPressed"]("F2") or
							not isMobile and not modules["corelib"]["g_keyboard"]["isCtrlPressed"]()
						) 
					then
						return false;
					end
					widget:breakAnchors();
					widget["movingReference"] = { x = mousePos["x"] - widget:getX(), y = mousePos["y"] - widget:getY() };
					return true;
				end
				if (widget["oldCallback"] == nil) then
					widget["oldCallback"] = widget["onClick"];
				end
		
				
				widget["onClick"] = function(widget)
					widget:oldCallback();
					if (icon ~= nil) then
						icon["setOn"](widget:isOn());
					end
				end
			end
			current_data["activatedIcon"] = checked;
			updateData();
		end
		
		checkBox:setTooltip("Utilizar icon");
		
		if (current_data["iconId"] == nil) then
			current_data["iconId"] = math["random"](1, 100);
		end
		
		
		
		itemEdit = UI["createWidget"]("UseItem", parent);
				
		
		
		itemEdit["item"]["onItemChange"] = function(widget)
			local item = widget:getItem();
			if (item ~= nil) then
				local itemId = item:getId();
				current_data["iconId"] = itemId;
				checkBox:onCheckChange(true);
				updateData();
			end
		end
		itemEdit["text"]:setText("Id do icon");
		
			
			
				
				
				
			
			
			
			
			
			
		
		
		
		
		
		
		
		firstExec = false;
		checkBox:setChecked(current_data["activatedIcon"]);
		checkBox:onCheckChange(current_data["activatedIcon"]);
	end
end

UI["Button"](tr("Close"), function()
	mainWindow:hide();
end, mainWindow["mainPanel"]["content"])

schedule(100, function()
	UI["Button"]("Atalhos", function()
		mainWindow:show();
	end, getTab("User"));
end)

schedule(100, main);

mainWindow:hide();