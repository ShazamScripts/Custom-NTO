setDefaultTab("Main")
UI.Separator()

local characterName = g_game.getCharacterName and g_game.getCharacterName() or "Ninja"
local worldName = g_game.getWorldName and g_game.getWorldName() or "Mundo"

-- Cabecalho principal da custom. O alinhamento e feito por anchors para
-- funcionar corretamente em qualquer largura, sem espacos artificiais.
local ui = setupUI([[
Panel
  height: 44
  margin-left: 3
  margin-right: 3
  background-color: #0b1018dd
  border-width: 1
  border-color: #d89a32

  Label
    id: brand
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 6
    text-align: center
    color: #ffc45c
    font: verdana-11px-rounded
    !text: tr('SHAZAM SCRIPTS 2.0')

  Label
    id: playerInfo
    anchors.top: brand.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 4
    text-align: center
    color: #b8c4d6
    font: verdana-11px-rounded
]], parent)

ui.playerInfo:setText(characterName .. "  |  " .. worldName)

if type(print) == "function" then
  print("[Shazam Scripts] Atualizacao automatica 2.0. ativa.")
end

UI.Separator()


-- Nome da imagem vem do campo criado no Sense.lua (aba UTI). Se a pessoa
-- ainda nao mexeu em nada, cai no "Minato" padrao.
Img = (storage and storage["_custom_img_name"] or "Minato") .. ".png"
-----------------------Sistema de IMG (baseado no LoboScripts)---------------------------------------------------------------------------------------------------------------------------------
local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text;
local Imgs = "/bot/" .. configName .. "/Img/" .. Img;

local rootWidget = g_ui.getRootWidget()
if rootWidget then
  local botWindow = rootWidget:recursiveGetChildById("botWindow")
  if botWindow then
    local contents = botWindow:recursiveGetChildById("contentsPanel")
    if contents then
      -- Imagem sem tint, na cor original -- exatamente como o LoboScripts faz.
      contents:setImageSource(Imgs)
    end

    -- Moldura da janela (fora do conteudo): sem imagem, so preto solido +
    -- botoes escurecidos. Igual ao padrao usado no LoboScripts.
    pcall(function() botWindow.closeButton:setImageColor("#363434") end)
    pcall(function() botWindow.minimizeButton:setImageColor("#363434") end)
    pcall(function() botWindow.lockButton:setImageColor("#363434") end)
    botWindow:setImageSource()
    botWindow:setBackgroundColor("black")
    botWindow:setBorderWidth(1)
    botWindow:setBorderColor("black")
    botWindow:setWidth(200)--Largura
    botWindow:setHeight(600)--Altura
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

local timeTrack = {
	["ntoultimate"] = 15,
  ["ntoimperial"] = 10,
	["ntolost"] = 5,
	["katon"] = 5, -- NTO SPLIT
	["dbolost"] = 2,
	["dragon ball rising"] = 5,
	["dbo galaxy"] = 5,
	["dbo infinity duel"] = 5
}

local storage = tyrBot and tyrBot.storage or storage;

local pzTime = timeTrack[g_game.getWorldName():lower()] or 15
	

os = os or modules.os

if type(storage.battleTracking) ~= "table" or storage.battleTracking[2] ~= player:getId() or (not os and storage.battleTracking[1] - now > pzTime * 60 * 1000) then
    storage.battleTracking = {0, player:getId(), {}}
end 

onTextMessage(function(mode, text)
	text = text:lower()
	if text:find("o assassinato de") or text:find("was not justified") or text:find("o assassinato do")then
		storage.battleTracking[1] = not os and now + (pzTime * 60 * 1000) or os.time() + (pzTime * 60)
		return
	end
	if not text:find("due to your") and not text:find("you deal") then return end
	local spectators = getSpecs or getSpectators;
	for _, spec in ipairs(spectators()) do
		local specName = spec:getName():lower()
		if spec:isPlayer() and text:find(specName) then
			storage.battleTracking[3][specName] = {timeBattle = not os and now + 60000 or os.time() + 60, playerId = spec:getId()}
			break
		end
	end
end)

math.mod = math.mod or function(base, modulus)
	return base % modulus
end

