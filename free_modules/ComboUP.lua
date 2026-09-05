comboUpUI = {};
-- Usa a tabela "storage" nativa do bot (salva por personagem/perfil,
-- igual o Combo faz) em vez de escrever um arquivo .json manualmente.
storage.comboup_data = storage.comboup_data or {
    enabled = false,
    distance = 3,
    amountOfMonsters = 4,
    comboSpells = {},
    areaSpells = {}
};
comboup_data = storage.comboup_data;
comboup_data.comboSpells = comboup_data.comboSpells or {};
comboup_data.areaSpells = comboup_data.areaSpells or {};

comboUpUI.save = function()
    if (type(saveConfig) == "function") then
        saveConfig();
    end
end

local entryTemplateUp = [[
UIWidget
  background-color: alpha
  text-offset: 18 0
  focusable: true
  height: 16

  CheckBox
    id: enabled
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 15
    height: 15
    margin-top: 2
    margin-left: 3

  Label
    id: text
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 25
    font: terminus-14px-bold

  $focus:
    background-color: #00000055

  Button
    id: remove
    !text: tr('X')
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 18
    width: 15
    height: 15
    tooltip: Remover
]];

comboUpUI.buttons = setupUI([[
Panel
  height: 17
  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    text-align: center
    !text: tr('ComboUP')

    image-source:

    $on:
      color: green

    $!on:
      color: white
]]);

comboUpUI.interface = setupUI([[
MainWindow
  !text: tr('ComboUP - BY Shazam')
  size: 480 340

  Panel
    id: leftPanel
    image-source: /images/ui/panel_flat
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.bottom: bottomBar.top
    margin-top: 10
    margin-left: 10
    margin-bottom: 10
    width: 220
    image-border: 6
    padding: 3

    Label
      id: comboTitle
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      text-align: center
      font: sans-bold-16px
      color: orange
      margin-top: 5
      text: Combo

    ScrollablePanel
      id: comboList
      layout:
        type: verticalBox
      anchors.top: comboTitle.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: comboAddButton.top
      margin-top: 5
      margin-bottom: 5
      vertical-scrollbar: comboListScroll

    VerticalScrollBar
      id: comboListScroll
      anchors.top: comboList.top
      anchors.bottom: comboList.bottom
      anchors.right: comboList.right
      step: 14
      pixels-scroll: true

    TextEdit
      id: comboNameField
      tooltip: Nome da magia do combo
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      margin-bottom: 5
      width: 130

    Button
      id: comboAddButton
      !text: tr('+')
      anchors.left: comboNameField.right
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      margin-left: 3
      margin-bottom: 5

  Panel
    id: rightPanel
    image-source: /images/ui/panel_flat
    anchors.top: parent.top
    anchors.left: leftPanel.right
    anchors.right: parent.right
    anchors.bottom: bottomBar.top
    margin-top: 10
    margin-left: 10
    margin-right: 10
    margin-bottom: 10
    image-border: 6
    padding: 3

    Label
      id: areaTitle
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      text-align: center
      font: sans-bold-16px
      color: orange
      margin-top: 5
      text: Area

    ScrollablePanel
      id: areaList
      layout:
        type: verticalBox
      anchors.top: areaTitle.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: areaAddButton.top
      margin-top: 5
      margin-bottom: 5
      vertical-scrollbar: areaListScroll

    VerticalScrollBar
      id: areaListScroll
      anchors.top: areaList.top
      anchors.bottom: areaList.bottom
      anchors.right: areaList.right
      step: 14
      pixels-scroll: true

    TextEdit
      id: areaNameField
      tooltip: Nome da magia de area
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      margin-bottom: 5
      width: 130

    Button
      id: areaAddButton
      !text: tr('+')
      anchors.left: areaNameField.right
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      margin-left: 3
      margin-bottom: 5

  Panel
    id: bottomBar
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 60

    Label
      id: distanceLabel
      anchors.top: parent.top
      anchors.left: parent.left
      margin-left: 10
      margin-top: 3
      text: Distancia

    HorizontalScrollBar
      id: distance
      anchors.top: distanceLabel.bottom
      anchors.left: parent.left
      margin-left: 10
      width: 110
      minimum: 0
      maximum: 10
      step: 1

    Label
      id: distanceValue
      anchors.verticalCenter: distance.verticalCenter
      anchors.left: distance.right
      margin-left: 6
      width: 20
      text: '0'

    Label
      id: amountLabel
      anchors.top: parent.top
      anchors.left: distanceValue.right
      margin-left: 20
      margin-top: 3
      text: Qtd. monstros (area)

    HorizontalScrollBar
      id: amount
      anchors.top: amountLabel.bottom
      anchors.left: distanceValue.right
      margin-left: 20
      width: 110
      minimum: 1
      maximum: 15
      step: 1

    Label
      id: amountValue
      anchors.verticalCenter: amount.verticalCenter
      anchors.left: amount.right
      margin-left: 6
      width: 20
      text: '0'

    Button
      id: closeButton
      !text: tr('Fechar')
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      margin-right: 10
      margin-bottom: 5
      size: 70 21

  Panel
    id: cooldownPopup
    image-source: /images/ui/panel_flat
    image-border: 6
    anchors.centerIn: parent
    size: 240 130
    visible: false

    Label
      id: title
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 8
      font: sans-bold-16px
      color: orange
      text: Cooldown do jutsu

    Label
      id: spellNameLabel
      anchors.top: prev.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      margin-top: 8
      margin-left: 10
      margin-right: 10
      text-align: center
      text-auto-resize: true
      text-wrap: true
      color: white
      text: ''

    Label
      id: cooldownLabel
      anchors.top: prev.bottom
      anchors.left: parent.left
      margin-left: 15
      margin-top: 10
      text: Cooldown (seg)

    HorizontalScrollBar
      id: cooldown
      anchors.top: prev.bottom
      anchors.left: parent.left
      margin-left: 15
      margin-top: 3
      width: 130
      minimum: 0
      maximum: 120
      step: 1

    Label
      id: cooldownValue
      anchors.verticalCenter: cooldown.verticalCenter
      anchors.left: cooldown.right
      margin-left: 6
      width: 25
      text: '0'

    Button
      id: confirmButton
      !text: tr('Adicionar')
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.right: cancelButton.left
      margin-left: 10
      margin-right: 5
      margin-bottom: 8

    Button
      id: cancelButton
      !text: tr('Cancelar')
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      margin-right: 10
      margin-bottom: 8
      width: 70
]], g_ui.getRootWidget());
comboUpUI.interface:hide();

