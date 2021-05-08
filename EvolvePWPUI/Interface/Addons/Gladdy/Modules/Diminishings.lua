local max = math.max
local select = select
local pairs = pairs

local drDuration = 18

local GetSpellInfo = GetSpellInfo
local CreateFrame = CreateFrame
local GetTime = GetTime

local Gladdy = LibStub("Gladdy")
local L = Gladdy.L
local Diminishings = Gladdy:NewModule("Diminishings", nil, {
    drFontColor = {r = 1, g = 1, b = 0, a = 1},
    drFontSize = 20,
    drCooldownPos = "LEFT",
    drIconSize = 30,
    drEnabled = true
})

local function StyleActionButton(f)
    local name = f:GetName()
    local button  = _G[name]
    local icon  = _G[name .. "Icon"]
    local normalTex = _G[name .. "NormalTexture"]

    normalTex:SetHeight(button:GetHeight())
    normalTex:SetWidth(button:GetWidth())
    normalTex:SetPoint("CENTER")

    button:SetNormalTexture("Interface\\AddOns\\Gladdy\\Images\\Gloss")

    icon:SetTexCoord(.1, .9, .1, .9)
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)

    normalTex:SetVertexColor(1, 1, 1, 1)
end

function Diminishings:OnEvent(event, ...)
	self[event](self, ...)
end

function Diminishings:Initialise()
    self.frames = {}
	self.spells = {}
    self.icons = {}

    local spells = self:GetDRList()
    for k, v in pairs(spells) do
        local name, _, icon = GetSpellInfo(k)
        self.spells[name] = v
        self.icons[name] = icon
    end

    self:RegisterMessage("UNIT_DEATH", "ResetUnit")
	self:SetScript("OnEvent", Diminishings.OnEvent)
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function Diminishings:COMBAT_LOG_EVENT_UNFILTERED(...)
	local timestamp, eventType, sourceGUID,sourceName,sourceFlags,destGUID,destName,destFlags,spellID,spellName,spellSchool,auraType = select ( 1 , ... );
    local destUnit = Gladdy.guids[destGUID]
	if eventType == "SPELL_AURA_REMOVED" and destUnit then
		self:Fade(destUnit, spellName)
	end
end	

function Diminishings:CreateFrame(unit)
    local drFrame = CreateFrame("Frame", nil, Gladdy.buttons[unit])

	for i = 1, 16 do
        local icon = CreateFrame("CheckButton", "GladdyDr" .. unit .. "Icon" .. i, drFrame, "ActionButtonTemplate")
        icon:SetAlpha(0)
        icon:EnableMouse(false)
        icon:SetFrameStrata("BACKGROUND")
        icon.texture = _G[icon:GetName() .. "Icon"]
        icon:SetScript("OnUpdate", function(self, elapsed)
            if (self.active) then
                if (self.timeLeft <= 0) then
                    if (self.factor == drFrame.tracked[self.dr]) then
                        drFrame.tracked[self.dr] = 0
                    end

                    self.active = false
                    self.dr = nil
                    self.texture:SetTexture("")
                    self.text:SetText("")
                    self:SetAlpha(0)

                    Diminishings:Positionate(unit)
                else
                    self.timeLeft = self.timeLeft - elapsed
                    self.timeText:SetFormattedText("%d", self.timeLeft+1)
                end
            end
        end)

        icon.text = icon:CreateFontString(nil, "OVERLAY")
        icon.text:SetDrawLayer("OVERLAY")
        icon.text:SetFont(Gladdy.LSM:Fetch("font"), Gladdy.db.drFontSize, "OUTLINE")
        icon.text:SetTextColor(Gladdy.db.drFontColor.r, Gladdy.db.drFontColor.g, Gladdy.db.drFontColor.b, Gladdy.db.drFontColor.a)
        icon.text:SetShadowOffset(1, -1)
        icon.text:SetShadowColor(0, 0, 0, 1)
        icon.text:SetJustifyH("CENTER")
        icon.text:SetPoint("CENTER")

        icon.timeText = icon:CreateFontString(nil, "OVERLAY")
        icon.timeText:SetDrawLayer("OVERLAY")
        icon.timeText:SetFont(Gladdy.LSM:Fetch("font"), Gladdy.db.drFontSize - 2, "OUTLINE")
        icon.timeText:SetTextColor(Gladdy.db.drFontColor.r, Gladdy.db.drFontColor.g, Gladdy.db.drFontColor.b, Gladdy.db.drFontColor.a)
        icon.timeText:SetShadowOffset(1, -1)
        icon.timeText:SetShadowColor(0, 0, 0, 1)
        icon.timeText:SetJustifyH("CENTER")
        icon.timeText:SetPoint("CENTER")

        drFrame["icon" .. i] = icon
    end

    drFrame.tracked = {}

    self.frames[unit] = drFrame
    self:ResetUnit(unit)
