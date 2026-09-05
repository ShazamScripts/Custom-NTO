setDefaultTab("UTI");

-----------------------------------------------------------------------------------------------------------

if not getNeck() then
    say("!jam")
    schedule(2000, function()
        if not getNeck() then
            error("!! Jam não comprado !!")
        end
    end)
end

-----------------------------------------------------------------------------------------------------------

-- config

local keyUp = "="
local keyDown = "-"

-- script

local lockedLevel = pos().z

onPlayerPositionChange(function(newPos, oldPos)
    lockedLevel = pos().z
    modules.game_interface.getMapPanel():unlockVisibleFloor()
end)

onKeyPress(function(keys)
    if keys == keyDown then
        lockedLevel = lockedLevel + 1
        modules.game_interface.getMapPanel():lockVisibleFloor(lockedLevel)
    elseif keys == keyUp then
        lockedLevel = lockedLevel - 1
        modules.game_interface.getMapPanel():lockVisibleFloor(lockedLevel)
    end
end)

-----------------------------------------------------------------------------------------------------------

leaderPositions = {}
local leaderDirections = {}
local leader
local lastLeaderFloor
local ropeId = 9596
local standTime = now
local lastLeaderRemoval
local currentPosition

local function copyPosition(position)
  if not position then return nil end
  local x, y, z = tonumber(position.x), tonumber(position.y), tonumber(position.z)
  if x == nil or y == nil or z == nil then return nil end
  return {x = x, y = y, z = z}
end

local function safeMethod(object, methodName)
  if not object or type(object[methodName]) ~= "function" then return nil end
  local ok, value = pcall(function() return object[methodName](object) end)
  if ok then return value end
  return nil
end

local function isLeaderCreature(creature)
  if not creature or safeMethod(creature, "isPlayer") ~= true then return false end
  local name = safeMethod(creature, "getName")
  local configuredName = tostring(storage.rtsFollow or "")
  return name and configuredName ~= "" and name:lower() == configuredName:lower()
end

local function removedTilePosition(tile)
  return copyPosition(safeMethod(tile, "getPosition"))
end

local function samePosition(first, second)
  return first and second and first.x == second.x and first.y == second.y and first.z == second.z
end

local function followRemovedLeaderTile(tile, creature)
  if ultimateFollow and ultimateFollow.isOff and ultimateFollow.isOff() then return end
  if not player or not currentPosition() or not isLeaderCreature(creature) then return end

  local tilePos = removedTilePosition(tile)
  if not tilePos then return end
  local direction = safeMethod(creature, "getDirection")
  local capturedAt = tonumber(now) or 0

  leaderPositions[tilePos.z] = copyPosition(tilePos)
  lastLeaderFloor = tilePos.z
  if direction ~= nil then leaderDirections[tilePos.z] = direction end
  lastLeaderRemoval = {position = copyPosition(tilePos), tile = tile, at = capturedAt}
  leader = nil

  local walkPrecision = safeMethod(tile, "hasCreature") == false and 0 or 1
  autoWalk(tilePos, 40, {
  ignoreNonPathable = true,
  ignoreCreatures = false,
  precision = walkPrecision
  })
end

currentPosition = function()
  if not g_game or type(g_game.isOnline) ~= "function" or not g_game.isOnline() then
    return nil
  end
  if type(pos) ~= "function" then return nil end
  local ok, position = pcall(pos)
  if ok and position then return position end
  return nil
end

FloorChangers = {
RopeSpots = {
Up = {386, 12202, 211966},
Down = {}
},

Use = {
Up = {1948, 14559, 5542, 16693, 16692, 1723, 7771, 28906, 20474, 33770, 33985, 5129, 5111, 16277, 37001, 28906},
Down = {435, 28906, 1648, 1646, 8912, 8911, 32642, 5952, 1644, 25054, 1764, 1968}
}
}

local function getPlayerByName(name)
  if not name then
    return nil
  end

  local center = currentPosition()
  if not center or not g_map or type(g_map.getSpectators) ~= "function" then return nil end
  local spectators = type(OblivionGetSpectatorsCached) == "function"
    and OblivionGetSpectatorsCached(false) or nil
  if type(spectators) ~= "table" then
    local ok
    ok, spectators = pcall(function() return g_map.getSpectators(center, false) end)
    if not ok or type(spectators) ~= "table" then return nil end
  end

  local wantedName = tostring(name):lower()

  for _, creature in ipairs(spectators) do
    if creature:isPlayer() and creature:getName():lower() == wantedName then
      return creature
    end
  end

  return nil
end

-- Algumas builds deste client nao exportam o helper global levitate. Nesse
-- caso a acao nao existia de qualquer forma, mas a tentativa gerava um erro a
-- cada ciclo do follow e alimentava o log sem parar.
local function tryLevitate(direction)
  if type(levitate) ~= "function" then return false end
  local ok = pcall(levitate, direction)
  return ok
end

