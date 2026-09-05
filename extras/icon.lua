-- Controles rapidos com estado visual consistente com o tema Shazam.

local cIcon = addIcon("shazamCave",{text="CAVE\nOFF",switchable=false,moveable=true}, function()
  if CaveBot.isOff() then 
    CaveBot.setOn()
  else 
    CaveBot.setOff()
  end
end)
cIcon:setSize({height=42,width=68})
cIcon:setBackgroundColor("#ffffff00")
cIcon:setImageColor("#ffffff00")
cIcon:setBorderWidth(0)
cIcon.text:setFont('verdana-11px-rounded')
cIcon.onHoverChange = function(widget)
  widget:setBackgroundColor("#ffffff00")
  widget:setImageColor("#ffffff00")
  widget:setBorderWidth(0)
end

local tIcon = addIcon("shazamTarget",{text="TARGET\nOFF",switchable=false,moveable=true}, function()
  if TargetBot.isOff() then 
    TargetBot.setOn()
  else 
    TargetBot.setOff()
  end
end)
tIcon:setSize({height=42,width=68})
tIcon:setBackgroundColor("#ffffff00")
tIcon:setImageColor("#ffffff00")
tIcon:setBorderWidth(0)
tIcon.text:setFont('verdana-11px-rounded')
tIcon.onHoverChange = function(widget)
  widget:setBackgroundColor("#ffffff00")
  widget:setImageColor("#ffffff00")
  widget:setBorderWidth(0)
end

macro(100,function()
  if CaveBot.isOn() then
    cIcon.text:setColoredText({"CAVE\n","#ffffff","ON","#55ff72"})
  else
    cIcon.text:setColoredText({"CAVE\n","#ffffff","OFF","#ffffff"})
  end
  if TargetBot.isOn() then
    tIcon.text:setColoredText({"TARGET\n","#ffffff","ON","#55ff72"})
  else
    tIcon.text:setColoredText({"TARGET\n","#ffffff","OFF","#ffffff"})
  end
end)
UI.Separator()
