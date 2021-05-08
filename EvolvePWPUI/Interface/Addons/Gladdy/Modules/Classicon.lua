local unpack = unpack

local CLASS_BUTTONS = CLASS_BUTTONS

local Gladdy = LibStub("Gladdy")
local L = Gladdy.L
local Classicon = Gladdy:NewModule("Classicon", 80, {
    classIconPos = "LEFT"
})

function Classicon:Initialise()
    self.frames = {}

    self:RegisterMessage("ENEMY_SPOTTED")
    self:RegisterMessage("UNIT_DEATH")
end

function Classicon:CreateFrame(unit)
    local classIcon = Gladdy.buttons[unit]:CreateTexture(nil, "ARTWORK")
    classIcon:ClearAllPoints()
    if( Gladdy.db.classIconPos == "RIGHT" ) then
	    classIcon:SetPoint("TOPLEFT", Gladdy.buttons[unit], "TOPRIGHT", 2, 0)
	else
		classIcon:SetPoint("TOPLEFT", Gladdy.buttons[unit], "TOPLEFT", -2, 0)    	
    end
    
    self.frames[unit] = classIcon
end

function Classicon:UpdateFrame(unit)
    local classIcon = self.frames[unit]
    if (not classIcon) then return end

    local iconSize = Gladdy.db.healthBarHeight + Gladdy.db.powerBarHeight

    classIcon:SetWidth(iconSize)
    classIcon:SetHeight(iconSize + 1)
    
    if( Gladdy.db.classIconPos == "RIGHT" ) then
	    classIcon:SetPoint("TOPLEFT", Gladdy.buttons[unit], "TOPRIGHT", 2, 0)
	else
		classIcon:SetPoint("TOPLEFT", Gladdy.buttons[unit], "TOPLEFT", -2, 0)    	
    end
end

function Classicon:Test(unit)
    self:ENEMY_SPOTTED(unit)
end

function Classicon:ResetUnit(unit)
    local classIcon = self.frames[unit]
    if (not classIcon) then return end

    classIcon:SetTexture("")
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

function Classicon:GetOptions()
    return {
    	classIconPos = option({
            type = "select",
            name = L["Icon position"],
            desc = L["This changes positions with trinket"],
            order = 2,
            values = {
                ["LEFT"] = L["Left"],
                ["RIGHT"] = L["Right"],
            },
        })
    }
end

function Classicon:ENEMY_SPOTTED(unit)
    local classIcon = self.frames[unit]
    if (not classIcon) then return end

    classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    classIcon:SetTexCoord(unpack(CLASS_BUTTONS[Gladdy.buttons[unit].class]))
end