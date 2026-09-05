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
configData["comboLeader"] = {};

local comboLeader = setupUI("Panel\n  height: 17\n\n  BotSwitch\n    id: macro\n    anchors.top: parent.top\n    anchors.left: parent.left\n    anchors.right: parent.right\n    text-align: center\n    !text: tr(\"Combo Leader\")\n\n    image-source:\n\n    $on:\n      color: green\n\n    $!on:\n      color: white\n");

comboLeader["configWindow"] = setupUI("MainWindow\n  size: 180 295\n  !text: tr(\"Combo Leader\")\n  color: white\n  @onEscape: self:hide();\n  @onSetup: self:hide();\n\n  Panel\n    id: mainPanel\n    image-source: /images/ui/panel_flat\n    anchors.top: parent.top\n    anchors.bottom: parent.bottom\n    anchors.left: parent.left\n    anchors.right: parent.right\n    image-border: 6\n\n\n    Button\n      id: addButton\n      text: Add\n      anchors.top: parent.top\n      anchors.right: parent.right\n      size: 35 20\n\n    TextEdit\n      id: name\n      anchors.top: prev.top\n      anchors.left: parent.left\n      anchors.right: prev.left\n      height: 20\n\n    TextList\n      id: leaderList\n      anchors.left: parent.left\n      anchors.right: parent.right\n      anchors.top: prev.bottom\n      height: 120\n\n      image-border: 3\n      image-source: /images/ui/textedit\n      vertical-scrollbar: leaderListScroll\n      margin-top: 6\n\n    VerticalScrollBar\n      id: leaderListScroll\n      anchors.top: leaderList.top\n      anchors.bottom: leaderList.bottom\n      anchors.right: leaderList.right\n      step: 10\n      pixels-scroll: true\n\n    Label\n      !text: tr(\"Sou Lider\")\n      color: white\n      anchors.top: leaderList.bottom\n      anchors.left: parent.left\n      anchors.right: parent.right\n      margin-top: 5\n      margin-left: 45\n\n\n    BotSwitch\n      id: guildSay\n      !text: tr(\"Guild Say\")\n      anchors.top: prev.bottom\n      anchors.left: parent.left\n      anchors.right: parent.right\n      margin-top: 5\n\n    BotSwitch\n      id: partySay\n      !text: tr(\"Party Say\")\n      anchors.top: prev.bottom\n      anchors.left: parent.left\n      anchors.right: parent.right\n      margin-top: 5\n\n    Button\n      id: closeButton\n      !text: tr(\"Close\")\n      anchors.right: parent.right\n      anchors.left: parent.left\n      anchors.bottom: parent.bottom\n      @onClick: self:getParent():getParent():hide();\n", g_ui["getRootWidget"]());

local leaderList = comboLeader["configWindow"]["mainPanel"]["leaderList"];
local addButton = comboLeader["configWindow"]["mainPanel"]["addButton"];
local nameTextEdit = comboLeader["configWindow"]["mainPanel"]["name"];
local guildSay = comboLeader["configWindow"]["mainPanel"]["guildSay"];
local partySay = comboLeader["configWindow"]["mainPanel"]["partySay"];

storage["comboLeader"] = storage["comboLeader"] or {};
local config = storage["comboLeader"];

if (type(config["leaders"]) ~= "table") then
	config["leaders"] = {};
end

comboLeader["getAttackingCreature"] = tyrBot and tyrBot["getAttackingCreature"] or g_game["getAttackingCreature"];
comboLeader["doAttack"] = tyrBot and tyrBot["doAttack"] or g_game["attack"];

-- Config agora abre com botao direito em qualquer parte da linha (painel, nao so o switch)
comboLeader["onMouseRelease"] = function(self, mousePos, mouseButton)
	if mouseButton == 2 then
		comboLeader["configWindow"]:show();
	end
end

local setupSwitch = function(widget, id)
	widget["onClick"] = function(_, pos)
		config[id] = not config[id];
		widget:setOn(config[id]);
	end
	
	widget:setOn(config[id]);
