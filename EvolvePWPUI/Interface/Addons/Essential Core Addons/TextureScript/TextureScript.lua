--EVOLVE PWP UI

--dark theme
local frame2=CreateFrame("Frame")
frame2:RegisterEvent("ADDON_LOADED")
frame2:SetScript("OnEvent", function(self, event, addon)
        if (addon == "Blizzard_TimeManager") then
                for i, v in pairs({PlayerFrameTexture, TargetFrameTexture, PetFrameTexture, PartyMemberFrame1Texture, PartyMemberFrame2Texture, PartyMemberFrame3Texture, PartyMemberFrame4Texture, SlidingActionBarTexture0,
        SlidingActionBarTexture1,
        MainMenuBarLeftEndCap,
        MainMenuBarRightEndCap,
                        PartyMemberFrame1PetFrameTexture, PartyMemberFrame2PetFrameTexture, PartyMemberFrame3PetFrameTexture, PartyMemberFrame4PetFrameTexture, BonusActionBarTexture0, BonusActionBarTexture1,
                        TargetofTargetTexture, TargetofFocusTexture, BonusActionBarFrameTexture0, BonusActionBarFrameTexture1, BonusActionBarFrameTexture2, BonusActionBarFrameTexture3,
                        BonusActionBarFrameTexture4, MainMenuBarTexture0, MainMenuBarTexture1, MainMenuBarTexture2, MainMenuBarTexture3, MainMenuMaxLevelBar0, MainMenuMaxLevelBar1, MainMenuMaxLevelBar2,
                        MainMenuMaxLevelBar3, MinimapBorder, CastingBarFrameBorder, MiniMapBattlefieldBorder, FocusFrameSpellBarBorder, CastingBarBorder, TargetFrameSpellBarBorder, MiniMapTrackingButtonBorder, MiniMapLFGFrameBorder, MiniMapBattlefieldBorder,
                        MiniMapMailBorder, MinimapBorderTop,
                        select(1, TimeManagerClockButton:GetRegions())
                }) do
                        v:SetVertexColor(.0, .0, .0)
                end

                for i,v in pairs({ select(2, TimeManagerClockButton:GetRegions()) }) do
                        v:SetVertexColor(1, 1, 1)
                end

                self:UnregisterEvent("ADDON_LOADED")
                frame2:SetScript("OnEvent", nil)
		end
end)

--classcolournames

local frame3 = CreateFrame("FRAME")
frame3:RegisterEvent("GROUP_ROSTER_UPDATE")
frame3:RegisterEvent("PLAYER_TARGET_CHANGED")
frame3:RegisterEvent("PLAYER_FOCUS_CHANGED")
frame3:RegisterEvent("UNIT_FACTION")
local function eventHandler(self, event, ...)
        if UnitIsPlayer("target") then
                c = RAID_CLASS_COLORS[select(2, UnitClass("target"))]
                TargetFrameNameBackground:SetVertexColor(0, 0, 0, 0)
        end
        if UnitIsPlayer("focus") then
                c = RAID_CLASS_COLORS[select(2, UnitClass("focus"))]
                FocusFrameNameBackground:SetVertexColor(0, 0, 0, 0)
        end
end
frame3:SetScript("OnEvent", eventHandler)

--minimap buttons, horder/alliance icons on target/focus/player,minimap city location, minimap sun/clock, minimap text frame,minimap zoomable with mousewheel etc

MinimapZoomIn:Hide()
MinimapZoomOut:Hide()
Minimap:EnableMouseWheel(true)
Minimap:SetScript('OnMouseWheel', function(self, delta)
        if delta > 0 then
                Minimap_ZoomIn()
        else
                Minimap_ZoomOut()
        end
end)
MiniMapTracking:Hide()
MinimapBorderTop:Hide()
PlayerPVPIcon:SetAlpha(0)
TargetPVPIcon:SetAlpha(0)
FocusPVPIcon:SetAlpha(0) -- another guess about the focus frame!
for i=1,4 do
   _G["PartyMemberFrame"..i.."PVPIcon"]:SetAlpha(0)
end
GameTimeTexture:Hide()
MiniMapWorldMapButton:Hide()
MinimapToggleButton:Hide()
MiniMapMailFrame:ClearAllPoints() MiniMapMailFrame:SetPoint('BOTTOMRIGHT', 0, -10)
MinimapZoneTextButton:Hide()

--player health bar(status bar) colouring at certain % HP;class colours

local function colour(statusbar, unit)
   if UnitIsPlayer(unit) and UnitIsConnected(unit) and unit == statusbar.unit then
      if UnitIsUnit(statusbar.unit, "player") then
         local percent = UnitHealth(statusbar.unit) * 100 / UnitHealthMax(statusbar.unit)
         if percent <= 25 then
            statusbar:SetStatusBarColor(1, 0, 0)
         elseif percent <= 60 then
            statusbar:SetStatusBarColor(1, 1, 0)
         else
            statusbar:SetStatusBarColor(0, 1, 0)
         end
      else
         local _, class = UnitClass(unit)
         local c = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
         if c then
   statusbar:SetStatusBarColor(c.r, c.g, c.b)
end
      end
   end
end 
hooksecurefunc("UnitFrameHealthBar_Update", colour)
hooksecurefunc("HealthBar_OnValueChanged", function()
        colour(this, this.unit)
end)

-- Disable combat text spam over player & pet frame
PlayerHitIndicator:SetText(nil)
PlayerHitIndicator.SetText = function() end

PetHitIndicator:SetText(nil)
PetHitIndicator.SetText = function() end

