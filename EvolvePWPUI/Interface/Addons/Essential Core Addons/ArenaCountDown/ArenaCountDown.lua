-- An Addon By Midna/Ramono
local timer = 0
local total = 0
local frame = CreateFrame("FRAME", "ArenaCountDown")
frame:ClearAllPoints()
frame:SetHeight(300)
frame:SetWidth(300)
frame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
frame.text = frame:CreateFontString(nil, "BACKGROUND", "PVPInfoTextFont")
frame.text:SetAllPoints()
frame:SetPoint("CENTER", UIPARENT, "CENTER", 0, 0)
frame:SetAlpha(1)

local function OnUpdate(self,elapsed)
  total = total + elapsed
  if (total >= 1.0) then
    total = total - 1
    timer = timer - 1
    frame.text:SetText(timer)
    if(timer == 0) then
      frame:Hide()
      frame:SetScript("OnUpdate", nil)
    end
  end

end

local function EventHandler(self, event, ...)
		if(string.find(arg1, "Fifteen seconds until the Arena battle begins!")) then
			timer = 15
			frame.text:SetText(timer)
			frame:Show()
			frame:SetScript("OnUpdate", OnUpdate)
		end				
end
frame:SetScript("OnEvent", EventHandler)