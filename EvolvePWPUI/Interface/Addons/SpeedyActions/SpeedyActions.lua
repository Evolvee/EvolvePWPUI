--[[
	SpeedyActions by humfras
	
	SpeedyActions is a modification of
	Speedy Actions by Shadowed / Mayen - Mal'Ganis (US)
]]

SpeedyActions = {supportModules = {}, overriddenButtons = {}}

local L = SpeedyActionsLocals
local _G = getfenv(0)
local CREATED_BUTTONS = 0
local eventFrame = CreateFrame("Frame")
local buttonCache, cachedBindingButton, bindingsLoaded = {}, {}
local overriddenButtons = SpeedyActions.overriddenButtons
local playerclass

local function pairsByKeys(t, f)
	local a = {}
		for n in pairs(t) do table.insert(a, n) end
		table.sort(a, f)
		local i = 0      -- iterator variable
		local iter = function ()   -- iterator function
			i = i + 1
			if a[i] == nil then return nil
			else return a[i], t[a[i]]
			end
		end
	return iter
end

local bindables = {
	'ESCAPE', "`", 'TAB', 'SPACE', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', 'A', 'S',
	'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '-', '=', '[', ']',
	'\\', ';', "'", '.', '/', ',', 'ENTER', 'MOUSEWHEELUP', 'MOUSEWHEELDOWN', 'BACKSPACE', 'DELETE',
	'INSERT', 'HOME', 'END', 'PAGEUP', 'PAGEDOWN', 'NUMLOCK', 'NUMPADSLASH', 'NUMPADMULTIPLY', 'NUMPADMINUS',
	'NUMPADPLUS', 'NUMPADENTER', 'NUMPADPERIOD', "^", "+", "#", "<",
}
for i = 0, 9 do
	bindables[getn(bindables)+1] = tostring(i)
	bindables[getn(bindables)+1] = 'NUMPAD'..i
end
for i = 1, 12 do
	bindables[getn(bindables)+1] = 'F'..i
end
for i = 1, 5 do
	bindables[getn(bindables)+1] = 'BUTTON'..i
end
local modifiers = { -- order: alt-ctrl-shift-
	'', 'ALT-', 'CTRL-', 'SHIFT-', 'ALT-CTRL-', 'ALT-SHIFT-', 'CTRL-SHIFT-', 'ALT-CTRL-SHIFT-'
}

SpeedyActions.AddOns = {
	Blizzard = {
		func = function()
			local buttons = {
				"ActionButton";
				"MultiBarBottomLeftButton";
				"MultiBarBottomRightButton";
				"MultiBarLeftButton";
				"MultiBarRightButton";
				"BonusActionButton";
			}
			for k,v in pairs(buttons) do
				for i=1,12 do
					local name = v..i
					local button = _G[name]
					if button then
						button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
					end
				end
			end
		end;
	};
	Bartender4 = {
		func = function()
			for i=1,120 do
				local name =  "BT4Button"..i.."Secure"
				local button = _G[name]
				if button then
					button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
				end
			end
		end;
	};
	Bongos_AB = {
		func = function()
			for i=1,108 do
				local name = "Bongos3ActionButton"..i
				local button = _G[name]
				if button then
					button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
				end
			end
		end;
	};
	Clique = {
		func = function()
			if( ClickCastFrames ) then
				for frame in pairs(ClickCastFrames) do
					frame:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
				end
			end
		end;
	};
	Dominos = {
		func = function()
			for i=1,48 do
				local button = _G["DominosActionButton"..i]
				if button then
					button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
				end
			end		
			for i=1,10 do
				local button = _G["DominosClassButton"..i]
				if button then
					button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
				end
			end
		end;
	};
	Lunarsphere = {
		func = function()
			local i = 1
			while true do
				local button = i <= 10 and _G["LunarMenu"..i.."Button"] or _G["LunarSub"..i.."Button"]
				if button == nil or not button then break end
				
				button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
				i = i + 1
			end
		end;
	};
	
}

function SpeedyActions:OnInitialize()
	self.defaults = {
		profile = {
			blacklistKeys = {},
			disableModules = {},
			keystate = "Down",
		},
		global = {
			keyList = {},	
		},
	}
	
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("SpeedyActionsDB", self.defaults)
	playerclass = select(2,UnitClass("player"))
