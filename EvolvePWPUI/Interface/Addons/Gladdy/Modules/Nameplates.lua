local select = select
local pairs = pairs

local WorldFrame = WorldFrame

local Gladdy = LibStub("Gladdy")
local L = Gladdy.L
local Nameplates = Gladdy:NewModule("Nameplates", nil, {
    npTotems = true,
    npCastbars = true,
    npCastbarGuess = false,
})
LibStub("AceHook-3.0"):Embed(Nameplates)
LibStub("AceTimer-3.0"):Embed(Nameplates)


local totems = {
	["Nameplates"] = {},
	["Totems"] = {
		["Disease Cleansing Totem"] = true,
		["Earth Elemental Totem"] = true,
		["Earthbind Totem"] = true,
		["Fire Elemental Totem"] = true,
		["Fire Nova Totem I"] = true,
		["Fire Nova Totem II"] = true,
		["Fire Nova Totem III"] = true,
		["Fire Nova Totem IV"] = true,
		["Fire Nova Totem V"] = true,
		["Fire Nova Totem VI"] = true,
		["Fire Nova Totem VII"] = true,
		["Fire Resistance Totem I"] = true,
		["Fire Resistance Totem II"] = true,
		["Fire Resistance Totem III"] = true,
		["Fire Resistance Totem IV"] = true,
		["Fire Resistance Totem  "] = true,
		["Flametongue Totem I"] = true,
		["Flametongue Totem II"] = true,
		["Flametongue Totem III"] = true,
		["Flametongue Totem IV"] = true,
		["Flametongue Totem V"] = true,
		["Frost Resistance Totem I"] = true,
		["Frost Resistance Totem II"] = true,
		["Frost Resistance Totem III"] = true,
		["Frost Resistance Totem IV"] = true,
		["Grace of Air Totem I"] = true,
		["Grace of Air Totem II"] = true,
		["Grace of Air Totem III"] = true,
		["Grounding Totem"] = true,
		["Healing Stream Totem"] = true,
		["Healing Stream Totem II"] = true,
		["Healing Stream Totem III"] = true,
		["Healing Stream Totem IV"] = true,
		["Healing Stream Totem V "] = true,
		["Healing Stream Totem VI"] = true,
		["Magma Totem"] = true,
		["Magma Totem II"] = true,
		["Magma Totem III"] = true,
		["Magma Totem IV"] = true,
		["Magma Totem V"] = true,
		["Mana Spring Totem"] = true,
		["Mana Spring Totem II"] = true,
		["Mana Spring Totem III"] = true,
		["Mana Spring Totem IV"] = true,
		["Mana Spring Totem V"] = true,
		["Mana Tide Totem"] = true,
		["Nature Resistance Totem"] = true,
		["Nature Resistance Totem II"] = true,
		["Nature Resistance Totem III"] = true,
		["Nature Resistance Totem IV"] = true,
		["Nature Resistance Totem V"] = true,
		["Nature Resistance Totem V"] = true,
		["Poison Cleansing Totem"] = true,
		["Searing Totem"] = true,
		["Searing Totem II"] = true,
		["Searing Totem III"] = true,
		["Searing Totem IV"] = true,
		["Searing Totem V"] = true,
		["Searing Totem VI"] = true,
		["Searing Totem VII"] = true,
		["Sentry Totem"] = true,
		["Stoneclaw Totem"] = true,
		["Stoneclaw Totem II"] = true,
		["Stoneclaw Totem III"] = true,
		["Stoneclaw Totem IV"] = true,
		["Stoneclaw Totem V"] = true,
		["Stoneclaw Totem VI"] = true,
		["Stoneclaw Totem VII"] = true,
		["Stoneskin Totem"] = true,
		["Stoneskin Totem II"] = true,
		["Stoneskin Totem III"] = true,
		["Stoneskin Totem IV"] = true,
		["Stoneskin Totem V"] = true,
		["Stoneskin Totem VI"] = true,
		["Stoneskin Totem VII"] = true,
		["Stoneskin Totem VIII"] = true,
		["Strength of Earth Totem"] = true,
		["Strength of Earth Totem II"] = true,
		["Strength of Earth Totem III"] = true,
		["Strength of Earth Totem IV"] = true,
		["Strength of Earth Totem V"] = true,
		["Strength of Earth Totem VI"] = true,
		["Totem of Wrath"] = true,
		["Totem of Wrath II"] = true,
		["Totem of Wrath III"] = true,
		["Totem of Wrath IV"] = true,
		["Tremor Totem"] = true,
		["Windfury Totem"] = true,
		["Windfury Totem II"] = true,
		["Windfury Totem III"] = true,
		["Windfury Totem IV"] = true,
		["Windfury Totem V"] = true,
		["Windwall Totem"] = true,
		["Windwall Totem II"] = true,
		["Windwall Totem III"] = true,
		["Windwall Totem IV"] = true,
		["Wrath of Air Totem"] = true,
	},
}

