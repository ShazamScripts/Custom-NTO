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
CaveBot.Actions = {}

local oldTibia = g_game.getClientVersion() < 960
local nextTile = nil

local noPath = 0

-------------------------------------------------------------------
-- CaveBot lib 1.0
-- Contains a universal set of functions to be used in CaveBot

----------------------[[ basic assumption ]]-----------------------
-- in general, functions cannot be slowed from within, only externally, by event calls, delays etc.
-- considering that and the fact that there is no while loop, every function return action
-- thus, functions will need to be verified outside themselfs or by another function
-- overall tips to creating extension:
--   - functions return action(nil) or true(done)
--   - extensions are controlled by retries var
-------------------------------------------------------------------

-- local variables, constants and functions, used by global functions
local LOCKERS_LIST = {3497, 3498, 3499, 3500}
local LOCKER_ACCESSTILE_MODIFIERS = {
    [3497] = {0,-1},
    [3498] = {1,0},
    [3499] = {0,1},
    [3500] = {-1,0}
}

local function getSafeContainerItemId(container)
    if not container or type(container.getContainerItem) ~= "function" then
        return nil
    end
    local ok, item = pcall(function() return container:getContainerItem() end)
    if not ok or not item or type(item.getId) ~= "function" then
        return nil
    end
    local idOk, id = pcall(function() return item:getId() end)
    return idOk and id or nil
end

local function CaveBotConfigParse()
	local name = tyrBot.storage["_configs"]["targetbot_configs"]["selected"]
    if not name then
        return warn("[vBot] Please create a new TargetBot config and reset bot")
    end
	local file = configDir .. "/targetbot_configs/" .. name .. ".json"
    if not g_resources.fileExists(file) then
        return nil
    end
	local data = g_resources.readFileContents(file)
    local ok, parsed = pcall(Config.parse, data)
    if not ok or type(parsed) ~= "table" then
        return nil
    end
	return parsed['looting']
end

local function getNearTilesTwo(pos)
    if type(pos) ~= "table" then
        pos = FREE_SAFE_POSITION and FREE_SAFE_POSITION(pos) or nil
    end
    if type(pos) ~= "table" or type(pos.x) ~= "number" or type(pos.y) ~= "number" or type(pos.z) ~= "number" then
        return {}
    end

    local tiles = {}
    local dirs = {
        {-1, 1},
        {0, 1},
        {1, 1},
        {-1, 0},
        {1, 0},
        {-1, -1},
        {0, -1},
        {1, -1}
    }
    for i = 1, #dirs do
        local tile =
            g_map.getTile(
            {
                x = pos.x - dirs[i][1],
                y = pos.y - dirs[i][2],
                z = pos.z
            }
        )
        if tile then
            table.insert(tiles, tile)
        end
    end

    return tiles
end

-- ##################### --
-- [[ Information class ]] --
-- ##################### --

--- global variable to reflect current CaveBot status
CaveBot.Status = "waiting"

--- Parses config and extracts loot list.
-- @return table
function CaveBot.GetLootItems()
    local t = CaveBotConfigParse() and CaveBotConfigParse()["items"] or nil

    local returnTable = {}
    if type(t) == "table" then
        for i, item in pairs(t) do
            table.insert(returnTable, item["id"])
        end
    end

    return returnTable
end


--- Checks whether player has any visible items to be stashed
-- @return boolean
function CaveBot.HasLootItems()
    for _, container in pairs(getContainers()) do
        local name = container:getName():lower()
        if not name:find("depot") and not name:find("your inbox") then
            for _, item in pairs(container:getItems()) do
                local id = item:getId()
                if table.find(CaveBot.GetLootItems(), id) then
                    return true
                end
            end
        end
    end
end

--- Parses config and extracts loot containers.
-- @return table
function CaveBot.GetLootContainers()
    local t = CaveBotConfigParse() and CaveBotConfigParse()["containers"] or nil

    local returnTable = {}
    if type(t) == "table" then
        for i, container in pairs(t) do
            table.insert(returnTable, container["id"])
        end
    end

    return returnTable
end

--- Information about open containers.
-- @param amount is boolean
-- @return table or integer
function CaveBot.GetOpenedLootContainers(containerTable)
    local containers = CaveBot.GetLootContainers()

    local t = {}
    for i, container in pairs(getContainers()) do
        local containerId = getSafeContainerItemId(container)
        if table.find(containers, containerId) then
            table.insert(t, container)
        end
    end

    return containerTable and t or #t