end

comboLeader["macro"]["onClick"] = function()
	local status = not config["macroActive"];
	comboLeader["macro"]:setOn(status);
	config["macroActive"] = status;
end

guildSay["onClick"] = function(widget)
	local status = not config["guildCombo"];
	comboLeader["macro"]:setOn(status);
	config["guildCombo"] = status;
end


local FREE_VERSION = false; -- UNIVERSAL: nao aplica limitacoes da versao free.
if (FREE_VERSION) then
	addButton:setTooltip("Essa script est\225 desativada para a vers\227o free.");
	guildSay:setTooltip("Essa script est\225 desativada para a vers\227o free.");	
	partySay:setTooltip("Essa script est\225 desativada para a vers\227o free.");	
	comboLeader["macro"]:setTooltip("Essa script est\225 desativada para a vers\227o free.");
	comboLeader["macro"]["onClick"] = nil
	
else
	setupSwitch(comboLeader["macro"], "macroActive");
	setupSwitch(guildSay, "guildCombo");
	setupSwitch(partySay, "partyCombo");

	addButton["onClick"] = function()
		local name = nameTextEdit:getText():trim():lower();
		
		if (name:len() == 0) then
			error("Insert a name");
			return;
		end
		
		if (table["find"](config["leaders"], name)) then
			error("Already exists");
			return;
		end
		
		table["insert"](config["leaders"], name);
		nameTextEdit:clearText();
		comboLeader["refreshList"]();
	end
end

local widgetEntry = "UIWidget\n  background-color: alpha\n  text-offset: 3 1\n  focusable: true\n  height: 16\n  font: verdana-11px-rounded\n  text-align: left\n\n  $focus:\n    background-color: #00000055\n\n  Button\n    id: remove\n    !text: tr('X')\n    anchors.right: parent.right\n    anchors.verticalCenter: parent.verticalCenter\n    width: 14\n    height: 14\n    margin-right: 15\n    text-align: center\n    text-offset: 0 1\n    tooltip: Remover o nome da lista.\n";


local removeEntry = function(widget)

	local name = widget:getId();
	local entry = config[name];
	if (not entry) then
		widget = widget:getParent();
		name = widget:getId();
		entry = config[name];
	end
	leaderList:removeChild(widget);
	nameTextEdit:setText(name:ucwords());
	table["removevalue"](config["leaders"], name);
	comboLeader["refreshList"]();
end


local setupEntry = function(name)
	local widget = setupUI(widgetEntry, leaderList);
	widget:setId(name);
	widget:setText(name:ucwords());
	
	
	widget["onDoubleClick"] = removeEntry;
	widget["remove"]["onClick"] = removeEntry;
end


comboLeader["refreshList"] = function()
	leaderList:destroyChildren();
	
	if (table["size"](config["leaders"]) == 0) then return; end
	
	for _, name in ipairs(config["leaders"]) do
		setupEntry(name);
	end
end

local rootWidget = g_ui["getRootWidget"]();
local rootPanel = rootWidget:recursiveGetChildById("gameRootPanel");
local consoleTabBar = rootWidget:recursiveGetChildById("consoleTabBar");

local getChannelId = function(name)
	if (not name) then return; end
	local tab = consoleTabBar:getTab(name);	
	if (not tab) then return; end
	return tab["channelId"];
end


comboLeader["sender"] = {
	delay = 0
};

comboLeader["sender"]["getAttackChannel"] = function()
	if (config["guildCombo"]) then
		if (comboLeader["guildName"]) then
			return comboLeader["guildName"];
		end
	end
	if (config["partyCombo"]) then
		return "Party";
	end
end

