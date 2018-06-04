local Support = {}
Support.usage = SpeedyActionsLocals["Speeds up clicking of LunarSphere actions as well as key bindings."]
SpeedyActions.supportModules["LunarSphere"] = Support

local _G = getfenv(0)
function Support:SupportLoaded()
	hooksecurefunc(Lunar.Button, "Initialize", function()
		-- First 10 buttons are menus, after that they are all sub menus
		local id = 1
		while( true ) do
			local button = id <= 10 and _G["LunarMenu" .. id .. "Button"] or _G["LunarSub" .. id .. "Button"]
			if( not button ) then break end
			
			button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
			SpeedyActions.overriddenButtons[button] = true
			id = id + 1
		end
	end)
end