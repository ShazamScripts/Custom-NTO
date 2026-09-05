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
configData["enemy"] = {};


local FREE_VERSION = false; -- UNIVERSAL: nao aplica limitacoes da versao free.
local attackEnemy = {};
local friendList = tyrBot["friendList"];

local _G = modules["_G"];
local isMobile = _G["g_app"]["isMobile"]();



attackEnemy["isFriend"] = friendList["isFriend"];

attackEnemy["getSpectators"] = tyrBot["getSpectators"];

attackEnemy["getCreatureById"] = getCreatureById;

attackEnemy["doAttack"] = tyrBot["doAttack"];

attackEnemy["getAttackingCreature"] = tyrBot["getAttackingCreature"];

onCreaturePositionChange(function(creature, newPos, oldPos)
	
	if (not newPos or not oldPos) then return; end
	
	local newPos = newPos["x"] .. "," .. newPos["y"] .. "," .. newPos["z"];
	
	if (creature["lastPos"] ~= newPos) then
		creature["lastPos"] = newPos;
		creature["whiteList"] = nil;
	end
end)

attackEnemy["whiteListedCase"] = {
    "You may not attack a person in a protection zone.",
    "You may not attack this player.",
    "This action is not permitted in a safe zone.",
	"Voc\234 n\227o pode atacar este jogador.",
	"Voc\234 n\227o pode atacar uma pessoa em zona de prote\231\227o."	
};

for index, case in ipairs(attackEnemy["whiteListedCase"]) do
	attackEnemy["whiteListedCase"][index] = case:trim():lower();
end


onTextMessage(function(mode, text)
	text = text:trim():lower();
	for _, case in ipairs(attackEnemy["whiteListedCase"]) do
		if (text:find(case)) then
			local target = attackEnemy["getAttackingCreature"]();
			if (target) then
				local targetPos = target:getPosition();
				if (targetPos == nil) then return; end
				schedule(500, function()
					local newPos = target:getPosition();
					if (newPos) then
						if (table["equal"](newPos, targetPos)) then
							target["whiteList"] = true;
						end
					end
				end)
			end
			break;
		end
	end	
end)

function Creature:isAttackable()
	if (not self:getPosition()) then
		return false;
	end
	if (not self:getTile():hasBlockingCreature()) then
		return false;
	end
	local safeFight = g_game["isSafeFight"]();
	local skull = self:getSkull()
	local emblem = self:getEmblem();
	if (not safeFight or skull ~= 0) then
		local selfName = self:getName();
		if (self:isPlayer()) then
			local healthPercent = self:getHealthPercent();
			if (healthPercent and healthPercent > 0) then
					if (not attackEnemy["isFriend"](selfName)) then
						if (emblem ~= 1 and self:getShield() < 3 and self ~= player) then
							return self["whiteList"] == nil
						else
							friendList["window"]["mainPanel"]["addText"]:setText(selfName);
							friendList["window"]["mainPanel"]["addButton"]["onClick"]();
						end
					end
			end
		end
	end
end


local protocol = _G["ProtocolGame"];
_G["canAttackCache"] = _G["canAttackCache"] or {};

local creatureTypes = {
	97, 
	98, 
	99 
};

local opcode_callbacks = {};

opcode_callbacks[106] = function(self, msg)
	self:getPosition(msg);
	if (g_game["getFeature"](19)) then 
		msg:getU8();
	end
	
	local type = msg:getU16();
	if (not table["find"](creatureTypes, type)) then
		return false;
	end
	
	local creature;
	local id;
	local known = type ~= 97;
	if (type == 97 or type == 98) then
		id = msg:getU32();
		if (not known) then
			id = msg:getU32();
			if (g_game["getFeature"](89)) then  
				if (g_game["getProtocolVersion"]() >= 1252) then
					msg:getU8();
				end
			end
			
			local creatureType;
            if (g_game["getProtocolVersion"]() >= 910) then
                creatureType = msg:getU8();
            else
                if (id >= 0x10000000 and id < 0x40000000) then
                    creatureType = 0;
                elseif (id >= 0x40000000 and id < 0x80000000) then
                    creatureType = 1;
                else
                    creatureType = 2;
				end
			end
				
			if (g_game["getFeature"](89) and creatureType == 3) then
				msg:getU32();
			end
			
			msg:getString();
		end
	end
	
	local healthPercent = msg:getU8();
	local manaPercent = -1;
	if (g_game["getFeature"](122)) then
		if (msg:getU8() == 0x01) then
			manaPercent = msg:getU8();
		end
	end
	
	local direction = msg:getU8();
	local outfit = self:getOutfit(msg);
	local light = {};
	light["intensity"] = msg:getU8();
	light["color"] = msg:getU8();
	
	local speed = msg:getU16();
	if (g_game["getFeature"](89) and g_game["getProtocolVersion"]() >= 1240) then
		msg:getU8();
	end
	local skull = msg:getU8();
	local shield = msg:getU8();
	
	local emblem = -1;
	local creatureType = -1;
	local icon = -1;
	local unpass = true;
	local mark;
	
	if (g_game["getFeature"](14) and not known) then 
		emblem = msg:getU8();
	end
	
	if (g_game["getFeature"](41)) then 
		creatureType = msg:getU8();
		if (g_game["getFeature"](89)) then
			if (creatureType == 3) then
				msg:getU32();
			end
			if (g_game["getProtocolVersion"]() >= 1215 and creatureType == 0) then
				msg:getU8();
			end
		end
	end
	
	if (g_game["getFeature"](54)) then 
		icon = msg:getU8();
	end
	
	if (g_game["getFeature"](41)) then 
		mark = msg:getU8();
		if (g_game["getFeature"](89)) then
			msg:getU8();
		else
			msg:getU16();
		end
		
	end
	
	if (g_game["getProtocolVersion"]() >= 854 or g_game["getFeature"](86)) then 
		unpass = msg:getU8();
	end
	
