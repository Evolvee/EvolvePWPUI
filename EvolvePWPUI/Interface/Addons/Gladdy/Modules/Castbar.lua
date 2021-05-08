local pairs = pairs

local CreateFrame = CreateFrame
local GetSpellInfo = GetSpellInfo

local Gladdy = LibStub("Gladdy")
local L = Gladdy.L
local AceGUIWidgetLSMlists = AceGUIWidgetLSMlists
local Castbar = Gladdy:NewModule("Castbar", 70, {
    castBarHeight = 20,
    castBarTexture = "Minimalist",
    castBarFontColor = {r = 1, g = 1, b = 1, a = 1},
    castBarFontSize = 12,
    castBarColor = {r = 1, g = 1, b = 0, a = 1},
    castBarBgColor = {r = 1, g = 1, b = 1, a = .3},
    castBarGuesses = true,
})

function Castbar:Initialise()
    self.frames = {}

    self:RegisterMessage("CAST_START")
    self:RegisterMessage("CAST_STOP")
    self:RegisterMessage("UNIT_DEATH", "CAST_STOP")
end

function Castbar:CreateFrame(unit)
    local castBar = CreateFrame("StatusBar", nil, Gladdy.buttons[unit])
    castBar:SetStatusBarTexture(Gladdy.LSM:Fetch("statusbar", Gladdy.db.castBarTexture))
    castBar:SetStatusBarColor(Gladdy.db.castBarColor.r, Gladdy.db.castBarColor.g, Gladdy.db.castBarColor.b, Gladdy.db.castBarColor.a)
    castBar:SetMinMaxValues(0, 100)
    castBar:SetScript("OnUpdate", function(self, elapsed)
        if (self.isCasting) then
            if (self.value >= self.maxValue) then
                Castbar:CAST_STOP(unit)
            else
                self.value = self.value + elapsed
                self:SetValue(self.value)
                self.timeText:SetFormattedText("%.1f", self.value)
            end
        elseif (self.isChanneling) then
            if (self.value <= 0) then
                Castbar:CAST_STOP(unit)
            else
                self.value = self.value - elapsed
                self:SetValue(self.value)
                self.timeText:SetFormattedText("%.1f", self.value)
            end
        end
    end)

    castBar.bg = castBar:CreateTexture(nil, "BACKGROUND")
    castBar.bg:SetTexture(Gladdy.LSM:Fetch("statusbar", Gladdy.db.castBarTexture))
    castBar.bg:SetVertexColor(Gladdy.db.castBarBgColor.r, Gladdy.db.castBarBgColor.g, Gladdy.db.castBarBgColor.b, Gladdy.db.castBarBgColor.a)
    castBar.bg:SetAlpha(.3)

    castBar.icon = castBar:CreateTexture(nil)
    castBar.icon:ClearAllPoints()
    castBar.icon:SetPoint("RIGHT", castBar, "LEFT")
    castBar.icon:SetTexCoord(.1, .9, .1, .9)

    castBar.spellText = castBar:CreateFontString(nil, "LOW")
    castBar.spellText:SetFont(Gladdy.LSM:Fetch("font"), Gladdy.db.castBarFontSize)
    castBar.spellText:SetTextColor(Gladdy.db.castBarFontColor.r, Gladdy.db.castBarFontColor.g, Gladdy.db.castBarFontColor.b, Gladdy.db.castBarFontColor.a)
    castBar.spellText:SetShadowOffset(1, -1)
    castBar.spellText:SetShadowColor(0, 0, 0, 1)
    castBar.spellText:SetJustifyH("CENTER")
    castBar.spellText:SetPoint("LEFT", 5, 0)

    castBar.timeText = castBar:CreateFontString(nil, "LOW")
    castBar.timeText:SetFont(Gladdy.LSM:Fetch("font"), Gladdy.db.castBarFontSize)
    castBar.timeText:SetTextColor(Gladdy.db.castBarFontColor.r, Gladdy.db.castBarFontColor.g, Gladdy.db.castBarFontColor.b, Gladdy.db.castBarFontColor.a)
    castBar.timeText:SetShadowOffset(1, -1)
    castBar.timeText:SetShadowColor(0, 0, 0, 1)
    castBar.timeText:SetJustifyH("CENTER")
    castBar.timeText:SetPoint("RIGHT", -5, 0)

    self.frames[unit] = castBar
    self:ResetUnit(unit)
end