end	

function SpeedyActions:AlterAllRegisteredButtons()
	if InCombatLockdown() then SpeedyActions:Print("|cffff0000Can not alter keystate while in combat.|r") return end
	for k,v in pairs(SpeedyActions.AddOns) do
		if IsAddOnLoaded(k) or k == "Blizzard" then
			SpeedyActions.AddOns[k].func()
		end
	end
end

-- Retrieves a button out of the cache
local function retrieveButton(attributeKey, attributeValue)
	local button
	for _, cacheButton in pairs(buttonCache) do
		if( not cacheButton.active ) then
			button = cacheButton
			break
		end
	end
	
	if( not button ) then
		CREATED_BUTTONS = CREATED_BUTTONS + 1
		button = CreateFrame("Button", "SpeedyActionsButton" .. CREATED_BUTTONS, nil, "SecureActionButtonTemplate")
		table.insert(buttonCache, button)
	end
	
	button.active = true
	button.setKey = attributeKey
	button:SetAttribute("type", attributeKey)
	button:SetAttribute(attributeKey, attributeValue)
	
	return button
end

-- Releases all buttons to cache
local function releaseButtons()
	for _, button in pairs(buttonCache) do
		if( button.active ) then
			button:SetAttribute("type", button.setKey)
			button:SetAttribute(button.setKey, nil)
			button.active = nil
			button.setKey = nil
		end	
	end
end

-- Rebinds the actual button
function SpeedyActions:RebindButton(button, key, mouseButton)
	-- The key is blacklisted, it should have the speedy portion disabled and not bound
	if( self.db.profile.blacklistKeys[string.upper(key)] ) then
		if( overriddenButtons[button] ) then button:RegisterForClicks("AnyUp") end
		return
	end
	
	if( type(button) ~= "table" or not button.IsProtected or not button:IsProtected() ) then return end
	button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
	overriddenButtons[button] = true
	
	SetOverrideBindingClick(eventFrame, true, key, button:GetName(), mouseButton)
end

-- Because overriding action buttons 1 - 12 calls the button directly rather than the ActionButton/etc, the actual buttons
-- loose the events that trigger there state change, because those funcitons are secure I have to duplicate them again here
local function fakeActionDown(self)
	if( BonusActionBarFrame:IsShown() ) then
		self.bonusButton:SetButtonState("PUSHED")
	else
		self.actionButton:SetButtonState("PUSHED")
	end
end

local function fakeActionUp(self)
	if( BonusActionBarFrame:IsShown() ) then
		self.bonusButton:SetButtonState("NORMAL")
	else
		self.actionButton:SetButtonState("NORMAL")
	end
end

-- I dislike secure hooking and force overriding, but it's cleaner code wise to do this then hack in support for each action-y mod
local function overrideBinding(owner, isPriority, key)
	if( not InCombatLockdown() and owner ~= eventFrame ) then
		SetOverrideBinding(eventFrame, nil, key) 
		SpeedyActions:OverrideKeybind(key, GetBindingAction(key, true))
		SpeedyActions:RegisterOverrideKey(key)
	end
end

local function normalBinding(key)
	if( not InCombatLockdown() ) then
		SetOverrideBinding(eventFrame, nil, key) 
		SpeedyActions:OverrideKeybind(key, GetBindingAction(key, true))
		SpeedyActions:RegisterOverrideKey(key)
	end
end

hooksecurefunc("SetBindingClick", normalBinding)
hooksecurefunc("SetBindingItem", normalBinding)
hooksecurefunc("SetBindingMacro", normalBinding)
hooksecurefunc("SetBindingSpell", normalBinding)
hooksecurefunc("SetOverrideBindingSpell", overrideBinding)
hooksecurefunc("SetOverrideBindingMacro", overrideBinding)
hooksecurefunc("SetOverrideBindingItem", overrideBinding)
hooksecurefunc("SetOverrideBindingClick", overrideBinding)
hooksecurefunc("SetOverrideBinding", overrideBinding)