local function handleUse(pos)
  local lastZ = posz()
  if posz() == lastZ then
    local newTile = g_map.getTile({x = pos.x, y = pos.y, z = pos.z})
    if newTile then
      g_game.use(newTile:getTopUseThing())
    end
  end
end

local function handleRope(pos)
  local lastZ = posz()
  if posz() == lastZ then
    local newTile = g_map.getTile({x = pos.x, y = pos.y, z = pos.z})
    if newTile then
      useWith(ropeId, newTile:getTopUseThing())
    end
  end
end

local floorChangeSelector = {
RopeSpots = {Up = handleRope, Down = handleRope},
Use = {Up = handleUse, Down = handleUse}
}

local function distance(pos1, pos2)
  local pos2 = pos2 or player:getPosition()
  return math.abs(pos1.x - pos2.x) + math.abs(pos1.y - pos2.y)
end

local function executeClosest(possibilities)
  local closest
  local closestDistance = 99999

  for _, data in ipairs(possibilities) do
    local dist = distance(data.pos)

    if dist < closestDistance then
      closest = data
      closestDistance = dist
    end
  end

  if closest then
    closest.changer(closest.pos)
    return true
  end

  return false
end

local function handleFloorChange()
  local range = 1
  local p = player:getPosition()
  local possibleChangers = {}

  for _, dir in ipairs({"Down", "Up"}) do
    for changer, data in pairs(FloorChangers) do
      for x = -range, range do
        for y = -range, range do
          local tile = g_map.getTile({
          x = p.x + x,
          y = p.y + y,
          z = p.z
          })

          if tile and tile:getTopUseThing() then
            if table.find(data[dir], tile:getTopUseThing():getId()) then
              table.insert(possibleChangers, {
              changer = floorChangeSelector[changer][dir],
              pos = {
              x = p.x + x,
              y = p.y + y,
              z = p.z
              }
              })
            end
          end
        end
      end
    end
  end

  if #possibleChangers > 0 then
    return executeClosest(possibleChangers)
  end

  return false
end

local function matchPos(p1, p2)
  return (p1.x == p2.x and p1.y == p2.y)
end

local function handleUsing()
  if true then
    handleFloorChange()
  else
    local usePos = leaderUsePositions[posz()]

    if usePos then
      local useTile = g_map.getOrCreateTile(usePos)

      if useTile then
        use(useTile:getTopUseThing())
      end
    end
  end
end

local function useRope(pos)
  if not pos then
    pos = player:getPosition()
  end

  local dirs = {
  {0, 0},
  {-1, 0},
  {1, 0},
  {0, -1},
  {0, 1},
  {1, -1},
  {1, 1},
  {-1, 1},
  {-1, -1}
  }

  for i = 1, #dirs do
    local tpos = {
    x = pos.x + dirs[i][1],
    y = pos.y + dirs[i][2],
    z = posz()
    }

    local tile = g_map.getTile(tpos)

    if tile then
      if tile:getGround() then
        local ropeSpots = FloorChangers.RopeSpots.Up

        if table.contains(ropeSpots, tile:getGround():getId()) then
          local waitTime = getDistanceBetween(player:getPosition(), tpos) * 60
          handleRope(tpos)
          delay(waitTime)
          return true
        end
      end
    end
  end

  return false
end

local function getStandTime()
  return now - standTime
end

ultimateFollow = macro(350, "Follow RTS", function()
  if not leader then
    local leaderPos = leaderPositions[posz()]

    if leaderPos then
      if getDistanceBetween(player:getPosition(), leaderPos) > 0 then
        if autoWalk(leaderPos, 80, {
        ignoreNonPathable = true,
        precision = 0
        }) then
          delay(200)
          return
        end
      end
    end

    if true then
      if handleFloorChange() then
        return
      end

      local dir = leaderDirections[posz()]

      if dir then
        tryLevitate(dir)
      end
    else
      local levitatePos = listenedLeaderPosDir

      if levitatePos and matchPos(player:getPosition(), levitatePos) then
        tryLevitate(listenedLeaderDir)
        return
      end

      if useRope(leaderPos) then
        return
      end

      handleUsing()
    end
  else
    listenedLeaderPosDir = nil
    listenedLeaderDir = nil

    local lpos = leader:getPosition()
    local distance = getDistanceBetween(player:getPosition(), lpos)

    if distance >= 2 then
      if getStandTime() > 500 then
        if autoWalk(lpos, 40, {
        ignoreNonPathable = true,
        precision = 1,
        ignoreCreatures = true
        }) then
          delay(200)
          return
        end
      end
    end

    if distance > 1 and not findPath(
    player:getPosition(),
    lpos,
    20,
    {
    ignoreNonPathable = true,
    precision = 1
    }
    ) then
      handleUsing()
    end
  end
end)

UI.Label("Follow Player:")

UI.TextEdit(storage.rtsFollow or "Name", function(widget, text)
  storage.rtsFollow = text
  leader = getPlayerByName(text)
end)

if type(onRemoveThing) == "function" then
  onRemoveThing(function(tile, thing)
    followRemovedLeaderTile(tile, thing)
  end)
end

