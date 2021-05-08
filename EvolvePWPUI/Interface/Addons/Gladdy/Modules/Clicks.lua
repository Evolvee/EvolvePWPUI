local tinsert = table.insert
local pairs = pairs
local tonumber = tonumber

local InCombatLockdown = InCombatLockdown
local GetBindingKey = GetBindingKey
local ClearOverrideBindings = ClearOverrideBindings
local SetOverrideBindingClick = SetOverrideBindingClick
local MACRO, TARGET, FOCUS, ADDON_DISABLED = MACRO, TARGET, FOCUS, ADDON_DISABLED

local Gladdy = LibStub("Gladdy")
local L = Gladdy.L

local attributes = {
    {name = "Target", button = "1", modifier = "", action = "target", spell = ""},
    {name = "Focus", button = "2", modifier = "", action = "focus", spell = ""},
}
for i = 3, 10 do
    tinsert(attributes, {name = L["Action #%d"]:format(i), button = "", modifier = "", action = "disabled", spell = ""})
end
local Clicks = Gladdy:NewModule("Clicks", nil, {
    attributes = attributes,
})
LibStub("AceTimer-3.0"):Embed(Clicks)

BINDING_HEADER_GLADDY = "Gladdy"
BINDING_NAME_GLADDYBUTTON1_LEFT = L["Left Click Enemy 1"]
BINDING_NAME_GLADDYBUTTON2_LEFT = L["Left Click Enemy 2"]
BINDING_NAME_GLADDYBUTTON3_LEFT = L["Left Click Enemy 3"]
BINDING_NAME_GLADDYBUTTON4_LEFT = L["Left Click Enemy 4"]
BINDING_NAME_GLADDYBUTTON5_LEFT = L["Left Click Enemy 5"]

BINDING_NAME_GLADDYBUTTON1_RIGHT = L["Right Click Enemy 1"]
BINDING_NAME_GLADDYBUTTON2_RIGHT = L["Right Click Enemy 2"]
BINDING_NAME_GLADDYBUTTON3_RIGHT = L["Right Click Enemy 3"]
BINDING_NAME_GLADDYBUTTON4_RIGHT = L["Right Click Enemy 4"]
BINDING_NAME_GLADDYBUTTON5_RIGHT = L["Right Click Enemy 5"]

BINDING_NAME_GLADDYBUTTON1_MIDDLE = L["Middle Click Enemy 1"]
BINDING_NAME_GLADDYBUTTON2_MIDDLE = L["Middle Click Enemy 2"]
BINDING_NAME_GLADDYBUTTON3_MIDDLE = L["Middle Click Enemy 3"]
BINDING_NAME_GLADDYBUTTON4_MIDDLE = L["Middle Click Enemy 4"]
BINDING_NAME_GLADDYBUTTON5_MIDDLE = L["Middle Click Enemy 5"]

BINDING_NAME_GLADDYBUTTON1_BUTTON4 = L["Button4 Click Enemy 1"]
BINDING_NAME_GLADDYBUTTON2_BUTTON4 = L["Button4 Click Enemy 2"]
BINDING_NAME_GLADDYBUTTON3_BUTTON4 = L["Button4 Click Enemy 3"]
BINDING_NAME_GLADDYBUTTON4_BUTTON4 = L["Button4 Click Enemy 4"]
BINDING_NAME_GLADDYBUTTON5_BUTTON4 = L["Button4 Click Enemy 5"]

BINDING_NAME_GLADDYBUTTON1_BUTTON5 = L["Button5 Click Enemy 1"]
BINDING_NAME_GLADDYBUTTON2_BUTTON5 = L["Button5 Click Enemy 2"]
BINDING_NAME_GLADDYBUTTON3_BUTTON5 = L["Button5 Click Enemy 3"]
BINDING_NAME_GLADDYBUTTON4_BUTTON5 = L["Button5 Click Enemy 4"]
BINDING_NAME_GLADDYBUTTON5_BUTTON5 = L["Button5 Click Enemy 5"]

BINDING_NAME_GLADDYTRINKET1 = L["Trinket Used Enemy 1"]
BINDING_NAME_GLADDYTRINKET2 = L["Trinket Used Enemy 2"]
BINDING_NAME_GLADDYTRINKET3 = L["Trinket Used Enemy 3"]
BINDING_NAME_GLADDYTRINKET4 = L["Trinket Used Enemy 4"]
BINDING_NAME_GLADDYTRINKET5 = L["Trinket Used Enemy 5"]


function Clicks:Initialise()
    self:RegisterMessage("JOINED_ARENA")
end

function Clicks:Reset()
    self:CancelAllTimers()
end

function Clicks:ResetUnit(unit)
    local button = Gladdy.buttons[unit]
    if (not button) then return end

    for k, v in pairs(Gladdy.db.attributes) do
        button.secure:SetAttribute(v.modifier .. "macrotext" .. v.button, "")
    end
end