local function hideLogicUp()
    if not comboUpUI.interface:isVisible() then
        comboUpUI.interface:show();
    else
        comboUpUI.interface.cooldownPopup:setVisible(false);
        comboUpUI.interface:hide();
        comboUpUI.save();
    end
end

comboUpUI.interface.bottomBar.closeButton.onClick = hideLogicUp;

comboUpUI.buttons.title.onClick = function(widget)
    comboup_data.enabled = not comboup_data.enabled;
    widget:setOn(comboup_data.enabled);
    comboUpUI.save();
end

-- Config agora abre com botao direito em qualquer parte da linha (painel, nao so o switch)
comboUpUI.buttons.onMouseRelease = function(self, mousePos, mouseButton)
    if mouseButton == 2 then
        hideLogicUp();
    end
end

local function buildEntryUp(parentList, listKey, entry, index)
    local label = setupUI(entryTemplateUp, parentList);
    local cooldownTotal = entry.cooldownTotal or 0;
    label.text:setText(entry.spellName);
    if (cooldownTotal > 0) then
        label:setTooltip("Cooldown: " .. cooldownTotal .. "s");
    else
        label:setTooltip("Sem cooldown");
    end
    label.enabled:setChecked(entry.enabled);
    label.enabled.onClick = function()
        entry.enabled = not entry.enabled;
        label.enabled:setChecked(entry.enabled);
        comboUpUI.save();
    end
    label.remove.onClick = function()
        table.remove(comboup_data[listKey], index);
        comboUpUI.save();
        comboUpUI.refreshLists();
    end
end

comboUpUI.refreshLists = function()
    comboUpUI.interface.leftPanel.comboList:destroyChildren();
    for index, entry in ipairs(comboup_data.comboSpells) do
        buildEntryUp(comboUpUI.interface.leftPanel.comboList, "comboSpells", entry, index);
    end
    comboUpUI.interface.rightPanel.areaList:destroyChildren();
    for index, entry in ipairs(comboup_data.areaSpells) do
        buildEntryUp(comboUpUI.interface.rightPanel.areaList, "areaSpells", entry, index);
    end
end

-- Guarda qual lista (comboSpells/areaSpells) e qual nome de magia
-- está pendente enquanto o popup de cooldown está aberto.
local pendingListKey = nil;
local pendingSpellName = nil;

local function openCooldownPopup(listKey, spellName)
    pendingListKey = listKey;
    pendingSpellName = spellName;
    local popup = comboUpUI.interface.cooldownPopup;
    popup.spellNameLabel:setText(spellName);
    popup.cooldown:setValue(0);
    popup.cooldownValue:setText('0');
    popup:setVisible(true);