local druidstances = {
	icons = {
		["Interface\\Icons\\Ability_Racial_BearForm"] = true,		--Bear/Dire Bear Form
		["Interface\\Icons\\Ability_Druid_AquaticForm"] = false,	--Aquatic Form
		["Interface\\Icons\\Ability_Druid_CatForm"] = true,			--Cat Form
		["Interface\\Icons\\Ability_Druid_TravelForm"] = false,		--Travel Form
		["Interface\\Icons\\Spell_Nature_ForceOfNature"] = true,	--Moonkin Form
		["Interface\\Icons\\Ability_Druid_TreeofLife"] = true,		--Tree Form / Tree of Life
		["Interface\\Icons\\Ability_Druid_FlightForm"] = false,		--Flight Form
	},
	spellIDs = {
		[5487] = true,		--Bear Form	
		[9634] = true,		--Dire Bear Form
		[1066] = false,		--Aquatic Form
		[768] = true,		--Cat Form
		[783] = false,		--Travel Form
		[24858] = true,		--Moonkin Form
		[33891] = true,		--Tree Form / Tree of Life
		[33943] = false,	--Flight Form
		[40120] = false,	--Swift Flight Form
	},
	
}

local function returnDruidStances()
	local stancestring = ""
	local isfirst = true
	for i=1,8 do
		local icon, name, active, castable = GetShapeshiftFormInfo(i)
		if icon == nil then
			break
		else
			if icon == "Interface\\Icons\\Spell_Nature_WispSplode" then
				for spellID,v in pairs(druidstances.spellIDs) do
					local spellname, spellrank, spellicon = GetSpellInfo(spellID)
					if name == spellname then
						icon = spellicon
						break
					end
				end
			end
			if druidstances.icons[icon] then
				stancestring = stancestring..((isfirst and "") or "/")..i
				if isfirst then isfirst = false end
			end
		end				
	end
	
	return stancestring
end

local stances = {
	
	["DRUID"] = returnDruidStances,
	["WARRIOR"] = {
		[1] = "battle",
		[2] = "defence",
		[3] = "berserker",
	},
	["ROGUE"] = {
		[1] = { id = "stealth", name = GetSpellInfo(1784), index = 1 },
	},
	["PRIEST"] = {
		[1] = { id = "shadowform", name = GetSpellInfo(15473), index = 1 },
	},
}


local function GetBlizzardABMacro(actionID)
	local macrotext = "/click"
	local stancetext = ""
			
	local t = stances[playerclass]
	if t then
		if type(t) == "table" then
			local isfirst = true
			for k,v in ipairs(t) do
				stancetext = stancetext..((isfirst and "") or "/")..k
				if isfirst then isfirst = false end
			end
			macrotext = macrotext.." [stance:"..stancetext.."] BonusActionButton"..actionID..";"
		elseif type(t) == "function" then
			stancetext = t()
			macrotext = macrotext.." [stance:"..stancetext.."] BonusActionButton"..actionID..";"
		end
	end
	
	macrotext = macrotext.." ActionButton"..actionID..";"
	
	return macrotext
	
end