end;

opcode_callbacks[146] = function(self, msg)
	local id = msg:getU32();
	local unpass = msg:getU8();
	
end



	
	
	



	





	
	
		
		
	


storage["scrollBars"] = storage["scrollBars"] or {};

attackEnemy["button"] = setupUI("Panel\n  height: 17\n\n  BotSwitch\n    id: macro\n    anchors.top: parent.top\n    anchors.left: parent.left\n    anchors.right: parent.right\n    text-align: center\n    !text: tr(\"Enemy\")\n\n    image-source:\n\n    $on:\n      color: green\n\n    $!on:\n      color: white\n");

-- Igual ao Combo e as outras: botao direito em qualquer parte da linha
-- abre a janela de configuracao (aqui, a lista de amigos).
attackEnemy["button"]["onMouseRelease"] = function(self, mousePos, mouseButton)
	if (mouseButton == 2) then
		friendList["window"]:show();
	end
end

if (type(storage["attackEnemy"]) ~= "table") then
	storage["attackEnemy"] = {};
end
local config = storage["attackEnemy"];

if (config["macroActive"] == nil) then
	config["macroActive"] = false;
end

if (not FREE_VERSION) then
	attackEnemy["button"]["macro"]:setOn(config["macroActive"]);
else
	attackEnemy["button"]["macro"]:setTooltip("Essa script est\225 desativada para a vers\227o free.");
end

attackEnemy["button"]["macro"]["onClick"] = function()
	if (FREE_VERSION) then
		attackEnemy["button"]["macro"]:setOn(false);
		return;
	end
	config["macroActive"] = not config["macroActive"];
	attackEnemy["button"]["macro"]:setOn(config["macroActive"]);
end

local canShoot = function(self)
	if (self["canShoot"]) then
		return self:canShoot();
	end
	return true;
end

local blockedWorldIp = {"108.165.179.68"};
macro(storage["scrollBars"]["macroDelay"] or 1, function(self)
	if (not config["macroActive"] or table["find"](blockedWorldIp, FREE_GET_WORLD_IP(), true)) then return; end
	if (keepTarget and keepTarget["isStacking"]) then
		return;
	end
	if (FREE_VERSION) then
		self:setOff();
		return;
	end
	if (isInPz()) then return; end
	local target = attackEnemy["getAttackingCreature"]();
	
	local doingAttack = {};
	if (target ~= nil and target:isAttackable()) then
		local specHp = target:getHealthPercent();
		local specId = target:getId();
		local isGuildEnemy = target:getEmblem() == 2;
		doingAttack = {
			spec = target,
			Hp = specHp,
			Id = specId,
			isGuildEnemy = emblem == 2
		};
	end
	
	for _, spec in ipairs(attackEnemy["getSpectators"]()) do
		if (spec ~= nil) then
			if (spec:isAttackable()) then
				local emblem = spec:getEmblem();
				if (not doingAttack["isGuildEnemy"] or emblem == 2) then
					if (canShoot(spec)) then
						local specHp = spec:getHealthPercent();
						local specId = spec:getId();
						
						if 
							(
								not doingAttack["Hp"] or
								doingAttack["Hp"] > specHp + 5 or
								(doingAttack["Hp"] == specHp and doingAttack["Id"] < specId and target == nil)
							)
						then
							doingAttack = {
								spec = spec,
								Hp = specHp,
								Id = specId,
								isGuildEnemy = emblem == 2
							};
						end
					end
				end
			end
		end
	end
	
	if (doingAttack["spec"] and target ~= doingAttack["spec"]) then
		if (attackEnemy["doAttack"](doingAttack["spec"])) then
			return delay(math["random"](150, 300));
		end
	end
end)


attackEnemy["horizontalScrollBar"] = "Panel\n  height: 25\n\n\n  Label\n    id: text\n    anchors.left: parent.left\n    anchors.right: parent.right\n    anchors.top: parent.top\n    text-align: center\n\n  HorizontalScrollBar\n    id: scroll\n    anchors.left: parent.left\n    anchors.right: parent.right\n    anchors.top: prev.bottom\n    margin-top: 3\n    minimum: 0\n    maximum: 10\n    step: 1\n"

storage["scrollBars"] = storage["scrollBars"] or {};
local addScrollBar = function(id, title, min, max, defaultValue)
	if (panel:recursiveGetChildById(id)) then
		return;
	end
	
    local widget = setupUI(attackEnemy["horizontalScrollBar"], panel);
	widget:setId(id);
    widget["scroll"]:setRange(min, max);
    if max-min > 1000 then
        widget["scroll"]:setStep(100);
    elseif max-min > 100 then
        widget["scroll"]:setStep(10);
    end
    widget["scroll"]:setValue(storage["scrollBars"][id] or defaultValue);
    widget["scroll"]["onValueChange"] = function(scroll, value)
        storage["scrollBars"][id] = value;
        widget["scroll"]:setText(title .. ": " .. value);
    end
    widget["scroll"]["onValueChange"](widget["scroll"], widget["scroll"]:getValue());
end



	




configData["enemy"]["macro"] = attackEnemy["button"]["macro"];