--current HP/MANA value
PetFrameHealthBar.useSimpleValue = true
PetFrameManaBar.useSimpleValue = true
PlayerFrameHealthBar.useSimpleValue = true
PlayerFrameManaBar.useSimpleValue = true
TargetFrameHealthBar.useSimpleValue = true
TargetFrameManaBar.useSimpleValue = true
FocusFrameHealthBar.useSimpleValue = true
FocusFrameManaBar.useSimpleValue = true
for i=1,4 do
   _G["PartyMemberFrame"..i.."HealthBar"].useSimpleValue = true
   _G["PartyMemberFrame"..i.."ManaBar"].useSimpleValue = true
end

function TextStatusBar_UpdateTextString(textStatusBar)
   if ( not textStatusBar ) then
      textStatusBar = this;
   end
   local textString = textStatusBar.TextString;
   if(textString) then
      local value = textStatusBar.finalValue or textStatusBar:GetValue();
      local valueMin, valueMax = textStatusBar:GetMinMaxValues();

      if ( ( tonumber(valueMax) ~= valueMax or valueMax > 0 ) and not ( textStatusBar.pauseUpdates ) ) then
         textStatusBar:Show();
         if ( value and valueMax > 0 and ( GetCVar("statusTextPercentage") == "1" or textStatusBar.showPercentage ) ) then
            if ( value == 0 and textStatusBar.zeroText ) then
               textString:SetText(textStatusBar.zeroText);
               textStatusBar.isZero = 1;
               textString:Show();
               return;
            end
            value = tostring(math.ceil((value / valueMax) * 100)) .. "%";
            if ( textStatusBar.prefix and (textStatusBar.alwaysPrefix or not (textStatusBar.cvar and GetCVar(textStatusBar.cvar) == "1" and textStatusBar.textLockable) ) ) then
               textString:SetText(textStatusBar.prefix .. " " .. value);
            else
               textString:SetText(value);
            end
         elseif ( value == 0 and textStatusBar.zeroText ) then
            textString:SetText(textStatusBar.zeroText);
            textStatusBar.isZero = 1;
            textString:Show();
            return;
         elseif ( textStatusBar.useSimpleValue ) then
            textStatusBar.isZero = nil;
            textString:SetText(value);
         else
            textStatusBar.isZero = nil;
            if ( textStatusBar.prefix and (textStatusBar.alwaysPrefix or not (textStatusBar.cvar and GetCVar(textStatusBar.cvar) == "1" and textStatusBar.textLockable) ) ) then
               textString:SetText(textStatusBar.prefix.." "..value.." / "..valueMax);
            else
               textString:SetText(value.." / "..valueMax);
            end
         end
         
         if ( (textStatusBar.cvar and GetCVar(textStatusBar.cvar) == "1" and textStatusBar.textLockable) or textStatusBar.forceShow ) then
            textString:Show();
         elseif ( textStatusBar.lockShow > 0 ) then
            textString:Show();
         else
            textString:Hide();
         end
      else
         textString:Hide();
         textStatusBar:Hide();
      end
   end
end

--Pet Frame (IT IS NECCESSARY TO COPY INTERFACE/TARGETINGFRAME FOLDER AS WELL)

PetFrameHealthBar:SetWidth(70)
PetFrameHealthBar:SetHeight(18)
PetFrameManaBar:SetWidth(71)
PetFrameManaBar:SetHeight(10)
PetFrameHealthBar:SetPoint("TOPLEFT", 45, -14)
PetFrameHealthBarText:SetPoint("CENTER", 19, 4)
PetFrameHealthBarText:SetFont("Fonts/FRIZQT__.TTF", 14, "OUTLINE")
PetFrameManaBarText:SetPoint("CENTER", 19, -10)
PetFrameManaBarText:SetFont("Fonts/FRIZQT__.TTF", 9, "OUTLINE")
PetFrameManaBar:SetPoint("TOPLEFT", 45, -32)


--Party Member Frames 1-4

PartyMemberFrame1Texture:SetTexture("Interface\\AddOns\\TextureScript\\UI-PartyFrame")
PartyMemberFrame1HealthBar:SetWidth(70)
PartyMemberFrame1HealthBar:SetHeight(18)
PartyMemberFrame1ManaBar:SetWidth(71)
PartyMemberFrame1ManaBar:SetHeight(10)
PartyMemberFrame1HealthBar:SetPoint("TOPLEFT", 45, -14)
PartyMemberFrame1HealthBarText:SetPoint("CENTER", 19, 4)
PartyMemberFrame1HealthBarText:SetFont("Fonts/FRIZQT__.TTF", 14, "OUTLINE")
PartyMemberFrame1ManaBarText:SetPoint("CENTER", 19, -10)
PartyMemberFrame1ManaBarText:SetFont("Fonts/FRIZQT__.TTF", 9, "OUTLINE")
PartyMemberFrame1ManaBar:SetPoint("TOPLEFT", 45, -32)

PartyMemberFrame2Texture:SetTexture("Interface\\AddOns\\TextureScript\\UI-PartyFrame")
PartyMemberFrame2HealthBar:SetWidth(70)
PartyMemberFrame2HealthBar:SetHeight(18)
PartyMemberFrame2ManaBar:SetWidth(71)
PartyMemberFrame2ManaBar:SetHeight(10)
PartyMemberFrame2HealthBar:SetPoint("TOPLEFT", 45, -14)
PartyMemberFrame2HealthBarText:SetPoint("CENTER", 19, 4)
PartyMemberFrame2HealthBarText:SetFont("Fonts/FRIZQT__.TTF", 14, "OUTLINE")
PartyMemberFrame2ManaBarText:SetPoint("CENTER", 19, -10)
PartyMemberFrame2ManaBarText:SetFont("Fonts/FRIZQT__.TTF", 9, "OUTLINE")
PartyMemberFrame2ManaBar:SetPoint("TOPLEFT", 45, -32)


