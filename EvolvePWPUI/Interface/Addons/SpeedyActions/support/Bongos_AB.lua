local Support = {}
Support.usage = SpeedyActionsLocals["Keeps Bongos actions sped up, also speeds up Bongos buttons that are not bound to a key."]
SpeedyActions.supportModules["Bongos_AB"] = Support

local _G = getfenv(0)

function Support:SupportLoaded()
	--ActionBar
	local Bongos3_oldfunc = Bongos3.modules.ActionBar.Button.Create
	function Bongos3.modules.ActionBar.Button:Create(parent)
		local button = Bongos3_oldfunc(self, parent)			
		button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
		SpeedyActions.overriddenButtons[button] = true
		return button
	end
	--StanceBar
	--PetBar
end

