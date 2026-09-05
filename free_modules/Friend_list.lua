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

-- Garante a tabela ANTES de qualquer uso (evita "bad argument #1 to
-- 'ipairs' (table expected, got nil)" se algo limpar o storage antes
-- deste modulo carregar).
global_storage["tyrFriendlist"] = global_storage["tyrFriendlist"] or {};

local friendList = {};

friendList["nameEntry"] = "UIWidget\n  background-color: alpha\n  text-offset: 3 1\n  focusable: true\n  height: 16\n  font: verdana-11px-rounded\n  text-align: left\n\n  $focus:\n    background-color: #00000055\n\n  Button\n    id: remove\n    !text: tr('X')\n    anchors.right: parent.right\n    anchors.verticalCenter: parent.verticalCenter\n    width: 14\n    height: 14\n    margin-right: 15\n    text-align: center\n    text-offset: 0 1\n    tooltip: Remover o nome da lista.\n";

friendList["window"] = setupUI("MainWindow\n  size: 180 295\n  !text: tr(\"Friend list\")\n  @onEscape: self:hide()\n\n  Panel\n    id: mainPanel\n    image-source: /images/ui/panel_flat\n    anchors.top: parent.top\n    anchors.bottom: parent.bottom\n    anchors.left: parent.left\n    anchors.right: parent.right\n    image-border: 6\n\n    Button\n      id: addButton\n      text: Add\n      anchors.top: parent.top\n      anchors.right: parent.right\n      size: 35 20\n\n    TextEdit\n      id: addText\n      anchors.top: prev.top\n      anchors.left: parent.left\n      anchors.right: prev.left\n      height: 20\n\n    TextList\n      id: playersList\n      anchors.left: parent.left\n      anchors.right: parent.right\n      anchors.top: prev.bottom\n      margin-top: 5\n      height: 180\n      image-border: 3\n      image-source: /images/ui/textedit\n      vertical-scrollbar: playersListScroll\n\n    VerticalScrollBar\n      id: playersListScroll\n      anchors.top: playersList.top\n      anchors.bottom: playersList.bottom\n      anchors.right: playersList.right\n      step: 10\n      pixels-scroll: true\n\n  Button\n    id: closeButton\n    !text: tr(\"Close\")\n    anchors.left: parent.left\n    anchors.right: parent.right\n    anchors.bottom: parent.bottom\n    @onClick: self:getParent():hide()\n", g_ui["getRootWidget"]());

friendList["window"]:setColor("white");
friendList["window"]:hide();
friendList["nameCache"] = {};

function friendList:parse()
	self["nameCache"] = {};
	global_storage["tyrFriendlist"] = global_storage["tyrFriendlist"] or {};
	for index, name in ipairs(global_storage["tyrFriendlist"]) do
		local newName = name:trim():lower();
		if (newName:len() == 0) then
			table["remove"](global_storage["tyrFriendlist"], name);
			return self:parse();
		end
		self["nameCache"][newName] = true;
	end
end

friendList["window"]["mainPanel"]["addButton"]["onClick"] = function()
	local widget = friendList["window"]["mainPanel"]["addText"];
	local name = widget:getText():trim();
	
	if (#name == 0) then return; end
	
	if (friendList["nameCache"][name:lower()]) then return; end
	
	table["insert"](global_storage["tyrFriendlist"], name);
	widget:setText("");
	friendList["refreshNames"]();
end

friendList["refreshNames"] = function()
	friendList:parse();
	
	for _, child in ipairs(friendList["window"]["mainPanel"]["playersList"]:getChildren()) do
		child:destroy();
	end
	
	for index, name in ipairs(global_storage["tyrFriendlist"]) do
		local widget = setupUI(friendList["nameEntry"], friendList["window"]["mainPanel"]["playersList"]);
		widget:setText(name:ucwords());
		widget["remove"]["onClick"] = function()
			table["remove"](global_storage["tyrFriendlist"], index);
			friendList["window"]["mainPanel"]["addText"]:setText(name:ucwords());
			friendList["refreshNames"]();
		end
		widget["onDoubleClick"] = widget["remove"]["onClick"];
	end
end

friendList["isFriend"] = function(name)
	if (type(name) ~= "string") then
		name = name:getName();
	end

	name = name:trim():lower();
	return friendList["nameCache"][name] ~= nil;
end

tyrBot["friendList"] = friendList;

if (global_storage["tyrFriendlist"] == nil) then
	global_storage["tyrFriendlist"] = {};
end

if (storage["tyrFriendlist"] ~= nil) then
	for _, name in ipairs(storage["tyrFriendlist"]) do
		if (not table["find"](global_storage["tyrFriendlist"], name)) then
			table["insert"](global_storage["tyrFriendlist"], name);
		end
	end
	storage["tyrFriendlist"] = nil;
end


friendList["refreshNames"]();