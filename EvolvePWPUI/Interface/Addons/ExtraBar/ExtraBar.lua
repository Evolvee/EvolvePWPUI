--[[
Author: Massiner of Nathrezim
Date: 03-May-2009

Hacks and other notes:
1. The fade effect for the bar background is a good canidate to move into the new animation model (I've done a prototype but it didn't work as the onupdate implementation here). - Not applicable since the ui for this has been altered
2. This file could do with some more commenting and general cleanup before reaching v1
3. When we change from vertical to horizontal layout we don't have a fixed pivot point.
	a. This is because the anchor point does not stay fixed when the player drags the bar.
	b. It is possible to code around that issue and correct the position - unfortunately this buggers up positioning between sessions (I tried several different ways to resolve this without luck)
]]

local EBCore = CreateFrame("FRAME"); -- Needs to be a frame to respond to events
EBCore:RegisterEvent("ADDON_LOADED"); -- Fired when saved variables are loaded
EBCore:RegisterEvent("PLAYER_ENTERING_WORLD");

function EBCore:OnEvent(event, arg1)
	if (event == "ADDON_LOADED" and arg1 == "ExtraBar") then

	elseif (event == "PLAYER_ENTERING_WORLD") then
		self:Init();
		EBCore:UnregisterEvent("PLAYER_ENTERING_WORLD");
	end
end
EBCore:SetScript("OnEvent", EBCore.OnEvent);


function EBCore:Init()
	self.UpdateSavedData();
	
	self:InitBar(ExtraBar1, 1);
	self:InitBar(ExtraBar2, 2);
	self:InitBar(ExtraBar3, 3);
	self:InitBar(ExtraBar4, 4);
	
	ABTMethods_LoadAll(ExtraBar_ButtonEntries, ExtraBar_ButtonSettings);
end

function EBCore:InitBar(bar, num)



