-- Shazam Scripts - utilidades independentes reunidas na aba UTI.
setDefaultTab("UTI")

storage["changeWeapon"] = storage["changeWeapon"] == true
storage["buyBless"] = storage["buyBless"] == true
storage["buyAol"] = storage["buyAol"] == true

local checkBoxStyle = [[
CheckBox
  id: checkBox
  font: cipsoftFont
]]

UI["Separator"]()
UI["Label"]("Utilidades")

local changeWeaponBox = setupUI(checkBoxStyle)
changeWeaponBox:setText("Change Weapon")

local closeLabel = UI["Label"]("Arma de perto")
local closeWidget = addTextEdit("closeWeapon", storage["CLOSE_ID"] or 3281, function(widget, text)
    local itemId = tonumber(text)
    if not itemId then
        return widget:setText(widget["oldText"] or storage["CLOSE_ID"] or 3281)
    end
    widget["oldText"] = itemId
    storage["CLOSE_ID"] = itemId
end)

local distLabel = UI["Label"]("Arma de longe")
local distWidget = addTextEdit("distWeapon", storage["DIST_ID"] or 3067, function(widget, text)
    local itemId = tonumber(text)
    if not itemId then
        return widget:setText(widget["oldText"] or storage["DIST_ID"] or 3067)
    end
    widget["oldText"] = itemId
    storage["DIST_ID"] = itemId
end)

local function setWeaponWidgetsVisible(visible)
    for _, widget in ipairs({closeLabel, closeWidget, distLabel, distWidget}) do
        if visible then
            widget:show()
        else
            widget:hide()
        end
    end
end

changeWeaponBox["onCheckChange"] = function(widget, checked)
    storage["changeWeapon"] = checked
    widget:setChecked(checked)
    setWeaponWidgetsVisible(checked)
end
changeWeaponBox:setChecked(storage["changeWeapon"])
setWeaponWidgetsVisible(storage["changeWeapon"])

macro(50, function()
    if not storage["changeWeapon"] then return end

    local target = tyrBot and tyrBot["getAttackingCreature"] and tyrBot["getAttackingCreature"]()
    if not target or not target:getPosition() then return end

    local distance = getDistanceBetween(target:getPosition(), pos())
    local desiredId = distance <= 1 and tonumber(storage["CLOSE_ID"]) or tonumber(storage["DIST_ID"])
    if not desiredId or desiredId <= 0 then return end

    local equipped = getLeft()
    if equipped and equipped:getId() == desiredId then return end

    local item = findItem(desiredId)
    if item then
        g_game["stop"]()
        moveToSlot(item, SlotLeft)
    end
end)

UI["Separator"]()

local buyBlessBox = setupUI(checkBoxStyle)
buyBlessBox:setText("Buy Bless")
buyBlessBox["onCheckChange"] = function(widget, checked)
    storage["buyBless"] = checked
    widget:setChecked(checked)
end
buyBlessBox:setChecked(storage["buyBless"])

local buyAolBox = setupUI(checkBoxStyle)
buyAolBox:setText("Buy AOL")
buyAolBox["onCheckChange"] = function(widget, checked)
    storage["buyAol"] = checked
    widget:setChecked(checked)
end
buyAolBox:setChecked(storage["buyAol"])

local blessBought = false
local function npcSay(text)
    if g_game and type(g_game["talkChannel"]) == "function" then
        g_game["talkChannel"](11, 0, text)
    end
end

onTextMessage(function(_, text)
    local message = tostring(text or ""):lower()
    if message:find("bless") and (
        message:find("ja esta") or
        message:find("voce ja") or
        message:find("already") or
        message:find("com a")
    ) then
        blessBought = true
    end
end)

macro(2000, function()
    if storage["buyBless"] and not blessBought then
        npcSay("!bless")
    end
end)

macro(2000, function()
    if storage["buyAol"] and not getNeck() then
        npcSay("!aol")
    end
end)

UI["Separator"]()
UI["Label"]("MW (Magic Wall)")

-- ID do item da MW, usado pelas 6 macros de MW do painel PVP / MW (Macros.lua):
-- MW no mouse, Mwall na frente do alvo [F5], MW no cursor [R], timer visual,
-- Mw Atras e Hold MW [X]. Muda aqui e reflete nas 6 na hora, sem reiniciar nada.
storage.pvpPanel = storage.pvpPanel or {}
storage.pvpPanel.mwId = storage.pvpPanel.mwId or 12105

local mwIdLabel = UI["Label"]("ID da MW")
local mwIdWidget = addTextEdit("mwId", storage.pvpPanel.mwId, function(widget, text)
    local itemId = tonumber(text)
    if not itemId then
        return widget:setText(widget["oldText"] or storage.pvpPanel.mwId or 12105)
    end
    widget["oldText"] = itemId
    storage.pvpPanel.mwId = itemId
end)
