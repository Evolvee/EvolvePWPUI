local Support = {}
Support.usage = SpeedyActionsLocals["Keeps Bartender3 actions sped up, also speeds up Bartender4 buttons that are not bound to a key."]
SpeedyActions.supportModules["Bartender3"] = Support

local _G = getfenv(0)


function Support:SupportLoaded()
	--[[
	hooksecurefunc(Bartender4.modules.StanceBar, "CreateStanceButton", function(self, id)
		local button = _G[string.format("BT4StanceButton%d", id)]
		button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
		SpeedyActions.overriddenButtons[button] = true
	end)]]
		
	hooksecurefunc(Bartender3.Class.Button.prototype, "init", function(self, parent, id)
		local button = _G["BT3Button"..id]
		button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
	end)
	--[[
	hooksecurefunc(Bartender3.Class.Button.prototype, "CreateButtonFrame", function(self)
		
	end)
	]]

	--[[
	hooksecurefunc(Bartender4.modules.PetBar, "OnEnable", function(self, ...)
		for _, button in pairs(self.bar.buttons) do
			button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
			SpeedyActions.overriddenButtons[button] = true
		end
	end)]]
end

