local pairs = pairs
local floor = math.floor

local CreateFrame = CreateFrame

local Gladdy = LibStub("Gladdy")
local L = Gladdy.L
local AceGUIWidgetLSMlists = AceGUIWidgetLSMlists
local Powerbar = Gladdy:NewModule("Powerbar", 90, {
    powerBarHeight = 16,
    powerBarTexture = "Minimalist",
    powerBarFontColor = {r = 1, g = 1, b = 1, a = 1},
    powerBarFontSize = 10,
    powerActual = true,
    powerMax = true,
    powerPercentage = false,
})

function Powerbar:Initialise()
    self.frames = {}

    self:RegisterMessage("ENEMY_SPOTTED")
    self:RegisterMessage("UNIT_SPEC")
    self:RegisterMessage("UNIT_POWER")
    self:RegisterMessage("UNIT_DEATH")
end

function Powerbar:CreateFrame(unit)
    local powerBar = CreateFrame("StatusBar", nil, Gladdy.buttons[unit])
    powerBar:SetStatusBarTexture(Gladdy.LSM:Fetch("statusbar", Gladdy.db.powerBarTexture))
    powerBar:SetMinMaxValues(0, 100)

    powerBar.bg = powerBar:CreateTexture(nil, "BACKGROUND")
    powerBar.bg:SetTexture(Gladdy.LSM:Fetch("statusbar", Gladdy.db.powerBarTexture))
    powerBar.bg:ClearAllPoints()
    powerBar.bg:SetAllPoints(powerBar)
    powerBar.bg:SetAlpha(.3)

    powerBar.raceText = powerBar:CreateFontString(nil, "LOW")
    powerBar.raceText:SetFont(Gladdy.LSM:Fetch("font"), Gladdy.db.powerBarFontSize)
    powerBar.raceText:SetTextColor(Gladdy.db.powerBarFontColor.r, Gladdy.db.powerBarFontColor.g, Gladdy.db.powerBarFontColor.b, Gladdy.db.powerBarFontColor.a)
    powerBar.raceText:SetShadowOffset(1, -1)
    powerBar.raceText:SetShadowColor(0, 0, 0, 1)
    powerBar.raceText:SetJustifyH("CENTER")
    powerBar.raceText:SetPoint("LEFT", 5, 0)

    powerBar.powerText = powerBar:CreateFontString(nil, "LOW")
    powerBar.powerText:SetFont(Gladdy.LSM:Fetch("font"), Gladdy.db.powerBarFontSize)
    powerBar.powerText:SetTextColor(Gladdy.db.powerBarFontColor.r, Gladdy.db.powerBarFontColor.g, Gladdy.db.powerBarFontColor.b, Gladdy.db.powerBarFontColor.a)
    powerBar.powerText:SetShadowOffset(1, -1)
    powerBar.powerText:SetShadowColor(0, 0, 0, 1)
    powerBar.powerText:SetJustifyH("CENTER")
    powerBar.powerText:SetPoint("RIGHT", -5, 0)

    self.frames[unit] = powerBar
    self:ResetUnit(unit)
end

function Powerbar:UpdateFrame(unit)
    local powerBar = self.frames[unit]
    if (not powerBar) then return end

    local healthBar = Gladdy.modules.Healthbar.frames[unit]

    powerBar:SetStatusBarTexture(Gladdy.LSM:Fetch("statusbar", Gladdy.db.powerBarTexture))
    powerBar.bg:SetTexture(Gladdy.LSM:Fetch("statusbar", Gladdy.db.powerBarTexture))

    powerBar:SetWidth(healthBar:GetWidth())
    powerBar:SetHeight(Gladdy.db.powerBarHeight)

    powerBar:ClearAllPoints()
    powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -1)

    powerBar.raceText:SetFont(Gladdy.LSM:Fetch("font"), Gladdy.db.powerBarFontSize)
    powerBar.raceText:SetTextColor(Gladdy.db.powerBarFontColor.r, Gladdy.db.powerBarFontColor.g, Gladdy.db.powerBarFontColor.b, Gladdy.db.powerBarFontColor.a)
    powerBar.powerText:SetFont(Gladdy.LSM:Fetch("font"), Gladdy.db.powerBarFontSize)
    powerBar.powerText:SetTextColor(Gladdy.db.powerBarFontColor.r, Gladdy.db.powerBarFontColor.g, Gladdy.db.powerBarFontColor.b, Gladdy.db.powerBarFontColor.a)