onCreaturePositionChange(function(creature, newPos, oldPos)
  if ultimateFollow.isOff() then
    return
  end

  if not player or not currentPosition() then return end

  if creature:getName() == player:getName() then
    standTime = now
    return
  end

  if not creature:isPlayer() then
    return
  end

  if not isLeaderCreature(creature) then
    return
  end

  if newPos then
    leaderPositions[newPos.z] = newPos
    lastLeaderFloor = newPos.z

    if newPos.z == posz() then
      leader = creature
    else
      leader = nil
    end
  else
    leader = nil
  end

  local removalAlreadyHandled = oldPos and lastLeaderRemoval
  and samePosition(lastLeaderRemoval.position, oldPos)
  and (tonumber(now) or 0) - (tonumber(lastLeaderRemoval.at) or 0) <= 100
  if oldPos and not removalAlreadyHandled then
    if newPos and oldPos.z ~= newPos.z then
      leaderDirections[oldPos.z] = creature:getDirection()
    end

    local oldTile = g_map.getTile(oldPos)
    local walkPrecision = 1

    if oldTile then
      if not oldTile:hasCreature() then
        walkPrecision = 0
      end
    end

    autoWalk(oldPos, 40, {
    ignoreNonPathable = true,
    ignoreCreatures = false,
    precision = walkPrecision
    })
  end
end)

onCreatureAppear(function(creature)
  if ultimateFollow.isOff() then
    return
  end

  if not player or not currentPosition() then return end

  local creaturePosition = safeMethod(creature, "getPosition")
  if not creaturePosition or creaturePosition.z ~= posz() then
    return
  end

  if isLeaderCreature(creature) then
    leader = creature
  elseif creature:getName() == player:getName() then
    if lastLeaderFloor and lastLeaderFloor == posz() then
      leader = getPlayerByName(storage.rtsFollow)
    end
  end
end)

onCreatureDisappear(function(creature)
  if ultimateFollow.isOff() then
    return
  end

  if not player or not currentPosition() then return end

  if isLeaderCreature(creature) then
    leader = nil
  elseif safeMethod(creature, "getName") == safeMethod(player, "getName") and posz() ~= lastLeaderFloor then
    leader = nil
  end
end)

leader = getPlayerByName(storage.rtsFollow)

macro(200, "Follow Normal", function()
  local center = currentPosition()
  if not center then return end
  if g_game.isFollowing() then
    return
  end

  local spectators = type(OblivionGetSpectatorsCached) == "function"
    and OblivionGetSpectatorsCached(false) or nil
  if type(spectators) ~= "table" then
    local ok
    ok, spectators = pcall(function() return g_map.getSpectators(center, false) end)
    if not ok or type(spectators) ~= "table" then return end
  end
  for _, followcreature in ipairs(spectators) do
    local followPos = FREE_SAFE_POSITION and FREE_SAFE_POSITION(followcreature) or nil
    if followcreature:isPlayer()
    and followcreature:getName():lower() == tostring(storage.rtsFollow or ""):lower()
    and followPos and getDistanceBetween(center, followPos) <= 8 then
      g_game.follow(followcreature)
    end
  end
end)

-----------------------------------------------------------------------------------------------------------------------------------------------------

-- Ajuda a evitar o erro "attempt to index global 'g_clock' (a nil value)"
-- quando g_clock ainda nao esta pronto no momento em que um schedule()/evento dispara.
local function nowMillis()
    if type(g_clock) == "table" and type(g_clock.millis) == "function" then
        return g_clock.millis()
    end
    return now or 0
end

-----------------------------------------
-- CHECKBOX: ACEITAR PT
-----------------------------------------
local aceitarPTCheck = setupUI([[
CheckBox
  id: aceitarPTToggle
  text: "Aceitar PT"
  checked: false
]], mainTab)

aceitarPTCheck.onCheckChange = function(widget, checked)
    storage.ptSystem.aceitar = checked
    if checked then
        aceitarPTMacro.setOn()
    else
        aceitarPTMacro.setOff()
    end
end

-----------------------------------------
-- CHECKBOX: INVITAR PT
-----------------------------------------
local invitarPTCheck = setupUI([[
CheckBox
  id: invitarPTToggle
  text: "Invitar PT"
  checked: false
]], mainTab)

invitarPTCheck.onCheckChange = function(widget, checked)
    storage.ptSystem.invitar = checked
    if checked then
        invitarPTMacro.setOn()
    else
        invitarPTMacro.setOff()
    end
end

-----------------------------------------
-- STORAGE
-----------------------------------------
storage.ptSystem = storage.ptSystem or {
    aceitar = false,
    invitar = false
}


UI.Separator()

