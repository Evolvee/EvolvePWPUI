local FRAMEZ = CreateFrame("FRAME")

FRAMEZ:RegisterEvent("ADDON_LOADED")

FRAMEZ:SetScript("OnUpdate", 

	function()
		TargetofTargetFrame:ClearAllPoints();
		TargetofTargetFrame:SetPoint("RIGHT", "TargetFrame", "BOTTOMRIGHT", -20, 5);
	end 
	
) 