--Init the bar itself
	local name = bar:GetName();
	_G["BINDING_HEADER_"..name] = "Extra Bar "..num;
	_G["BINDING_NAME_CLICK "..name.."Button1:LeftButton"] = name.." Button 1";
	_G["BINDING_NAME_CLICK "..name.."Button2:LeftButton"] = name.." Button 2";
	_G["BINDING_NAME_CLICK "..name.."Button3:LeftButton"] = name.." Button 3";
	_G["BINDING_NAME_CLICK "..name.."Button4:LeftButton"] = name.." Button 4";
	_G["BINDING_NAME_CLICK "..name.."Button5:LeftButton"] = name.." Button 5";
	_G["BINDING_NAME_CLICK "..name.."Button6:LeftButton"] = name.." Button 6";
	_G["BINDING_NAME_CLICK "..name.."Button7:LeftButton"] = name.." Button 7";
	_G["BINDING_NAME_CLICK "..name.."Button8:LeftButton"] = name.." Button 8";
	_G["BINDING_NAME_CLICK "..name.."Button9:LeftButton"] = name.." Button 9";
	_G["BINDING_NAME_CLICK "..name.."Button10:LeftButton"] = name.." Button 10";
	_G["BINDING_NAME_CLICK "..name.."Button11:LeftButton"] = name.." Button 11";
	_G["BINDING_NAME_CLICK "..name.."Button12:LeftButton"] = name.." Button 12";

	bar.timing = 0;
	bar.number = num;
	_G[name.."Number"]:SetAlpha(0);
	_G[name.."Number"]:SetText(num);
	_G[name.."ConfigNumber"]:SetAlpha(0);
	_G[name.."ConfigNumber"]:SetText(num);

	bar.dragstate = "notshown";
	bar:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "", 
					tile = true, tileSize = 16, edgeSize = 16, 
					insets = nil});
	bar:SetBackdropColor(0.1, 0.1, 0.3, 0);
	
	--This will allow the bar to be dragged, note that EnableMouse must be true for this to work, and is toggled off to lock the bar
	bar:SetMovable(true);	



	if (ExtraBar_Config["ExtraBar"..num.."Left"] ~= nil and ExtraBar_Config["ExtraBar"..num.."Top"] ~= nil) then
		bar:ClearAllPoints();
		bar:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ExtraBar_Config["ExtraBar"..num.."Left"], ExtraBar_Config["ExtraBar"..num.."Top"]);
	end
	bar.OnUpdate = EBCore.OnUpdate;
	--This will setup dragging for the bar.
	bar:SetScript("OnMouseDown", bar.StartMoving);
	bar:SetScript("OnMouseUp", function () bar:StopMovingOrSizing(); ExtraBar_Config["ExtraBar"..num.."Left"] = bar:GetLeft(); ExtraBar_Config["ExtraBar"..num.."Top"] = bar:GetTop(); end);

	bar:SetScript("OnSizeChanged", EBCore.OnSizeChangedNum);
	
	--Setup secure handlers for enabling and disabling the bar, the main driver for doing this is for vehicles where the user stands a good chance of entering/exiting a vehicle while in combat
	--bar:Execute([[ebButtons = newtable(); owner:GetChildList(ebButtons);]]);		--Get secure references to the buttons on this bar
	bar:SetAttribute("_onshow", [[for k, v in ipairs(ebButtons) do v:Enable(); end]]);	--When the bar is shown enable the buttons
	bar:SetAttribute("_onhide", [[for k, v in ipairs(ebButtons) do v:Disable(); end]]);	--When the bar is hidden disable them

	local adjustNumber = ExtraBarConfigLib:CreateIcon("ExtraBar"..num.."AdjustNumber", bar, "Interface\\Addons\\ExtraBar\\Images\\Handle.tga", 16, 32);
	adjustNumber:AddState("bottom", "Interface\\Addons\\ExtraBar\\Images\\HandleRot.tga", 32, 16);
	adjustNumber:SetPoint("RIGHT", bar, "RIGHT", 2, 0);
	adjustNumber:EnableMouse(true);
	adjustNumber:SetScript("OnMouseDown", function () bar:SetResizable(true); bar:SetScript("OnUpdate", bar.OnUpdate); bar:StartSizing(); end);
	adjustNumber:SetScript("OnMouseUp", function () bar:StopMovingOrSizing(); bar:SetResizable(false); bar:SetScript("OnUpdate", nil); EBCore.SetBarNumButtons(EBCore.GetBarNumButtons(num), num); end);



	
	local gui = ExtraBarConfigLib:CreateIconButton("ExtraBar"..num.."Lock", bar, "Interface\\Addons\\ExtraBar\\Images\\Gui.tga", "Interface\\Addons\\ExtraBar\\Images\\Gui.tga", 12, 12,
														EBCore.GetBarLock, EBCore.SetBarLock, num);
	gui:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -14, 0);
	
	local orient = ExtraBarConfigLib:CreateIconButton("ExtraBar"..num.."Orientation", bar, "Interface\\Addons\\ExtraBar\\Images\\Horizontal.tga", "Interface\\Addons\\ExtraBar\\Images\\Vertical.tga", 12, 12,
														EBCore.GetBarVertical, EBCore.SetBarVertical, num);
	orient:SetPoint("TOPRIGHT", gui, "TOPLEFT", -2, 0);

	local menu = ExtraBarConfigLib:CreateIcon("ExtraBar"..num.."Menu", bar, "Interface\\Addons\\ExtraBar\\Images\\Menu.tga", 12, 12);
	menu:SetPoint("TOPRIGHT", orient, "TOPLEFT", -2, 0);
	menu:EnableMouse(true);
	menu:SetScript("OnMouseUp", function () EBCore.OpenConfig(num); end);

	EBCore.RefreshBar(num);

	--Create the config pages	
	EBCore:InitBarConfig(bar, num);
	bar:SetClampRectInsets(14, -14, -14, 14);	--I've adjusted the border subsequently so these may be slightly off,
	bar:SetClampedToScreen(true);
end