comboLeader["setChannelId"] = function()
	local channelId;
	if (comboLeader["guildName"] and config["guildCombo"]) then
		channelId = 0;
	elseif (comboLeader["partyChannelId"] and config["partyCombo"]) then
		channelId = comboLeader["partyChannelId"];
	end
	
	if (
		(player:getShield() >= 3 ~= (comboLeader["partyChannelId"] ~= nil)) or
		(player:getEmblem() ~= 0 ~= (comboLeader["guildName"] ~= nil))
	) then
		comboLeader["hasChannelListOpened"] = nil;
		schedule(100, g_game["requestChannels"]);
		delay(500);
		return;
	end
	
	return channelId;
end	

comboLeader["macro"] = macro(100, function(self)
	if (not config["macroActive"]) then return; end
	if (FREE_VERSION) then
		return self:setOff();
	end
	local channelId = comboLeader["setChannelId"]();
	if (not channelId) then return; end
	local channelName = comboLeader["sender"]["getAttackChannel"]();
	local channelIsOpen = getChannelId(channelName);
	if (not channelIsOpen) then
		return g_game["joinChannel"](channelId);
	end
	
	local talk_delay = comboLeader["sender"]["delay"];
	local creature = comboLeader["sender"]["creature"];
	local target = comboLeader["getAttackingCreature"]();
	if (not target) then return; end
	
	local targetId = target:getId();
	
	if (talk_delay > now and creature == targetId) then return; end
	
	comboLeader["talkingMsg"] = "." .. targetId;
	sayChannel(channelId, comboLeader["talkingMsg"]);
	comboLeader["sender"]["creature"] = targetId;
	delay(1000);
end)

onTalk(function(name, level, mode, text)
	if (name ~= player:getName()) then return; end
	
	if (text == comboLeader["talkingMsg"]) then
		comboLeader["sender"]["delay"] = now + 5000;
		comboLeader["talkingMsg"] = nil;
	end
end)



onChannelList(function(channelList)
	if (FREE_VERSION) then return; end
	if (comboLeader["hasChannelListOpened"]) then return; end
	comboLeader["hasChannelListOpened"] = true;
	local channelsWindow = rootWidget:recursiveGetChildById("channelsWindow");
	if (channelsWindow) then
		channelsWindow:destroy();
	end
	rootPanel:focus();
	local partyChannelId;
	for _, channel in pairs(channelList) do
		local channelId, channelName = modules["_G"]["unpack"](channel);
		if (channelId == 0) then
			comboLeader["guildName"] = channelName;
		elseif (channelName == "Party") then
			partyChannelId = channelId;
		end
	end
	comboLeader["partyChannelId"] = partyChannelId;
end)

comboLeader["getSpectators"] = getSpectators;
	
comboLeader["getCreatureById"] = getCreatureById;

macro(100, function(self)
	if (not config["macroActive"]) then return; end
	
	if (FREE_VERSION) then
		return self:setOff();
	end
	
	if (comboLeader["guildName"]) then
		if (not getChannelId(comboLeader["guildName"])) then
			g_game["joinChannel"](0)
		end
	end
	if (comboLeader["partyChannelId"]) then
		if (not getChannelId("Party")) then
			g_game["joinChannel"](comboLeader["partyChannelId"]);
		end
	end
	
end)


local modes = {7, 8, 13};
local header = ".";
local blockedWorldIp = {"108.165.179.68"};
onTalk(function(name, level, mode, text)
	if (not config["macroActive"] or table["find"](blockedWorldIp, FREE_GET_WORLD_IP(), true)) then return; end
	if (not table["find"](modes, mode)) then return; end
	
	if (not table["find"](config["leaders"], name, true)) then return; end
	
	if (text:sub(1, #header) ~= header) then return; end
	
	local id = text:match("%d+");
	id = tonumber(id);
	if (not id) then return; end
	
	local creature = comboLeader["getCreatureById"](id);
	if (not creature) then return; end
	
	if (FREE_VERSION) then return; end
	comboLeader["doAttack"](creature);
end)


comboLeader["refreshList"]();

configData["comboLeader"]["macro"] = comboLeader["macro"];