end

comboUpUI.interface.cooldownPopup.cooldown.onValueChange = function(widget, value)
    comboUpUI.interface.cooldownPopup.cooldownValue:setText(tostring(value));
end

comboUpUI.interface.cooldownPopup.cancelButton.onClick = function()
    comboUpUI.interface.cooldownPopup:setVisible(false);
    pendingListKey = nil;
    pendingSpellName = nil;
end

comboUpUI.interface.cooldownPopup.confirmButton.onClick = function()
    if (not pendingListKey or not pendingSpellName) then
        comboUpUI.interface.cooldownPopup:setVisible(false);
        return;
    end
    local cooldownTotal = comboUpUI.interface.cooldownPopup.cooldown:getValue();
    table.insert(comboup_data[pendingListKey], {
        spellName = pendingSpellName,
        enabled = true,
        cooldownTotal = cooldownTotal,
        cooldownTime = nil
    });
    comboUpUI.interface.cooldownPopup:setVisible(false);
    pendingListKey = nil;
    pendingSpellName = nil;
    comboUpUI.save();
    comboUpUI.refreshLists();
end

comboUpUI.interface.leftPanel.comboAddButton.onClick = function()
    local field = comboUpUI.interface.leftPanel.comboNameField;
    local spellName = field:getText():trim();
    if (not spellName or spellName:len() == 0) then return; end
    field:setText("");
    openCooldownPopup("comboSpells", spellName);
end

comboUpUI.interface.rightPanel.areaAddButton.onClick = function()
    local field = comboUpUI.interface.rightPanel.areaNameField;
    local spellName = field:getText():trim();
    if (not spellName or spellName:len() == 0) then return; end
    field:setText("");
    openCooldownPopup("areaSpells", spellName);
end

comboUpUI.interface.bottomBar.distance.onValueChange = function(widget, value)
    comboup_data.distance = value;
    comboUpUI.interface.bottomBar.distanceValue:setText(tostring(value));
    comboUpUI.save();
end

comboUpUI.interface.bottomBar.amount.onValueChange = function(widget, value)
    comboup_data.amountOfMonsters = value;
    comboUpUI.interface.bottomBar.amountValue:setText(tostring(value));
    comboUpUI.save();
end

comboUpUI.onLoading = function()
    comboUpUI.buttons.title:setOn(comboup_data.enabled or false);
    comboUpUI.interface.bottomBar.distance:setValue(comboup_data.distance or 3);
    comboUpUI.interface.bottomBar.amount:setValue(comboup_data.amountOfMonsters or 4);
    comboUpUI.interface.bottomBar.distanceValue:setText(tostring(comboup_data.distance or 3));
    comboUpUI.interface.bottomBar.amountValue:setText(tostring(comboup_data.amountOfMonsters or 4));
    comboUpUI.refreshLists();
end
comboUpUI.onLoading();

-- Macro anônima (sem nome) de propósito, pra não criar uma entrada
-- separada na lista de scripts do bot além do painel "ComboUP".
macro(250, function()
    if (not comboup_data.enabled) then return; end
    if (not g_game.isAttacking()) then return; end

    local specAmount = 0;
    for _, mob in ipairs(getSpectators()) do
        local mobPos = FREE_SAFE_POSITION and FREE_SAFE_POSITION(mob) or nil;
        local playerPos = FREE_SAFE_POSITION and FREE_SAFE_POSITION(player) or nil;
        if (mob:isMonster() and playerPos and mobPos and getDistanceBetween(playerPos, mobPos) <= (comboup_data.distance or 3)) then
            specAmount = specAmount + 1;
        end
    end

    local now = os.time();
    local function castIfReady(entry)
        if (not entry.enabled) then return; end
        if (entry.cooldownTime and entry.cooldownTime > now) then return; end
        -- "-1" pula o delay de "digitacao" padrao do say(), igual o
        -- AntiRed.lua ja faz. Sem isso, trocar de magia de area pra
        -- combo (fast attack) ou vice-versa fica preso no delay padrao.
        say(entry.spellName, -1);
        local cooldownTotal = entry.cooldownTotal or 0;
        if (cooldownTotal > 0) then
            entry.cooldownTime = now + cooldownTotal;
        end
    end

    if (specAmount >= (comboup_data.amountOfMonsters or 4)) then
        for _, entry in ipairs(comboup_data.areaSpells) do
            castIfReady(entry);
        end
    else
        for _, entry in ipairs(comboup_data.comboSpells) do
            castIfReady(entry);
        end
    end
end);