-----------------------------------------
-- MACRO: ACEITAR PT
-----------------------------------------
aceitarPTMacro = macro(200, "Aceitar PT", function()

    if not storage.ptSystem.aceitar then return end

    -- FIX (Slow macro): getSpectators() pedia a lista de novo do zero a cada
    -- 200ms. Reaproveitamos o cache ja usado no resto do arquivo (mesmo dado,
    -- sem custo extra de consulta ao mapa).
    local spectators = type(OblivionGetSpectatorsCached) == "function"
        and OblivionGetSpectatorsCached(false) or getSpectators()

    for _, spec in ipairs(spectators) do
        if spec:isPlayer() and spec:getShield() == 1 then
            g_game.partyJoin(spec:getId())
        end
    end

end)

-- FIX (Slow onTalk): esse onTalk ficava DENTRO da macro acima, que roda a
-- cada 200ms. Isso registrava um onTalk novo a cada ciclo, sem nunca remover
-- os antigos -- depois de um tempo com "Invitar PT" ligado, o client acumula
-- milhares de onTalk empilhados, e toda vez que alguem fala no chat, TODOS
-- eles rodam de uma vez. Era exatamente isso que gerava o aviso
-- "Slow onTalk" apontando pra esse arquivo. Agora ele e registrado UMA unica
-- vez, e a checagem de ligado/desligado fica dentro do proprio callback.
onTalk(function(name, level, mode, text, channelId, pos)
    if not storage.ptSystem.invitar then return end

    local player = g_game.getLocalPlayer()
    if not player then return end

    if name == player:getName() then return end
    if mode ~= 1 then return end

    if text:lower():find("pt") then
        local friend = getPlayerByName(name)
        if friend then
            g_game.partyInvite(friend:getId())
        end
    end
end)

-----------------------------------------
-- CONFIG: INVITAR POR GUILD
-----------------------------------------
local guildConfig = {
    guildEmblem = 1,
    maxDist = 5,
    multifloor = true,
    ignoreShield = 2
}

-----------------------------------------
-- MACRO: INVITAR PT
-----------------------------------------
invitarPTMacro = macro(200, "Invitar PT", function()

    if not storage.ptSystem.invitar then return end

    -- FIX (Slow macro): mesma ideia da macro "Aceitar PT" acima -- reaproveita
    -- o cache de spectators em vez de consultar o mapa de novo a cada 200ms.
    local spectators = type(OblivionGetSpectatorsCached) == "function"
        and OblivionGetSpectatorsCached(guildConfig.multifloor) or getSpectators(guildConfig.multifloor)

    for _, spec in ipairs(spectators) do
        
        if spec:isPlayer()
        and spec ~= g_game.getLocalPlayer()
        and spec:getEmblem() == guildConfig.guildEmblem
        and not spec:isPartyMember()
        and spec:getShield() ~= guildConfig.ignoreShield
        and getDistanceBetween(spec:getPosition(), pos()) <= guildConfig.maxDist then

            g_game.partyInvite(spec:getId())
            break
        end
    end

end)

macro(250, function()
    aceitarPTCheck:setChecked(storage.ptSystem.aceitar)
    invitarPTCheck:setChecked(storage.ptSystem.invitar)

    if storage.ptSystem.aceitar then
        aceitarPTMacro.setOn()
    else
        aceitarPTMacro.setOff()
    end

    if storage.ptSystem.invitar then
        invitarPTMacro.setOn()
    else
        invitarPTMacro.setOff()
    end
end)

-----------------------------------------------------------------------------------------------------------
-- PVP / MW - Macros com painel proprio
-----------------------------------------------------------------------------------------------------------

-- Ajuda a evitar o erro "attempt to index global 'g_clock' (a nil value)"
-- quando g_clock ainda nao esta pronto no momento em que um schedule()/evento dispara.
local function nowMillis()
    if type(g_clock) == "table" and type(g_clock.millis) == "function" then
        return g_clock.millis()
    end
    return now or 0
end

-----------------------------------------------------------------------------------------------------------
-- Storage do painel (liga/desliga cada macro)
-----------------------------------------------------------------------------------------------------------
storage.pvpPanel = storage.pvpPanel or {
    useMwMouse   = true,
    mwallFrente  = true,
    mwCursor     = true,
    mwWgTimer    = true,
    mwAtras      = true,
    holdMw       = true,
    avoidEffects = true,
    openMainBag  = true,
    openNextBag  = true
}

-- ID do item da MW (Magic Wall), agora editavel pelo painel PVP / MW.
-- Se o storage ja existia de uma versao antiga (sem esse campo), cai no default 12105.
storage.pvpPanel.mwId = storage.pvpPanel.mwId or 12105

local function getMwId()
    return tonumber(storage.pvpPanel.mwId) or 12105
end

-----------------------------------------------------------------------------------------------------------
-- Botao (fora do Bot/UTI): botao solto na tela, movido com CTRL + Mouse
-- (mesmo padrao usado no widget flutuante do AntiRed.lua desta custom)
-----------------------------------------------------------------------------------------------------------
storage.widgetPos = storage.widgetPos or {}

local pvpPanelButton = setupUI([[
Button
  color: green
  size: 110 30
  text: - PVP / MW -
  focusable: true
  phantom: false
  draggable: true
]], g_ui.getRootWidget())