function EBCore:InitBarConfig(bar, num)

	local page = ExtraBarConfigLib:CreateConfigPage("EBConfig"..num, UIParent, "Extra Bar "..num, "Configure Extra Bar "..num, "SecureActionButtonTemplate");


	local enabled = 	ExtraBarConfigLib:CreateCheckBox("EBConfig"..num.."BEnabled", page, "Enable Bar",
						"Enable bar "..num, true, EBCore.GetBarEnabled, EBCore.SetBarEnabled, num);
	local showGrid = 	ExtraBarConfigLib:CreateCheckBox("EBConfig"..num.."BShowGrid", page, "Always Show Grid",
						"Always display bar "..num.."'s grid", true, EBCore.GetBarShowGrid, EBCore.SetBarShowGrid, num);
	local lockButtons = ExtraBarConfigLib:CreateCheckBox("EBConfig"..num.."BLockButtons", page, "Lock Buttons",
						"Check this option to prevent\nactions being dragged from the bar\n(you will still be able to drop actions on the bar)", false, EBCore.GetBarLockButtons, EBCore.SetBarLockButtons, num);
	local lockBar = 	ExtraBarConfigLib:CreateCheckBox("EBConfig"..num.."BLockBar", page, "Lock Bar",
						"Locking the bar prevents it being moved and will hide its graphical controls", false, EBCore.GetBarLock, EBCore.SetBarLock, num);
	local hideV = 		ExtraBarConfigLib:CreateCheckBox("EBConfig"..num.."BHideV", page,
						"Hide on Enter Vehicle", "Check this option to hide the bar\nwhen the player enters a vehicle", true, EBCore.GetBarHideV, EBCore.SetBarHideV, num);
	local vert = 		ExtraBarConfigLib:CreateCheckBox("EBConfig"..num.."BVertical", page, "Vertical",
						"Lay the bar out vertically\nrather than horizontally", false, EBCore.GetBarVertical, EBCore.SetBarVertical, num);
	local tooltips = 	ExtraBarConfigLib:CreateCheckBox("EBConfig"..num.."BNoTooltips", page, "Disable Tooltips",
						"Check to disable tooltips\nfor buttons on this bar", false, EBCore.GetBarNoTooltips, EBCore.SetBarNoTooltips, num);
	local numButtons = 	ExtraBarConfigLib:CreateSlider("EBConfig"..num.."SNumber", page,
						"Number of Buttons", "Adjust the number of buttons\non the bar", 1, 12, 1, 12, EBCore.GetBarNumButtons, EBCore.SetBarNumButtons, num);
	local size = 		ExtraBarConfigLib:CreateSlider("EBConfig"..num.."SSize", page, "Button Size",
						"Adjust the button size", .1, 2, .05, 1, EBCore.GetBarSize, EBCore.SetBarSize, num);
	
	enabled:SetPoint("TOPLEFT", _G["EBConfig"..num.."Text"], "BOTTOMLEFT", 0, -8);
	showGrid:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 0, -8);
	hideV:SetPoint("TOPLEFT", showGrid, "BOTTOMLEFT", 0, -8);
	tooltips:SetPoint("TOPLEFT", hideV, "BOTTOMLEFT", 0, -8);

	lockButtons:SetPoint("TOPLEFT", _G["EBConfig"..num.."Text"], "BOTTOMLEFT", 224, -8);
	lockBar:SetPoint("TOPLEFT", lockButtons, "BOTTOMLEFT", 0, -8);
	vert:SetPoint("TOPLEFT", lockBar, "BOTTOMLEFT", 0, -8);

	numButtons:SetPoint("TOPLEFT", tooltips, "BOTTOMLEFT", 0, -24);
	size:SetPoint("TOPLEFT", numButtons, "BOTTOMLEFT", 0, -32);
	
	page.bar = bar;

	page.ShowBarNums = EBCore.ShowBarNums;
	page:SetAttribute("_onshow", [[control:CallMethod("ShowBarNums", 1);]]);
	page:SetAttribute("_onhide", [[control:CallMethod("ShowBarNums", 0);]]);
end

function EBCore.OpenConfig(num)
	if (InCombatLockdown()) then
		UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1.0, 0.1, 0.1, 1.0);
		return false;
	end
	InterfaceOptionsFrame_OpenToFrame("Extra Bar "..num);
end

function EBCore:ShowBarNums(value)
	ExtraBar1ConfigNumber:SetAlpha(value);
	ExtraBar2ConfigNumber:SetAlpha(value);
	ExtraBar3ConfigNumber:SetAlpha(value);
	ExtraBar4ConfigNumber:SetAlpha(value);
end


function EBCore.CalcSize(vertical, num)
	local sizeA = num * 42 + 26;
	
	if (vertical) then
		return 68, num * 42 + 26;
	else
		return num * 42 + 26, 68;
	end
end

function EBCore:OnUpdate()
	if (InCombatLockdown()) then
		self:StopMovingOrSizing(); self:SetResizable(false);
	end

end


function EBCore.OnSizeChangedNum(self, width, height)

	local vertical = ExtraBar_Config["EB"..self.number.."CfgVertical"];
	local numButtons = ExtraBar_Config["EB"..self.number.."CfgNumberOFButtons"];
	local bSize = numButtons * 42 + 26;
	local newNum;
	
	if (InCombatLockdown()) then
		width, height = EBCore.CalcSize(vertical, numButtons);
		--self:SetHeight(height);
		--self:SetWidth(width);
