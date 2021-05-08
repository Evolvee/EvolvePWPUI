-- /script countdown = 60
local Gladdy = LibStub("Gladdy")
local L = Gladdy.L
local ACDFrame = Gladdy:NewModule("Countdown", nil, {
	countdown = true,
})

function ACDFrame:Initialise()
	self.hidden = false
	self.countdown = -1
	self.texturePath = "Interface\\AddOns\\Gladdy\\Images\\Countdown\\";
end

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
ACDNumTens:SetPoint("CENTER", ACDNumFrame, "CENTER", -48, 0)

local ACDNumOnes = ACDNumFrame:CreateTexture("ACDNumOnes", "HIGH")
ACDNumOnes:SetWidth(256)
ACDNumOnes:SetHeight(128)
ACDNumOnes:SetPoint("CENTER", ACDNumFrame, "CENTER", 48, 0)

local ACDNumOne = ACDNumFrame:CreateTexture("ACDNumOne", "HIGH")
ACDNumOne:SetWidth(256)
ACDNumOne:SetHeight(128)
ACDNumOne:SetPoint("CENTER", ACDNumFrame, "CENTER", 0, 0)

ACDFrame:SetScript("OnUpdate", function(self, elapse )
	if (self.countdown > 0 and Gladdy.db.countdown) then
		self.hidden = false;
		
		if ((math.floor(self.countdown) ~= math.floor(self.countdown - elapse)) and (math.floor(self.countdown - elapse) >= 0)) then
			local str = tostring(math.floor(self.countdown - elapse));
			
			if (math.floor(self.countdown - elapse) == 0) then
				ACDNumTens:Hide();
				ACDNumOnes:Hide();		
				ACDNumOne:Hide();
			elseif (string.len(str) == 2) then			
				-- Display has 2 digits
				ACDNumTens:Show();
				ACDNumOnes:Show();
				
				ACDNumTens:SetTexture(self.texturePath.. string.sub(str,0,1));
				ACDNumOnes:SetTexture(self.texturePath.. string.sub(str,2,2));
				ACDNumFrame:SetScale(0.7)
			elseif (string.len(str) == 1) then		
				-- Display has 1 digit
				ACDNumOne:Show();
				ACDNumOne:SetTexture(self.texturePath.. string.sub(str,0,1));
				ACDNumOnes:Hide();
				ACDNumTens:Hide();
				ACDNumFrame:SetScale(1.0)
			end
		end
		self.countdown = self.countdown - elapse;
	elseif (not hidden) then
		self.hidden = true;
		ACDNumTens:Hide();
		ACDNumOnes:Hide();
		ACDNumOne:Hide();
	end
	
end)

function ACDFrame:CHAT_MSG_BG_SYSTEM_NEUTRAL(arg1)
	if (event == "CHAT_MSG_BG_SYSTEM_NEUTRAL") then
		if (string.find(arg1, "One minute until the Arena battle begins!")) then
			self.countdown = 61;
			return;
		end
		if (string.find(arg1, "Thirty seconds until the Arena battle begins!")) then
			self.countdown = 31;
			return;
		end
		if (string.find(arg1, "Fifteen seconds until the Arena battle begins!")) then
			self.countdown = 16;
			return;
		end
		if (string.find(arg1, "Ten seconds until the Arena battle begins!")) then
			self.countdown = 11;
			return;
		end		
  end
end

local function option(params)
	local defaults = {
		get = function(info)
			local key = info.arg or info[#info]
			return Gladdy.dbi.profile[key]
		end,
		set = function(info, value)
			local key = info.arg or info[#info]
			Gladdy.dbi.profile[key] = value
			Gladdy:UpdateFrame()
		end,
	}

	for k, v in pairs(params) do
		defaults[k] = v
	end

	return defaults
end

function ACDFrame:GetOptions()
	return {
		countdown = option({
			type = "toggle",
			name = L["Turn on/off"],
			desc = L["Turns countdown before the start of an arena match on/off."],
			order = 2,
		}),
	}
end
