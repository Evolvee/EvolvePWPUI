local Support = {}
Support.usage = SpeedyActionsLocals["Speeds up Dominos action key bindings as well as auction buttons that are not bound to a key."]
SpeedyActions.supportModules["Dominos"] = Support

local _G = getfenv(0)

-- Dominos delays creation of its buttons until OnEnable in AceAddon-3.0, unfortunately that means it has to bind everything on UPDATE_BINDINGS when they load, then again when Dominos finishes loading. I'll come up with a better system for this soon
function Support:SupportLoaded()
	hooksecurefunc(Dominos, "Load", function()
		-- If a button isn't key bound then it's possible for it to not be registered to accept clicks, this forces it to accept them
		for id=1, 48 do
			local button = _G["DominosActionButton" .. id]
			if( button ) then
				button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
				SpeedyActions.overriddenButtons[button] = true
			end
		end
		
		for id=1, 10 do
			local button = _G["DominosClassButton" .. id]
			if( button ) then
				button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
				SpeedyActions.overriddenButtons[button] = true
			end
		end

		SpeedyActions:UPDATE_BINDINGS()
	end)
end