self:StopMovingOrSizing(); self:SetResizable(false);
		return false;
	end
	if (vertical) then
		width = 68;
		newNum = math.floor((height - 26) / 42 + .00001);
		if (newNum >= 12) then
			newNum = 12;
			height = 42 * 12 + 26;
		elseif (newNum < 1) then
			newNum = 1;
			height = 42 + 26;
		end
	else
		height = 68;
		newNum = math.floor((width - 26) / 42 + .00001);
		if (newNum >= 12) then
			newNum = 12;
			width = 42 * 12 + 26;
		elseif (newNum < 1) then
			newNum = 1;
			width = 42 + 26;
		end
	end
	
	if (newNum ~= numButtons) then
		EBCore.SetBarNumButtons(newNum, self.number);
	end
	self:SetHeight(height);		--Do this to override what the setbarnumbuttons function does so that we have a smooth gui during manipulation
	self:SetWidth(width);
	ExtraBar_Config["ExtraBar"..self.number.."Left"] = self:GetLeft();
	ExtraBar_Config["ExtraBar"..self.number.."Top"] = self:GetTop();
end

function EBCore.UpdateVisibilityStateDriver(num)
	if (InCombatLockdown()) then
		return false;
	end
	local bar = _G["ExtraBar"..num];
	if (not ExtraBar_Config["EB"..num.."CfgEnabled"]) then
		UnregisterStateDriver(bar, "visibility");
		bar:Hide();
	elseif (ExtraBar_Config["EB"..num.."CfgHideInVehicle"]) then
		UnregisterStateDriver(bar, "visibility");
		RegisterStateDriver(bar, "visibility", "[target=vehicle, exists] hide; show" );
	else
		UnregisterStateDriver(bar, "visibility");
		bar:Show();
	end
	
	return true;
end


function EBCore.RefreshBar(num)

	EBCore.SetBarEnabled(EBCore.GetBarEnabled(num), num);
	EBCore.SetBarShowGrid(EBCore.GetBarShowGrid(num), num);
	EBCore.SetBarLockButtons(EBCore.GetBarLockButtons(num), num);
	EBCore.SetBarLock(EBCore.GetBarLock(num), num);
	EBCore.SetBarHideV(EBCore.GetBarHideV(num), num);
	EBCore.SetBarVertical(EBCore.GetBarVertical(num), num);	
	EBCore.SetBarNoTooltips(EBCore.GetBarNoTooltips(num), num);
	EBCore.SetBarNumButtons(EBCore.GetBarNumButtons(num), num);
	EBCore.SetBarSize(EBCore.GetBarSize(num), num);

end

function EBCore.GetBarEnabled(num)
	return ExtraBar_Config["EB"..num.."CfgEnabled"];
end

function EBCore.SetBarEnabled(value, num)
	if (InCombatLockdown()) then
		return false;
	end
	ExtraBar_Config["EB"..num.."CfgEnabled"] = value;
	return EBCore.UpdateVisibilityStateDriver(num);
end


function EBCore.GetBarShowGrid(num)
	return ExtraBar_Config["EB"..num.."CfgAlwaysShowGrid"];
end

function EBCore.SetBarShowGrid(value, num)
	ExtraBar_Config["EB"..num.."CfgAlwaysShowGrid"] = value;
	
	local buttons = {_G["ExtraBar"..num]:GetChildren()};
	for i,v in ipairs(buttons) do
		if (v:GetObjectType() == "CheckButton") then
			ABTMethods_SetAlwaysShowGrid(v, value);
		end
	end
	return true;
end


function EBCore.GetBarLockButtons(num)
	return ExtraBar_Config["EB"..num.."CfgLockButtons"];
end

function EBCore.SetBarLockButtons(value, num)
	ExtraBar_Config["EB"..num.."CfgLockButtons"] = value;
	
	local buttons = {_G["ExtraBar"..num]:GetChildren()};
	for i,v in ipairs(buttons) do
		if (v:GetObjectType() == "CheckButton") then
			ABTMethods_SetLockButton(v, value);
		end
	end

	return true;
end



function EBCore.GetBarLock(num)
	return ExtraBar_Config["EB"..num.."CfgLockBar"];
end