function Clicks:JOINED_ARENA()
    for k, v in pairs(Gladdy.buttons) do
        local left = GetBindingKey(("GLADDYBUTTON%d_LEFT"):format(v.id))
        local right = GetBindingKey(("GLADDYBUTTON%d_RIGHT"):format(v.id))
        local middle = GetBindingKey(("GLADDYBUTTON%d_MIDDLE"):format(v.id))
        local button4 = GetBindingKey(("GLADDYBUTTON%d_BUTTON4"):format(v.id))
        local button5 = GetBindingKey(("GLADDYBUTTON%d_BUTTON5"):format(v.id))
		local key = GetBindingKey("GLADDYTRINKET" .. v.id)
		
		ClearOverrideBindings(v.trinketButton)
        ClearOverrideBindings(v.secure)

        if (left) then
            SetOverrideBindingClick(v.secure, false, left, v.secure:GetName(), "LeftButton")
        end

        if (right) then
            SetOverrideBindingClick(v.secure, false, right, v.secure:GetName(), "RightButton")
        end

        if (middle) then
            SetOverrideBindingClick(v.secure, false, middle, v.secure:GetName(), "MiddleButton")
        end

        if (button4) then
            SetOverrideBindingClick(v.secure, false, button4, v.secure:GetName(), "Button4")
        end

        if (button5) then
            SetOverrideBindingClick(v.secure, false, button5, v.secure:GetName(), "Button5")
        end
		
		if (key) then
            SetOverrideBindingClick(v.trinketButton, true, key, v.trinketButton:GetName(), "LeftButton")
        end
    end

    self:ScheduleRepeatingTimer("CheckAttributes", .1, self)
end

function Clicks:CheckAttributes()
    for k, v in pairs(Gladdy.buttons) do
        if (v.guid ~= "") then
            if (not v.click and not InCombatLockdown()) then
                self:SetupAttributes(k)
                v.click = true
            end

            local healthBar = Gladdy.modules.Healthbar.frames[k]

            if (v.click) then
                healthBar.nameText:SetText(v.name)
                v:SetAlpha(1)
            else
                healthBar.nameText:SetFormattedText("**%s**", v.name)
                v:SetAlpha(.66)
            end
        end
    end
end

function Clicks:SetupAttributes(unit)
    local button = Gladdy.buttons[unit]
    if (not button) then return end

    for k, v in pairs(Gladdy.db.attributes) do
        self:SetupAttribute(button, v.button, v.modifier, v.action, v.spell)
    end
end

function Clicks:SetupAttribute(button, key, mod, action, spell)
    local attr = mod .. "macrotext" .. key
    local text = ""

    if (action == "macro") then
        text = spell:gsub("*name*", button.name)
    elseif (action ~= "disabled") then
        text = "/targetexact " .. button.name

        if (action == "focus") then
            text = text .. "\n/focus\n/targetlasttarget"
        elseif (action == "spell") then
            text = text .. "\n/cast " .. spell .. "\n/targetlasttarget"
        end
    end

    button.secure:SetAttribute(attr, text)
end

local buttons = {["1"] = L["Left button"], ["2"] = L["Right button"], ["3"] = L["Middle button"], ["4"] = L["Button 4"], ["5"] = L["Button 5"]}
local modifiers = {[""] = L["None"], ["ctrl-"] = L["CTRL"], ["shift-"] = L["SHIFT"], ["alt-"] = L["ALT"]}
local clickValues = {["macro"] = MACRO, ["target"] = TARGET, ["focus"] = FOCUS, ["spell"] = L["Cast Spell"], ["disabled"] = ADDON_DISABLED}

local function SetupAttributeOption(i)
    return {
        type = "group",
        name = Gladdy.dbi.profile.attributes[i].name,
        desc = Gladdy.dbi.profile.attributes[i].name,
        order = i + 1,
        get = function(info)
            return Gladdy.dbi.profile.attributes[tonumber(info[#info - 1])][info[#info]]
        end,
        set = function(info, value)
            Gladdy.dbi.profile.attributes[tonumber(info[#info - 1])][info[#info]] = value

            if (info[#info] == "name") then
                Gladdy.options.args.Clicks.args[info[#info - 1]].name = value
            end

            Gladdy:UpdateFrame()
        end,
        args = {
            name = {
                type = "input",
                name = L["Name"],
                desc = L["Select the name of the click option"],
                order = 1,
            },
            button = {
                type = "select",
                name = L["Button"],
                desc = L["Select which mouse button to use"],
                order = 2,
                values = buttons,
            },
            modifier = {
                type = "select",
                name = L["Modifier"],
                desc = L["Select which modifier to use"],
                order = 3,
                values = modifiers,
            },
            action = {
                type = "select",
                name = L["Action"],
                desc = L["Select what action this mouse button does"],
                order = 4,
                values = clickValues,
            },
            spell = {
                type = "input",
                name = L["Spell name / Macro text"],
                desc = L["Use *name* as unit's name. Like a '/rofl *name*'"],
                order = 5,
                multiline = true,
            },
        },
    }
end

function Clicks:GetOptions()
    local options = {}

    for i = 1, 10 do
        options[tostring(i)] = SetupAttributeOption(i)
    end

    return options
end