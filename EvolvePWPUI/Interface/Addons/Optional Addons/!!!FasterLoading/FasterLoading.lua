local RestartGx, SetCVar = RestartGx, SetCVar
local frame = CreateFrame("frame")
frame:SetScript("OnEvent", function(self, event)
	self:UnregisterEvent(event)
	if event == "ADDON_LOADED" then
		SetCVar("gxVSync", 0)
		SetCVar("maxFPS", 0)
		RestartGx()
	else
		self:SetScript("OnEvent", nil)
		SetCVar("gxVSync", 1)
		RestartGx()
		RestartGx, SetCVar = nil, nil
	end
end)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