local isMobile = modules._G.g_app.isMobile()
g_keyboard = g_keyboard or modules.corelib.g_keyboard

local function isPvpButtonDragKeyPressed()
    return isMobile and g_keyboard.isKeyPressed("F2") or g_keyboard.isCtrlPressed()
end

pvpPanelButton.onDragEnter = function(widget, mousePos)
    if not isPvpButtonDragKeyPressed() then return end
    widget:breakAnchors()
    local widgetPos = widget:getPosition()
    widget.movingReference = {x = mousePos.x - widgetPos.x, y = mousePos.y - widgetPos.y}
    return true
end

pvpPanelButton.onDragMove = function(widget, mousePos, moved)
    local parentRect = widget:getParent():getRect()
    local x = math.min(math.max(parentRect.x, mousePos.x - widget.movingReference.x), parentRect.x + parentRect.width - widget:getWidth())
    local y = math.min(math.max(parentRect.y - widget:getParent():getMarginTop(), mousePos.y - widget.movingReference.y), parentRect.y + parentRect.height - widget:getHeight())
    widget:move(x, y)
    storage.widgetPos.pvpButton = {x = x, y = y}
    return true
end

storage.widgetPos.pvpButton = storage.widgetPos.pvpButton or {}
pvpPanelButton:setPosition({
    x = storage.widgetPos.pvpButton.x or 50,
    y = storage.widgetPos.pvpButton.y or 50
})

local pvpPanelWindow = setupUI([[
MainWindow
  !text: tr('PVP / MW - Configuracoes')
  size: 300 380

  Panel
    id: mainPanel
    image-source: /images/ui/panel_flat
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: bottomBar.top
    margin-top: 10
    margin-left: 10
    margin-right: 10
    margin-bottom: 10
    image-border: 6
    padding: 5

    Label
      id: listTitle
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      text-align: center
      font: sans-bold-16px
      color: orange
      margin-top: 3
      text: PVP / MW

    ScrollablePanel
      id: toggleList
      layout:
        type: verticalBox
      anchors.top: listTitle.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      margin-top: 8
      margin-bottom: 5
      vertical-scrollbar: toggleListScroll

    VerticalScrollBar
      id: toggleListScroll
      anchors.top: toggleList.top
      anchors.bottom: toggleList.bottom
      anchors.right: toggleList.right
      step: 14
      pixels-scroll: true

  Panel
    id: bottomBar
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 30

    Button
      id: closeButton
      !text: tr('Fechar')
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      margin-right: 10
      margin-bottom: 5
      size: 70 21
]], g_ui.getRootWidget())
pvpPanelWindow:hide()

pvpPanelButton.onClick = function()
    if pvpPanelWindow:isVisible() then
        pvpPanelWindow:hide()
    else
        pvpPanelWindow:show()
        pvpPanelWindow:raise()
        pvpPanelWindow:focus()
    end
end

pvpPanelWindow.bottomBar.closeButton.onClick = function()
    pvpPanelWindow:hide()
end

-- Helper pra criar uma linha de checkbox no painel, ja sincronizada com a storage
local function addPvpToggle(label, key)
    local row = setupUI([[
CheckBox
  height: 20
  text-offset: 24 0
]], pvpPanelWindow.mainPanel.toggleList)
    row:setText(label)
    row:setChecked(storage.pvpPanel[key])
    row.onCheckChange = function(widget, checked)
        storage.pvpPanel[key] = checked
    end
end

-----------------------------------------------------------------------------------------------------------
-- MW no botao do mouse (macro anonima: sem nome nao cria botao solto)
-----------------------------------------------------------------------------------------------------------
macro(100, function()
    if not storage.pvpPanel.useMwMouse then return end

    -- Verifica se o botão 7 do mouse está pressionado
    if not g_mouse.isPressed(7) then return end

    -- Pega o tile onde o mouse está apontando
    local tile = getTileUnderCursor()
    if not tile then return end

    -- Usa o item MW (3106) no tile
    g_game.useInventoryItemWith(getMwId(), tile:getTopUseThing())
end)

-------------------------------------------------------------------------------------------
-- Mwall na frente do alvo (target) - via onKeyPress (nao cria botao solto)
-------------------------------------------------------------------------------------------
local function mwallId() return getMwId() end -- Mwall ID (agora lido do painel)
local squaresThreshold = 2 -- quantidade de sqm a tacar MW frente do char

onKeyPress(function(keys)
    if keys ~= "F5" then return end
    if not storage.pvpPanel.mwallFrente then return end

    local target = g_game.getAttackingCreature()
    if target then
        local targetPos = target:getPosition()
        local targetDir = target:getDirection()
        local mwallTile
        if targetDir == 0 then -- north
            targetPos.y = targetPos.y - squaresThreshold
            mwallTile = g_map.getTile(targetPos)
        elseif targetDir == 1 then -- east
            targetPos.x = targetPos.x + squaresThreshold
            mwallTile = g_map.getTile(targetPos)
        elseif targetDir == 2 then -- south
            targetPos.y = targetPos.y + squaresThreshold
            mwallTile = g_map.getTile(targetPos)
        elseif targetDir == 3 then -- west
            targetPos.x = targetPos.x - squaresThreshold
            mwallTile = g_map.getTile(targetPos)
        end
        -- FIX (mesma classe do bug do "Mw Atras"): g_map.getTile pode devolver nil
        -- se a tile alvo nao estiver carregada; sem esse check dava pra crashar.
        if mwallTile then
            useWith(mwallId(), mwallTile:getTopUseThing())
        end
    end
end)

