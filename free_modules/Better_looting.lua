local LootMonsters = {};

LootMonsters["waitTill"] = 0;
LootMonsters["status"] = "";
LootMonsters["containers"] = {};
LootMonsters["list"] = {};

storage["looting"] = storage["looting"] or {items={},containers={}};
LootMonsters["storage"] = storage["looting"];

LootMonsters["save"] = function()

end

LootMonsters["update"] = function()

end

LootMonsters["getStatus"] = function()
	return LootMonsters["status"];
end

LootMonsters["setFilteredItems"] = function(items, config)
    local filtered = {};
	for _, item in ipairs(items) do
        local id = tonumber(item) or item["id"];
		table["insert"](filtered, id);
	end
	LootMonsters["storage"][config] = filtered;
end

LootMonsters["getLootContainers"] = function()
	local openingContainer;
    local lootContainers = {};
    local openedContainersById = {};
	local containers = g_game["getContainers"]();
    for _, container in pairs(containers) do
		local containerId = (container:getContainerItem() and container:getContainerItem():getId());
        openedContainersById[containerId] = true;
        if (table["find"](LootMonsters["storage"]["containers"], containerId) and not container["lootContainer"]) then
            if (container:getItemsCount() < container:getCapacity()) then
                table["insert"](lootContainers, container);
            else
                for _, item in ipairs(container:getItems()) do
                    if (item:isContainer()) then
                        local itemId = item:getId();
                        if (table["find"](LootMonsters["storage"]["containers"], itemId)) then
                            openingContainer = {item=item, parent=container};
                            break
                        end
                    end
                end
            end
        end
    end
    if (table["size"](lootContainers) == 0) then
        if (openingContainer ~= nil) then
            g_game["open"](openingContainer["item"], openingContainer["parent"]);
            LootMonsters["waitTill"] = now + 300;
            return lootContainers;
        end
        for _, container in pairs(containers) do
            local containerId = (container:getContainerItem() and container:getContainerItem():getId());
            if (not table["find"](LootMonsters["storage"]["containers"], containerId) and not container["lootContainer"]) then
                for _, item in ipairs(container:getItems()) do
                    if (item:isContainer()) then
                        local itemId = item:getId();
                        if (table["find"](LootMonsters["storage"]["containers"], itemId)) then
                            g_game["open"](item);
                            LootMonsters["waitTill"] = now + 300;
                            return lootContainers;
                        end
                    end
                end
            end
        end
        for slot = InventorySlotFirst, InventorySlotLast do
            local item = getInventoryItem(slot);
            if (item and item:isContainer()) then
                local itemId = item:getId();
                if (not openedContainersById[itemId]) then
                    g_game["open"](item);
                    LootMonsters["waitTill"] = now + 300;
                    return lootContainers;
                end
            end
        end
    end
    return lootContainers;
end

LootMonsters["lootItem"] = function(lootContainers, item)
    local count = item:getCount();
    if (item:isStackable()) then
        for _, container in ipairs(lootContainers) do
            for slot, citem in ipairs(container:getItems()) do
                if (item:getId() == citem:getId() and citem:getCount() < 100) then
					LootMonsters["waitTill"] = now + 100;
                    g_game["move"](item, container:getSlotPosition(slot - 1), count);
                    return;
                end
            end
        end
    end
	
	
    LootMonsters["waitTill"] = now + 100;
    local container = lootContainers[1];
    g_game["move"](item, container:getSlotPosition(container:getItemsCount()), count);
end

LootMonsters["lootContainer"] = function(lootContainers, container)

    local nextContainer;
    for _, item in ipairs(container:getItems()) do
        local itemId = item:getId();
        local isLootItem = table["find"](LootMonsters["storage"]["items"], itemId);
        local isContainer = item:isContainer();
        if (isContainer and not isLootItem) then
            nextContainer = item;
        elseif (isLootItem or (LootMonsters["storage"]["loot_all"] and not isContainer)) then
			local tries = item["_looting_tries"] or 1;
			if (tries < 30) then
				item["_looting_tries"] = tries + 1;
				return LootMonsters["lootItem"](lootContainers, item);
			end
        end
    end

    if (nextContainer ~= nil) then
        nextContainer["_looting_attempt"] = (nextContainer["_looting_attempt"] or 0) + 1
        if (nextContainer["_looting_attempt"]) < 2 then 
            g_game["open"](nextContainer, container);
            LootMonsters["waitTill"] = now + 300;
            LootMonsters["waitingContainer"] = nextContainer:getId();
            return;
        end
    end

    
    container["lootContainer"] = false;
    g_game["close"](container);
    table["remove"](LootMonsters["list"], 1);
