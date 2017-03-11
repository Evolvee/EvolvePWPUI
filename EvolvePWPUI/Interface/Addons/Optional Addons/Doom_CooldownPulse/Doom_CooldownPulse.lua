local fadeInTime
local fadeOutTime
local maxAlpha
local animScale
local iconSize
local holdTime

local defaultsettings = { 
    fadeInTime = 0.3, 
    fadeOutTime = 0.7, 
    maxAlpha = 0.7, 
    animScale = 1.5, 
    iconSize = 70, 
    holdTime = 0, 
    x = UIParent:GetWidth()/2, 
    y = UIParent:GetHeight()/2 
}

local GetTime = GetTime

local DCP = CreateFrame("frame")
DCP:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
DCP:SetMovable(true)
DCP:RegisterForDrag("LeftButton")
DCP:SetScript("OnDragStart", function(self) self:StartMoving() end)
DCP:SetScript("OnDragStop", function(self) 
    self:StopMovingOrSizing() 
    DCP_Saved.x = self:GetLeft()+self:GetWidth()/2 
    DCP_Saved.y = self:GetBottom()+self:GetHeight()/2 
    self:ClearAllPoints() 
    self:SetPoint("CENTER",UIParent,"BOTTOMLEFT",DCP_Saved.x,DCP_Saved.y)
end)

local DCPT = DCP:CreateTexture(nil,"BACKGROUND")
DCPT:SetAllPoints(DCP)

local cooldowns = { }
local animating = { }
local watching = { }

function DCP:ADDON_LOADED(addon)
    if (not DCP_Saved) then
        DCP_Saved = defaultsettings
    else
        for i,v in pairs(defaultsettings) do
            if (not DCP_Saved[i]) then
                DCP_Saved[i] = v
            end
        end
    end
    self:RefreshLocals()
    self:SetPoint("CENTER",UIParent,"BOTTOMLEFT",DCP_Saved.x,DCP_Saved.y)
    self:UnregisterEvent("ADDON_LOADED")
end
DCP:RegisterEvent("ADDON_LOADED")

function DCP:UNIT_SPELLCAST_SUCCEEDED(unit,spell)
    if (unit == "player") then
        watching[spell] = {GetTime(),"spell",spell}
        if (not self:IsMouseEnabled()) then
            self:SetScript("OnUpdate", function(self, elapsed) self:OnUpdate(elapsed) end)
        end
    end
end
DCP:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

function DCP:COMBAT_LOG_EVENT_UNFILTERED(...)
    local _,event,_,_,sourceFlags,_,_,_,spellID = ...
    if (event == "SPELL_CAST_SUCCESS") then
        if (bit.band(sourceFlags,COMBATLOG_OBJECT_TYPE_PET) == COMBATLOG_OBJECT_TYPE_PET and bit.band(sourceFlags,COMBATLOG_OBJECT_AFFILIATION_MINE) == COMBATLOG_OBJECT_AFFILIATION_MINE) then
            local name = GetSpellInfo(spellID)
            local index = self:GetPetActionIndexByName(name)
            if (not select(7,GetPetActionInfo(index))) then
                watching[name] = {GetTime(),"pet",index}
                if (not self:IsMouseEnabled()) then
                    self:SetScript("OnUpdate", function(self, elapsed) self:OnUpdate(elapsed) end)
                end
            end
        end
    end
end

function DCP:UNIT_PET()
    if (HasPetUI()) then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end
DCP:RegisterEvent("UNIT_PET")

function DCP:PLAYER_ENTERING_WORLD()
    local inInstance,instanceType = IsInInstance()
    if (inInstance and instanceType == "arena") then
        self:SetScript("OnUpdate",nil)
        cooldowns = { }
        watching = { }
    end
end
DCP:RegisterEvent("PLAYER_ENTERING_WORLD")

hooksecurefunc("UseInventoryItem", function(slot)
    local item = GetItemInfo(GetInventoryItemLink("player",slot) or "")
    if (item) then
        watching[item] = {GetTime(),"inventory",slot}
    end
end)
hooksecurefunc("UseContainerItem", function(bag,slot)
    local item = GetItemInfo(GetContainerItemLink(bag,slot) or "")
    if (item) then
        watching[item] = {GetTime(),"container",bag,slot}
    end
end)

function DCP:RefreshLocals()
    fadeInTime = DCP_Saved.fadeInTime
    fadeOutTime = DCP_Saved.fadeOutTime
    maxAlpha = DCP_Saved.maxAlpha
    animScale = DCP_Saved.animScale
    iconSize = DCP_Saved.iconSize
    holdTime = DCP_Saved.holdTime