end

function Diminishings:UpdateFrame(unit)
    local drFrame = self.frames[unit]
    if (not drFrame) then return end
    
    if( Gladdy.db.drEnabled == false ) then
    	drFrame:Hide()
    	return
    end

    local margin = max(5, Gladdy.db.padding)
    local offset = Gladdy.db.healthBarHeight + Gladdy.db.powerBarHeight

    drFrame:ClearAllPoints()
    if (Gladdy.db.drCooldownPos == "LEFT") then
        drFrame:SetPoint("TOPRIGHT", Gladdy.buttons[unit], "TOPLEFT", -margin, -1)
    else
        drFrame:SetPoint("TOPLEFT", Gladdy.buttons[unit], "TOPRIGHT", offset + margin, -1) -- Trinket icon
    end

    drFrame:SetWidth(Gladdy.db.drIconSize * 16)
    drFrame:SetHeight(Gladdy.db.drIconSize)

    for i = 1, 16 do
        local icon = drFrame["icon" .. i]

        icon:SetWidth(Gladdy.db.drIconSize)
        icon:SetHeight(Gladdy.db.drIconSize)

        icon.text:SetFont(Gladdy.LSM:Fetch("font"), Gladdy.db.drFontSize, "OUTLINE")
        icon.text:SetTextColor(Gladdy.db.drFontColor.r, Gladdy.db.drFontColor.g, Gladdy.db.drFontColor.b, Gladdy.db.drFontColor.a)
        icon.timeText:SetFont(Gladdy.LSM:Fetch("font"), Gladdy.db.drFontSize - 2, "OUTLINE")
        icon.timeText:SetTextColor(Gladdy.db.drFontColor.r, Gladdy.db.drFontColor.g, Gladdy.db.drFontColor.b, Gladdy.db.drFontColor.a)

        icon:ClearAllPoints()
        if (Gladdy.db.drCooldownPos == "LEFT") then
            if (i == 1) then
                icon:SetPoint("TOPRIGHT")
            else
                icon:SetPoint("RIGHT", drFrame["icon" .. (i - 1)], "LEFT")
            end
        else
            if (i == 1) then
                icon:SetPoint("TOPLEFT")
            else
                icon:SetPoint("LEFT", drFrame["icon" .. (i - 1)], "RIGHT")
            end
        end

        StyleActionButton(icon)
    end
end

function Diminishings:ResetUnit(unit)
    local drFrame = self.frames[unit]
    if (not drFrame) then return end

    drFrame.tracked = {}

    for i = 1, 16 do
        local icon = drFrame["icon" .. i]
        icon.active = false
        icon.timeLeft = 0
        icon.texture:SetTexture("")
        icon.text:SetText("")
        icon.timeText:SetText("")
        icon:SetAlpha(0)
    end
end

function Diminishings:Test(unit)
    local spells = {33786, 118, 8643, 8983}

    for i = 1, 4 do
        local spell = GetSpellInfo(spells[i])
        self:Fade(unit, spell)
    end
end

function Diminishings:Fade(unit, spell)
    local drFrame = self.frames[unit]
    local dr = self.spells[spell]
    if (not drFrame or not dr) then return end

    for i = 1, 16 do
        local icon = drFrame["icon" .. i]
        if (not icon.active or (icon.dr and icon.dr == dr)) then
            icon.dr = dr
            icon.timeLeft = drDuration
            icon.texture:SetTexture(self.icons[spell])
            icon.active = true
            self:Positionate(unit)
            icon:SetAlpha(1)
            break
        end
    end
end

