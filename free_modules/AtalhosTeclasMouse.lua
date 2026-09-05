mouseShortcutsUI = {};

-- Usa a storage nativa do bot (igual Combo/ComboUP), salva por personagem/perfil.
storage.mouseShortcuts_data = storage.mouseShortcuts_data or {
    enabled = false,
    entries = {}
};
mouseShortcuts_data = storage.mouseShortcuts_data;
mouseShortcuts_data.entries = mouseShortcuts_data.entries or {};

mouseShortcutsUI.save = function()
    if (type(saveConfig) == "function") then
        saveConfig();
    end
end

-- Nenhuma lista fixa de botões: o número digitado é usado direto,
-- do mesmo jeito que g_mouse.isPressed(numero) espera na macro.

local entryTemplateMS = [[
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
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 25
    margin-right: 25
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

mouseShortcutsUI.buttons = setupUI([[
Panel
  height: 17
  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    text-align: center
    !text: tr('Mouse Shortcuts')

    image-source:

    $on:
      color: green

    $!on:
      color: white
]]);

mouseShortcutsUI.interface = setupUI([[
MainWindow
  !text: tr('Mouse Shortcuts - Configuracoes')
  size: 320 340

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
    padding: 3

    Label
      id: listTitle
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      text-align: center
      font: sans-bold-16px
      color: orange
      margin-top: 5
      text: Atalhos

    ScrollablePanel
      id: shortcutList
      layout:
        type: verticalBox
      anchors.top: listTitle.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: buttonNumberLabel.top
      margin-top: 5
      margin-bottom: 8
      vertical-scrollbar: shortcutListScroll

    VerticalScrollBar
      id: shortcutListScroll
      anchors.top: shortcutList.top
      anchors.bottom: shortcutList.bottom
      anchors.right: shortcutList.right
      step: 14
      pixels-scroll: true

    Label
      id: buttonNumberLabel
      anchors.left: parent.left
      anchors.bottom: nameLabel.top
      margin-bottom: 14
      text: Numero do botao (mouse)

    TextEdit
      id: buttonField
      tooltip: Numero do botao do mouse (ex: 1, 2, 3, 7, 8...)
      anchors.left: buttonNumberLabel.right
      anchors.verticalCenter: buttonNumberLabel.verticalCenter
      margin-left: 8
      width: 50

    Label
      id: nameLabel
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      margin-bottom: 5
      text: Jutsu

    TextEdit
      id: nameField
      tooltip: Nome do jutsu
      anchors.left: nameLabel.right
      anchors.right: addButton.left
      anchors.verticalCenter: nameLabel.verticalCenter
      margin-left: 8
      margin-right: 5

    Button
      id: addButton
      !text: tr('+')
      anchors.right: parent.right
      anchors.verticalCenter: nameLabel.verticalCenter
      width: 28

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
]], g_ui.getRootWidget());
mouseShortcutsUI.interface:hide();

local function hideLogicMS()
    if not mouseShortcutsUI.interface:isVisible() then
        mouseShortcutsUI.interface:show();
    else
        mouseShortcutsUI.interface:hide();
        mouseShortcutsUI.save();
    end
end

mouseShortcutsUI.interface.bottomBar.closeButton.onClick = hideLogicMS;

mouseShortcutsUI.buttons.title.onClick = function(widget)
    mouseShortcuts_data.enabled = not mouseShortcuts_data.enabled;
    widget:setOn(mouseShortcuts_data.enabled);
    mouseShortcutsUI.save();
end

-- Config agora abre com botao direito em qualquer parte da linha (painel, nao so o switch)
mouseShortcutsUI.buttons.onMouseRelease = function(self, mousePos, mouseButton)
    if mouseButton == 2 then
        hideLogicMS();
    end
end

local function buildEntryMS(entry, index)
    local label = setupUI(entryTemplateMS, mouseShortcutsUI.interface.mainPanel.shortcutList);
    label.text:setText("Botao " .. tostring(entry.button) .. "  ->  " .. entry.spellName);
    label.enabled:setChecked(entry.enabled);
    label.enabled.onClick = function()
        entry.enabled = not entry.enabled;
        label.enabled:setChecked(entry.enabled);
        mouseShortcutsUI.save();
    end
    label.remove.onClick = function()
        table.remove(mouseShortcuts_data.entries, index);
        mouseShortcutsUI.save();
        mouseShortcutsUI.refreshList();
    end
end

mouseShortcutsUI.refreshList = function()
    mouseShortcutsUI.interface.mainPanel.shortcutList:destroyChildren();
    for index, entry in ipairs(mouseShortcuts_data.entries) do
        buildEntryMS(entry, index);
    end
end

mouseShortcutsUI.interface.mainPanel.addButton.onClick = function()
    local field = mouseShortcutsUI.interface.mainPanel.nameField;
    local spellName = field:getText():trim();
    if (not spellName or spellName:len() == 0) then return; end

    local buttonField = mouseShortcutsUI.interface.mainPanel.buttonField;
    local buttonNumber = tonumber(buttonField:getText():trim());
    if (not buttonNumber) then
        warn("[Mouse Shortcuts] Digite um numero valido pro botao do mouse.");
        return;
    end

    table.insert(mouseShortcuts_data.entries, {
        button = buttonNumber,
        spellName = spellName,
        enabled = true
    });
    field:setText("");
    buttonField:setText("");
    mouseShortcutsUI.save();
    mouseShortcutsUI.refreshList();
end

mouseShortcutsUI.onLoading = function()
    mouseShortcutsUI.buttons.title:setOn(mouseShortcuts_data.enabled or false);
    mouseShortcutsUI.refreshList();
end
mouseShortcutsUI.onLoading();

-- Macro anônima (sem nome) de propósito, pra não criar uma entrada
-- separada na lista de scripts além do painel "Mouse Shortcuts".
macro(100, function()
    if (not mouseShortcuts_data.enabled) then return; end
    for _, entry in ipairs(mouseShortcuts_data.entries) do
        if (entry.enabled and g_mouse.isPressed(entry.button)) then
            say(entry.spellName);
        end
    end
end);
