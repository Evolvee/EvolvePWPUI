local function log(msg) DEFAULT_CHAT_FRAME:AddMessage(msg) end -- alias for convenience
local ClassPortraits=CreateFrame("Frame", nil, UIParent);

local iconPath="Interface\\Addons\\ClassPortraits\\UI-CLASSES-CIRCLES.BLP";




local classIcons = {
-- UpperLeftx, UpperLefty, LowerLeftx, LowerLefty, UpperRightx, UpperRighty, LowerRightx, LowerRighty
	["WARRIOR"] = {0, 0, 0, 0.25, 0.25, 0, 0.25, 0.25},
	["ROGUE"] = {0.5, 0, 0.5, 0.25, 0.75, 0, 0.75, 0.25},
	["DRUID"] = {0.75, 0, 0.75, 0.25, 1, 0, 1, 0.25},
	["WARLOCK"] = {0.75, 0.25, 0.75, 0.5, 1, 0.25, 1, 0.5},
	["HUNTER"] = {0, 0.25, 0, 0.5, 0.25, 0.25, 0.25, 0.5},
	["PRIEST"] = {0.5, 0.25, 0.5, 0.5, 0.75, 0.25, 0.75, 0.5},
	["PALADIN"] = {0, 0.5, 0, 0.75, 0.25, 0.5, 0.25, 0.75},
	["SHAMAN"] = {0.25, 0.25, 0.25, 0.5, 0.5, 0.25, 0.5, 0.5},
	["MAGE"] = {0.25, 0, 0.25, 0.25, 0.5, 0, 0.5, 0.25}
};

ClassPortraits:SetScript("OnUpdate",  function() -- not returning any UnitID, have to check all frames manually
			
		if(UnitGUID("target")~=nil and UnitIsPlayer("target") ~= nil and TargetFrame.portrait~=nil) then
			TargetFrame.portrait:SetTexture(iconPath, true);
			local t=classIcons[select(2, UnitClass("target"))];
			TargetFrame.portrait:SetTexCoord(unpack(t));
		elseif(UnitGUID("target")~=nil) then
			TargetFrame.portrait:SetTexCoord(0,1,0,1);
		end
		
		if(UnitGUID("targettarget")~=nil and UnitIsPlayer("targettarget") ~= nil and TargetofTargetFrame.portrait~=nil) then
		TargetofTargetFrame.portrait:SetTexture(iconPath, true);
		local tt=classIcons[select(2, UnitClass("targettarget"))];
		TargetofTargetFrame.portrait:SetTexCoord(unpack(tt));
		elseif(UnitGUID("targettarget")~=nil) then
			TargetofTargetFrame.portrait:SetTexCoord(0,1,0,1);
		end
		
		if(UnitGUID("focus") ~= nil and UnitIsPlayer("focus") ~= nil and FocusFrame.portrait~=nil) then
		FocusFrame.portrait:SetTexture(iconPath, true);
		local f=classIcons[select(2, UnitClass("focus"))];
		FocusFrame.portrait:SetTexCoord(unpack(f));
		elseif(UnitGUID("focus")~=nil) then
			FocusFrame.portrait:SetTexCoord(0,1,0,1);
		end
		
		if(UnitGUID("focustarget")~=nil and UnitIsPlayer("focustarget") ~= nil and TargetofFocusFrame.portrait~=nil) then
		TargetofFocusFrame.portrait:SetTexture(iconPath, true);
		local ft=classIcons[select(2, UnitClass("focustarget"))];
		TargetofFocusFrame.portrait:SetTexCoord(unpack(ft));
		elseif(UnitGUID("focustarget")~=nil) then
			TargetofFocusFrame.portrait:SetTexCoord(0,1,0,1);
		end
		
		if (UnitGUID("party1")~=nil and PartyMemberFrame1~=nil and PartyMemberFrame1.portrait~=nil) then
		PartyMemberFrame1.portrait:SetTexture(iconPath, true);
		local p1=classIcons[select(2, UnitClass("party1"))];
		if p1 then PartyMemberFrame1.portrait:SetTexCoord(unpack(p1)); end
		end
		
		if(UnitGUID("party2")~=nil and PartyMemberFrame2~=nil and PartyMemberFrame2.portrait~=nil) then
		PartyMemberFrame2.portrait:SetTexture(iconPath, true);
		local p2=classIcons[select(2, UnitClass("party2"))];
		if p2 then PartyMemberFrame2.portrait:SetTexCoord(unpack(p2)); end
		end
		
		if(UnitGUID("party3")~=nil and PartyMemberFrame3~=nil and PartyMemberFrame3.portrait~=nil) then
		PartyMemberFrame3.portrait:SetTexture(iconPath, true);
		local p3=classIcons[select(2, UnitClass("party3"))];
		if p3 then PartyMemberFrame3.portrait:SetTexCoord(unpack(p3)); end
		end
		
		if(UnitGUID("party4")~=nil and PartyMemberFrame4~=nil and PartyMemberFrame4.portrait~=nil) then
		PartyMemberFrame4.portrait:SetTexture(iconPath, true);
		local p4=classIcons[select(2, UnitClass("party4"))];
		if p4 then PartyMemberFrame4.portrait:SetTexCoord(unpack(p4)); end
		end
		
		
		

--REMOVE THE SHIT BELLOW TO REMOVE CUSTOM PlayerFrame PORTRAIT

		if(UnitGUID("player")~=nil and PlayerFrame.portrait~=nil) then
		
		SetPortraitToTexture("PlayerPortrait", "Interface\\Addons\\ClassPortraits\\MYSKIN");

		end
		----]]

