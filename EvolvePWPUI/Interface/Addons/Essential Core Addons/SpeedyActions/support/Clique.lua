-- In honor of clad, who will kill me when he sees this
local Support = {}
Support.usage = SpeedyActionsLocals["Speeds up click casting, making actions trigger on mouse down rather than on release."]
SpeedyActions.supportModules["Clique"] = Support

function Support:SupportLoaded()
	-- Register all existing frames loaded before the module
	if( ClickCastFrames ) then
		for frame in pairs(ClickCastFrames) do
			frame:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
			SpeedyActions.overriddenButtons[frame] = true
		end
	end
	
	-- Now keep watch for any frames registered after that should also be sped up
	local Orig_RegisterFrame = Clique.RegisterFrame
	Clique.RegisterFrame = function(self, frame, ...)
		Orig_RegisterFrame(self, frame, ...)
		
		frame:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
		SpeedyActions.overriddenButtons[frame] = true
	end

	local Orig_UnregisterFrame = Clique.UnregisterFrame
	Clique.UnregisterFrame = function(self, frame, ...)
		Orig_UnregisterFrame(self, frame, ...)
		
		frame:RegisterForClicks("AnyUp")
		SpeedyActions.overriddenButtons[frame] = true
	end
end