function Nameplates:Initialise()
    self.numChildren = 0
	self:SetScript("OnUpdate", self.Update)
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

function Nameplates:GetOptions()
    return {
        npTotems = option({
            type = "toggle",
            name = L["Totem icons on/off (works only WITHOUT Aloft)"],
            desc = L["Turns totem icons instead of nameplates on or off. (Requires reload)"],
            order = 2,
        }),
        npCastbars = option({
            type = "toggle",
            name = L["Castbars on/off"],
            desc = L["Turns castbars of nameplates on or off. (Requires reload)"],
        }),
        npCastbarGuess = option({
            type = "toggle",
            name = L["Castbar guesses on/off"],
			desc = L["If disabled, castbars will stop as soon as you lose your 'unit', e.g. mouseover or your party targeting someone else."
					.."\nDisable this, if you see castbars, even though the player isn't casting."],
        }),
    }
end

function Nameplates:Reset()
    self:CancelAllTimers()
    self:UnhookAll()
    self.numChildren = 0
end

function Nameplates:Update()
    if ( WorldFrame:GetNumChildren() ~= self.numChildren ) then
		self.numChildren = WorldFrame:GetNumChildren()
		if Gladdy.db.npTotems and not IsAddOnLoaded("Aloft") then
			self:HookTotems(WorldFrame:GetChildren())
		end			
	end
end

local function UpdateTotems(hp)
	local frame = hp:GetParent()
	local hpborder, cbborder, cbicon, overlay, oldname, level, bossicon, raidicon = frame:GetRegions()
	--local overlayRegion, castBarOverlayRegion, spellIconRegion, highlightRegion, nameTextRegion, bossIconRegion, levelTextRegion, raidIconRegion = frame:GetRegions()
	local name = oldname:GetText()

	for totem in pairs(totems["Totems"]) do
		if ( name == totem and totems["Totems"][totem] == true ) then
			overlay:SetAlpha(0) 
			hpborder:Hide()
			oldname:Hide()
			level:Hide()
			hp:SetAlpha(0)
			raidicon:Hide()
			if not frame.totem then
				frame.totem = frame:CreateTexture(nil, "BACKGROUND")
				frame.totem:ClearAllPoints()
				frame.totem:SetPoint("CENTER", frame, "CENTER", 0 , 5)
			else
				frame.totem:Show()
			end	
			frame.totem:SetTexture("Interface\\AddOns\\Gladdy\\Images\\Totems\\" .. totem)
			frame.totem:SetWidth(64)
			frame.totem:SetHeight(64)
			break
		elseif ( name == totem ) then
			overlay:SetAlpha(0)
			hpborder:Hide()
			oldname:Hide()
			level:Hide()
			hp:SetAlpha(0)
			raidicon:Hide()
			break
		else
			overlay:SetAlpha(1)
			hpborder:Show()
			oldname:Show()
			level:Show()
			hp:SetAlpha(1)
			if frame.totem then frame.totem:Hide() end
		end
	end
end

function Nameplates:SkinTotems(frame)
	local HealthBar, CastBar = frame:GetChildren()
	--local threat, hpborder, cbshield, cbborder, cbicon, overlay, oldname, level, bossicon, raidicon, elite = frame:GetRegions()
	local overlayRegion, castBarOverlayRegion, spellIconRegion, highlightRegion, nameTextRegion, bossIconRegion, levelTextRegion, raidIconRegion = frame:GetRegions()
	HealthBar:SetScript("OnShow", UpdateTotems)
	HealthBar:SetScript("OnSizeChanged", UpdateTotems)
	UpdateTotems(HealthBar)
	totems["Nameplates"][frame] = true
end

function Nameplates:HookTotems(...)
	for index = 1, select('#', ...) do
		local frame = select(index, ...)
		local region = frame:GetRegions()
		if ( not totems["Nameplates"][frame] and not frame:GetName() and region and region:GetObjectType() == "Texture" and region:GetTexture() == "Interface\\Tooltips\\Nameplate-Border" ) then
			self:SkinTotems(frame)						
			frame.region = region
		end
	end
end