end

--- Some actions needs to be additionally slowed down in case of high ping.
-- Maximum at 2000ms in case of lag spike.
-- @param multiplayer is integer
-- @return void
function CaveBot.PingDelay(multiplayer)
    multiplayer = multiplayer or 1
    if ping() and ping() > 150 then -- in most cases ping above 150 affects CaveBot
        local value = math.min(ping() * multiplayer, 2000)
        return delay(value)
    end
end

-- ##################### --
-- [[ Container class ]] --
-- ##################### --

--- Closes any loot container that is open.
-- @return void or boolean
function CaveBot.CloseLootContainer()
    local containers = CaveBot.GetLootContainers()

    for i, container in pairs(getContainers()) do
        local containerId = getSafeContainerItemId(container)
        if table.find(containers, containerId) then
            return g_game.close(container)
        end
    end

    return true
end

function CaveBot.CloseAllLootContainers()
    local containers = CaveBot.GetLootContainers()

    for i, container in pairs(getContainers()) do
        local containerId = getSafeContainerItemId(container)
        if table.find(containers, containerId) then
            g_game.close(container)
        end
    end

    return true
end

--- Opens any loot container that isn't already opened.
-- @return void or boolean
function CaveBot.OpenLootContainer()
    local containers = CaveBot.GetLootContainers()

    local t = {}
    for i, container in pairs(getContainers()) do
        local containerId = getSafeContainerItemId(container)
        table.insert(t, containerId)
    end

    for _, container in pairs(getContainers()) do
        for _, item in pairs(container:getItems()) do
            local id = item:getId()
            if table.find(containers, id) and not table.find(t, id) then
                return g_game.open(item)
            end
        end
    end

    return true
end