local function doFormatMin(v)
    v = v > 1000 and v / 1000 or v
    local mins = 00
    if v >= 60 then
        mins = string.format("%02.f", math.floor(v / 60))
    end
    local seconds = string.format("%02.f", math.abs(math.floor(math.mod(v, 60))))
    return mins .. ":" .. seconds
end




storage.widgetPos = storage.widgetPos or {}

local pkTimeWidget = setupUI([[
UIWidget
  size: 154 28
  background-color: #0b1018e8
  border-width: 1
  border-color: #526070
  color: #67e8a5
  font: verdana-11px-rounded
  text-align: center
  padding: 0 8
  focusable: true
  phantom: false
  draggable: true
]], g_ui.getRootWidget())


pkTimeWidget.onDragEnter = function(widget, mousePos)
	if not (modules.corelib.g_keyboard.isCtrlPressed()) then
		return false
	end
	widget:breakAnchors()
	widget.movingReference = {x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY()}
	return true
end

pkTimeWidget.onDragMove = function(widget, mousePos, moved)
	local parentRect = widget:getParent():getRect()
	local x = math.min(math.max(parentRect.x, mousePos.x - widget.movingReference.x), parentRect.x + parentRect.width - widget:getWidth())
	local y = math.min(math.max(parentRect.y - widget:getParent():getMarginTop(), mousePos.y - widget.movingReference.y), parentRect.y + parentRect.height - widget:getHeight())        
	widget:move(x, y)
	storage.widgetPos["pkTimeWidget"] = {x = x, y = y}
	return true
end

local name = "pkTimeWidget"
storage.widgetPos[name] = storage.widgetPos[name] or {}
pkTimeWidget:setPosition({x = storage.widgetPos[name].x or 50, y = storage.widgetPos[name].y or 50})



if g_game.getWorldName() == "Katon" then -- FIX NTO SPLIT
	-- FIX (Slow macro): getSpecs() fazia uma varredura manual de todas as
	-- tiles visiveis toda vez que era chamada, e era chamada (via
	-- getPlayerByName) dentro de macro(1, ...) -- ou seja, a cada 1ms -- tanto
	-- aqui no pkTimeMacro quanto de dentro do Sense.lua. Agora reaproveita
	-- getSpectators(), que o proprio client ja mantem otimizado, em vez de
	-- escanear tile por tile toda vez.
	function getSpecs()
		if type(getSpectators) == "function" then
			return getSpectators()
		end
		local specs = {}
		for _, tile in pairs(g_map.getTiles(posz())) do
			local creatures = tile:getCreatures();
			if (#creatures > 0) then
				for i = 1, #creatures do
					table.insert(specs, creatures[i]);
				end
			end
		end
		return specs
	end
	function getPlayerByName(name)
		name = name:lower():trim();
		for _, spec in ipairs(getSpecs()) do
			if spec:getName():lower() == name then
				return spec
			end
		end
	end
end

pkTimeMacro = macro(100, function()
	local time = os and os.time() or now
	if isInPz() then storage.battleTracking[1] = 0 end
	for specName, value in pairs(storage.battleTracking[3]) do
		if (os and value.timeBattle >= time) or (not os and value.timeBattle >= time and value.timeBattle - 60000 <= time) then
			local playerSearch = getPlayerByName(specName, true)
			if playerSearch then
				if playerSearch:getId() == value.playerId then
					if playerSearch:getHealthPercent() == 0 then
						storage.battleTracking[1] = not os and time + (pzTime * 60 * 1000) or time + (pzTime * 60)
						storage.battleTracking[3][specName] = nil
					end
				else
					storage.battleTracking[3][specName] = nil
				end
			end
		else
			storage.battleTracking[3][specName] = nil
		end
	end
	local timeWidget = pkTimeWidget
	if storage.battleTracking[1] < time then
		timeWidget:setText("SAFE  |  PK 00:00")
		timeWidget:setColor("#67e8a5")
		timeWidget:setBorderColor("#23895a")
	else
		timeWidget:setText("DANGER  |  PK " .. doFormatMin(storage.battleTracking[1] - time))
		timeWidget:setColor("#ff6b6b")
		timeWidget:setBorderColor("#b83b45")
	end
end)
