local Support = {}
Support.usage = SpeedyActionsLocals["Keeps Bartender4 actions sped up, also speeds up Bartender4 buttons that are not bound to a key."]
SpeedyActions.supportModules["Bartender4"] = Support

local _G = getfenv(0)

-- Ugly solution, but it works and it stops Bartender4 from not having actions associated to it correctly
-- buttons only have to be overrode once because after that the issue where Bartender4 hasn't registered yet is fixed
function Support:SupportLoaded()
	-- Make sure non-keybound buttons are also sped up
	hooksecurefunc(Bartender4.modules.StanceBar, "CreateStanceButton", function(self, id)
		local button = _G[string.format("BT4StanceButton%d", id)]
		button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
		SpeedyActions.overriddenButtons[button] = true
	end)
	--[[
	hooksecurefunc(Bartender4.Button, "Create", function(self, id, parent)
		local button = _G[string.format("BT4Button%d", (parent.id - 1) * 12 + id)]
		button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
		print(button:GetName())
	end)]]
	
	local Bartender4_oldfunc = Bartender4.Button.Create
	function Bartender4.Button:Create(id, parent)
		local button = Bartender4_oldfunc(self, id, parent)			
		button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
		SpeedyActions.overriddenButtons[button] = true
		return button
	end
		
	hooksecurefunc(Bartender4.modules.PetBar, "OnEnable", function(self, ...)
		for _, button in pairs(self.bar.buttons) do
			button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
			SpeedyActions.overriddenButtons[button] = true
		end
	end)
end