end

function Powerbar:ResetUnit(unit)
    local powerBar = self.frames[unit]
    if (not powerBar) then return end

    powerBar:SetStatusBarColor(1, 1, 1, 1)
    powerBar.raceText:SetText("")
    powerBar.powerText:SetText("")
    powerBar:SetValue(0)
end

function Powerbar:Test(unit)
    local powerBar = self.frames[unit]
    local button = Gladdy.buttons[unit]
    if (not powerBar or not button) then return end

    self:ENEMY_SPOTTED(unit)
    self:UNIT_POWER(unit, button.power, button.powerMax, button.powerType)
end

function Powerbar:ENEMY_SPOTTED(unit)
    local powerBar = self.frames[unit]
    local button = Gladdy.buttons[unit]
    if (not powerBar or not button) then return end

    local raceText = button.raceLoc

    if (button.spec) then
        raceText = button.spec .. " " .. raceText
    end

    powerBar.raceText:SetText(raceText)
end

function Powerbar:UNIT_SPEC(unit, spec)
    local powerBar = self.frames[unit]
    local button = Gladdy.buttons[unit]
    if (not powerBar or not button) then return end

    powerBar.raceText:SetText(spec .. " " .. button.raceLoc)
end

function Powerbar:UNIT_POWER(unit, power, powerMax, powerType)
    local powerBar = self.frames[unit]
    if (not powerBar) then return end

    local powerPercentage = floor(power * 100 / powerMax)
    local powerText

    if (Gladdy.db.powerActual) then
        powerText = powerMax > 999 and ("%.1fk"):format(power / 1000) or power
    end

    if (Gladdy.db.powerMax) then
        local text = powerMax > 999 and ("%.1fk"):format(powerMax / 1000) or powerMax
        if (powerText) then
            powerText = ("%s/%s"):format(powerText, text)
        else
            powerText = text
        end
    end

    if (Gladdy.db.powerPercentage) then
        if (powerText) then
            powerText = ("%s (%d%%)"):format(powerText, powerPercentage)
        else
            powerText = ("%d%%"):format(powerPercentage)
        end
    end

    if (powerType == 1) then
        powerBar:SetStatusBarColor(1, 0, 0, 1)
    elseif (powerType == 3) then
        powerBar:SetStatusBarColor(1, 1, 0, 1)
    else
        powerBar:SetStatusBarColor(.18, .44, .75, 1)
    end

    powerBar.powerText:SetText(powerText)
    powerBar:SetValue(powerPercentage)
end

function Powerbar:UNIT_DEATH(unit)
    local powerBar = self.frames[unit]
    if (not powerBar) then return end

    powerBar:SetValue(0)
    powerBar.powerText:SetText("0%")
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

function Powerbar:GetOptions()
    return {
        powerBarHeight = option({
            type = "range",
            name = L["Bar height"],
            desc = L["Height of the bar"],
            order = 2,
            min = 0,
            max = 50,
            step = 1,
        }),
        powerBarTexture = option({
            type = "select",
            name = L["Bar texture"],
            desc = L["Texture of the bar"],
            order = 3,
            dialogControl = "LSM30_Statusbar",
            values = AceGUIWidgetLSMlists.statusbar,
        }),
        powerBarFontColor = colorOption({
            type = "color",
            name = L["Font color"],
            desc = L["Color of the text"],
            order = 4,
            hasAlpha = true,
        }),
        powerBarFontSize = option({
            type = "range",
            name = L["Font size"],
            desc = L["Size of the text"],
            order = 5,
            min = 1,
            max = 20,
        }),
        powerActual = option({
            type = "toggle",
            name = L["Show the actual power"],
            desc = L["Show the actual power on the power bar"],
            order = 6,
        }),
        powerMax = option({
            type = "toggle",
            name = L["Show max power"],
            desc = L["Show max power on the power bar"],
            order = 7,
        }),
        powerPercentage = option({
            type = "toggle",
            name = L["Show power percentage"],
            desc = L["Show power percentage on the power bar"],
            order = 8,
        }),
    }
end