-- Takes the action bound to a key and figures out how it's going to have to be bound
function SpeedyActions:OverrideKeybind(key, action)
	if( not action or action == "" ) then return end
	
	-- SetBindingClick, BUTTON# pretty commonly seems to be used by fishing addons along with CLICK actions so simply block any buttons from click actions from being sped up
	local buttonName, mouseButton = string.match(action, "^CLICK (.+):(.+)")
	if( buttonName ) then
		local button = _G[buttonName]
		if( not string.match(key, "^BUTTON(%d+)") and button and ( cachedBindingButton[buttonName] or button:GetAttribute("type") and button:GetAttribute("type") ~= "click" ) ) then
			self:RebindButton(button, key, mouseButton)
		end
		return
	end
	
	-- SetBindingSpell
	local spell = string.match(action, "^SPELL (.+)")
	if( spell ) then
		self:RebindButton(retrieveButton("spell", spell), key)
		return
	end
	
	-- SetBindingItem
	local item = string.match(action, "^ITEM (.+)")
	if( item ) then
		self:RebindButton(retrieveButton("item", item), key)
		return
	end
	
	-- SetBindingMacro
	local macro = string.match(action, "^MACRO (.+)")
	if( macro ) then
		self:RebindButton(retrieveButton("macro", macro), key)
		return
	end
	
	-- SetBinding, but it's a multicast so it needs special handling
	local multiID = string.match(action, "MULTICASTSUMMONBUTTON(%d+)")
	if( multiID ) then
		self:RebindButton(retrieveButton("spell", TOTEM_MULTI_CAST_SUMMON_SPELLS[tonumber(multiID)]), key)
		return
	end
	
	-- SetBinding, for a totem recall
	local recallID = string.match(action, "MULTICASTRECALLBUTTON(%d+)")
	if( recallID ) then
		self:RebindButton(retrieveButton("spell", TOTEM_MULTI_CAST_RECALL_SPELLS[tonumber(recallID)]), key)
		return
	end
	
	-- SetBinding, the action buttons 1 - 12 need special handling, because they can also be stance buttons
	
	local actionID = string.match(action, "^ACTIONBUTTON(%d+)")
	if( actionID ) then
		actionID = tonumber(actionID)
		
		local button = _G["SpeedyActionsBarButton" .. actionID]
		if( not button ) then
			button = CreateFrame("Button", "SpeedyActionsBarButton" .. actionID, nil, "SecureActionButtonTemplate")
			button.actionButton = _G["ActionButton" .. actionID]
			button.bonusButton = _G["BonusActionButton" .. actionID]
			--button.vehicleButton = _G["VehicleMenuBarActionButton" .. actionID]
			button.actionID = actionID
			button:SetAttribute("type", "macro")
			button:SetAttribute("macrotext", GetBlizzardABMacro(actionID))
			--button:SetFrameRef("bonusFrame", BonusActionBarFrame)
			--button:SetFrameRef("vehicleFrame", VehicleMenuBar)
			button:SetScript("OnMouseDown", fakeActionDown)
			button:SetScript("OnMouseUp", fakeActionUp)
						
			-- Fun little restriction, when in combat IsProtected() returns nil, nil for vehicle/bonus frames
			-- unless they are actively being used by something, such as the default UI. IsProtected() check will stop any error
			--[=[
			if( button.vehicleButton ) then
				button:WrapScript(button, "OnClick", string.format([[
					if( self:GetFrameRef("vehicleFrame"):IsProtected() and self:GetFrameRef("vehicleFrame"):IsVisible() ) then
						self:SetAttribute("macrotext", "/click VehicleMenuBarActionButton%d")
					elseif( self:GetFrameRef("bonusFrame"):IsProtected() and self:GetFrameRef("bonusFrame"):IsVisible() ) then
						self:SetAttribute("macrotext", "/click BonusActionButton%d")
					else
						self:SetAttribute("macrotext", "/click ActionButton%d")
					end
				]], actionID, actionID, actionID))
			else
				button:WrapScript(button, "OnClick", string.format([[
					if( self:GetFrameRef("bonusFrame"):IsProtected() and self:GetFrameRef("bonusFrame"):IsVisible() ) then
						self:SetAttribute("macrotext", "/click BonusActionButton%d")
					else
						self:SetAttribute("macrotext", "/click ActionButton%d")
					end
				]], actionID, actionID))
			end]=]
		end
		button:SetAttribute("type", "macro")
		button:SetAttribute("macrotext", GetBlizzardABMacro(actionID))

		-- Annnnd bind us off	
		self:RebindButton(button, key)
		return
	end
	--SpeedyActions.AddOns.Blizzard.func()
	
	
	-- None of those, it should be a default Blizzard one then, because Blizzard does not use the same casing
	-- as the frames name, the mass gsub to turn it into the buttons real name is necessary
	-- it's cached so it doesn't have to do this every time at least 
	local buttonName = cachedBindingButton[action]
	if( not buttonName ) then
		buttonName = string.gsub(action, "MULTIACTIONBAR4BUTTON", "MultiBarLeftButton")
		buttonName = string.gsub(buttonName, "MULTIACTIONBAR3BUTTON", "MultiBarRightButton")
		buttonName = string.gsub(buttonName, "MULTIACTIONBAR2BUTTON", "MultiBarBottomRightButton")
		buttonName = string.gsub(buttonName, "MULTIACTIONBAR1BUTTON", "MultiBarBottomLeftButton")
		buttonName = string.gsub(buttonName, "MULTICASTACTIONBUTTON", "MultiCastActionButton")
		buttonName = string.gsub(buttonName, "SHAPESHIFTBUTTON", "ShapeshiftButton")
		buttonName = string.gsub(buttonName, "BONUSACTIONBUTTON", "PetActionButton")
		buttonName = string.gsub(buttonName, "ACTIONBUTTON", "ActionButton")

		cachedBindingButton[action] = buttonName
	end
	
	self:RebindButton(_G[buttonName], key)
