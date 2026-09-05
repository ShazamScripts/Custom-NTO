if not storage.ES_Spells then
  storage.ES_Spells = {}
end

if not storage.ES_Players then
  storage.ES_Players = {}
end

local panelES = setupUI([[
Panel
  height: 17
  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    text-align: center
    !text: tr('Time-Spell Enemy')

    image-source:

    $on:
      color: green

    $!on:
      color: white
]])

if not storage.ES then storage.ES = false end

panelES.title.onClick = function(widget)
    storage.ES = not storage.ES;
    widget:setOn(storage.ES);
    refreshMainWidget()
end

panelES.title:setOn(storage.ES)

local enemyPUI = setupUI([[
PanelEntry < UIWidget
  background-color: alpha
  text-offset: 18 0
  focusable: true
  height: 16
  text-align: center
  text-offset: -10 0

  CheckBox
    id: enabled
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 15
    height: 15
    margin-top: 2
    margin-left: 3
    image-source: /images/ui/checkbox_round
    change-cursor-image: true
    cursor: pointer
  
    $hover !disabled:
      image-color: red
  
    $!checked:
      image-color: red
  
    $checked:
      image-color: red
  
    $disabled:
      image-color: #dfdfdf88
      color: #dfdfdf88
      opacity: 0.8
      change-cursor-image: false

  $focus:
    background-color: gray
    opacity: 0.4

  UIButton
    id: remove
    !text: tr('X')
    color: #000120
    anchors.right: parent.right
    margin-right: 15
    width: 15
    height: 15
    !tooltip: tr('Remover Magia.')

MainWindow
  size: 400 350
  anchors.centerIn: parent
  text: Spells Enemys
  font: sans-bold-16px
  color: white
  visible: false

  TextList
    id: spellList
    anchors.left: parent.left
    anchors.top: parent.top
    padding: 1
    size: 200 260
    margin-bottom: 3
    margin-left: 3
    vertical-scrollbar: spellListScrollBar

  VerticalScrollBar
    id: spellListScrollBar
    anchors.top: spellList.top
    anchors.bottom: spellList.bottom
    anchors.right: spellList.right
    step: 14
    pixels-scroll: true

  Label
    id: spellNameLabel
    anchors.left: spellList.right
    anchors.top: spellList.top
    text: Spell:
    margin-top: 10
    margin-left: 70

  TextEdit
    id: spellName
    anchors.right: parent.right
    anchors.top: spellNameLabel.bottom
    margin-top: 10
    margin-right: 15
    width: 125

  Label
    id: activeLabel
    anchors.left: spellList.right
    anchors.top: spellList.top
    text: Active Time:
    margin-top: 70
    margin-left: 50

  TextEdit
    id: active
    anchors.right: parent.right
    anchors.top: activeLabel.bottom
    margin-top: 10
    margin-right: 15
    width: 125

  Label
    id: cdLabel
    anchors.left: spellList.right
    anchors.top: spellList.top
    text: Cooldown Time:
    margin-top: 130
    margin-left: 40

  TextEdit
    id: cooldown
    anchors.right: parent.right
    anchors.top: cdLabel.bottom
    margin-top: 10
    margin-right: 15
    width: 125

  Label
    id: nicknameLabel
    anchors.left: spellList.right
    anchors.top: spellList.top
    text: Apelido:
    margin-top: 190
    margin-left: 65

  TextEdit
    id: nickname
    anchors.right: parent.right
    anchors.top: nicknameLabel.bottom
    margin-top: 10
    margin-right: 15
    width: 125

  Button
    id: addSpell
    anchors.left: spellList.right
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    margin-bottom: 33
    margin-left: 8
    text: Add
    size: 60 17
    font: cipsoftFont

  Button
    id: closeButton
    !text: tr('Close')
    font: cipsoftFont
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 45 21
    margin-top: 15
    margin-right: 5
]], g_ui.getRootWidget())


local timerWidget = setupUI([[
Panel
  text: Time Spell Enemys
  font: sans-bold-16px
  size: 260 350
  text-align: top
  background-color: alpha
  opacity: 0.9
  visible: false
  draggable: true

  ScrollablePanel
    id: timersList
    layout:
      type: verticalBox
    anchors.fill: parent
    background-color: alpha
    opacity: 0.9
    margin-top: 20
    margin-left: 30
    margin-right: 0
    margin-bottom: 10
    phantom: true
]], g_ui.getRootWidget())

if storage.ES_Pos then
  timerWidget:setPosition(storage.ES_Pos)