end

local elapsed = 0
local runtimer = 0
function DCP:OnUpdate(update)
    elapsed = elapsed + update
    if (elapsed > 0.05) then
        for i,v in pairs(watching) do
            if (GetTime() >= v[1] + 0.5) then
                local start, duration, enabled, texture
                if (v[2] == "spell") then
                    texture = GetSpellTexture(v[3])
                    start, duration, enabled = GetSpellCooldown(v[3])
                elseif (v[2] == "inventory") then
                    texture = select(10,GetItemInfo(GetInventoryItemLink("player",v[3])))
                    start, duration, enabled = GetInventoryItemCooldown("player",v[3])
                elseif (v[2] == "container") then
                    texture = select(10,GetItemInfo(GetContainerItemLink(v[3],v[4]) or ""))
                    start, duration, enabled = GetContainerItemCooldown(v[3],v[4])
                elseif (v[2] == "pet") then
                    texture = select(3,GetPetActionInfo(v[3]))
                    start, duration, enabled = GetPetActionCooldown(v[3])
                end
                if (enabled ~= 0) then
                    if (duration and duration > 2.0 and texture) then
                        cooldowns[i] = { start, duration, texture }
                    end
                end
                if (not (enabled == 0 and v[2] == "spell")) then
                    watching[i] = nil
                end
            end
        end
        for i,v in pairs(cooldowns) do
            local remaining = v[2]-(GetTime()-v[1])
            if (remaining <= 0) then
                tinsert(animating, v[3])
                cooldowns[i] = nil
            end
        end
        
        elapsed = 0
        if (#animating == 0 and self:tcount(watching) == 0 and self:tcount(cooldowns) == 0) then
            self:SetScript("OnUpdate",nil)
            return
        end
    end
    
    if (#animating > 0) then
        runtimer = runtimer + update
        if (runtimer > (fadeInTime + holdTime + fadeOutTime)) then
            tremove(animating,1)
            runtimer = 0
            DCPT:SetTexture(nil)
        else
            if (not DCPT:GetTexture()) then
                DCPT:SetTexture(animating[1])
            end
            local alpha = maxAlpha
            if (runtimer < fadeInTime) then
                alpha = maxAlpha * (runtimer / fadeInTime)
            elseif (runtimer >= fadeInTime + holdTime) then
                alpha = maxAlpha - ( maxAlpha * ((runtimer - holdTime - fadeInTime) / fadeOutTime))
            end
            self:SetAlpha(alpha)
            local scale = iconSize+(iconSize*((animScale-1)*(runtimer/(fadeInTime+holdTime+fadeOutTime))))
            self:SetWidth(scale)
            self:SetHeight(scale)
        end
    end
end

function DCP:tcount(tab)
    local n = 0
    for _ in pairs(tab) do
        n = n + 1
    end
    return n
end

function DCP:GetPetActionIndexByName(name)
    for i=1, NUM_PET_ACTION_SLOTS, 1 do
        if (GetPetActionInfo(i) == name) then
            return i
        end
    end
    return nil
end

-------------------
-- OPTIONS FRAME --
-------------------

SlashCmdList["DOOMCOOLDOWNPULSE"] = function() if (not DCP_OptionsFrame) then DCP:CreateOptionsFrame() end DCP_OptionsFrame:Show() end
SLASH_DOOMCOOLDOWNPULSE1 = "/dcp"
SLASH_DOOMCOOLDOWNPULSE2 = "/cooldownpulse"
SLASH_DOOMCOOLDOWNPULSE3 = "/doomcooldownpulse"

function DCP:CreateOptionsFrame()
    local sliders = {
        { text = "Icon Size", value = "iconSize", min = 30, max = 125, step = 5 },
        { text = "Fade In Time", value = "fadeInTime", min = 0, max = 1.5, step = 0.1 },
        { text = "Fade Out Time", value = "fadeOutTime", min = 0, max = 1.5, step = 0.1 },
        { text = "Max Opacity", value = "maxAlpha", min = 0, max = 1, step = 0.1 },
        { text = "Max Opacity Hold Time", value = "holdTime", min = 0, max = 1.5, step = 0.1 },
        { text = "Animation Scaling", value = "animScale", min = 0, max = 2, step = 0.1 },
    }
    
    local buttons = {
        { text = "Close", func = function(self) self:GetParent():Hide() end },
        { text = "Test", func = function(self) 
            DCP_OptionsFrameButton3:SetText("Unlock") 
            DCP:EnableMouse(false) 
            DCP:RefreshLocals() 
            tinsert(animating,"Interface\\Icons\\Spell_Nature_Earthbind") 
            DCP:SetScript("OnUpdate",function(self, elapsed) self:OnUpdate(elapsed) end) 
            end },
        { text = "Unlock", func = function(self) 
            if (self:GetText() == "Unlock") then
                DCP:RefreshLocals()
                DCP:SetWidth(iconSize) 
                DCP:SetHeight(iconSize) 
                self:SetText("Lock") 
                DCP:SetScript("OnUpdate",nil) 
                DCP:SetAlpha(1) 
                DCPT:SetTexture("Interface\\Icons\\Spell_Nature_Earthbind") 
                DCP:EnableMouse(true) 
            else 
                DCP:SetAlpha(0) 
                self:SetText("Unlock") 
                DCP:EnableMouse(false) 
            end end },
        { text = "Defaults", func = function(self) 
            for i,v in pairs(defaultsettings) do 
                DCP_Saved[i] = v 
            end 
            for i,v in pairs(sliders) do 
                getglobal("DCP_OptionsFrameSlider"..i):SetValue(DCP_Saved[v.value]) 
            end
            DCP:ClearAllPoints()
            DCP:SetPoint("CENTER",UIParent,"BOTTOMLEFT",DCP_Saved.x,DCP_Saved.y) 
            end },
    }

    local optionsframe = CreateFrame("frame","DCP_OptionsFrame")
    optionsframe:SetBackdrop({
      bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", 
      edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
      tile=1, tileSize=32, edgeSize=32, 
      insets={left=11, right=12, top=12, bottom=11}
    })
    optionsframe:SetWidth(220)
    optionsframe:SetHeight(400)
    optionsframe:SetPoint("CENTER",UIParent)
    optionsframe:EnableMouse(true)
    optionsframe:SetMovable(true)
    optionsframe:RegisterForDrag("LeftButton")
    optionsframe:SetScript("OnDragStart", function(self) self:StartMoving() end)
    optionsframe:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    optionsframe:SetFrameStrata("FULLSCREEN_DIALOG")
    optionsframe:SetScript("OnHide", function() DCP:RefreshLocals() end)
    tinsert(UISpecialFrames, "DCP_OptionsFrame")

    local header = optionsframe:CreateTexture(nil,"ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header.blp")
    header:SetWidth(350)
    header:SetHeight(68)
    header:SetPoint("TOP",optionsframe,"TOP",0,12)

    local headertext = optionsframe:CreateFontString(nil,"ARTWORK","GameFontNormal")
    headertext:SetPoint("TOP",header,"TOP",0,-14)
    headertext:SetText("Doom_CooldownPulse")

    for i,v in pairs(sliders) do
        local slider = CreateFrame("slider", "DCP_OptionsFrameSlider"..i, optionsframe, "OptionsSliderTemplate")
        if (i == 1) then
            slider:SetPoint("TOP",optionsframe,"TOP",0,-40)
        else
            slider:SetPoint("TOP",getglobal("DCP_OptionsFrameSlider"..(i-1)),"BOTTOM",0,-35)
        end
        local valuetext = slider:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
        valuetext:SetPoint("TOP",slider,"BOTTOM",0,-1)
        valuetext:SetText(format("%.1f",DCP_Saved[v.value]))
        getglobal("DCP_OptionsFrameSlider"..i.."Text"):SetText(v.text)
        getglobal("DCP_OptionsFrameSlider"..i.."Low"):SetText(v.min)
        getglobal("DCP_OptionsFrameSlider"..i.."High"):SetText(v.max)
        slider:SetMinMaxValues(v.min,v.max)
        slider:SetValueStep(v.step)
        slider:SetValue(DCP_Saved[v.value])
        slider:SetScript("OnValueChanged",function() 
            local val=slider:GetValue() DCP_Saved[v.value]=val 
            valuetext:SetText(format("%.1f",val)) 
            if (DCP:IsMouseEnabled()) then 
                DCP:SetWidth(DCP_Saved.iconSize) 
                DCP:SetHeight(DCP_Saved.iconSize) 
            end end)
    end
    
    for i,v in pairs(buttons) do
        local button = CreateFrame("Button", "DCP_OptionsFrameButton"..i, optionsframe, "UIPanelButtonTemplate")
        button:SetHeight(24)
        button:SetWidth(60)
        button:SetPoint("BOTTOM", optionsframe, "BOTTOM", ((i%2==0 and -1) or 1)*35, ceil(i/2)*15 + (ceil(i/2)-1)*15)
        button:SetText(v.text)
        button:SetScript("OnClick", function(self) PlaySound("igMainMenuOption") v.func(self) end)
    end
end