-- ##################### --
-- [[[ Position class ]] --
-- ##################### --

--- Compares distance between player position and given pos.
-- @param position is table
-- @param distance is integer
-- @return boolean
function CaveBot.MatchPosition(position, distance)
    local pPos = player:getPosition()
    distance = distance or 1
    if not pPos or not position then
        return false
    end
    return getDistanceBetween(pPos, position) <= distance
end

--- Stripped down to take less space.
-- Use only to safe position, like pz movement or reaching npc.
-- Needs to be called between 200-500ms to achieve fluid movement.
-- @param position is table
-- @param distance is integer
-- @return void
function CaveBot.GoTo(position, precision)
    if not precision then
        precision = 3
    end
    return CaveBot.walkTo(position, 20, {ignoreCreatures = true, precision = precision})
end

--- Finds position of npc by name and reaches its position.
-- @return void(acion) or boolean
function CaveBot.ReachNPC(name)
    name = name:lower()

    local npc = nil
    for i, spec in pairs(getSpectators()) do
        if spec:isNpc() and spec:getName():lower() == name then
            npc = spec
        end
    end

    if not npc then
        return false
    end

    local npcPos = npc:getPosition()
    if not npcPos then
        return false
    end

    if not CaveBot.MatchPosition(npcPos, 3) then
        CaveBot.GoTo(npcPos)
    else
        return true
    end
end

-- ##################### --
-- [[[[ Depot class ]]]] --
-- ##################### --

--- Reaches closest locker.
-- @return void(acion) or boolean

local depositerLockerTarget = nil
local depositerLockerReachRetries = 0
function CaveBot.ReachDepot()
    local pPos = player:getPosition()
    local tiles = getNearTilesTwo(player:getPosition())

    for i, tile in pairs(tiles) do
        for i, item in pairs(tile:getItems()) do
            if table.find(LOCKERS_LIST, item:getId()) then
                depositerLockerTarget = nil
                depositerLockerReachRetries = 0
                return true -- if near locker already then return function
            end
        end
    end

    if depositerLockerReachRetries > 20 then
        depositerLockerTarget = nil
        depositerLockerReachRetries = 0
    end

    local candidates = {}

    if not depositerLockerTarget or distanceFromPlayer(depositerLockerTarget, pPos) > 12 then
        for i, tile in pairs(g_map.getTiles(posz())) do
            local tPos = tile:getPosition()
            for i, item in pairs(tile:getItems()) do
                if table.find(LOCKERS_LIST, item:getId()) then
                    local lockerTilePos = tile:getPosition()
                          lockerTilePos.x = lockerTilePos.x + LOCKER_ACCESSTILE_MODIFIERS[item:getId()][1]
                          lockerTilePos.y = lockerTilePos.y + LOCKER_ACCESSTILE_MODIFIERS[item:getId()][2]
                    local lockerTile = g_map.getTile(lockerTilePos)
                    if not lockerTile:hasCreature() then
                        if findPath(pos(), tPos, 20, {ignoreNonPathable = false, precision = 1, ignoreCreatures = true}) then
                            local distance = getDistanceBetween(tPos, pPos)
                            table.insert(candidates, {pos=tPos, dist=distance})
                        end
                    end
                end
            end
        end

        if #candidates > 1 then
            table.sort(candidates, function(a,b) return a.dist < b.dist end)
        end
    end

    if not depositerLockerTarget and candidates[1] then
        depositerLockerTarget = candidates[1].pos
    end

    if depositerLockerTarget then
        if not CaveBot.MatchPosition(depositerLockerTarget) then
            depositerLockerReachRetries = depositerLockerReachRetries + 1
            return CaveBot.GoTo(depositerLockerTarget, 1)
        else
            depositerLockerReachRetries = 0
            depositerLockerTarget = nil
            return true
        end
    end

    -- Nenhum locker alcancavel encontrado neste ciclo. Evita retornar nil
    -- para o executor do CaveBot e permite que a acao seja tentada novamente.
    delay(300)
    return "retry"
end

--- Opens locker item.
-- @return void(acion) or boolean
function CaveBot.OpenLocker()
    local pPos = player:getPosition()
    local tiles = getNearTilesTwo(player:getPosition())

    local locker = getContainerByName("Locker")
    if not locker then
        for i, tile in pairs(tiles) do
            for i, item in pairs(tile:getItems()) do
                if table.find(LOCKERS_LIST, item:getId()) then
                    local topThing = tile:getTopUseThing()
                    if not topThing:isNotMoveable() then
                        g_game.move(topThing, pPos, topThing:getCount())
                    else
                        return g_game.open(item)
                    end
                end
            end
        end
    else
        return true
    end
end

--- Opens depot chest.
-- @return void(acion) or boolean
function CaveBot.OpenDepotChest()
    local depot = getContainerByName("Depot chest")
    if not depot then
        local locker = getContainerByName("Locker")
        if not locker then
            return CaveBot.OpenLocker()
        end
        for i, item in pairs(locker:getItems()) do
            if item:getId() == 3502 then
                return g_game.open(item, locker)
            end
        end
    else
        return true
    end
end

--- Opens inbox inside locker.
-- @return void(acion) or boolean
function CaveBot.OpenInbox()
    local inbox = getContainerByName("Your inbox")
    if not inbox then
        local locker = getContainerByName("Locker")
        if not locker then
            return CaveBot.OpenLocker()
        end
        for i, item in pairs(locker:getItems()) do
            if item:getId() == 12902 then
                return g_game.open(item)
            end
        end
    else
        return true
    end
end

--- Opens depot box of given number.
-- @param index is integer
-- @return void or boolean
function CaveBot.OpenDepotBox(index)
    local depot = getContainerByName("Depot chest")
    if not depot then
        return CaveBot.ReachAndOpenDepot()
    end

    local foundParent = false
    for i, container in pairs(getContainers()) do
        if container:getName():lower():find("depot box") then
            foundParent = container
            break
        end
    end
    if foundParent then return true end

    for i, container in pairs(depot:getItems()) do
        if i == index then
            return g_game.open(container)
        end
    end
end

--- Reaches and opens depot.
-- Combined for shorthand usage.
-- @return boolean whether succeed to reach and open depot
function CaveBot.ReachAndOpenDepot()
    if CaveBot.ReachDepot() and CaveBot.OpenDepotChest() then
        return true
    end
    return false
end

--- Reaches and opens imbox.
-- Combined for shorthand usage.
-- @return boolean whether succeed to reach and open depot
function CaveBot.ReachAndOpenInbox()
    if CaveBot.ReachDepot() and CaveBot.OpenInbox() then
        return true
    end
    return false
end

--- Stripped down function to stash item.
-- @param item is object
-- @param index is integer
-- @param destination is object
-- @return void
function CaveBot.StashItem(item, index, destination)
    destination = destination or getContainerByName("Depot chest")
    if not destination then return false end

    return g_game.move(item, destination:getSlotPosition(index), item:getCount())
end

--- Withdraws item from depot chest or mail inbox.
-- main function for depositer/withdrawer
-- @param id is integer
-- @param amount is integer
-- @param fromDepot is boolean or integer
-- @param destination is object
-- @return void
function CaveBot.WithdrawItem(id, amount, fromDepot, destination)
    if destination and type(destination) == "string" then
        destination = getContainerByName(destination)
    end
    local itemCount = itemAmount(id)
    local depot
    for i, container in pairs(getContainers()) do
        if container:getName():lower():find("depot box") or container:getName():lower():find("your inbox") then
            depot = container
            break
        end
    end
    if not depot then
        if fromDepot then
            if not CaveBot.OpenDepotBox(fromDepot) then return end
        else
            return CaveBot.ReachAndOpenInbox()
        end
        return
    end
    if not destination then
        for i, container in pairs(getContainers()) do
            if container:getCapacity() > #container:getItems() and not string.find(container:getName():lower(), "quiver") and not string.find(container:getName():lower(), "depot") and not string.find(container:getName():lower(), "loot") and not string.find(container:getName():lower(), "inbox") then
                destination = container
            end
        end
    end

    if itemCount >= amount then
        return true
    end

    local toMove = amount - itemCount
    for i, item in pairs(depot:getItems()) do
        if item:getId() == id then
            return g_game.move(item, destination:getSlotPosition(destination:getItemsCount()), math.min(toMove, item:getCount()))
        end
    end
end

-- ##################### --
-- [[[[[ Talk class ]]]] --
-- ##################### --

--- Controlled by event caller.
-- Simple way to build npc conversations instead of multiline overcopied code.
-- @return void
function CaveBot.Conversation(...)
    local expressions = {...}
    local delay = 1000

    local talkDelay = 0
    for i, expr in ipairs(expressions) do
        schedule(talkDelay, function() NPC.say(expr) end)
        talkDelay = talkDelay + delay
    end
end

--- Says hi trade to NPC.
-- Used as shorthand to open NPC trade window.
-- @return void
function CaveBot.OpenNpcTrade()
    return CaveBot.Conversation("hi", "trade")
end

--- Says hi destination yes to NPC.
-- Used as shorthand to travel.
-- @param destination is string
-- @return void
function CaveBot.Travel(destination)
    return CaveBot.Conversation("hi", destination, "yes")
end

-- antistuck f()
local nextPos = nil -- creature
local nextPosF = nil -- furniture
local function modPos(dir)
    local y = 0
    local x = 0

    if dir == 0 then
        y = -1
    elseif dir == 1 then
        x = 1
    elseif dir == 2 then
        y = 1
    elseif dir == 3 then
        x = -1
    elseif dir == 4 then
        y = -1
        x = 1
    elseif dir == 5 then
        y = 1
        x = 1
    elseif dir == 6 then
        y = 1
        x = -1
    elseif dir == 7 then
        y = -1
        x = -1
    end

    return {x, y}
end

function getNearTiles(pos)
  if type(pos) ~= "table" then
    if pos and type(pos.getPosition) == "function" then
      local ok, value = pcall(function() return pos:getPosition() end)
      pos = ok and value or nil
    else
      pos = player and player:getPosition() or nil
    end
  end

  if type(pos) ~= "table" or type(pos.x) ~= "number" or type(pos.y) ~= "number" or type(pos.z) ~= "number" then
    return {}
  end

  local tiles = {}
  local dirs = {
      {-1, 1}, {0, 1}, {1, 1}, {-1, 0}, {1, 0}, {-1, -1}, {0, -1}, {1, -1}
  }
  for i = 1, #dirs do
      local tile = g_map.getTile({
          x = pos.x - dirs[i][1],
          y = pos.y - dirs[i][2],
          z = pos.z
      })
      if tile then table.insert(tiles, tile) end
  end

  return tiles
end

-- self explanatory
-- use along with delay, it will only call action
function useGroundItem(id)
  if not id then return false end

  local dest = nil
  for i, tile in ipairs(g_map.getTiles(posz())) do
      for j, item in ipairs(tile:getItems()) do
          if item:getId() == id then
              dest = item
              break
          end
      end
  end

  if dest then
      return use(dest)
  else
      return false
  end
end

function distanceFromPlayer(coords, origin)
    if not coords then return math.huge end
    origin = origin or (type(pos) == "function" and pos() or nil)
    if not origin then return math.huge end
    return FREE_SAFE_DISTANCE and FREE_SAFE_DISTANCE(origin, coords) or getDistanceBetween(origin, coords)
end

function itemAmount(id)
  return player:getItemsCount(id)
end

function getContainerByItem(id, notFull)
  if type(id) ~= "number" then return nil end

  local d = nil
  for i, c in pairs(getContainers()) do
      if getSafeContainerItemId(c) == id and (not notFull or not containerIsFull(c)) then
          d = c
          break
      end
  end
  return d
end

-- stack-covered antystuck, in & out pz
local lastMoved = now - 200
onTextMessage(function(mode, text)
  if text ~= 'There is not enough room.' then return end
  if CaveBot.isOff() then return end

  local tiles = getNearTiles(pos())

  for i, tile in ipairs(tiles) do
    if not tile:hasCreature() and tile:isWalkable() and #tile:getItems() > 9 then
      local topThing = tile:getTopThing()
      if not isInPz() then
        return useWith(3197, tile:getTopThing()) -- disintegrate
      else
        if now < lastMoved + 200 then return end -- delay to prevent clogging
        local nearTiles = getNearTiles(tile:getPosition())
        for i, tile in ipairs(nearTiles) do
          local tpos = tile:getPosition()
          if pos() ~= tpos then
            if tile:isWalkable() then
              lastMoved = now
              return g_game.move(topThing, tpos) -- move item
            end
          end
        end
      end
    end
  end
end)

local furnitureIgnore = { 2986 }
local function breakFurniture(destPos)
  if isInPz() then return false end
  local candidate = {thing=nil, dist=100}
  for i, tile in ipairs(g_map.getTiles(posz())) do
    local walkable = tile:isWalkable()
    local topThing = tile:getTopThing()
    local isWg = topThing and topThing:getId() == 2130
    if topThing and (isWg or not table.find(furnitureIgnore, topThing:getId()) and topThing:isItem()) then
      local moveable = not topThing:isNotMoveable()
      local tpos = tile:getPosition()
      local path = findPath(player:getPosition(), tpos, 7, { ignoreNonPathable = true, precision = 1 })

      if path then
        if isWg or (not walkable and moveable) then
          local distance = getDistanceBetween(destPos, tpos)

          if distance < candidate.dist then
            candidate = {thing=topThing, dist=distance}
          end
        end
      end
    end
  end

  local thing = candidate.thing
  if thing then
    useWith(3197, thing)
    return true
  end

  return false
end

local function pushPlayer(creature)
  local cpos = creature:getPosition()
  local tiles = getNearTiles(cpos)

  for i, tile in ipairs(tiles) do
    local pos = tile:getPosition()
    local minimapColor = g_map.getMinimapColor(pos)
    local stairs = (minimapColor >= 210 and minimapColor <= 213)

    if not stairs and tile:isWalkable() then
      g_game.move(creature, pos)
    end
  end

end

local function pathfinder()
  if not tyrBot.storage.pathfinding then return end
  if noPath < 10 then return end

  if not CaveBot.gotoNextWaypointInRange() then
    if getConfigFromName and getConfigFromName() then
      local profile = CaveBot.getCurrentProfile()
      local config = getConfigFromName()
      local newProfile = profile == '#Unibase' and config or '#Unibase'

      CaveBot.setCurrentProfile(newProfile)
    end
  end
  noPath = 0
  return true
end

function getBestTileByPatern(pattern, specType, maxDist, safe)
    if not pattern or not specType then return end
    if not maxDist then maxDist = 4 end

    local bestTile = nil
    local best = nil
    for _, tile in pairs(g_map.getTiles(posz())) do
        if distanceFromPlayer(tile:getPosition()) <= maxDist then
            local minimapColor = g_map.getMinimapColor(tile:getPosition())
            local stairs = (minimapColor >= 210 and minimapColor <= 213)
            if tile:canShoot() and tile:isWalkable() then
                if getCreaturesInArea(tile:getPosition(), pattern, specType) > 0 then
                    if (not safe or
                        getCreaturesInArea(tile:getPosition(), pattern, 3) == 0) then
                        local candidate =
                            {
                                pos = tile,
                                count = getCreaturesInArea(tile:getPosition(),
                                                           pattern, specType)
                            }
                        if not best or best.count <= candidate.count then
                            best = candidate
                        end
                    end
                end
            end
        end
    end

    bestTile = best

    if bestTile then
        return bestTile
    else
        return false
    end
end

-- returns container object based on name
function getContainerByName(name, notFull)
    if type(name) ~= "string" then return nil end

    local d = nil
    for i, c in pairs(getContainers()) do
        if c:getName():lower() == name:lower() and (not notFull or not containerIsFull(c)) then
            d = c
            break
        end
    end
    return d
end

-- returns container object based on container ID
function getContainerByItem(id, notFull)
    if type(id) ~= "number" then return nil end

    local d = nil
    for i, c in pairs(getContainers()) do
        if getSafeContainerItemId(c) == id and (not notFull or not containerIsFull(c)) then
            d = c
            break
        end
    end
    return d
end

-- it adds an action widget to list
CaveBot.addAction = function(action, value, focus)
    action = action:lower()
    local raction = CaveBot.Actions[action]
    if not raction then
        return error("Invalid cavebot action: " .. action)
    end
    if type(value) == 'number' then
        value = tostring(value)
    end
    local widget = UI.createWidget("CaveBotAction", CaveBot.actionList)
    widget:setText(action .. ":" .. value:split("\n")[1])
    widget.action = action
    widget.value = value
    if raction.color then
        widget:setColor(raction.color)
    end
    widget.onDoubleClick = function(cwidget) -- edit on double click
        if CaveBot.Editor then
            schedule(20, function() -- schedule to have correct focus
                CaveBot.Editor.edit(cwidget.action, cwidget.value, function(action, value)
                    CaveBot.editAction(cwidget, action, value)
                    CaveBot.save()
                end)
            end)
    end
    end
    if focus then
        widget:focus()
        CaveBot.actionList:ensureChildVisible(widget)
    end
    return widget
end

-- it updates existing widget, you should call CaveBot.save() later
CaveBot.editAction = function(widget, action, value)
    action = action:lower()
    local raction = CaveBot.Actions[action]
    if not raction then
        return error("Invalid cavebot action: " .. action)
    end

    if not widget.action or not widget.value then
        return error("Invalid cavebot action widget, has missing action or value")
    end

    widget:setText(action .. ":" .. value:split("\n")[1])
    widget.action = action
    widget.value = value
    if raction.color then
        widget:setColor(raction.color)
    end
    return widget
end

--[[
registerAction:
action - string, color - string, callback = function(value, retries, prev)
value is a string value of action, retries is number which will grow by 1 if return is "retry"
prev is a true when previuos action was executed succesfully, false otherwise
it must return true if executed correctly, false otherwise
it can also return string "retry", then the function will be called again in 20 ms
]]--
CaveBot.registerAction = function(action, color, callback)
    action = action:lower()
    if CaveBot.Actions[action] then
        return error("Duplicated acction: " .. action)
    end
    CaveBot.Actions[action] = {
        color=color,
        callback=callback
    }
end

CaveBot.registerAction("label", "yellow", function(value, retries, prev)
    return true
end)

CaveBot.registerAction("gotolabel", "#FFFF55", function(value, retries, prev)
    return CaveBot.gotoLabel(value)
end)

CaveBot.registerAction("delay", "#AAAAAA", function(value, retries, prev)
    if retries == 0 then
      local data = string.split(value, ",")
      local val = tonumber(data[1]:trim())
      local random
      local final


      if #data == 2 then
        random = tonumber(data[2]:trim())
      end

      if random then
        local diff = (val/100) * random
        local min = val - diff
        local max = val + diff
        final = math.random(min, max)
      end
      final = final or val

      CaveBot.delay(final)
      return "retry"
    end
    return true
end)

CaveBot.registerAction("follow", "#FF8400", function(value, retries, prev)
    local c = getCreatureByName(value)
    if not c then
      print("CaveBot[follow]: can't find creature to follow")
      return false
    end
    local cpos = c:getPosition()
    local pos = pos()
    if getDistanceBetween(cpos, pos) < 2 then
      g_game.cancelFollow()
      return true
    else
      follow(c)
      delay(200)
      return "retry"
    end
end)

CaveBot.registerAction("function", "red", function(value, retries, prev)
    local prefix = "local retries = " .. retries .. "\nlocal prev = " .. tostring(prev) .. "\nlocal delay = CaveBot.delay\nlocal gotoLabel = CaveBot.gotoLabel\n"
    prefix = prefix .. "local macro = function() error('Macros inside cavebot functions are not allowed') end\n"
    for extension, callbacks in pairs(CaveBot.Extensions) do
        prefix = prefix .. "local " .. extension .. " = CaveBot.Extensions." .. extension .. "\n"
    end
    local status, result = pcall(function()
        return assert(load(prefix .. value, "cavebot_function"))()
    end)
    if not status then
        error("Error in cavebot function:\n" .. result)
        return false
    end

    -- O executor exige explicitamente true, false ou "retry".
    -- Funcoes personalizadas que terminam sem return produzem nil e
    -- quebravam o executor.lua com "Invalid return from cavebot action".
    if result == nil then
        warn("[Shazam Safety] CaveBot function terminou sem return; tratado como false.")
        return false
    end

    if result ~= true and result ~= false and result ~= "retry" then
        warn("[Shazam Safety] CaveBot function retornou valor invalido (" .. tostring(result) .. "); tratado como false.")
        return false
    end

    return result
end)

CaveBot.registerAction("goto", "green", function(value, retries, prev)
    local pos = regexMatch(value, "\\s*([0-9]+)\\s*,\\s*([0-9]+)\\s*,\\s*([0-9]+),?\\s*([0-9]?)")
    if not pos[1] then
      warn("Invalid cavebot goto action value. It should be position (x,y,z), is: " .. value)
      return false
    end

    -- reset pathfinder
    nextPosF = nil
    nextPos = nil

    if CaveBot.Config.get("mapClick") then
      if retries >= 5 then
        noPath = noPath + 1
        pathfinder()
        return false -- tried 5 times, can't get there
      end
    else
      if retries >= 100 then
        noPath = noPath + 1
        pathfinder()
        return false -- tried 100 times, can't get there
      end
    end

    local precision = tonumber(pos[1][5])
    pos = {x=tonumber(pos[1][2]), y=tonumber(pos[1][3]), z=tonumber(pos[1][4])}
    local playerPos = player:getPosition()
    if pos.z ~= playerPos.z then
      noPath = noPath + 1
      pathfinder()
      return false -- different floor
    end

    local maxDist = tyrBot.storage.gotoMaxDistance or 40

    if math.abs(pos.x-playerPos.x) + math.abs(pos.y-playerPos.y) > maxDist then
      noPath = noPath + 1
      pathfinder()
      return false -- too far way
    end

    local minimapColor = g_map.getMinimapColor(pos)
    local stairs = (minimapColor >= 210 and minimapColor <= 213)

    if stairs then
      if math.abs(pos.x-playerPos.x) == 0 and math.abs(pos.y-playerPos.y) <= 0 then
        noPath = 0
        return true -- already at position
      end
    elseif math.abs(pos.x-playerPos.x) == 0 and math.abs(pos.y-playerPos.y) <= (precision or 1) then
        noPath = 0
        return true -- already at position
    end
    -- check if there's a path to that place, ignore creatures and fields
    local path = findPath(playerPos, pos, maxDist, { ignoreNonPathable = true, precision = 1, ignoreCreatures = true, allowUnseen = true, allowOnlyVisibleTiles = false  })
    if not path then
      if breakFurniture(pos, tyrBot.storage.machete) then
        CaveBot.delay(1000)
        retries = 0
        return "retry"
      end
      noPath = noPath + 1
      pathfinder()
      return false -- there's no way
    end

    -- local path2 = findPath(playerPos, pos, maxDist, { ignoreNonPathable = true, precision = 1 })
    -- if not path2 then
      -- local foundMonster = false
      -- for i, dir in ipairs(path) do
        -- local dirs = modPos(dir)
        -- nextPos = nextPos or playerPos
        -- nextPos.x = nextPos.x + dirs[1]
        -- nextPos.y = nextPos.y + dirs[2]

        -- local tile = g_map.getTile(nextPos)
        -- if tile then
            -- if tile:hasCreature() then
                -- local creature = tile:getCreatures()[1]
                -- local hppc = creature:getHealthPercent()
                -- if creature:isMonster() and (hppc and hppc > 0) and (oldTibia or creature:getType() < 3) then
                    -- local path = findPath(playerPos, creature:getPosition(), 7, { ignoreNonPathable = true, precision = 1 })
                    -- if path then
                        -- foundMonster = true
                        -- if g_game.getAttackingCreature() ~= creature then
                          -- if distanceFromPlayer(creature:getPosition()) > 3 then
                            -- CaveBot.walkTo(creature:getPosition(), 7, { ignoreNonPathable = true, precision = 1 })
                          -- else
                            -- attack(creature)
                          -- end
                        -- end
                        -- g_game.setChaseMode(1)
                        -- CaveBot.delay(100)
                        -- retries = 0 
                        -- break
                    -- end
                -- end
            -- end
        -- end
      -- end

      -- if not foundMonster then
        -- foundMonster = false
        -- return false 
      -- end
    -- end

    -- try to find path, don't ignore creatures, don't ignore fields
    if not CaveBot.Config.get("ignoreFields") and CaveBot.walkTo(pos, 40) then
      return "retry"
    end

    -- try to find path, don't ignore creatures, ignore fields
    if CaveBot.walkTo(pos, maxDist, { ignoreNonPathable = true, allowUnseen = true, allowOnlyVisibleTiles = false }) then
      return "retry"
    end

    if retries >= 3 then
      -- try to lower precision, find something close to final position
      local precison = retries - 1
      if stairs then
        precison = 0
      end
      if CaveBot.walkTo(pos, 50, { ignoreNonPathable = true, precision = precison, allowUnseen = true, allowOnlyVisibleTiles = false }) then
        return "retry"
      end
    end

    if not CaveBot.Config.get("mapClick") and retries >= 5 then
      noPath = noPath + 1
      pathfinder()
      return false
    end

    if CaveBot.Config.get("skipBlocked") then
      noPath = noPath + 1
      pathfinder()
      return false
    end

    -- everything else failed, try to walk ignoring creatures, maybe will work
    CaveBot.walkTo(pos, maxDist, { ignoreNonPathable = true, precision = 1, ignoreCreatures = true, allowUnseen = true, allowOnlyVisibleTiles = false })
    return "retry"
end)

CaveBot.registerAction("use", "#FFB272", function(value, retries, prev)
    local pos = regexMatch(value, "\\s*([0-9]+)\\s*,\\s*([0-9]+)\\s*,\\s*([0-9]+)")
    if not pos[1] then
      local itemid = tonumber(value)
      if not itemid then
        warn("Invalid cavebot use action value. It should be (x,y,z) or item id, is: " .. value)
        return false
      end
      use(itemid)
      return true
    end

    pos = {x=tonumber(pos[1][2]), y=tonumber(pos[1][3]), z=tonumber(pos[1][4])}
    local playerPos = player:getPosition()
    if pos.z ~= playerPos.z then
      return false -- different floor
    end

    if math.max(math.abs(pos.x-playerPos.x), math.abs(pos.y-playerPos.y)) > 7 then
      return false -- too far way
    end

    local tile = g_map.getTile(pos)
    if not tile then
      return false
    end

    local topThing = tile:getTopUseThing()
    if not topThing then
      return false
    end

    use(topThing)
    CaveBot.delay(CaveBot.Config.get("useDelay") + CaveBot.Config.get("ping"))
    return true
end)

CaveBot.registerAction("usewith", "#EEB292", function(value, retries, prev)
    local pos = regexMatch(value, "\\s*([0-9]+)\\s*,\\s*([0-9]+)\\s*,\\s*([0-9]+)\\s*,\\s*([0-9]+)")
    if not pos[1] then
      if not itemid then
        warn("Invalid cavebot usewith action value. It should be (itemid,x,y,z) or item id, is: " .. value)
        return false
      end
      use(itemid)
      return true
    end

    local itemid = tonumber(pos[1][2])
    pos = {x=tonumber(pos[1][3]), y=tonumber(pos[1][4]), z=tonumber(pos[1][5])}
    local playerPos = player:getPosition()
    if pos.z ~= playerPos.z then
      return false -- different floor
    end

    if math.max(math.abs(pos.x-playerPos.x), math.abs(pos.y-playerPos.y)) > 7 then
      return false -- too far way
    end

    local tile = g_map.getTile(pos)
    if not tile then
      return false
    end

    local topThing = tile:getTopUseThing()
    if not topThing then
      return false
    end

    usewith(itemid, topThing)
    CaveBot.delay(CaveBot.Config.get("useDelay") + CaveBot.Config.get("ping"))
    return true
end)

CaveBot.registerAction("say", "#FF55FF", function(value, retries, prev)
    say(value)
    return true
end)
CaveBot.registerAction("npcsay", "#FF55FF", function(value, retries, prev)
    NPC.say(value)
    return true
end)
