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
CaveBot.Extensions.Tasker = {}

local dataValidationFailed = function()
    print("CaveBot[Tasker]: data validation failed! incorrect data, check cavebot/tasker for more info")
    return false
end

function getNpcs(range, multifloor)
    if not range then range = 10 end
    local npcs = 0;
    for _, spec in pairs(getSpectators(multifloor)) do
        npcs =
            spec:isNpc() and distanceFromPlayer(spec:getPosition()) <= range and
                npcs + 1 or npcs;
    end
    return npcs;
end

-- miniconfig
local talkDelay = 1000
if not tyrBot.storage.caveBotTasker then
    tyrBot.storage.caveBotTasker = {
        inProgress = false,
        monster = "",
        taskName = "",
        count = 0,
        max = 0
    }
end

local resetTaskData = function()
    tyrBot.storage.caveBotTasker.inProgress = false
    tyrBot.storage.caveBotTasker.monster = ""
    tyrBot.storage.caveBotTasker.monster2 = ""
    tyrBot.storage.caveBotTasker.taskName = ""
    tyrBot.storage.caveBotTasker.count = 0
    tyrBot.storage.caveBotTasker.max = 0
end

CaveBot.Extensions.Tasker.setup = function()
  CaveBot.registerAction("Tasker", "#FF0090", function(value, retries)
    local taskName = ""
    local monster = ""
    local monster2 = ""
    local count = 0
    local label1 = ""
    local label2 = ""
    local task

    local data = string.split(value, ",")
    if not data or #data < 1 then
        dataValidationFailed()
    end
    local marker = tonumber(data[1])

    if not marker then
        dataValidationFailed()
        resetTaskData()
    elseif marker == 1 then
        if getNpcs(3) == 0 then
            print("CaveBot[Tasker]: no NPC found in range! skipping")
            return false
        end
        if #data ~= 4 and #data ~= 5 then
            dataValidationFailed()
            resetTaskData()
        else
            taskName = data[2]:lower():trim()
            count = tonumber(data[3]:trim())
            monster = data[4]:lower():trim()
            if #data == 5 then
                monster2 = data[5]:lower():trim()
            end
        end
    elseif marker == 2 then
        if #data ~= 3 then
            dataValidationFailed()
        else
            label1 = data[2]:lower():trim()
            label2 = data[3]:lower():trim()
        end
    elseif marker == 3 then
        if getNpcs(3) == 0 then
            print("CaveBot[Tasker]: no NPC found in range! skipping")
            return false
        end
        if #data ~= 1 then
            dataValidationFailed()
        end
    end

    -- let's cover markers now
    if marker == 1 then -- starting task
        CaveBot.Conversation("hi", "task", taskName, "yes")
        delay(talkDelay*4)

        tyrBot.storage.caveBotTasker.monster = monster
        if monster2 then tyrBot.storage.caveBotTasker.monster2 = monster2 end
        tyrBot.storage.caveBotTasker.taskName = taskName
        tyrBot.storage.caveBotTasker.inProgress = true
        tyrBot.storage.caveBotTasker.max = count
        tyrBot.storage.caveBotTasker.count = 0

        print("CaveBot[Tasker]: taken task for: " .. monster .. " x" .. count)
        return true
    elseif marker == 2 then -- only checking
        if not tyrBot.storage.caveBotTasker.inProgress then
            CaveBot.gotoLabel(label2)
            print("CaveBot[Tasker]: there is no task in progress so going to take one.")
            return true
        end

        local max = tyrBot.storage.caveBotTasker.max
        local count = tyrBot.storage.caveBotTasker.count

        if count >= max then
            CaveBot.gotoLabel(label2)
            print("CaveBot[Tasker]: task completed: " .. tyrBot.storage.caveBotTasker.taskName)
            return true
        else
            CaveBot.gotoLabel(label1)
            print("CaveBot[Tasker]: task in progress, left: " .. max - count .. " " .. tyrBot.storage.caveBotTasker.taskName)
            return true
        end


    elseif marker == 3 then -- reporting task
        CaveBot.Conversation("hi", "report", "task")
        delay(talkDelay*3)

        resetTaskData()
        print("CaveBot[Tasker]: task reported, done")
        return true
    end

  end)

 CaveBot.Editor.registerAction("tasker", "tasker", {
  value=[[     There is 3 scenarios for this extension, as example we will use medusa:

  1. start task,
      parameters:
      - scenario for extension: 1
      - task name in gryzzly adams: medusae
      - monster count: 500
      - monster name to track: medusa
      - optional, monster name 2:
  2. check status,
      to be used on refill to decide whether to go back or spawn or go give task back
      parameters:
      - scenario for extension: 2
      - label if task in progress: skipTask
      - label if task done: taskDone
  3. report task,
      parameters:
      - scenario for extension: 3

  Strong suggestion, almost mandatory - USE POS CHECK to verify position! this module will only check if there is ANY npc in range!

  when begin remove all the text and leave just a single string of parameters
  some examples:

  2, skipReport, goReport
  3
  1, drakens, 500, draken warmaster, draken spellweaver
  1, medusae, 500, medusa]],
  title="Tasker",
  multiline = true
 })
end

local regex = "Loot of ([a-z])* ([a-z A-Z]*):"
local regex2 = "Loot of ([a-z A-Z]*):"
onTextMessage(function(mode, text)
   -- if CaveBot.isOff() then return end
    if not text:lower():find("loot of") then return end
    if #regexMatch(text, regex) == 1 and #regexMatch(text, regex)[1] == 3 then
        monster = regexMatch(text, regex)[1][3]
    elseif #regexMatch(text, regex2) == 1 and #regexMatch(text, regex2)[1] == 2 then
        monster = regexMatch(text, regex2)[1][2]
    end

    local m1 = tyrBot.storage.caveBotTasker.monster
    local m2 = tyrBot.storage.caveBotTasker.monster2

    if monster == m1 or monster == m2 and tyrBot.storage.caveBotTasker.count then
        tyrBot.storage.caveBotTasker.count = tyrBot.storage.caveBotTasker.count + 1
    end
end)