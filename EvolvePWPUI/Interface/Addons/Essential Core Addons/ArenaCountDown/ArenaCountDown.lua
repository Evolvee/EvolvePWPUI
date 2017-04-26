-- /script countdown = 60

local hidden = false;
local countdown = -1;
 
local ACDFrame = CreateFrame("Frame", "ACDFrame", UIParent)
function ACDFrame:OnEvent(event, ...) -- functions created in "object:method"-style have an implicit first parameter of "self", which points to object
	self[event](self, ...) -- route event parameters to LoseControl:event methods
end
ACDFrame:SetScript("OnEvent", ACDFrame.OnEvent)
ACDFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")

local ACDNumFrame = CreateFrame("Frame", "ACDNumFrame", UIParent)
ACDNumFrame:SetHeight(256)
ACDNumFrame:SetWidth(256)
ACDNumFrame:SetPoint("CENTER", 0, 128)
ACDNumFrame:Show()

local ACDNumTens = ACDNumFrame:CreateTexture("ACDNumTens", "HIGH")
ACDNumTens:SetWidth(256)
ACDNumTens:SetHeight(128)
ACDNumTens:SetPoint("CENTER", ACDNumFrame, "CENTER", -64, 0)

local ACDNumOnes = ACDNumFrame:CreateTexture("ACDNumOnes", "HIGH")
ACDNumOnes:SetWidth(256)
ACDNumOnes:SetHeight(128)
ACDNumOnes:SetPoint("CENTER", ACDNumFrame, "CENTER", 64, 0)

local ACDNumOne = ACDNumFrame:CreateTexture("ACDNumOne", "HIGH")
ACDNumOne:SetWidth(256)
ACDNumOne:SetHeight(128)
ACDNumOne:SetPoint("CENTER", ACDNumFrame, "CENTER", 0, 0)

ACDFrame:SetScript("OnUpdate", function(self, elapse )
	if (countdown > 0) then
		hidden = false;
		
		if ((math.floor(countdown) ~= math.floor(countdown - elapse)) and (math.floor(countdown - elapse) >= 0)) then
			local str = tostring(math.floor(countdown - elapse));
			
			if (math.floor(countdown - elapse) == 0) then
				ACDNumTens:Hide();
				ACDNumOnes:Hide();		
				ACDNumOne:Hide();
			elseif (string.len(str) == 2) then			
				-- Display has 2 digits
				ACDNumTens:Show();
				ACDNumOnes:Show();
				
				ACDNumTens:SetTexture("Interface\\AddOns\\ArenaCountDown\\Artwork\\".. string.sub(str,0,1));
				ACDNumOnes:SetTexture("Interface\\AddOns\\ArenaCountDown\\Artwork\\".. string.sub(str,2,2));
			elseif (string.len(str) == 1) then		
				-- Display has 1 digit
				ACDNumOne:Show();
				ACDNumOne:SetTexture("Interface\\AddOns\\ArenaCountDown\\Artwork\\".. string.sub(str,0,1));				
				ACDNumOnes:Hide();
				ACDNumTens:Hide();
			end
		end
		countdown = countdown - elapse;
	elseif (not hidden) then
		hidden = true;
		ACDNumTens:Hide();
		ACDNumOnes:Hide();
		ACDNumOne:Hide();
	end
	
end)

function ACDFrame:CHAT_MSG_BG_SYSTEM_NEUTRAL(arg1)
	if (event == "CHAT_MSG_BG_SYSTEM_NEUTRAL") then
		if (string.find(arg1, "One minute until the Arena battle begins!")) then
			countdown = 61;
			return;
		end
		if (string.find(arg1, "Thirty seconds until the Arena battle begins!")) then
			countdown = 31;
			return;
		end
		if (string.find(arg1, "Fifteen seconds until the Arena battle begins!")) then
			countdown = 16;
			return;
		end		
  end
end