function EBCore.SetBarLock(value, num)
	if (InCombatLockdown()) then
		return false;
	end
	ExtraBar_Config["EB"..num.."CfgLockBar"] = value;
	
	_G["ExtraBar"..num]:EnableMouse(not value);
	if (value) then
		_G["ExtraBar"..num.."AdjustNumber"]:Hide();
		_G["ExtraBar"..num.."Orientation"]:Hide();
		_G["ExtraBar"..num.."Menu"]:Hide();
		_G["ExtraBar"..num.."Lock"]:SetAlpha(.2);
		_G["ExtraBar"..num.."Number"]:SetAlpha(0);
		_G["ExtraBar"..num]:SetBackdropColor(0.1, 0.1, 0.3, 0);
	else
		_G["ExtraBar"..num.."AdjustNumber"]:Show();
		_G["ExtraBar"..num.."Orientation"]:Show();
		_G["ExtraBar"..num.."Menu"]:Show();
		_G["ExtraBar"..num.."Lock"]:SetAlpha(1);
		_G["ExtraBar"..num.."Number"]:SetAlpha(1);
		_G["ExtraBar"..num]:SetBackdropColor(0.1, 0.1, 0.3, 0.7);
	end
	_G["ExtraBar"..num.."Lock"]:Refresh();
	return true;
end



function EBCore.GetBarHideV(num)
	return ExtraBar_Config["EB"..num.."CfgHideInVehicle"];
end

function EBCore.SetBarHideV(value, num)
	if (InCombatLockdown()) then
		return false;
	end
	ExtraBar_Config["EB"..num.."CfgHideInVehicle"] = value;
	
	--process
	return EBCore.UpdateVisibilityStateDriver(num);
end



function EBCore.GetBarVertical(num)
	return ExtraBar_Config["EB"..num.."CfgVertical"];
end

function EBCore.SetBarVertical(value, num)
	if (InCombatLockdown()) then
		return false;
	end
	ExtraBar_Config["EB"..num.."CfgVertical"] = value;
	
	local bar = _G["ExtraBar"..num];
	local buttons ={bar:GetChildren()};
	local prev;
	local left = bar:GetLeft();
	local top = bar:GetTop();

	bar:ClearAllPoints();
	bar:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top);
	if (value) then
		bar:SetWidth(68);
		bar:SetHeight(ExtraBar_Config["EB"..num.."CfgNumberOFButtons"] * 42 + 26);
		_G[bar:GetName().."AdjustNumber"]:ClearAllPoints();
		_G[bar:GetName().."AdjustNumber"]:SetPoint("BOTTOM", bar, "BOTTOM", 0, -2);
		_G[bar:GetName().."AdjustNumber"]:SetState("bottom");
		
	else
		bar:SetHeight(68);
		bar:SetWidth(ExtraBar_Config["EB"..num.."CfgNumberOFButtons"] * 42 + 26);
		_G[bar:GetName().."AdjustNumber"]:ClearAllPoints();
		_G[bar:GetName().."AdjustNumber"]:SetPoint("RIGHT", bar, "RIGHT", 2, 0);
		_G[bar:GetName().."AdjustNumber"]:SetState("original");
	end

	for i,v in ipairs(buttons) do
		if (i ~= 1 and v:GetObjectType() == "CheckButton") then
			if (value) then
				v:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -6);
			else
				v:SetPoint("TOPLEFT", prev, "TOPRIGHT", 6, 0);
			end
		end
		prev = v;
	end
	
	_G["ExtraBar"..num.."Orientation"]:Refresh();
	ExtraBar_Config["ExtraBar"..num.."Left"] = bar:GetLeft();
	ExtraBar_Config["ExtraBar"..num.."Top"] = bar:GetTop();
	return true;
end



function EBCore.GetBarNoTooltips(num)
	return ExtraBar_Config["EB"..num.."CfgDisableTooltips"];
end

function EBCore.SetBarNoTooltips(value, num)
	ExtraBar_Config["EB"..num.."CfgDisableTooltips"] = value;
	
	local buttons = {_G["ExtraBar"..num]:GetChildren()};
	for i,v in ipairs(buttons) do
		if (v:GetObjectType() == "CheckButton") then
			ABTMethods_SetDisableTooltip(v, value);
		end
	end
	return true;
end



function EBCore.GetBarNumButtons(num)
	return ExtraBar_Config["EB"..num.."CfgNumberOFButtons"];
end

