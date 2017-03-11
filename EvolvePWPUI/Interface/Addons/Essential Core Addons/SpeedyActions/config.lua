local L = SpeedyActionsLocals
local Config = {}
local AceDialog, AceRegistry, options, keyBlacklistTable

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

local function loadGeneralOptions()
	options.args.general = {
		order = 1,
		type = "group",
		name = L["General"],
		args = {
			general = {
				order = 1,
				type = "group",
				name = L["General"],
				inline = true,
				args = {
					toggle = {
						order = 1,
						type = "toggle",
						name = L["Disable SpeedyActions"],
						desc = L["This lets you *temporarily* disable SpeedyActions, it will be reenabled automatically on relog or reload.\n\nUseful if you want to drag buttons around on your action bar."],
						set = function() if( SpeedyActions.isDisabled ) then SpeedyActions:Enable() else SpeedyActions:Disable() end end,
						get = function() return SpeedyActions.isDisabled end,
						width = "full",
					},
				},
			},
			modules = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Modules"],
				args = {
					help = {
						order = 1,
						type = "description",
						name = L["Disabling modules will require a UI reload for the changes to take effect."],	
					},	
					div = {
						order = 2,
						type = "header",
						name = "",	
					},
				},
			},
		},	
	}
	
	-- Build module table	
	local getModuleStatus = function(info) return not SpeedyActions.db.profile.disableModules[info[#(info)]] end
	local setModuleStatus = function(info, value) SpeedyActions.db.profile.disableModules[info[#(info)]] = not value; SpeedyActions:UPDATE_BINDINGS() end
	
	for addon, module in pairsByKeys(SpeedyActions.supportModules) do
		options.args.general.args.modules.args[addon] = {
			order = select(6, GetAddOnInfo(addon)) and 4 or 3,
			type = "toggle",
			name = string.format(L["Enable %s"], addon),
			desc = module.usage,
			get = getModuleStatus,
			set = setModuleStatus,	
			disabled = select(6, GetAddOnInfo(addon)) and true or false,
		}
	end
end

local function rebuildKeyBlacklist()
	options.args.keys.args.list.args = {}
	
	local found
	for key in pairsByKeys(SpeedyActions.db.profile.blacklistKeys) do
		options.args.keys.args.list.args[key] = keyBlacklistTable
		found = true
	end
	
	if( not found ) then
		options.args.keys.args.list.args.noneFound = {
			order = 1,
			type = "description",
			name = L["You do not have any keys blacklisted yet! Use the button above to add a new key to the blacklist."],	
		}
	end
end

local function loadKeyOptions()
	options.args.keys = {
		order = 2,
		type = "group",
		name = L["Blacklist keybindings"],
		args = {
			help = {
				order = 1,
				type = "group",
				inline = true,
				name = L["Help"],
				args = {
					help = {
						order = 1,
						type = "description",
						name = L["If you do not want a key to be sped up, you can blacklist it here."],	
					},	
				},
			},
			add = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Blacklist a new keybinding"],
				args = {
					keybinding = {
						order = 1,
						type = "keybinding",
						name = "",	--L["Click and then press the key you want to blacklist"],
						set = function(info, key)
							if( key and key ~= "" ) then
								SpeedyActions.db.profile.blacklistKeys[key] = true
								SpeedyActions:UPDATE_BINDINGS()
								rebuildKeyBlacklist()
							end
						end,
					},
				},
			},
			list = {
				order = 3,
				type = "group",
				inline = true,
				name = L["Blacklisted keybindings"],
				args = {},
			},
		},
	}
	
	keyBlacklistTable = {
		order = 1,
		type = "execute",
		name = function(info) return info[#(info)] end,
		desc = function(info) return string.format(L["Click to remove blacklist on %s."], info[#(info)]) end,
		func = function(info)
			SpeedyActions.db.profile.blacklistKeys[info[#(info)]] = nil
			SpeedyActions:UPDATE_BINDINGS()
			rebuildKeyBlacklist()
		end,
	}

	rebuildKeyBlacklist()
end


local function loadDescription()
	options.args.description = {
		order = 3,
		type = "group",
		name = L["Description"],
		args = {
			description = {
				order = 1,
				type = "group",
				inline = true,
				name = L["Description"],
				args = {
					description = {
						name = L["DescriptionText"],
						order = 1,
						type = "description"
					},
				},
			},
		},	
	}
end


local function loadOptions()
	options = {
		type = "group",	
		name = "SpeedyActions TBC",
		childGroups = "tab",
		args = {},
	}
	
	loadGeneralOptions()
	loadKeyOptions()
	loadDescription()
end

SLASH_SPEEDYACTIONS1 = "/sa"
SLASH_SPEEDYACTIONS2 = "/speedyaction"
SLASH_SPEEDYACTIONS3 = "/speedyactions"
SlashCmdList["SPEEDYACTIONS"] = function(msg)
	msg = string.lower(msg or "")
	if( msg == "disable" ) then
		if( InCombatLockdown() ) then
			self:Print(L["Cannot disable while you are in combat, drop combat and run /speedyactions disable again."])
			return
		end
		
		self:Print(L["Disabled! Type /speedyactions enable to reenable the mod."])
		self:Disable()
	elseif( msg == "enable" ) then
		self:Print(L["Enabled! Actions will be sped up again."])
		self:Enable()
		return
	end
	
	if( not AceDialog and not AceRegistry ) then
		loadOptions()
		
		AceDialog = LibStub("AceConfigDialog-3.0")
		AceRegistry = LibStub("AceConfigRegistry-3.0")
		LibStub("AceConfig-3.0"):RegisterOptionsTable("SpeedyActions", options)
		AceDialog:SetDefaultSize("SpeedyActions", 500, 450)
	end
		
	AceDialog:Open("SpeedyActions")
end