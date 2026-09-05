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
CaveBot.Editor.ExampleFunctions = {}

local function addExampleFunction(title, text)
  return table.insert(CaveBot.Editor.ExampleFunctions, {title, text:trim()})
end

addExampleFunction("Click to browse example functions", [[
-- available functions/variables:
-- prev - result of previous action (true or false)
-- retries - number of retries of current function, goes up by one when you return "retry"
-- delay(number) - delays bot next action, value in milliseconds
-- gotoLabel(string) - goes to specific label, return true if label exists
-- you can easily access bot extensions, Depositer.run() instead of CaveBot.Extensions.Depositer.run()
-- also you can access bot global variables, like CaveBot, TargetBot
-- use tyrBot.storage variable to store date between calls

-- function should return false, true or "retry"
-- if "retry" is returned, function will be executed again in 20 ms (so better call delay before)

return true
]])

addExampleFunction("Check for PZ and wait until dropped", [[
if retries > 25 or not isPzLocked() then
  return true
else
  if isPoisioned() then
      say("exana pox")
  end
  if isPzLocked() then
      delay(8000)
  end
  return "retry"
end
]])

addExampleFunction("Check for stamina and imbues", [[
  if stamina() < 900 or player:getSkillLevel(11) == 0 then CaveBot.setOff() return false else return true end
]])

addExampleFunction("buy 200 mana potion from npc Eryn", [[
--buy 200 mana potions
local npc = getCreatureByName("Eryn")
if not npc then
  return false
end
if retries > 10 then
  return false
end
local pos = player:getPosition()
local npcPos = npc:getPosition()
if math.max(math.abs(pos.x - npcPos.x), math.abs(pos.y - npcPos.y)) > 3 then
  autoWalk(npcPos, {precision=3})
  delay(300)
  return "retry"
end
if not NPC.isTrading() then
  NPC.say("hi")
  NPC.say("trade")
  delay(200)
  return "retry"
end
NPC.buy(268, 100)
schedule(1000, function()
  -- buy again in 1s
  NPC.buy(268, 100)
  NPC.closeTrade()
  NPC.say("bye")
end)
delay(1200)
return true
]])

addExampleFunction("Say hello 5 times with some delay", [[
--say hello
if retries > 5 then
  return true -- finish
end
say("hello")
delay(100 + retries * 100)
return "retry"
]])

addExampleFunction("Disable TargetBot", [[
TargetBot.setOff()
return true
]])

addExampleFunction("Enable TargetBot", [[
TargetBot.setOn()
return true
]])

addExampleFunction("Enable TargetBot luring", [[
TargetBot.enableLuring()
return true
]])

addExampleFunction("Disable TargetBot luring", [[
TargetBot.disableLuring()
return true
]])

addExampleFunction("Logout", [[
g_game.safeLogout()
delay(1000)
return "retry"
]])

addExampleFunction("Close Loot Containers", [[
CaveBot.CloseAllLootContainers()
delay(3000)
return true
]])