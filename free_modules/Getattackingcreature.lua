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
if (global_storage["attackingFunctions"] == nil) then
	global_storage["attackingFunctions"] = {};
end

if (global_storage["ignoringFunctions"] == nil) then
	global_storage["ignoringFunctions"] = {};
end

local g_game = modules["_G"]["g_game"];
local ignoringFunctions = global_storage["ignoringFunctions"];
local attackingFunctions = global_storage["attackingFunctions"];
local ignoredFunctions = {"setTripleEffectsOption", "NewAtk", "acceptTrade", "addMountainSpriteId", "addVip", "answerModalDialog", "applyImbuement", "attack", "attackBot", "attackVs", "autoWalk", "browseField", "buffNormal", "buffVip", "buyItem", "buyStoreOffer", "canPerformGameAction", "canReportBugs", "cancel", "cancelAttack", "cancelAttackAndFollow", "cancelFollow", "cancelLogin", "cancelRuleViolation", "changeMapAwareRange", "changeOutfit", "checkBotProtection", "chooseRsa", "clearImbuement", "close", "closeImbuingWindow", "closeNpcChannel", "closeNpcTrade", "closeRuleViolation", "debugReport", "disableFeature", "download", "editList", "editText", "editVip", "enableFeature", "enableTileThingLuaCallback", "equipItem", "equipItemId", "excludeFromOwnChannel", "findItemInContainers", "findPlayerItem", "follow", "forceLogout", "get", "getCharacterName", "getChaseMode", "getClientProtocolVersion", "getClientVersion", "getContainer", "getContainers", "getCustomProtocolVersion", "getEffectsTransparency", "getFeature", "getFightMode", "getFollowingCreature", "getGMActions", "getLastWalkDir", "getLocalPlayer", "getMaxPreWalkingSteps", "getOpenPvpSituations", "getOs", "getPVPMode", "getPing", "getProtocolGame", "getProtocolVersion", "getRecivedPacketsCount", "getRecivedPacketsSize", "getRsa", "getServerBeat", "getShowAura", "getShowEloRanking", "getShowJutsus", "getSpellsCrosshair", "getSupportedClients", "getTibiaCoins", "getTransferableTibiaCoins", "getUnjustifiedPoints", "getVips", "getWorldIp", "getWorldName", "ignoreServerDirection", "inspectNpcTrade", "inspectTrade", "inviteToOwnChannel", "isAttacking", "isConnectionOk", "isDead", "isFollowing", "isGM", "isLogging", "isOfficialTibia", "isOnline", "isSafeFight", "isTileThingLuaCallbackEnabled", "joinChannel", "leaveChannel", "loginWorld", "look", "mount", "mousePointer", "move", "moveRaw", "moveToParentContainer", "moveToParentContainer", "oldTarget", "onAddAutomapFlag", "onAddItem", "onAddVip", "onAttackingCreatureChange", "onAttackingCreatureChangeBot", "onAutoWalk", "onChannelEvent", "onChannelList", "onChaseModeChange", "onClientVersionChange", "onCloseChannel", "onCloseImbuementWindow", "onCloseNpcTrade", "onCloseTrade", "onCoinBalance", "onConnectionError", "onCounterTrade", "onDeath", "onEditList", "onEditText", "onEnterGame", "onFightModeChange", "onFollowingCreatureChange", "onGMActions", "onGameEditText", "onGameEnd", "onGameStart", "onImbuementWindow", "onLoginAdvice", "onLoginError", "onLoginToken", "onLoginWait", "onLogout", "onMapChangeAwareRange", "onModalDialog", "onOpenChannel", "onOpenNpcTrade", "onOpenOutfitWindow", "onOpenOwnPrivateChannel", "onOpenPrivateChannel", "onOpenPvpSituationsChange", "onOwnTrade", "onPVPModeChange", "onPendingGame", "onPingBack", "onPlayerGoods", "onPreyActive", "onPreyFreeRolls", "onPreyInactive", "onPreyLocked", "onPreyPrice", "onPreySelection", "onPreyTimeLeft", "onQuestLine", "onQuestLog", "onRemoveAutomapFlag", "onRemoveItem", "onResourceBalance", "onRuleViolationCancel", "onRuleViolationChannel", "onRuleViolationLock", "onRuleViolationRemove", "onSafeFightChange", "onSpellCooldown", "onSpellGroupCooldown", "onStoreCategories", "onStoreError", "onStoreInit", "onStoreOffers", "onStorePurchase", "onStoreTransactionHistory", "onTalk", "onTalkChannel", "onTeleport", "onTextMessage", "onUnjustifiedPointsChange", "onUpdateNeeded", "onUse", "onUseWith", "onVipStateChange", "onWalk", "open", "openOwnChannel", "openParent", "openPrivateChannel", "openRuleViolation", "openStore", "openTransactionHistory", "partyInvite", "partyJoin", "partyLeave", "partyPassLeadership", "partyRevokeInvitation", "partyShareExperience", "ping", "playRecord", "post", "preyAction", "preyRequest", "refreshContainer", "rejectTrade", "removeVip", "reportBug", "reportRuleViolation", "requestChannels", "requestItemInfo", "requestOutfit", "requestQuestLine", "requestQuestLog", "requestStoreOffers", "requestTrade", "requestTransactionHistory", "resetFeatures", "rotate", "safeLogout", "seekInContainer", "sellItem", "sendSpellWithCrosshair", "sendUseCustomReceived", "setBuff", "setChaseMode", "setClientVersion", "setCustomOs", "setCustomProtocolVersion", "setEffectsTransparency", "setEnableBotString", "setFeature", "setFightMode", "setMaxPreWalkingSteps", "setOutfitExtensions", "setPVPMode", "setPingDelay", "setProtocolVersion", "setReajustOutfit", "setRsa", "setSafeFight", "setShowAura", "setShowEloRanking", "setShowJutsus", "setSpellCrosshair", "setTibiaCoins", "showRealDirection", "stop", "talk", "talkChannel", "talkPrivate", "transferCoins", "turn", "turnTarget", "use", "useInventoryItem", "useInventoryItemWith", "useWith", "walk", "wrap"};