end

-- One of the support modules found a key, register it then override whatever is associated with it (if we can)
function SpeedyActions:RegisterOverrideKey(...)
	for i=1, select("#", ...) do
		local key = select(i, ...)
		if( not self.db.global.keyList[key] ) then self.foundNewKey = true end
		self.db.global.keyList[key] = true
	end
end

function SpeedyActions:UPDATE_BINDINGS(event)
	-- Can't update in combat, queue if so
	if( InCombatLockdown() ) then
		eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	elseif( self.isDisabled ) then
		return
	end
	
	--self:Print("Updating bindings ...")
	
	-- First call, bindings just loaded so grab all the modules too
	if( not bindingsLoaded ) then
		bindingsLoaded = true
		SpeedyActions:ForceDefaultClick()

		for name, module in pairs(self.supportModules) do
			if( not self.db.profile.disableModules[name] ) then
				-- Addons been loaded already so can grab whatever support needs
				if( IsAddOnLoaded(name) ) then
					module.loaded = true
					if( module.SupportLoaded ) then
						module:SupportLoaded()
					end
				-- It didn't fail to load cause it's not being used, etc watch for it to load.
				elseif( not select(6, GetAddOnInfo(name)) ) then
					module.waitForLoad = true
				end	
			end
		end
		
	end
	
	-- Release everything we already had bound
	ClearOverrideBindings(eventFrame)
	releaseButtons()
	
	-- This adds support for bindings set to Blizzards default stuff, anything else is not supported and requires a support module
	for i=1, GetNumBindings() do
		local action, bindingOne, bindingTwo = GetBinding(i)
		if( bindingOne ) then self.db.global.keyList[bindingOne] = true end
		if( bindingTwo ) then self.db.global.keyList[bindingTwo] = true end
	end
	
	-- Tell the modules that there was a binding update and they need to look for any new supported keys
	for _, module in pairsByKeys(self.supportModules) do
		if( module.loaded and module.BindingsUpdated ) then
			module:BindingsUpdated()
		end
	end
	
	--Check for all bindings created via SetBinding that don't belong to Blizzard's default bindings or supported modules (such as bound items or spells)
	for i, m in ipairs(modifiers) do
		for k,v in ipairs(bindables) do
			local key = m..v
			if not self.db.global.keyList[bindingOne] then
				local action = GetBindingAction(key)
				if action and action ~= "" then
					self.db.global.keyList[key] = true
				end
			end
		end
	end
	
	-- Scan through all keys that were found using an action and override them
	for key in pairs(self.db.global.keyList) do
		self:OverrideKeybind(key, GetBindingAction(key, true))
	end
	
	--self:Print("Bindings updated.")
end

function SpeedyActions:ADDON_LOADED(event, addon)
	local module = self.supportModules[addon]
	if( module and module.waitForLoad ) then
		module.loaded = true
		module.waitForLoad = nil
		module:SupportLoaded()
		
		-- A new key was found and the player has already entered the world, can't expect another binding update to occur
		if( self.foundNewKey and bindingsLoaded ) then
			self:UPDATE_BINDINGS()
		end
	end
end

function SpeedyActions:PLAYER_REGEN_ENABLED()
	eventFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UPDATE_BINDINGS()
end

