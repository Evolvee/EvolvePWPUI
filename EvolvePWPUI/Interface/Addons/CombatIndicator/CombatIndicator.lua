--sizes
local targetSize=35;
local focusSize=35;
local FocusCreate = CreateFrame("Frame");
local Target=CreateFrame("Frame");
local Focus=CreateFrame("Frame");

--target part´
Target:SetParent(TargetFrame);
Target:SetPoint("RIGHT", TargetFrame, 0, 10);
Target:SetHeight(targetSize);
Target:SetWidth(targetSize);
Target.texture=Target:CreateTexture(nil,BORDER);
Target.texture:SetAllPoints();
Target.texture:SetTexture("Interface\\Icons\\ABILITY_DUALWIELD");
Target:Hide();

local function FrameOnUpdate(self)
	if UnitAffectingCombat("target") then 
		self:Show(); 
	else 
		self:Hide();
	end 
end 

local TargetUpdate = CreateFrame("Frame") 
TargetUpdate:SetScript("OnUpdate", function(self) FrameOnUpdate(Target) end);


--focus part, requires more work due to focusframe being an addon in TBC
local FocusUpdate = CreateFrame("Frame"); 

local function FrameOnUpdate(self)
	if UnitAffectingCombat("focus") then
		self:Show();
	else 
		self:Hide(); 
	end 
end 

local function CreateFocus()
	if(UnitGUID("focus")~=nil) then
		Focus:SetParent(FocusFrame);
		Focus:SetPoint("RIGHT", FocusFrame, 0, 10);
		Focus:SetHeight(focusSize);
		Focus:SetWidth(focusSize);
		Focus.texture=Focus:CreateTexture(nil,BORDER);
		Focus.texture:SetAllPoints(Focus);
		Focus.texture:SetTexture("Interface\\Icons\\ABILITY_DUALWIELD");
		Focus:Hide();
		FocusCreate:SetScript("OnUpdate", nil);
		
	end
end
FocusUpdate:SetScript("OnUpdate", function(self) FrameOnUpdate(Focus) end);
FocusCreate:SetScript("OnUpdate", CreateFocus);