else
  timerWidget:setPosition({x = 930, y = 60})
end

local isDragKeyPressed = function()
    return g_keyboard.isCtrlPressed()
end

timerWidget.onDragEnter = function(widget, mousePos)
    if not isDragKeyPressed() then return end
    widget:breakAnchors()
    widget.movingReference = {
        x = mousePos.x - widget:getX(),
        y = mousePos.y - widget:getY()
    }
    return true
end

timerWidget.onDragMove = function(widget, mousePos, moved)
    local parentRect = widget:getParent():getRect()
    local x = math.min(
        math.max(parentRect.x, mousePos.x - widget.movingReference.x),
        parentRect.x + parentRect.width - widget:getWidth()
    )
    local y = math.min(
        math.max(parentRect.y - widget:getParent():getMarginTop(), mousePos.y - widget.movingReference.y),
        parentRect.y + parentRect.height - widget:getHeight()
    )
    widget:move(x, y)
    return true
end

timerWidget.onDragLeave = function(widget, pos)
    storage.ES_Pos = {
        x = widget:getX(),
        y = widget:getY()
    }
    return true
end

macro(50, function()
    timerWidget:setPhantom(not isDragKeyPressed())
end)

local addTimer = [[
Label
  text-auto-resize: true
  font: verdana-11px-rounded
  color: orange
  margin-bottom: 5
  text-offset: 3 1
]]

-- Config agora abre com botao direito em qualquer parte da linha (painel, nao so o switch)
panelES.onMouseRelease = function(self, mousePos, mouseButton)
  if mouseButton == 2 then
    enemyPUI:show()
  end
end


enemyPUI.addSpell.onClick = function()
  local spell = enemyPUI.spellName:getText():lower()
  local active = enemyPUI.active:getText()
  local cooldown = enemyPUI.cooldown:getText()
  local nickname = enemyPUI.nickname:getText()

  if spell == "" or active == "" or cooldown == "" or nickname == "" then warn("Algo deu errado!") return end
  table.insert(storage.ES_Spells, {spell = spell, active = active, cooldown = cooldown, nickname = nickname, enabled = true})
  refreshWidget()
  refreshSpellList()
end

enemyPUI.closeButton.onClick = function()
  enemyPUI:hide()
end

onAnimatedText(function(thing, text)
  local pos = thing:getPosition()
  if not pos then return end

  if not storage.ES then return end

  local tile = g_map.getTile(pos)
  if not tile then return end

  local creature = tile:getTopCreature()
  if not creature or not creature:isPlayer() then return end

  local name = creature:getName()

  if name == player:getName() then return end

  for _, s in pairs(storage.ES_Spells) do
    if text:lower() == s.spell then
      table.insert(storage.ES_Players, {
        name = name,
        spell = s.nickname,
        time = os.time() + s.cooldown,
        active = os.time() + s.active
      })
    end
  end
end)

--===========================================================
--                      ARD CUSTONS                           
--===========================================================

onTalk(function(name, level, mode, text, channelId, pos)
  if name == player:getName() then
    return
  end

  if not storage.ES then
    return
  end
  
  for _, s in pairs(storage.ES_Spells) do
    if text:lower() == s.spell then
      table.insert(storage.ES_Players, {
        name = name,
        spell = s.nickname,
        time = os.time() + s.cooldown,
        active = os.time() + s.active
      })
    end
  end
end)

--===========================================================
--                      ARD CUSTONS                           
--===========================================================

function refreshWidget()
  enemyPUI.spellName:setText()
  enemyPUI.active:setText()
  enemyPUI.cooldown:setText()
  enemyPUI.nickname:setText()
end

function refreshSpellList()
  if not storage.ES_Spells then return end
  enemyPUI.spellList:destroyChildren()

  for index, value in pairs(storage.ES_Spells) do
    local label = UI.createWidget('PanelEntry', enemyPUI.spellList);
    label.onDoubleClick = function(widget)
      local spellTable = value;
      table.remove(storage.ES_Spells, index);
      enemyPUI.spellName:setText(spellTable.spell);
      enemyPUI.active:setText(spellTable.active);
      enemyPUI.cooldown:setText(spellTable.cooldown);
      enemyPUI.nickname:setText(spellTable.nickname);
      label:destroy();
      saveEnemySpells()
    end
    label.enabled:setChecked(value.enabled);
    label.enabled.onClick = function(widget)
      value.enabled = not value.enabled;
      label.enabled:setChecked(value.enabled);
      saveEnemySpells()
    end
    label.remove.onClick = function(widget)
      storage.ES_Spells[index] = nil;
      label:destroy();
      saveEnemySpells()
    end
    label:setText('['.. value.spell .. ']');
    label:setTooltip("Cooldown: ".. value.cooldown.. " | ".. "Active: ".. value.active)
    label:setFont("verdana-11px-rounded")
  end