local rebindtriggerspells = {
	DRUID = {
		[5487] = true,		--Bear Form	
		[9634] = true,		--Dire Bear Form
		[1066] = true,		--Aquatic Form
		[768] = true,		--Cat Form
		[783] = true,		--Travel Form
		[24858] = true,		--Moonkin Form
		[33891] = true,		--Tree Form / Tree of Life
		[33943] = true,		--Flight Form
		[40120] = true,		--Swift Flight Form
	},
	WARRIOR = {
		[2457] = true,
		[71] = true,
		[2458] = true,
	},
	ROGUE = {
		[1784] = true,
	},
	PRIEST = {
		[15473] = true,
	},
}

function SpeedyActions:CHAT_MSG_SYSTEM(event, arg, ...)
	local stringtoreplace, strvalue = string.gsub(ERR_LEARN_ABILITY_S, "%%s.", "")
	local stringtoreplace2, strvalue2 = string.gsub(ERR_LEARN_SPELL_S, "%%s.", "")
	if strvalue == 0 and strvalue == 0 then return end
	
	local newstring = string.gsub(string.gsub(string.gsub(arg, stringtoreplace, ""), stringtoreplace2, ""), "%.", "")
	
	local t = rebindtriggerspells[(playerclass or select(2,UnitClass("player")))]
	if t then
		for spellID,v in pairs(t) do
			local spellname, spellrank = GetSpellInfo(spellID)
			local spellstring = spellname
			if spellrank and spellrank ~= "" then spellstring = tostring(spellname.." ("..spellrank..")") end
			if newstring == spellstring and v then
				SpeedyActions:UPDATE_BINDINGS()
				SpeedyActions:Print("Updating Bindings because you learned '"..(spellname or spellID).."'")
				return
			end
		end
	end	
end

function SpeedyActions:Print(msg)
	print("|cff33ff99SpeedyActions|r >", msg)
end

function SpeedyActions:Echo(msg)
	DEFAULT_CHAT_FRAME:AddMessage(msg)
end

-- Initial scan that forces all of the default Blizzard buttons to accept clicks on mouse down, in case they are not key bound but they get clicked
local function setButtonsMouseDown(format)
	local id = 1
	while( true ) do
		local button = _G[format .. id]
		if( not button ) then return end
		
		button:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
		overriddenButtons[button] = true
		id = id + 1

		-- Find anything that binds directly to a Blizzard button, such as Dominos does
		SpeedyActions:RegisterOverrideKey(GetBindingKey(string.format("CLICK %s%d:LeftButton", format, id)))
	end
end

function SpeedyActions:ForceDefaultClick()
	setButtonsMouseDown("MultiBarLeftButton")
	setButtonsMouseDown("MultiBarRightButton")
	setButtonsMouseDown("MultiBarBottomRightButton")
	setButtonsMouseDown("MultiBarBottomLeftButton")
	setButtonsMouseDown("MultiCastActionButton")
	setButtonsMouseDown("ShapeshiftButton")
	setButtonsMouseDown("PetActionButton")
	setButtonsMouseDown("BonusActionButton")
	setButtonsMouseDown("ActionButton")
	setButtonsMouseDown("VehicleMenuBarActionButton")
	
	--MultiCastSummonSpellButton:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
	--overriddenButtons[MultiCastSummonSpellButton] = true
	--MultiCastRecallSpellButton:RegisterForClicks("Any"..SpeedyActions.db.profile.keystate)
	--overriddenButtons[MultiCastRecallSpellButton] = true
end

function SpeedyActions:Enable()
	if( not self.isDisabled ) then return end
	
	self.isDisabled = nil
	self:UPDATE_BINDINGS()
end

function SpeedyActions:Disable()
	if( self.isDisabled ) then return end
	self.isDisabled = true
	
	ClearOverrideBindings(eventFrame)
	releaseButtons()
	for button in pairs(overriddenButtons) do button:RegisterForClicks("AnyUp") end
end

-- Handle the events!
SpeedyActions.eventFrame = eventFrame
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if( event == "ADDON_LOADED" and select(1, ...) == "SpeedyActions" ) then
		SpeedyActions:OnInitialize()
	else
		SpeedyActions[event](SpeedyActions, event, ...)
	end
end)

--[===[@debug@
SpeedyActionsLocals = setmetatable(SpeedyActionsLocals, {
	__index = function(tbl, value)
		rawset(tbl, value, value)
		return value
	end,
})
--@end-debug@]===]