end

LootMonsters["refreshQueue"] = function()
    for index, value in ipairs(LootMonsters["list"]) do
        local added = value["added"];
        if (added) then
            local diff = math["abs"](now - added);
            if (diff >= 100) then
                table["remove"](LootMonsters["list"], index);
                return LootMonsters["refreshQueue"]();
            end
        end
    end
end

LootMonsters["setMarked"] = function(pos)
	schedule(50, function()
		if (pos ~= nil) then
			local tile = g_map["getTile"](pos);
			if (tile ~= nil) then
				local topThing = tile:getTopUseThing();
				if (topThing ~= nil and topThing:isContainer()) then
					topThing:setMarked("#000088");
				end
			end
		end
	end);
end

LootMonsters["process"] = function()
    if (table["size"](LootMonsters["storage"]["containers"]) == 0) then
        LootMonsters["status"] =  "";
        return false;
    end
	
	if (not LootMonsters["storage"]["status"]) then return; end

	LootMonsters["refreshQueue"]();
	local looting = LootMonsters["list"][1];
    if (looting == nil or looting["added"]) then
        LootMonsters["status"] =  "";
        return false;
    end

    if (LootMonsters["waitTill"] >= now) then
        return true;
    end

    local lootContainers = LootMonsters["getLootContainers"]();

    if (table["size"](lootContainers) == 0) then
        LootMonsters["status"] = "Nenhuma BP aberta.";
        return false;
    end

    LootMonsters["status"] = "Looteando";

    local containers = g_game["getContainers"]();
    for _, container in pairs(containers) do
        if (container["lootContainer"]) then
            LootMonsters["lootContainer"](lootContainers, container);
            return true;
        end
    end
	
	if (looting["position"] == nil) then
		table["remove"](LootMonsters["list"], 1);
		return true;
	end
	
    local playerPos = player:getPosition();
    local distance = getDistanceBetween(playerPos, looting["position"]);
    if (looting["_tries"] > 30 or looting["position"]["z"] ~= playerPos["z"] or distance > 15) then
        table["remove"](LootMonsters["list"], 1);
        return true;
    end

    local tile = g_map["getTile"](looting["position"]);
    if (distance > 2 or not tile) then
        looting["_tries"] = looting["_tries"] + 1;
        local autoWalk = TargetBot and TargetBot["walkTo"] or autoWalk;
        autoWalk(looting["position"], 20, {ignoreNonPathable = true, precision = 2});
        return true;
    end

    local container = tile:getTopUseThing();
    if (not container or not container:isContainer()) then
        table["remove"](LootMonsters["list"], 1);
        return true;
    end
	
	local containerId = container:getId();
	if (LootMonsters["waitingContainer"] ~= containerId) then
		LootMonsters["waitingContainer"] = containerId;
		looting["_tries"] = 0;
	end
	
	LootMonsters["waitTill"] = now + 300;
    looting["_tries"] = looting["_tries"] + 1;

    g_game["open"](container);
    return true;
end

onContainerOpen(function(container)
    if ((container:getContainerItem() and container:getContainerItem():getId()) == LootMonsters["waitingContainer"]) then
        container["lootContainer"] = true;
        LootMonsters["waitingContainer"] = nil;
    end
end)