function Castbar:UpdateFrame(unit)
    local castBar = self.frames[unit]
    if (not castBar) then return end

    local healthBar = Gladdy.modules.Healthbar.frames[unit]
    local classIcon = Gladdy.modules.Classicon.frames[unit]
    local iconSize = Gladdy.db.healthBarHeight + Gladdy.db.powerBarHeight

    castBar:SetStatusBarTexture(Gladdy.LSM:Fetch("statusbar", Gladdy.db.castBarTexture))
    castBar:SetStatusBarColor(Gladdy.db.castBarColor.r, Gladdy.db.castBarColor.g, Gladdy.db.castBarColor.b, Gladdy.db.castBarColor.a)
    castBar.bg:SetTexture(Gladdy.LSM:Fetch("statusbar", Gladdy.db.castBarTexture))
    castBar.bg:SetVertexColor(Gladdy.db.castBarBgColor.r, Gladdy.db.castBarBgColor.g, Gladdy.db.castBarBgColor.b, Gladdy.db.castBarBgColor.a)

    castBar:SetWidth(healthBar:GetWidth() + iconSize * 2 - Gladdy.db.castBarHeight)
    castBar:SetHeight(Gladdy.db.castBarHeight)
    castBar.bg:SetWidth(castBar:GetWidth() + Gladdy.db.castBarHeight)
    castBar.bg:SetHeight(Gladdy.db.castBarHeight)
    castBar.icon:SetWidth(Gladdy.db.castBarHeight)
    castBar.icon:SetHeight(Gladdy.db.castBarHeight)

    castBar:ClearAllPoints()
    castBar:SetPoint("TOPLEFT", classIcon, "BOTTOMLEFT", Gladdy.db.castBarHeight + 2, -1)
    castBar.bg:ClearAllPoints()
    castBar.bg:SetPoint("RIGHT", castBar, "RIGHT")

    castBar.spellText:SetFont(Gladdy.LSM:Fetch("font"), Gladdy.db.castBarFontSize)
    castBar.spellText:SetTextColor(Gladdy.db.castBarFontColor.r, Gladdy.db.castBarFontColor.g, Gladdy.db.castBarFontColor.b, Gladdy.db.castBarFontColor.a)
    castBar.timeText:SetFont(Gladdy.LSM:Fetch("font"), Gladdy.db.castBarFontSize)
    castBar.timeText:SetTextColor(Gladdy.db.castBarFontColor.r, Gladdy.db.castBarFontColor.g, Gladdy.db.castBarFontColor.b, Gladdy.db.castBarFontColor.a)
end

function Castbar:ResetUnit(unit)
    self:CAST_STOP(unit)
end

function Castbar:Test(unit)
    local spell, _, icon, value, maxValue, event

    if (unit == "arena2") then
        spell, _, icon = GetSpellInfo(27072)
        value, maxValue, event = 0, 2.5, "cast"
    elseif (unit == "arena4") then
        spell, _, icon = GetSpellInfo(27220)
        value, maxValue, event = 5, 5, "channel"
    elseif (unit == "arena5") then
        spell, _, icon = GetSpellInfo(20770)
        value, maxValue, event = 0, 10, "cast"
    end

    if (spell) then
        self:CAST_START(unit, spell, icon, value, maxValue, event)
    end
end

function Castbar:CAST_START(unit, spell, icon, value, maxValue, event)
    local castBar = self.frames[unit]
    if (not castBar) then return end

    castBar.value = value
    castBar.maxValue = maxValue
    castBar:SetMinMaxValues(0, maxValue)
    castBar:SetValue(value)
    castBar.icon:SetTexture(icon)
    castBar.spellText:SetText(spell)
    castBar.timeText:SetText(maxValue)
    castBar.isCasting = event == "cast"
    castBar.isChanneling = event == "channel"
end

function Castbar:CAST_STOP(unit)
    local castBar = self.frames[unit]
    if (not castBar) then return end

    castBar.isCasting = false
    castBar.isChanneling = false
    castBar.value = 0
    castBar.maxValue = 0
    castBar.icon:SetTexture("")
    castBar.spellText:SetText("")
    castBar.timeText:SetText("")
    castBar:SetValue(0)
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

function Castbar:GetOptions()
    return {
        castBarGuesses = option({
            type = "toggle",
            name = L["Castbar guesses on/off"],
            desc = L["If disabled, castbars will stop as soon as you lose your 'unit', e.g. mouseover or your party targeting someone else."
            .."\nDisable this, if you see castbars, even though the player isn't casting."],
            order = 2,
        }),
        castBarHeight = option({
            type = "range",
            name = L["Bar height"],
            desc = L["Height of the bar"],
            order = 3,
            min = 0,
            max = 50,
            step = 1,
        }),
        castBarFontSize = option({
            type = "range",
            name = L["Font size"],
            desc = L["Size of the text"],
            order = 4,
            min = 1,
            max = 20,
        }),
        castBarTexture = option({
            type = "select",
            name = L["Bar texture"],
            desc = L["Texture of the bar"],
            order = 5,
            dialogControl = "LSM30_Statusbar",
            values = AceGUIWidgetLSMlists.statusbar,
        }),
        castBarFontColor = colorOption({
            type = "color",
            name = L["Font color"],
            desc = L["Color of the text"],
            order = 6,
            hasAlpha = true,
        }),
        castBarColor = colorOption({
            type = "color",
            name = L["Bar color"],
            desc = L["Color of the cast bar"],
            order = 7,
            hasAlpha = true,
        }),
        castBarBgColor = colorOption({
            type = "color",
            name = L["Background color"],
            desc = L["Color of the cast bar background"],
            order = 8,
            hasAlpha = true,
        }),
    }
end