for index, value in ipairs(ignoredFunctions) do
	ignoredFunctions[value] = true;
	ignoredFunctions[index] = nil;
end

local searchWithinVariables = function()
	for key, content in pairs(g_game) do
		if (type(content) == "function" and not ignoredFunctions[key] and not table["find"](ignoringFunctions, key)) then
			local _, result = pcall(content)
			local res_type = type(result);
			if (res_type == "userdata") then
				local index = result:isPlayer() and "player" or result:isMonster() and "monster" or nil;
				if (index) then
					attackingFunctions[index] = key;
					return result;
				end
			elseif (res_type ~= "nil") then
				table["insert"](ignoringFunctions, key);
			end
		end
	end
end

local currentTarget;
local _G = modules["_G"];
local removeEvent = _G["removeEvent"];
local scheduleEvent = _G["scheduleEvent"];

if (_G["currentTyrAttackCreatureEvent"] ~= nil) then
	removeEvent(_G["currentTyrAttackCreatureEvent"]);
	_G["currentTyrAttackCreatureEvent"] = nil;
end

AttackingCreatureEvent = function()
	local size = 3;
	local mainFunctions = {g_game["getAttackingCreature"], g_game["getAttackinggCreature"], g_game["getAttackingCreatureFix"]};
	
	for i = 1, size do
		local func = mainFunctions[i];
		if (func ~= nil) then
			local ret = func();
			
			currentTarget = ret;
			if (ret ~= nil) then
				break;
			end
		end
	end
	
	_G["currentTyrAttackCreatureEvent"] = scheduleEvent(AttackingCreatureEvent, 30);
end

tyrBot["getAttackingCreature"] = function()
	return currentTarget;
	
	
		
	
	
		
		
			
				
					
				
					
				
			
			
		
	
end

modules["_G"]["getAttackingCreature"] = tyrBot["getAttackingCreature"];
AttackingCreatureEvent();