function EBCore.SetBarNumButtons(value, num)
	if (InCombatLockdown()) then
		return false;
	end
	ExtraBar_Config["EB"..num.."CfgNumberOFButtons"] = value;
	
	local bar = _G["ExtraBar"..num];
	local buttons ={bar:GetChildren()};
	for i,v in ipairs(buttons) do
		if (v:GetObjectType() == "CheckButton") then
			if (i <= value) then
				ABTMethods_SetEnabled(v, true);
			else
				ABTMethods_SetEnabled(v, false);
			end
		end
	end
	
	local left = bar:GetLeft();
	local top = bar:GetTop();
	
	bar:ClearAllPoints();
	bar:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top);
	if (ExtraBar_Config["EB"..num.."CfgVertical"]) then
		bar:SetWidth(68);
		bar:SetHeight(value * 42 + 26);
	else
		bar:SetHeight(68);
		bar:SetWidth(value * 42 + 26);
	end
	
	ExtraBar_Config["ExtraBar"..num.."Left"] = bar:GetLeft();
	ExtraBar_Config["ExtraBar"..num.."Top"] = bar:GetTop();
	return true;
end



function EBCore.GetBarSize(num)
	return ExtraBar_Config["EB"..num.."CfgSize"];
end

function EBCore.SetBarSize(value, num)
	if (InCombatLockdown()) then
		return false;
	end
	local bar = _G["ExtraBar"..num];
	local scale = ExtraBar_Config["EB"..num.."CfgSize"];
	local left = bar:GetLeft() * scale;
	local top = bar:GetTop() * scale;
	
	ExtraBar_Config["EB"..num.."CfgSize"] = value;

	bar:ClearAllPoints();
	bar:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left / value, top / value);
	bar:SetScale(value);
	ExtraBar_Config["ExtraBar"..num.."Left"] = bar:GetLeft();
	ExtraBar_Config["ExtraBar"..num.."Top"] = bar:GetTop();
	return true;
end









--[[This function will iteratively upgrade saved data from old versions to the current
it is also used to init data]]
function EBCore.UpdateSavedData()

	if (not ExtraBar_ButtonEntries) then
		ExtraBar_ButtonEntries = {};
		ExtraBar_ButtonSettings = {};
		ExtraBar_Config = {};
	end
	
	if (not ExtraBar_Config["version"] or ExtraBar_Config["version"]+0 < 0.6) then
		ExtraBar_Config = {};
		ExtraBar_Config["version"] = 0.6;
	end
	
	if (ExtraBar_Config["version"]+0 < 0.7) then
		ExtraBar_Config["version"] = 0.7;
		for num = 1, 4 do
			ExtraBar_Config["EB"..num.."CfgEnabled"] 		= EBCore.NVL(ExtraBar_Config["EB"..num.."CfgEnabled"], true);
			ExtraBar_Config["EB"..num.."CfgAlwaysShowGrid"] = EBCore.NVL(ExtraBar_Config["EB"..num.."CfgAlwaysShowGrid"], true);
			ExtraBar_Config["EB"..num.."CfgLockButtons"] 	= EBCore.NVL(ExtraBar_Config["EB"..num.."CfgLockButtons"], false);
			ExtraBar_Config["EB"..num.."CfgLockBar"] 		= EBCore.NVL(ExtraBar_Config["EB"..num.."CfgLockBar"], true);
			ExtraBar_Config["EB"..num.."CfgHideInVehicle"] 	= EBCore.NVL(ExtraBar_Config["EB"..num.."CfgHideInVehicle"], true);
			ExtraBar_Config["EB"..num.."CfgVertical"] 		= EBCore.NVL(ExtraBar_Config["EB"..num.."CfgVertical"], false);
			ExtraBar_Config["EB"..num.."CfgDisableTooltips"] = EBCore.NVL(ExtraBar_Config["EB"..num.."CfgDisableTooltips"], false);
			ExtraBar_Config["EB"..num.."CfgNumberOFButtons"] = EBCore.NVL(ExtraBar_Config["EB"..num.."CfgNumberOFButtons"], 12);
			ExtraBar_Config["EB"..num.."CfgSize"] 			= EBCore.NVL(ExtraBar_Config["EB"..num.."CfgSize"], 1);
		end
	end

	ExtraBar_ButtonEntries, ExtraBar_ButtonSettings = ABTMethods_UpdateSavedDataVersion(ExtraBar_ButtonEntries, ExtraBar_ButtonSettings);
end

function EBCore.NVL(v1, v2)
	if (type(v1) == "nil") then
		return v2;
	else
		return v1;
	end
end