PartyMemberFrame3Texture:SetTexture("Interface\\AddOns\\TextureScript\\UI-PartyFrame")
PartyMemberFrame3HealthBar:SetWidth(70)
PartyMemberFrame3HealthBar:SetHeight(18)
PartyMemberFrame3ManaBar:SetWidth(71)
PartyMemberFrame3ManaBar:SetHeight(10)
PartyMemberFrame3HealthBar:SetPoint("TOPLEFT", 45, -14)
PartyMemberFrame3HealthBarText:SetPoint("CENTER", 19, 4)
PartyMemberFrame3HealthBarText:SetFont("Fonts/FRIZQT__.TTF", 14, "OUTLINE")
PartyMemberFrame3ManaBarText:SetPoint("CENTER", 19, -10)
PartyMemberFrame3ManaBarText:SetFont("Fonts/FRIZQT__.TTF", 9, "OUTLINE")
PartyMemberFrame3ManaBar:SetPoint("TOPLEFT", 45, -32)


PartyMemberFrame4Texture:SetTexture("Interface\\AddOns\\TextureScript\\UI-PartyFrame")
PartyMemberFrame4HealthBar:SetWidth(70)
PartyMemberFrame4HealthBar:SetHeight(18)
PartyMemberFrame4ManaBar:SetWidth(71)
PartyMemberFrame4ManaBar:SetHeight(10)
PartyMemberFrame4HealthBar:SetPoint("TOPLEFT", 45, -14)
PartyMemberFrame4HealthBarText:SetPoint("CENTER", 19, 4)
PartyMemberFrame4HealthBarText:SetFont("Fonts/FRIZQT__.TTF", 14, "OUTLINE")
PartyMemberFrame4ManaBarText:SetPoint("CENTER", 19, -10)
PartyMemberFrame4ManaBarText:SetFont("Fonts/FRIZQT__.TTF", 9, "OUTLINE")
PartyMemberFrame4ManaBar:SetPoint("TOPLEFT", 45, -32)

--Player Frame, Focus Frame, Target Frame

PlayerFrameTexture:SetTexture("Interface\\AddOns\\TextureScript\\UI-TargetingFrame")
PlayerStatusTexture:SetTexture("Interface\\AddOns\\TextureScript\\UI-Player-Status")
PlayerFrameHealthBar:SetWidth(119)
PlayerFrameHealthBar:SetHeight(29)
PlayerFrameHealthBar:SetPoint("TOPLEFT", 106, -22)
PlayerName:SetPoint("CENTER", 50, 35)
PlayerFrameHealthBarText:SetPoint("CENTER", 50, 12)
PlayerFrameHealthBarText:SetFont("Fonts/FRIZQT__.TTF", 16, "OUTLINE")

for _,name in ipairs({"Target", "Focus"}) do
   _G[name.."FrameHealthBar"]:SetWidth(119)
   _G[name.."FrameHealthBar"]:SetHeight(29)
   _G[name.."FrameHealthBar"]:SetPoint("TOPLEFT", 7, -22)
   _G[name.."FrameHealthBar"]:SetPoint("CENTER", -50, 6)
   _G[name.."FrameNameBackground"]:Hide()
   _G[name.."Name"]:SetPoint("CENTER", -50, 35)
   _G[name.."FrameHealthBarText"]:SetPoint("CENTER", -50, 12)
   _G[name.."FrameHealthBarText"]:SetFont("Fonts/FRIZQT__.TTF", 16, "OUTLINE")
end
hooksecurefunc("TargetFrame_CheckClassification", function()
local classification = UnitClassification("target")
if classification == "elite" or classification == "worldboss" then
TargetFrameTexture:SetTexture("Interface\\AddOns\\TextureScript\\UI-TargetingFrame-Elite")
elseif classification == "rareelite" then
TargetFrameTexture:SetTexture("Interface\\AddOns\\TextureScript\\UI-TargetingFrame-Rare-Elite")
elseif classification == "rare" then
TargetFrameTexture:SetTexture("Interface\\AddOns\\TextureScript\\UI-TargetingFrame-Rare")
else
TargetFrameTexture:SetTexture("Interface\\AddOns\\TextureScript\\UI-TargetingFrame")
end
end)

hooksecurefunc("FocusFrame_CheckClassification", function()
   local classification = UnitClassification("focus")
   if classification == "elite" or classification == "worldboss" then
      FocusFrameTexture:SetTexture("Interface\\AddOns\\TextureScript\\UI-TargetingFrame-Elite")
   elseif classification == "rareelite" then
      FocusFrameTexture:SetTexture("Interface\\AddOns\\TextureScript\\UI-TargetingFrame-Rare-Elite")
   elseif classification == "rare" then
      FocusFrameTexture:SetTexture("Interface\\AddOns\\TextureScript\\UI-TargetingFrame-Rare")
   else
      FocusFrameTexture:SetTexture("Interface\\AddOns\\TextureScript\\FocusFrame")
   end
end)

--Blacklist of frames where tooltips mouseovering is hidden(editable)

local tooltipOwnerBlacklist = {
   "ActionButton%d+$",            -- bar buttons
   "MultiBarBottomLeftButton",
   "MultiBarBottomRightButton",
   "MultiBarLeftButton",
   "MultiBarRightButton",
   "MinimapZoneTextButton",
   "MicroButton$",                -- micro buttons
   "^KeyRingButton$",             -- key ring
   "^CharacterBag%dSlot$",        -- bags
   "^MainMenuBarBackpackButton$", -- backpack
}

