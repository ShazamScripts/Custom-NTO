-- /images/ui/window
local hpui = setupUI([[
Panel 
  image-border: 8
  anchors.horizontalCenter: parent.horizontalCenter
  anchors.top: parent.top
  height: 50
  width: 100
  visible: true
  focusable: true
  phantom: false
  draggable: true
  margin-top: 250
  margin-left: -102

  Panel
    id: PlayerPainel
    image-border: 6
    anchors.top: parent.top
    anchors.left: parent.left
    image-color: red
    size: 30 30

  Panel
    id: PlayerPainel_Name
    image-border: 8
    image-color: #d9d9d9
    padding: 1
    height: 5
    margin-top: 0
    margin-right: 0
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.left: PlayerPainel.right

    Label
      id: LIFE PERCENT
      anchors.left: PlayerPainel.right
      text: LIFE PERCENT: 
      color: green	
      font: verdana-11px-rounded
      text-horizontal-auto-resize: true
      margin-left: 30
      margin-top: 10

    UIWidget
      id: skullUI
      height: 1
      size: 43 43
      anchors.left: PlayerPainel_Name.right
      anchors.right: parent.right
      image-border: 5

  Panel
    id: HPprogressPanel
    image-border: -10
    image-color: #BEBEBE
    padding: 0
    height: 20
    margin-top: 12
    margin-right: -10
    anchors.top: PlayerPainel_Name.bottom
    anchors.left: PlayerPainel.right
    anchors.right: parent.right
  
    ProgressBar
      id: Hppercent
      background-color: green
      height: 16
      anchors.left: parent.left
      text: 100%
      width: 240
      margin-right: 0

]], modules.game_interface.gameMapPanel)

-- Verifica se a UI foi criada com sucesso
if not hpui then
    warn("Erro ao criar a barra de HP!")
    return
end

-- Posicao independente e persistente da barra.
storage.shazamHpBarPosition = storage.shazamHpBarPosition or {}
local savedPosition = storage.shazamHpBarPosition
if type(savedPosition.x) == "number" and type(savedPosition.y) == "number" then
    hpui:breakAnchors()
    hpui:setPosition({x = savedPosition.x, y = savedPosition.y})
end

-- A barra so pode ser arrastada enquanto Ctrl estiver pressionado.
local function isCtrlPressed()
    return modules.corelib.g_keyboard.isCtrlPressed()
end

hpui.onDragEnter = function(widget, mousePos)
    if not isCtrlPressed() then
        return false
    end

    widget:breakAnchors()
    widget.movingReference = {
        x = mousePos.x - widget:getX(),
        y = mousePos.y - widget:getY()
    }
    return true
end

hpui.onDragMove = function(widget, mousePos)
    if not isCtrlPressed() or not widget.movingReference then
        return false
    end

    local parentRect = widget:getParent():getRect()
    local x = math.min(
        math.max(parentRect.x, mousePos.x - widget.movingReference.x),
        parentRect.x + parentRect.width - widget:getWidth()
    )
    local y = math.min(
        math.max(parentRect.y, mousePos.y - widget.movingReference.y),
        parentRect.y + parentRect.height - widget:getHeight()
    )

    widget:move(x, y)
    storage.shazamHpBarPosition = {x = x, y = y}
    return true
end

hpui.onDragLeave = function(widget)
    widget.movingReference = nil
    if type(saveConfig) == "function" then
        saveConfig()
    end
    return true
end

local skull = {
  normal = "",
  white = "/images/game/skulls/skull_white",
  yellow = "/images/game/skulls/skull_yellow",
  green = "/images/game/skulls/skull_green",
  orange = "/images/game/skulls/skull_orange",
  red = "/images/game/skulls/skull_red",
  black = "/images/game/skulls/skull_black"
}

-- Variável para controlar se a macro está ativa
local hpMacroActive = true

macro(50, function()
    -- Verifica se a macro está ativa
    if not hpMacroActive then
        return
    end
    
    -- Verifica se a UI ainda existe e não foi destruída
    if not hpui or hpui:isDestroyed() then
        hpMacroActive = false
        warn("Barra de HP foi destruída, desativando macro...")
        return
    end
    
    -- Verifica se o player existe
    if not player then
        return
    end
    
    -- Verifica se os elementos filhos existem
    if not hpui.HPprogressPanel or hpui.HPprogressPanel:isDestroyed() then
        hpMacroActive = false
        warn("Elemento HPprogressPanel não encontrado, desativando macro...")
        return
    end
    
    if not hpui.HPprogressPanel.Hppercent or hpui.HPprogressPanel.Hppercent:isDestroyed() then
        hpMacroActive = false
        warn("Elemento Hppercent não encontrado, desativando macro...")
        return
    end
    
    -- Mostra a UI
    hpui:show()
    
    -- Obtém a porcentagem de HP do player
    local PlayerHP = player:getHealthPercent()
    
    -- Verifica se o valor é válido
    if not PlayerHP or type(PlayerHP) ~= "number" then
        return
    end
    
    -- Atualiza o texto e porcentagem COM VERIFICAÇÃO
    local success, err = pcall(function()
        hpui.HPprogressPanel.Hppercent:setText(PlayerHP.."%")
        hpui.HPprogressPanel.Hppercent:setPercent(PlayerHP)
    end)
    
    if not success then
        warn("Erro ao atualizar barra de HP: " .. err)
        hpMacroActive = false
        return
    end
    
    -- Define a cor baseado no HP
    if PlayerHP > 75 then
        hpui.HPprogressPanel.Hppercent:setBackgroundColor("green")
    elseif PlayerHP > 50 then
        hpui.HPprogressPanel.Hppercent:setBackgroundColor("yellow")
    elseif PlayerHP > 25 then
        hpui.HPprogressPanel.Hppercent:setBackgroundColor("orange")
    elseif PlayerHP > 1 then
        hpui.HPprogressPanel.Hppercent:setBackgroundColor("red")
    else
        -- BUGFIX: "darkred" não é um nome de cor reconhecido pelo client
        -- (só existem alguns nomes básicos tipo green/yellow/orange/red),
        -- então setBackgroundColor tentava converter a string pra Color
        -- e quebrava. Hex sempre funciona.
        hpui.HPprogressPanel.Hppercent:setBackgroundColor("#8B0000")
    end
end)

-- Função para desativar manualmente a barra de HP (se precisar)
function disableHPBar()
    hpMacroActive = false
    if hpui and not hpui:isDestroyed() then
        hpui:hide()
    end
    warn("Barra de HP desativada")
end

-- Função para ativar manualmente a barra de HP
function enableHPBar()
    hpMacroActive = true
    if hpui and not hpui:isDestroyed() then
        hpui:show()
    end
    warn("Barra de HP ativada")
end