-------------------------------------------------------------------------------------------
-- MW no cursor (tecla R) - via onKeyPress (nao cria botao solto)
-------------------------------------------------------------------------------------------
local function mwallIdCursor() return getMwId() end -- id da mw pra soltar (agora lido do painel)

onKeyPress(function(keys)
    if keys ~= "R" then return end
    if not storage.pvpPanel.mwCursor then return end
    if modules.game_console:isChatEnabled() or modules.corelib.g_keyboard.isCtrlPressed() then return end

    local tile = getTileUnderCursor()
    if not tile then return end
    g_game.stop()
    player:stopAutoWalk()
    useWith(mwallIdCursor(), tile:getTopUseThing())
end)

-------------------------------------------------------------------------------------------
-- Timer visual de MW / WG na tile
-------------------------------------------------------------------------------------------
local activeTimers = {}

-- IDs corrigidos (ajuste conforme seu servidor)
-- MWALL_ID nao fica mais fixo numa variavel: le getMwId() na hora de comparar,
-- assim o campo "ID da MW" do painel atualiza sem precisar reiniciar o script.
local WG_ID = 12105
-- Tempos em milissegundos
local MWALL_TIME = 10000  -- 15 segundos
local WG_TIME = 10000     -- 25 segundos

onAddThing(function(tile, thing)
    if not storage.pvpPanel.mwWgTimer then return end
    if not thing:isItem() then
        return
    end

    local timer = 0
    local itemId = thing:getId()

    if itemId == getMwId() then
        timer = MWALL_TIME
    elseif itemId == WG_ID then
        timer = WG_TIME
    else
        return
    end

    local pos = tile:getPosition().x .. "," .. tile:getPosition().y .. "," .. tile:getPosition().z

    -- Atualiza o timer apenas se for novo ou se o atual já expirou
    if not activeTimers[pos] or activeTimers[pos] < now then
        activeTimers[pos] = now + timer
    end

    tile:setTimer(activeTimers[pos] - now)
end)

onRemoveThing(function(tile, thing)
    if not storage.pvpPanel.mwWgTimer then return end
    if not thing:isItem() then
        return
    end

    local itemId = thing:getId()
    if (itemId == getMwId() or itemId == WG_ID) and tile:getGround() then
        local pos = tile:getPosition().x .. "," .. tile:getPosition().y .. "," .. tile:getPosition().z
        activeTimers[pos] = nil
        tile:setTimer(0)
    end
end)

-------------------------------------------------------------------------------------------
-- Mw Atras (larga MW no tile que acabou de sair) - sem macro() proprio, so a flag
-------------------------------------------------------------------------------------------
onPlayerPositionChange(function(newPos, oldPos)
    if oldPos.z ~= posz() then return end
    if oldPos then
        local tile = g_map.getTile(oldPos)
        -- FIX (crash "attempt to index local 'tile' (a nil value)"): g_map.getTile
        -- pode retornar nil (tile fora do range carregado/troca de andar), entao
        -- precisamos checar antes de chamar tile:isWalkable().
        if tile and storage.pvpPanel.mwAtras and tile:isWalkable() then
            useWith(getMwId(), tile:getTopUseThing())
        end
    end
end)

-------------------------------------------------------------------------------------------
-- Hold MW (marca posicoes com X e renova MW automaticamente)
-------------------------------------------------------------------------------------------
storage.mwPos = storage.mwPos or {}
local mwConfig = {
    effectId = 11099 -- id do EFEITO de cast da MW, nao do item (usado so pra detectar o cast)
}
local keyMwall = 'X'
local mwDuration = 15000 -- 15 segundos de duração da MW

-- Função para converter posição em string (para usar como chave)
local function posToStr(pos)
    return pos.x .. "," .. pos.y .. "," .. pos.z
end