local GameTooltip_OnShow = GameTooltip:GetScript("OnShow")
GameTooltip:SetScript("OnShow", function(...)
   local owner = this:GetOwner() and this:GetOwner():GetName()
   if owner then
      -- hide world object tooltips like torches and signs
      if owner == "UIParent" and not this:GetUnit() then
         this:Hide()
         return
      end
      -- hide tooltips owned by frames in the blacklist
      for i=1,#tooltipOwnerBlacklist do
         if owner:find(tooltipOwnerBlacklist[i]) then
            this:Hide()
            return
         end
      end
   end
   if GameTooltip_OnShow then
      GameTooltip_OnShow(...)
   end
end)

--Left and Right Dragons on action bar hidden

MainMenuBarLeftEndCap:Hide();MainMenuBarRightEndCap:Hide()

--Hidden Player glow combat/rested flashes + Hidden Focus Flash on Focused Target + Trying to completely hide the red glowing status on target/focus frames when they have low HP(this is not completely fixed yet)

hooksecurefunc("PlayerFrame_UpdateStatus", function() PlayerStatusTexture:Hide() end)
hooksecurefunc("TargetFrame_CheckFocus", function() TargetFrameFlash:Hide() end)
local function RemoveRedPortrait(texture)
   local r, g, b = texture:GetVertexColor()
   if g == 0 and r > .99 and b == 0 then -- using > .99 because the real value will be something like .999999824878495 instead of 1
      texture:SetVertexColor(1.0, 1.0, 1.0, 1.0)
   end
end

hooksecurefunc("TargetHealthCheck", function() RemoveRedPortrait(TargetPortrait) end)
hooksecurefunc("TargetofTargetHealthCheck", function() RemoveRedPortrait(TargetofTargetPortrait) end)
hooksecurefunc("FocusHealthCheck", function() RemoveRedPortrait(FocusPortrait) end)

--Player,Focus,Target,Pet and Party 1-4 Frames cleaned of names, group frame titles, combat indicators, glows, leader icons, master looter icons, levels, rest icons, !Improved Error Frame button hidden, Red Erros in top-center of screen hidden etc

PlayerName:Hide()
PetName:Hide()
FocusFrameTitle:Hide()
PlayerFrameGroupIndicator:SetScript("OnShow", PlayerFrameGroupIndicator.Hide)
ActionBarUpButton:Hide()
ActionBarDownButton:Hide()
MainMenuBarPageNumber:SetAlpha(0)

UIErrorsFrame:Hide()

PlayerRestIcon:SetAlpha(0)
PlayerAttackIcon:SetAlpha(0)
PlayerRestGlow:SetAlpha(0)
PlayerLevelText:SetAlpha(0)
PlayerAttackGlow:SetAlpha(0)
PlayerStatusGlow:SetAlpha(0)
PlayerAttackBackground:SetAlpha(0)
PlayerLeaderIcon:SetAlpha(0)
PlayerStatusTexture:SetAlpha(0)
PlayerMasterIcon:SetAlpha(0)


FocusLevelText:SetAlpha(0)
FocusLeaderIcon:SetAlpha(0)

TargetLevelText:SetAlpha(0)
TargetLeaderIcon:SetAlpha(0)


PartyMemberFrame1LeaderIcon:SetAlpha(0)
PartyMemberFrame1MasterIcon:SetAlpha(0)

PartyMemberFrame2LeaderIcon:SetAlpha(0)
PartyMemberFrame2MasterIcon:SetAlpha(0)

PartyMemberFrame3LeaderIcon:SetAlpha(0)
PartyMemberFrame3MasterIcon:SetAlpha(0)

PartyMemberFrame4LeaderIcon:SetAlpha(0)
PartyMemberFrame4MasterIcon:SetAlpha(0)

PartyMemberFrame1Name:SetAlpha(0)
PartyMemberFrame2Name:SetAlpha(0)
PartyMemberFrame3Name:SetAlpha(0)
PartyMemberFrame4Name:SetAlpha(0)

ChatFrameMenuButton:Hide()

--script preventing addons that are bound on combat log from bugging(automatically clearing combat log every frame--60fps=60x cleaned per 1 second)

local f = CreateFrame("frame",nil, UIParent); f:SetScript("OnUpdate", CombatLogClearEntries);


--TargetFrame castbar slight up-scaling

TargetFrameSpellBar:SetScale(1.1)


--FocusFrame castbar slight up-scaling

FocusFrameSpellBar:SetScale(1.1)


--Action bar buttons are now bigger, better looking and also fixes spellbook/wep switch bugging of dark theme