end

--===========================================================
--                      ARD CUSTONS                           
--===========================================================

refreshSpellList()

function refreshTimerWidget()
  if not storage.ES then return end
  if not timerWidget:isVisible() then return end
  if not storage.ES_Players then return end

  -- FIX: antes disso, expirados eram "removidos" com table.remove() durante
  -- um pairs() na mesma tabela -- em Lua isso e' comportamento indefinido e
  -- na pratica quase nunca limpava direito. Resultado: storage.ES_Players
  -- so' crescia, e a cada 100ms o codigo recriava (do zero, via setupUI) um
  -- widget para CADA entrada acumulada -- isso ia pesando cada vez mais ate'
  -- crashar o client. Agora primeiro filtramos os expirados pra uma tabela
  -- nova (seguro), so' depois criamos os widgets.
  local nowTime = os.time()
  local alive = {}
  for _, value in ipairs(storage.ES_Players) do
    if value.time > nowTime then
      table.insert(alive, value)
    end
  end
  storage.ES_Players = alive

  timerWidget.timersList:destroyChildren()

  for _, value in ipairs(storage.ES_Players) do
    local label = setupUI(addTimer, timerWidget.timersList)
    if value.active >= nowTime then
      label:setColoredText({value.name, "white",
      ": ", "white",
      value.spell, "orange",
      " [ AC: ", "teal",
      value.active - nowTime, "teal",
      " ]", "teal"})
    else
      label:setColoredText({value.name, "white",
      ": ", "white",
      value.spell, "orange",
      " [ CD: ", "red",
      value.time - nowTime, "red",
      " ]", "red"})
    end
  end
end

function refreshMainWidget()
  if storage.ES then
    timerWidget:show()
  else
    timerWidget:hide()
  end
end
refreshMainWidget()

--===========================================================
--                      ARD CUSTONS                           
--===========================================================
macro(100, refreshTimerWidget)

local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text;
local enemySpellFolder = "/bot/" .. configName .. "/TimeSpelleEnemy"
local enemySpellFile = enemySpellFolder .. "/" .. name() .. "_TimeSpellEnemy.json"

if not g_resources.directoryExists(enemySpellFolder) then
  g_resources.makeDir(enemySpellFolder)
end

-- Migra arquivo antigo (salvo direto na raiz da custom) para a nova pasta TimeSpelleEnemy
local oldEnemySpellFile = "/bot/" .. configName .. "/" .. name() .. "_TimeSpellEnemy.json"
if oldEnemySpellFile ~= enemySpellFile and g_resources.fileExists(oldEnemySpellFile) and not g_resources.fileExists(enemySpellFile) then
  local status, content = pcall(function()
    return g_resources.readFileContents(oldEnemySpellFile)
  end)
  if status then
    g_resources.writeFileContents(enemySpellFile, content)
    g_resources.deleteFile(oldEnemySpellFile)
  end
end

if g_resources.fileExists(enemySpellFile) then
  local status, result = pcall(function()
    return json.decode(g_resources.readFileContents(enemySpellFile))
  end)

  if not status then
    warn("Erro ao carregar TimeSpellEnemy.json: " .. result)
  else
    storage.ES_Spells = result
  end
end

local function saveEnemySpells()
  local status, result = pcall(function()
    return json.encode(storage.ES_Spells, 2)
  end)

  if not status then
    return warn("Erro ao salvar TimeSpellEnemy.json: " .. result)
  end

  g_resources.writeFileContents(enemySpellFile, result)
end

enemyPUI.addSpell.onClick = function()
  local spell = enemyPUI.spellName:getText():lower()
  local active = tonumber(enemyPUI.active:getText())
  local cooldown = tonumber(enemyPUI.cooldown:getText())
  local nickname = enemyPUI.nickname:getText()

  if spell == "" or not active or not cooldown or nickname == "" then 
    warn("Preencha todos os campos corretamente!") 
    return 
  end

  table.insert(storage.ES_Spells, {
    spell = spell,
    active = active,
    cooldown = cooldown,
    nickname = nickname,
    enabled = true
  })

  saveEnemySpells()
  refreshWidget()
  refreshSpellList()
end

enemyPUI.closeButton.onClick = function()
  enemyPUI:hide()
  saveEnemySpells()
end