function Diminishings:Positionate(unit)
    local drFrame = self.frames[unit]
    if (not drFrame) then return end

    local lastIcon

    for i = 1, 16 do
        local icon = drFrame["icon" .. i]

        if (icon.active) then
            icon:ClearAllPoints()
            if (Gladdy.db.drCooldownPos == "LEFT") then
                if (not lastIcon) then
                    icon:SetPoint("TOPRIGHT")
                else
                    icon:SetPoint("RIGHT", lastIcon, "LEFT")
                end
            else
                if (not lastIcon) then
                    icon:SetPoint("TOPLEFT")
                else
                    icon:SetPoint("LEFT", lastIcon, "RIGHT")
                end
            end

            lastIcon = icon
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
            -- hackfix to prevent DR/cooldown to be on the same side
            if( key == "drCooldownPos" and value == "LEFT") then
              Gladdy.db.cooldownPos = "RIGHT"
            elseif ( key == "drCooldownPos" and value == "RIGHT" ) then
              Gladdy.db.cooldownPos = "LEFT"
            end
            Gladdy.dbi.profile[key] = value
            Gladdy:UpdateFrame()
        end,
    }

    for k, v in pairs(params) do
        defaults[k] = v
    end

    return defaults
end

local function colorOption(params)
    local defaults = {
        get = function(info)
            local key = info.arg or info[#info]
            return Gladdy.dbi.profile[key].r, Gladdy.dbi.profile[key].g, Gladdy.dbi.profile[key].b, Gladdy.dbi.profile[key].a
        end,
        set = function(info, r, g, b ,a)
            local key = info.arg or info[#info]
            Gladdy.dbi.profile[key].r, Gladdy.dbi.profile[key].g, Gladdy.dbi.profile[key].b, Gladdy.dbi.profile[key].a = r, g, b, a
            Gladdy:UpdateFrame()
        end,
    }

    for k, v in pairs(params) do
        defaults[k] = v
    end

    return defaults
end

function Diminishings:GetOptions()
    return {
    	drEnabled = option({
            type = "toggle",
            name = L["Enable"],
            desc = L["Enabled DR module"],
            order = 2,
        }),
        drFontColor = colorOption({
            type = "color",
            name = L["Font color"],
            desc = L["Color of the text"],
            order = 3,
            hasAlpha = true,
        }),
        drFontSize = option({
            type = "range",
            name = L["Font size"],
            desc = L["Size of the text"],
            order = 4,
            min = 1,
            max = 20,
        }),
        drCooldownPos = option({
            type = "select",
            name = L["DR Cooldown position"],
            desc = L["Position of the cooldown icons"],
            order = 5,
            values = {
                ["LEFT"] = L["Left"],
                ["RIGHT"] = L["Right"],
            },
        }),
        drIconSize = option({
            type = "range",
            name = L["Icon Size"],
            desc = L["Size of the DR Icons"],
            order = 6,
            min = 5,
            max = 100,
            step = 1,
        }),
    }
end

function Diminishings:GetDRList()
    return {
        -- DRUID
        [33786] = "cycloneblind",           -- Cyclone
        [18658] = "sleep",                  -- Hibernate
        [26989] = "root",		    -- Entangling roots
        [8983] = "stun",                    -- Bash
        [9005] = "stun",                    -- Pounce
        [22570] = "disorient",              -- Maim

        -- HUNTER
        [14309] = "freezingtrap",           -- Freezing Trap
        [19386] = "sleep",                  -- Wyvern Sting
        [19503] = "scattershot",            -- Scatter Shot
        [19577] = "stun",                   -- Intimidation

        -- MAGE
        [12826] = "disorient",              -- Polymorph
        [31661] = "dragonsbreath",          -- Dragon's Breath
        [27088] = "root",                   -- Frost Nova
        [33395] = "root",                   -- Freeze (Water Elemental)

        -- PALADIN
        [10308] = "stun",                   -- Hammer of Justice
        [20066] = "repentance",             -- Repentance

        -- PRIEST
        [8122] = "fear",                    -- Phychic Scream
        [44047] = "root",                   -- Chastise
        [605] = "charm",                    -- Mind Control

        -- ROGUE
        [6770] = "disorient",               -- Sap
        [2094] = "cycloneblind",            -- Blind
        [1833] = "stun",                    -- Cheap Shot
        [8643] = "kidneyshot",              -- Kidney Shot
        [1776] = "disorient",               -- Gouge

        -- WARLOCK
        [5782] = "fear",                    -- Fear
        [27223] = "horror",                 -- Death Coil
        [30283] = "stun",                   -- Shadowfury
        [6358] = "fear",                    -- Seduction (Succubus)
        [5484] = "fear",                    -- Howl of Terror

        -- WARRIOR
        [12809] = "stun",                   -- Concussion Blow
        [25274] = "stun",                   -- Intercept Stun
        [5246] = "fear",                    -- Intimidating Shout

        -- TAUREN
        [20549] = "stun",                   -- War Stomp
    }
end