-- Função para converter string em posição
local function strToPos(str)
    local x, y, z = str:match("([^,]+),([^,]+),([^,]+)")
    return {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
end

local function checkIfMwallId(idEffect)
    return idEffect == mwConfig.effectId
end

-- Tecla para adicionar/remover posições
onKeyPress(function(key)
    if key == keyMwall then
        local tile = getTileUnderCursor()
        if tile then
            local tilePos = tile:getPosition()
            local posStr = posToStr(tilePos)

            if storage.mwPos[posStr] then
                -- Remover da lista
                storage.mwPos[posStr] = nil
                tile:setText("")
                print("Posição removida: " .. posStr)
            else
                -- Adicionar na lista
                storage.mwPos[posStr] = {
                    lastSeen = 0,
                    addedTime = nowMillis()
                }
                tile:setText("Aqui")
                print("Posição adicionada: " .. posStr)
            end
        end
    end
end)

-- Quando uma MW é colocada
onAddThing(function(tile, thing)
    if not storage.pvpPanel.holdMw then return end

    if checkIfMwallId(thing:getId()) then
        local tilePos = tile:getPosition()
        local posStr = posToStr(tilePos)

        if storage.mwPos[posStr] then
            -- Atualizar que vimos MW aqui agora
            storage.mwPos[posStr].lastSeen = nowMillis()
            tile:setText("Aqui")
        end
    end
end)

-- Quando uma MW desaparece
onRemoveThing(function(tile, thing)
    if not storage.pvpPanel.holdMw then return end

    if checkIfMwallId(thing:getId()) then
        local tilePos = tile:getPosition()
        local posStr = posToStr(tilePos)

        -- Mantém o texto "Aqui" mesmo após a MW desaparecer
        if storage.mwPos[posStr] then
            tile:setText("Aqui")

            -- Marcar que a MW desapareceu agora
            if storage.mwPos[posStr] then
                storage.mwPos[posStr].lastSeen = nowMillis() - mwDuration - 1000
            end
        end
    end
end)

-- Macro anonima (sem nome) - so a logica, sem criar botao solto na lista
macro(500, function()
    if not storage.pvpPanel.holdMw then return end

    local currentTime = nowMillis()

    for posStr, data in pairs(storage.mwPos) do
        local pos = strToPos(posStr)
        local tile = g_map.getTile(pos)

        if tile and tile:canShoot() then
            -- Verificar se já tem MW ativa
            local hasMw = false
            for _, thing in ipairs(tile:getThings()) do
                if checkIfMwallId(thing:getId()) then
                    hasMw = true
                    -- Atualizar o último tempo que vimos MW aqui
                    data.lastSeen = currentTime
                    break
                end
            end

            -- Se não tem MW e já passou tempo suficiente desde a última
            if not hasMw then
                local lastTime = data.lastSeen or 0

                -- Tentar renovar se:
                -- 1. Nunca vimos MW aqui antes, OU
                -- 2. A MW desapareceu há mais de 500ms (evita spam)
                if currentTime - lastTime > 500 then
                    useWith(getMwId(), tile:getTopUseThing())
                    data.lastSeen = currentTime
                    schedule(100, function()
                        local tileAgain = g_map.getTile(pos)
                        if tileAgain then
                            tileAgain:setText("Aqui")
                        end
                    end) -- Garante que o texto volta
                end
            end
        end
    end
end)

-- Reaplica os textos quando o script iniciar
local function initTexts()
    for posStr, data in pairs(storage.mwPos) do
        local pos = strToPos(posStr)
        local tile = g_map.getTile(pos)
        if tile then
            tile:setText("Aqui")
        end
    end
end

-- Limpeza de posições antigas (executada periodicamente)
local function scheduleCleanup()
    local currentTime = nowMillis()
    local toRemove = {}

    for posStr, data in pairs(storage.mwPos) do
        -- Remove posições que não tiveram MW por mais de 2 minutos
        if currentTime - (data.lastSeen or 0) > 120000 then
            table.insert(toRemove, posStr)
        end
    end

    for _, posStr in ipairs(toRemove) do
        storage.mwPos[posStr] = nil
    end

    if #toRemove > 0 then
        print("Removidas " .. #toRemove .. " posições antigas")
    end

    -- Agenda a próxima limpeza em 60 segundos
    schedule(60000, scheduleCleanup)
end

-- Inicializa quando tudo estiver carregado
schedule(1000, function()
    initTexts()
    -- Inicia a limpeza periódica
    scheduleCleanup()
end)

print("========================================")
print("MW Holder v2.0 carregado!")
print("Pressione '" .. keyMwall .. "' para marcar/desmarcar posições")
print("MWs serão renovadas automaticamente quando desaparecerem")
print("Ative/desative pelo painel PVP / MW")
print("========================================")

--------------------------------------------------------------------------------------------------------
-- Avoid Effects
--------------------------------------------------------------------------------------------------------
local MAX_WALK_DISTANCE = 8        -- Maximum distance to look for safe zones (max 7 recommended for performance)
local DELAY_AFTER_WALK = 250       -- Delay after walking to avoid lag (max 500)
local AVOIDED_EFFECT_IDS = { 750 } -- List of effect IDs to avoid

local diagonalOffsets = {
  { x = -1, y = -1, dir = NorthWest },
  { x =  1, y = -1, dir = NorthEast },
  { x = -1, y =  1, dir = SouthWest },
  { x =  1, y =  1, dir = SouthEast }
}

local safeTiles = {}
local isAvoiding = false
local lastSafePosition = nil

-- Marks a tile as temporarily invalid for walking
local function markTileAsInvalid(tile)
  tile.invalid = true
  tile:setText("Uzu bixa")
  schedule(500, function()
    if tile then
      tile.invalid = false
      tile:setText("")
    end
  end)
end

onAddThing(function(tile, thing)
  if not storage.pvpPanel.avoidEffects or not thing:isEffect() then return end
  if not table.find(AVOIDED_EFFECT_IDS, thing:getId()) then return end

  markTileAsInvalid(tile)
end)

-- Detects if the player is standing on an avoided effect and finds a nearby safe tile
onAddThing(function(tile, thing)
  if not storage.pvpPanel.avoidEffects or not tile or not thing or not thing:isEffect() then return end

  local playerPos = pos()
  local tilePos = tile:getPosition()

  if not table.equals(tilePos, playerPos) then return end
  if not table.find(AVOIDED_EFFECT_IDS, thing:getId()) then return end
  if isAvoiding then return end

  isAvoiding = true

  -- Clear previous safe tile entries
  for i = 1, MAX_WALK_DISTANCE do
    safeTiles[i] = {}
  end

  -- Scan for valid tiles
  -- FIX (Slow macro): antes isto rodava g_map.getTiles(playerPos.z), que devolve
  -- TODAS as tiles do andar inteiro (podem ser milhares numa sala grande), e
  -- chamava findPath (calculo completo de rota) pra cada uma delas. Isso e
  -- extremamente pesado e travava o client sempre que o efeito monitorado
  -- aparecia -- era exatamente isso que disparava o aviso de "Slow". Agora a
  -- varredura fica limitada a uma caixa pequena ao redor do jogador
  -- (2*MAX_WALK_DISTANCE+1 lado), ordenada da tile mais perto pra mais longe,
  -- e para no primeiro findPath valido em vez de testar tudo.
  schedule(100, function()
    local candidates = {}

    for dx = -MAX_WALK_DISTANCE, MAX_WALK_DISTANCE do
      for dy = -MAX_WALK_DISTANCE, MAX_WALK_DISTANCE do
        local distance = math.abs(dx) + math.abs(dy)

        if distance > 0 and distance < MAX_WALK_DISTANCE then
          local candidatePos = {x = playerPos.x + dx, y = playerPos.y + dy, z = playerPos.z}
          local mapTile = g_map.getTile(candidatePos)

          if mapTile and not mapTile.invalid and mapTile:isWalkable() then
            table.insert(candidates, {tile = mapTile, pos = candidatePos, distance = distance})
          end
        end
      end
    end

    table.sort(candidates, function(a, b) return a.distance < b.distance end)

    for _, candidate in ipairs(candidates) do
      if findPath(playerPos, candidate.pos, 10) then
        table.insert(safeTiles[candidate.distance], candidate.tile)
        break -- primeira tile valida ja e a mais proxima, nao precisa continuar
      end
    end

    -- Try to walk to the closest safe tile
    for distance = 1, MAX_WALK_DISTANCE do
      if #safeTiles[distance] > 0 then
        local targetTile = safeTiles[distance][1]
        local targetPos = targetTile:getPosition()
        lastSafePosition = targetPos

        -- If tile is adjacent, use direct walk direction
        if distance == 1 then
          for _, offset in ipairs(diagonalOffsets) do
            local offsetPos = { x = posx() + offset.x, y = posy() + offset.y, z = posz() }
            if table.equals(offsetPos, targetPos) then
              g_game.walk(offset.dir)
              schedule(DELAY_AFTER_WALK, function() isAvoiding = false end)
              return
            end
          end
        end

        -- Otherwise, use autoWalk
        autoWalk(targetPos)
        schedule(DELAY_AFTER_WALK, function() isAvoiding = false end)
        break
      end
    end
  end)
end)

---------------------------------------------------------------------------------
-- Bags (macros anonimas)
---------------------------------------------------------------------------------
macro(1000, function()
    if not storage.pvpPanel.openMainBag then return end

    bpItem = getBack()
    bp = getContainer(0)

    if not bp and bpItem ~= nil then
        g_game.open(bpItem)
    end
end)

macro(1000, function()
    if not storage.pvpPanel.openNextBag then return end

    local containers = getContainers()
    for i, container in pairs(containers) do
        if container:getItemsCount() == container:getCapacity() then
            for _, item in ipairs(container:getItems()) do
                if item:isContainer() then
                    g_game.open(item, container)
                end
            end
        end
    end
end)

-----------------------------------------------------------------------------------------------------------
-- Preenche o painel com os toggles
-----------------------------------------------------------------------------------------------------------
addPvpToggle("Use MW (Mouse)", "useMwMouse")
addPvpToggle("Mwall Frente Target [F5]", "mwallFrente")
addPvpToggle("MW Cursor [R]", "mwCursor")
addPvpToggle("Timer MW/WG na tile", "mwWgTimer")
addPvpToggle("Mw Atras", "mwAtras")
addPvpToggle("Hold MW (X)", "holdMw")
addPvpToggle("Desvia y Desvia", "avoidEffects")
addPvpToggle("Abrir Bag Principal", "openMainBag")
addPvpToggle("Abrir proxima Bag", "openNextBag")