onCreatureDisappear(function(creature)
    if (table["size"](LootMonsters["storage"]["containers"]) == 0) then return; end
    if (not creature:isMonster()) then return end
	local config = TargetBot["Creature"]["calculateParams"](creature, {});
	if (not config["config"] or config["config"]["dontLoot"]) then return; end
    local playerPos = player:getPosition();
    local creaturePosition = creature:getPosition();
    local creatureName = creature:getName();
    if (playerPos["z"] ~= creaturePosition["z"]) then return; end
    local distance = getDistanceBetween(playerPos, creaturePosition);
    if (distance > 6) then return; end

    table["insert"](LootMonsters["list"], {
        position=creaturePosition,
        name=creatureName:trim():lower(),
        _tries=0,
        added=LootMonsters["storage"]["only_ok"] and now or nil
    });
end)

onTextMessage(function(mode, text)
    if (mode ~= 20) then return; end
    text = text:trim():lower();
    if (text:find("loot of")) then
        schedule(30, function()
            LootMonsters["refreshQueue"]();
            for index, loot in ipairs(LootMonsters["list"]) do
                if (loot["added"]) then
					if (not text:ends(": nothing.")) then
						loot["added"] = nil;
						LootMonsters["setMarked"](loot["position"]);
					else
						table["remove"](LootMonsters["list"], index);
					end
					break;
                end 
            end
        end)
    end
end)

LootMonsters["setupContainer"] = function(id)
    local callback = function(widget, items)
        LootMonsters["setFilteredItems"](items, id);
    end
    local widget = UI["Container"](callback, true);
    widget:setHeight(37);
	local items = LootMonsters["storage"][id];
    callback(widget, LootMonsters["storage"][id]);
	widget:setItems(items);
    return widget;
end

LootMonsters["setupSwitch"] = function(id, text)
    local callback = function(widget)
		LootMonsters["storage"][id] = not LootMonsters["storage"][id];
		widget:setOn(LootMonsters["storage"][id]);
    end
    local widget = addSwitch("switch_" .. id, text, callback);
	if (LootMonsters["storage"][id] == nil) then
		LootMonsters["storage"][id] = true;
	end
	widget:setOn(LootMonsters["storage"][id]);
    return widget;
end


local tabNames = {"Cave", "Target"};
local execute_looting = function()
	if (LootMonsters["canExecute"] ~= nil) then return; end
	local default_tab = "Others";
    if (TargetBot) then
        LootMonsters["oldLooting"] = TargetBot["Looting"];
        local ui;
		for _, tabName in ipairs(tabNames) do
			if (ui ~= nil) then
				break;
			end
			local tab = tabs:getTab(tabName);
			if (tab ~= nil) then
				tab = tab["tabPanel"]["content"];
				for _, child in pairs(tab:getChildren()) do
					if (child:getStyleName() == "TargetBotLootingPanel") then
						ui = child;
						default_tab = tabName;
						break
					end
				end
			end
		end
		ui:hide();
        TargetBot["Looting"] = LootMonsters;
    end
	setDefaultTab(default_tab);

	local override_target = default_tab ~= "Others";
	if (not override_target) then
		LootMonsters["canExecute"] = true;
		LootMonsters["switch"] = addSwitch("LootMonsters", "Looting", function(widget)
		LootMonsters["storage"]["status"] = not LootMonsters["storage"]["status"];
			widget:setOn(LootMonsters["storage"]["status"]);
		end);
		LootMonsters["switch"]:setOn(LootMonsters["storage"]["status"]);
	end
	UI["Label"]("Items");
	LootMonsters["itemsUI"] = LootMonsters["setupContainer"]("items");
	LootMonsters["lootAllSwitch"] = LootMonsters["setupSwitch"]("loot_all", "Lootear todos items");
	UI["Label"]("Bags");
	LootMonsters["containersUI"] = LootMonsters["setupContainer"]("containers");
	LootMonsters["lootOnlyOkSwitch"] = LootMonsters["setupSwitch"]("only_ok", "Lootear apenas n\227o-vazios");
	if (override_target) then
		LootMonsters["canExecute"] = false;
		UI["Label"]("Looting by Shazam Scripts."):setColor("#7600bc");
	end
	
	panel = mainTab;
end

macro(200, function()
	if (LootMonsters["canExecute"] == nil) then
		schedule(1000, execute_looting);
		return delay(1000);
	end
    if (LootMonsters["canExecute"]) then
		LootMonsters["process"]();
	else
		LootMonsters["storage"]["status"] = TargetBot["isOn"]();
	end
end);