-- REMOVE THIS SHIT ABOVE TO REMOVE CUSTOM PlayerFrame PORTRAIT
end
);

local function UpdatePortrait(texture, unit)
   local _, class = UnitClass(unit)
   local iconCoords = CLASS_BUTTONS[class]
   if texture and iconCoords then
      texture:SetTexture(iconPath, true)
      texture:SetTexCoord(unpack(iconCoords))
   else
      DEFAULT_CHAT_FRAME:AddMessage(format("ERROR! unit:[%s] class:[%s] texture:[%s]", (unit or "nil"), (class or "nil"), (texture and texture:GetName() or "unknown")), 1, 0, 0)
   end
end
-- character sheet frame
hooksecurefunc("CharacterFrame_OnShow", function()
   UpdatePortrait(CharacterFramePortrait, "player")
end)
hooksecurefunc("CharacterFrame_OnEvent", function(event)
   if event == "UNIT_PORTRAIT_UPDATE" then
      UpdatePortrait(CharacterFramePortrait, "player")
   end
end)

local addonLoadEvent = CreateFrame("frame")
addonLoadEvent:RegisterEvent("ADDON_LOADED")
addonLoadEvent:SetScript("OnEvent", function(self, e, addon)

   -- talent frame
   if addon == "Blizzard_TalentUI" then
      hooksecurefunc(PlayerTalentFrame, "updateFunction", function()
         UpdatePortrait(PlayerTalentFramePortrait, PlayerTalentFrame.unit or "player")
      end)
      hooksecurefunc("PlayerTalentFrame_OnEvent", function()
         if event == "UNIT_PORTRAIT_UPDATE" and UnitIsUnit(arg1, "player") then
            UpdatePortrait(PlayerTalentFramePortrait, "player")
         end
      end)
      return
   end
   -- inspect frame
   if addon == "Blizzard_InspectUI" then
      hooksecurefunc("InspectFrame_OnShow", function()
         UpdatePortrait(InspectFramePortrait, InspectFrame.unit)
      end)
      hooksecurefunc("InspectFrame_UnitChanged", function()
         UpdatePortrait(InspectFramePortrait, InspectFrame.unit)
      end)
        hooksecurefunc("InspectFrame_OnEvent", function(event)
         if event == "UNIT_PORTRAIT_UPDATE" and InspectFrame.unit == arg1 then
            UpdatePortrait(InspectFramePortrait, arg1)
         end
      end)
      return
   end
end)

-- LFG, quest log, spellbook, and social window icons
LFGParentFrame:HookScript("OnShow", function() UpdatePortrait(LFGParentFrameIcon, "player") end)
UpdatePortrait((select(2, QuestLogFrame:GetRegions())), "player")
UpdatePortrait((SpellBookFrame:GetRegions()), "player")
UpdatePortrait((FriendsFrame:GetRegions()), "player")