hooksecurefunc("ActionButton_ShowGrid", function(Button)
   if not Button then
      Button = this
   end
   _G[Button:GetName().."NormalTexture"]:SetVertexColor(1, 1, 1, 1)
end)
for _, Bar in pairs({ "Action", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarLeft", "MultiBarRight", "Stance", "PetAction" }) do
for i = 1, 12 do
local Button = Bar.."Button"..i
if _G[Button] then _G[Button.."Icon"]:SetTexCoord(0.06, 0.94, 0.06, 0.94) end
end
end

--smooth status bars(animated)

local floor = math.floor
local barstosmooth = {
   PlayerFrameHealthBar = "player",
   PlayerFrameManaBar = "player",
   TargetFrameHealthBar = "target",
   PetFrameHealthBar = "pet",
   PetFrameManaBar = "pet",
   TargetFrameManaBar = "target",
   FocusFrameHealthBar = "focus",
   FocusFrameManaBar = "focus",
   MainMenuExpBar = "",
   ReputationWatchStatusBar = "",
   PartyMemberFrame1HealthBar = "party1",
   PartyMemberFrame1ManaBar = "party1",
   PartyMemberFrame2HealthBar = "party2",
   PartyMemberFrame2ManaBar = "party2",
   PartyMemberFrame3HealthBar = "party3",
   PartyMemberFrame3ManaBar = "party3",
   PartyMemberFrame4HealthBar = "party4",
   PartyMemberFrame4ManaBar = "party4",
    } 
    MODUI_RAIDBARS_TO_SMOOTH = {}
 
    local smoothframe = CreateFrame'Frame'
    smoothing = {}
 
    local isPlate = function(frame)
        local overlayRegion = frame:GetRegions()
        if not overlayRegion or overlayRegion:GetObjectType() ~= 'Texture'
        or overlayRegion:GetTexture() ~= [[Interface\Tooltips\Nameplate-Border]] then
            return false
        end
        return true
    end
 
    local min, max = math.min, math.max
    local function AnimationTick()
        local limit = 30/GetFramerate()
        for bar, value in pairs(smoothing) do
            local cur = bar:GetValue()
            local new = cur + min((value - cur)/3, max(value - cur, limit))
            if new ~= new then new = value end
            if cur == value or abs(new - value) < 2 then
                bar:SetValue_(value)
                smoothing[bar] = nil
            else
                bar:SetValue_(floor(new))
            end
        end
    end
 
local function SmoothSetValue(self, value)
   self.finalValue = value
   if self.unitType then
      local guid = UnitGUID(self.unitType)
      if value == self:GetValue() or not guid or guid ~= self.lastGuid then
         smoothing[self] = nil
         self:SetValue_(value)
      else
         smoothing[self] = value
      end
      self.lastGuid = guid
   else
     local _, max = self:GetMinMaxValues()
     if value == self:GetValue() or self._max and self._max ~= max then
         smoothing[self] = nil
         self:SetValue_(value)
     else
         smoothing[self] = value
     end
     self._max = max
   end
end 
    for bar, value in pairs(smoothing) do
        if bar.SetValue_ then bar.SetValue = SmoothSetValue end
    end
 
    local function SmoothBar(bar)
        if not bar.SetValue_ then
            bar.SetValue_ = bar.SetValue bar.SetValue = SmoothSetValue
        end
    end
 
    local function ResetBar(bar)
        if bar.SetValue_ then
            bar.SetValue = bar.SetValue_ bar.SetValue_ = nil
        end
    end
 
    smoothframe:SetScript('OnUpdate', function()
        local frames = {WorldFrame:GetChildren()}
        for _, plate in ipairs(frames) do
            if isPlate(plate) and plate:IsVisible() then
                local v = plate:GetChildren()
                SmoothBar(v)
            end
        end
        AnimationTick()
    end)
 
     for k,v in pairs (barstosmooth) do
      if _G[k] then
         SmoothBar(_G[k])
_G[k]:SetScript("OnHide", function() this.lastGuid = nil; this.max_ = nil end)
         if v ~= "" then
            _G[k].unitType = v
         end
      end
   end
    smoothframe:RegisterEvent'ADDON_LOADED'
    smoothframe:SetScript('OnEvent', function()
        if arg1 == 'Blizzard_RaidUI' then
            for i = 1, 40 do
                local hp = _G['modraid'..i]
                local pp = _G['modraid'..i]
                if hp then
                    for _, v in pairs({hp.hp, pp.mana}) do SmoothBar(v) end
                end
            end
        end
    end)



--POSITION OF DEBUFFS ON PARTY MEMBER FRAMES 1-4

PartyMemberFrame1Debuff1:ClearAllPoints();
PartyMemberFrame1Debuff1:SetPoint("BOTTOMLEFT", 45.00000048894432, -9.374971298968035);

PartyMemberFrame2Debuff1:ClearAllPoints();
PartyMemberFrame2Debuff1:SetPoint("BOTTOMLEFT", 44.99999870080508, -8.437474379317337);

PartyMemberFrame3Debuff1:ClearAllPoints();
PartyMemberFrame3Debuff1:SetPoint("BOTTOMLEFT", 44.99999870080508, -10.31263004755721);

PartyMemberFrame4Debuff1:ClearAllPoints();
PartyMemberFrame4Debuff1:SetPoint("BOTTOMLEFT", 44.99999870080508, -8.437541575172077);

--POSITION OF PET FRAMES AT PARTY MEMBER FRAMES 1-4 LF HELP WITH(WHEN I TRIED TO FIX, IT DIDNT WORK, MOVEANYTHING ADDON FUCKED OTHER PARTY FRAMES)


--tremor totem highlight

local AddOn = "TextureScript"

local Table = {
	["Nameplates"] = {},
	["Totems"] = {
				["Tremor Totem"] = true,
			},
	["Shits"] = {
				
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
		["Tranquil Air Totem"] = true,
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

	Scale = 1,
}
local function log(msg) DEFAULT_CHAT_FRAME:AddMessage(msg) end -- alias for convenience

local function UpdateObjects(hp)
	frame = hp:GetParent()

	local hpborder, cbborder, cbicon, overlay, oldname, level, bossicon, raidicon = frame:GetRegions()
	--local overlayRegion, castBarOverlayRegion, spellIconRegion, highlightRegion, nameTextRegion, bossIconRegion, levelTextRegion, raidIconRegion = frame:GetRegions()
	local name = oldname:GetText()

	for totem in pairs(Table["Shits"]) do
		if ( name == totem and Table["Shits"][totem] == true ) then
			
			overlay:SetAlpha(0) 
			hpborder:Hide()
			oldname:Hide()
			level:Hide()
			hp:SetAlpha(0)
			raidicon:Hide()

			if not frame.totem then
				frame.totem = frame:CreateTexture(nil, "BACKGROUND")
				frame.totem:ClearAllPoints()
				frame.totem:SetPoint("CENTER",frame,"CENTER",Table.xOfs,Table.yOfs)
			else
				frame.totem:Show()
			end	
		
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

local function SkinObjects(frame)
	local HealthBar, CastBar = frame:GetChildren()
	--local threat, hpborder, cbshield, cbborder, cbicon, overlay, oldname, level, bossicon, raidicon, elite = frame:GetRegions()
	local overlayRegion, castBarOverlayRegion, spellIconRegion, highlightRegion, nameTextRegion, bossIconRegion, levelTextRegion, raidIconRegion = frame:GetRegions()

	HealthBar:SetScript("OnShow", UpdateObjects)
	HealthBar:SetScript("OnSizeChanged", UpdateObjects)

	UpdateObjects(HealthBar)
	Table["Nameplates"][frame] = true
end

local select = select
local function HookFrames(...)
	for index = 1, select('#', ...) do
		local frame = select(index, ...)
		local region = frame:GetRegions()
		if ( not Table["Nameplates"][frame] and not frame:GetName() and region and region:GetObjectType() == "Texture" and region:GetTexture() == "Interface\\Tooltips\\Nameplate-Border" ) then
			SkinObjects(frame)						
			frame.region = region
		end
	end
end

local Frame = CreateFrame("Frame")
Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
Frame:SetScript("OnUpdate", function(self, elapsed)
	if ( WorldFrame:GetNumChildren() ~= numChildren ) then
		numChildren = WorldFrame:GetNumChildren()
		HookFrames(WorldFrame:GetChildren())		
	end
end)

--disable mouseover flashing on buttons

texture = MultiBarBottomLeftButton1:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomLeftButton2:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomLeftButton3:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomLeftButton4:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomLeftButton5:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomLeftButton6:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomLeftButton7:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomLeftButton8:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomLeftButton9:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomLeftButton10:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomLeftButton11:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomLeftButton12:GetHighlightTexture()
texture:SetAlpha(0)

texture = MultiBarBottomRightButton1:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomRightButton2:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomRightButton3:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomRightButton4:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomRightButton5:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomRightButton6:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomRightButton7:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomRightButton8:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomRightButton9:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomRightButton10:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomRightButton11:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarBottomRightButton12:GetHighlightTexture()
texture:SetAlpha(0)

texture = MultiBarLeftButton1:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarLeftButton2:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarLeftButton3:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarLeftButton4:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarLeftButton5:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarLeftButton6:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarLeftButton7:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarLeftButton8:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarLeftButton9:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarLeftButton10:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarLeftButton11:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarLeftButton12:GetHighlightTexture()
texture:SetAlpha(0)

texture = MultiBarRightButton1:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarRightButton2:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarRightButton3:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarRightButton4:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarRightButton5:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarRightButton6:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarRightButton7:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarRightButton8:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarRightButton9:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarRightButton10:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarRightButton11:GetHighlightTexture()
texture:SetAlpha(0)
texture = MultiBarRightButton12:GetHighlightTexture()
texture:SetAlpha(0)

texture = ActionButton1:GetHighlightTexture()
texture:SetAlpha(0)
texture = ActionButton2:GetHighlightTexture()
texture:SetAlpha(0)
texture = ActionButton3:GetHighlightTexture()
texture:SetAlpha(0)
texture = ActionButton4:GetHighlightTexture()
texture:SetAlpha(0)
texture = ActionButton5:GetHighlightTexture()
texture:SetAlpha(0)
texture = ActionButton6:GetHighlightTexture()
texture:SetAlpha(0)
texture = ActionButton7:GetHighlightTexture()
texture:SetAlpha(0)
texture = ActionButton8:GetHighlightTexture()
texture:SetAlpha(0)
texture = ActionButton9:GetHighlightTexture()
texture:SetAlpha(0)
texture = ActionButton10:GetHighlightTexture()
texture:SetAlpha(0)
texture = ActionButton11:GetHighlightTexture()
texture:SetAlpha(0)
texture = ActionButton12:GetHighlightTexture()
texture:SetAlpha(0)

texture = MainMenuBarBackpackButton:GetHighlightTexture()
texture:SetAlpha(0)

texture = CharacterBag0Slot:GetHighlightTexture()
texture:SetAlpha(0)

texture = CharacterBag1Slot:GetHighlightTexture()
texture:SetAlpha(0)

texture = CharacterBag2Slot:GetHighlightTexture()
texture:SetAlpha(0)

texture = CharacterBag3Slot:GetHighlightTexture()
texture:SetAlpha(0)

texture = CharacterMicroButton:GetHighlightTexture()
texture:SetAlpha(0)

texture = SpellbookMicroButton:GetHighlightTexture()
texture:SetAlpha(0)

texture = TalentMicroButton:GetHighlightTexture()
texture:SetAlpha(0)

texture = QuestLogMicroButton:GetHighlightTexture()
texture:SetAlpha(0)

texture = SocialsMicroButton:GetHighlightTexture()
texture:SetAlpha(0)

texture = LFGMicroButton:GetHighlightTexture()
texture:SetAlpha(0)

texture = MainMenuMicroButton:GetHighlightTexture()
texture:SetAlpha(0)

texture = HelpMicroButton:GetHighlightTexture()
texture:SetAlpha(0)

--Class-coloured nameplates

local plated = CreateFrame("Frame", "TextureScript", UIParent)

local healthBar, castBar
local overlayRegion, castBarOverlayRegion, spellIconRegion, highlightRegion, nameTextRegion, bossIconRegion, levelTextRegion, raidIconRegion
local lastUpdate = 0
local longUpdate = 0
local frame
local name, class, classL

local classes = {}
local rgb = {}
for k, v in pairs(RAID_CLASS_COLORS) do
	rgb[k] = { v.r, v.g, v.b }
end

local function IsNameplate(frame)
	if frame:GetName() then return false end

	overlayRegion = frame:GetRegions()
	if not overlayRegion or overlayRegion:GetObjectType() ~= "Texture" or overlayRegion:GetTexture() ~= "Interface\\Tooltips\\Nameplate-Border" then
		return false
	end
	return frame:GetChildren()
end


local function ColorNameplate(frame)
	healthBar, castBar = frame:GetChildren()
	overlayRegion, castBarOverlayRegion, spellIconRegion, highlightRegion, nameTextRegion, levelTextRegion, bossIconRegion, raidIconRegion = frame:GetRegions()
	
	name = nameTextRegion:GetText()
	if name and classes[name] then
		healthBar:SetStatusBarColor(unpack(rgb[classes[name]]))
	end
end

local function OnUpdate(self, elapsed)
	lastUpdate = lastUpdate + elapsed
	longUpdate = longUpdate + elapsed
	
	if lastUpdate > .1 then
		lastUpdate = 0
		for i = 1, select("#", WorldFrame:GetChildren()) do
			frame = select(i, WorldFrame:GetChildren())
    		if IsNameplate(frame) then ColorNameplate(frame) end
		end  
	end
	
	if longUpdate > 15 then
		longUpdate = 0
		if MiniMapBattlefieldFrame.status == "active" then RequestBattlefieldScoreData() end
	end
end

local function OnEvent(self, event, ...)
	if self[event] then self[event]() end
end

plated:SetScript("OnUpdate", OnUpdate)
plated:SetScript("OnEvent", OnEvent)

plated:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
plated:RegisterEvent("PLAYER_TARGET_CHANGED")
plated:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")

local function AddName(name, class)
	if not class or not name then return end
	if class == "UNKNOWN" or not RAID_CLASS_COLORS[class] then return end
	classes[name] = class
end

function plated:UPDATE_MOUSEOVER_UNIT()
	if UnitIsPlayer("mouseover") then
		classL, class = UnitClass("mouseover")
		name = UnitName("mouseover")
		AddName(name, class)
	end
end

function plated:PLAYER_TARGET_CHANGED()
	if UnitIsPlayer("target") then
		classL, class = UnitClass("target")
		name = UnitName("target")
		AddName(name, class)
	end
end

function plated:UPDATE_BATTLEFIELD_SCORE()
	for i = 1, GetNumBattlefieldScores() do
		local name, _, _, _, _, _, _, _, _, class = GetBattlefieldScore(i)
		name = ("-"):split(name, 2)
		AddName(name, class)
	end
end

--auto-sell gray shits and try to repair(from guildbank if possible)

local g = CreateFrame("Frame")
g:RegisterEvent("MERCHANT_SHOW")

g:SetScript("OnEvent", function()  
    local bag, slot
    for bag = 0, 4 do
        for slot = 0, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link and (select(3, GetItemInfo(link)) == 0) then
                UseContainerItem(bag, slot)
            end
        end
    end

    if(CanMerchantRepair()) then
        local cost = GetRepairAllCost()
        if cost > 0 then
            local money = GetMoney()
            if IsInGuild() then
                local guildMoney = GetGuildBankWithdrawMoney()
                if guildMoney > GetGuildBankMoney() then
                    guildMoney = GetGuildBankMoney()
                end
                if guildMoney > cost and CanGuildBankRepair() then
                    RepairAllItems(1)
                    ChatFrame1:AddMessage(format("|cfff07100Repair cost covered by G-Bank: %.1fg|r", cost * 0.0001))
                    return
                end
            end
            if money > cost then
                RepairAllItems()
                ChatFrame1:AddMessage(format("|cffead000Repair cost: %.1fg|r", cost * 0.0001))
            else
                ChatFrame1:AddMessage("Not enough gold to cover the repair cost.")
            end
        end
    end
end)


--ADD EXTRA COMMANDS for Ready Check + GM ticket /rc and /gm

SlashCmdList["READYCHECK"] = function() DoReadyCheck() end
SLASH_READYCHECK1 = '/rc'

SlashCmdList["TICKET"] = function() ToggleHelpFrame() end
SLASH_TICKET1 = "/gm"


--XP bar + reputation bar visual rework


 local BACKDROP = {  bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
                        insets = {left = -1, right = -1, top = -1, bottom = -1} }
    local _, class = UnitClass'Player'
    local colour = RAID_CLASS_COLORS[class]
    local orig = {}

    orig.ReputationWatchBar_Update = ReputationWatchBar_Update

    MainMenuExpBar:SetWidth(1021) MainMenuExpBar:SetHeight(5)
    MainMenuExpBar:ClearAllPoints() MainMenuExpBar:SetPoint('TOP', MainMenuBar, 0, -4)
    MainMenuExpBar:SetBackdrop(BACKDROP)
    MainMenuExpBar:SetBackdropColor(0, 0, 0, 1)

    MainMenuExpBar.spark = MainMenuExpBar:CreateTexture(nil, 'OVERLAY', nil, 7)
    MainMenuExpBar.spark:SetTexture[[Interface\CastingBar\UI-CastingBar-Spark]]
    MainMenuExpBar.spark:SetWidth(35) MainMenuExpBar.spark:SetHeight(35)
    MainMenuExpBar.spark:SetBlendMode'ADD'

    MainMenuExpBar.rep = MainMenuExpBar:CreateFontString(nil, 'OVERLAY')
    MainMenuExpBar.rep:SetFont(STANDARD_TEXT_FONT, 12, 'OUTLINE')
    MainMenuExpBar.rep:SetPoint('RIGHT', MainMenuBarExpText, 'LEFT')

    ReputationWatchStatusBar:SetWidth(1021)
    ReputationWatchStatusBar:SetBackdrop(BACKDROP)
    ReputationWatchStatusBar:SetBackdropColor(0, 0, 0, 1)

    ReputationWatchStatusBar.spark = ReputationWatchStatusBar:CreateTexture(nil, 'OVERLAY', nil, 7)
    ReputationWatchStatusBar.spark:SetTexture[[Interface\CastingBar\UI-CastingBar-Spark]]
    ReputationWatchStatusBar.spark:SetWidth(35) ReputationWatchStatusBar.spark:SetHeight(35)
    ReputationWatchStatusBar.spark:SetBlendMode'ADD'
    ReputationWatchStatusBar.spark:SetVertexColor(colour.r*1.3, colour.g*1.3, colour.b*1.3, .6)

    for i = 0, 3 do _G['MainMenuXPBarTexture'..i]:SetTexture'' end
    for i = 0, 3 do _G['ReputationWatchBarTexture'..i]:SetTexture'' end
    for i = 0, 3 do _G['ReputationXPBarTexture'..i]:SetTexture'' end

    function MainMenuExpBar_Update()
        local xp, next = UnitXP'player', UnitXPMax'player'
        MainMenuExpBar:SetMinMaxValues(min(0, xp), next)
        MainMenuExpBar:SetValue(math.floor(xp))
    end

    function ReputationWatchBar_Update(newLevel)
        if not newLevel then newLevel = UnitLevel'player' end
        orig.ReputationWatchBar_Update(newLevel)
        local name, standing, min, max, v = GetWatchedFactionInfo()
        local percent = math.floor((v - min)/(max - min)*100)
        local x

        local bar  = ReputationWatchBar
        local sb   = ReputationWatchStatusBar
        local text = ReputationWatchStatusBarText

        if v > 0 then x = ((v - min)/(max - min))*bar:GetWidth() end

        bar:SetFrameStrata'LOW'
        bar:SetHeight(newLevel < MAX_PLAYER_LEVEL and 4 or 5)

        if newLevel == MAX_PLAYER_LEVEL then
            bar:ClearAllPoints()
            bar:SetPoint('TOP', MainMenuBar, 0, -4)
            text:SetPoint('CENTER', ReputationWatchBarOverlayFrame, 0, 3)
            text:SetDrawLayer('OVERLAY', 7)
            if name then
                text:SetFont(STANDARD_TEXT_FONT, 12, 'OUTLINE')
                if GetCVar'modValue' == '1' then
                    text:SetText(name..': '..true_format((v - min))..' / '..true_format((max - min)))
                else
                    text:SetText(name..': '..percent..'% into '.._G['FACTION_STANDING_LABEL'..standing])
                end
            end
            MainMenuExpBar.spark:Hide()
        else
            TextStatusBar_UpdateTextString(MainMenuExpBar)
            text:SetText''
            MainMenuExpBar.spark:Show()
        end

        sb:SetHeight(newLevel < MAX_PLAYER_LEVEL and 4 or 5)
        sb:SetStatusBarColor(colour.r, colour.g, colour.b, 1)
        sb.spark:SetPoint('CENTER', sb, 'LEFT', x, -1)
    end

    local f = CreateFrame'Frame'
    f:RegisterEvent'CVAR_UPDATE'
    f:RegisterEvent'PLAYER_ENTERING_WORLD' f:RegisterEvent'PLAYER_XP_UPDATE'
    f:RegisterEvent'UPDATE_EXHAUSTION'     f:RegisterEvent'PLAYER_LEVEL_UP'
    f:SetScript('OnEvent', function()
        local xp, max = UnitXP'player', UnitXPMax'player'
		local x = (xp/max)*MainMenuExpBar:GetWidth()
		MainMenuExpBar.spark:SetPoint('CENTER', MainMenuExpBar, 'LEFT', x, -1)
        if event == 'PLAYER_ENTERING_WORLD' or event == 'UPDATE_EXHAUSTION' then
		    local rest = GetRestState()
		    if rest == 1 then
                MainMenuExpBar.spark:SetVertexColor(0*1.5, .39*1.5, .88*1.5, 1)
		    elseif rest == 2 then
			    MainMenuExpBar.spark:SetVertexColor(.58*1.5, 0*1.5, .55*1.5, 1)
	        end
	    end
    end)



--increasing player-debuff size

hooksecurefunc("BuffButton_Update", function()
for i=1,32 do
if _G["DebuffButton"..i] ~= nil then
_G["DebuffButton"..i]:SetScale(1.23)
end
end
end)


--position of minimap(remove to reset minimap position)
MinimapCluster:ClearAllPoints();
MinimapCluster:SetPoint("BOTTOMLEFT", 1186.333618164063, 595.0001831054688);

--removing character "C" button image
CharacterMicroButton:UnregisterEvent("UNIT_PORTRAIT_UPDATE")
MicroButtonPortrait:SetTexture(nil)
CharacterMicroButton:SetNormalTexture("Interface/BUTTONS/Custom Evo C panel");
CharacterMicroButton:SetPushedTexture("Interface/BUTTONS/Custom Evo C panel");

--login informing this UI was properly loaded
ChatFrame1:AddMessage("PWP UI 2.2 Loaded successfully!",255,255,0)
ChatFrame1:AddMessage("Regular updates at:",255,255,0)
ChatFrame1:AddMessage("https://evolvee.github.io/EvolvePWPUI/",255,255,0)
