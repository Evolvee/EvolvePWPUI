local _G = getfenv(0);
local cfg = AzCastBar_Config;
local f = AzCastBarOptions;
ACBFactory = {};

local function ChangeSetting(var,value)
	cfg[f.activeBar.token][var] = value;
	AzCastBar_ApplyBarSettings(f.activeBar);
end

--------------------------------------------------------------------------------------------------------
--                                            Slider Frame                                            --
--------------------------------------------------------------------------------------------------------

-- EditBox Enter Pressed
local function SliderEdit_OnEnterPressed(self)
	self:GetParent().slider:SetValue(self:GetNumber());
end

-- Slider Value Changed
local function Slider_OnValueChanged(self)
	if (not AzCastBarOptions.updatingOptions) then
		self:GetParent().edit:SetNumber(self:GetValue());
		ChangeSetting(self:GetParent().option.var,self:GetValue());
	end
end

-- OnMouseWheel
local function Slider_OnMouseWheel(self)
	self:SetValue(self:GetValue() + self:GetParent().option.step * arg1);
end

-- New Slider
ACBFactory.Slider = function(index)
	local f = CreateFrame("Frame",nil,AzCastBarOptions);
	f:SetWidth(292);
	f:SetHeight(32);

	f.edit = CreateFrame("EditBox","AzCastBarOptionsEdit"..index,f,"InputBoxTemplate");
	f.edit:SetWidth(45);
	f.edit:SetHeight(21);
	f.edit:SetPoint("BOTTOMLEFT");
	f.edit:SetScript("OnEnterPressed",SliderEdit_OnEnterPressed);
	f.edit:SetAutoFocus(nil);
	f.edit:SetMaxLetters(4);

	f.slider = CreateFrame("Slider","AzCastBarOptionsSlider"..index,f,"OptionsSliderTemplate");
	f.slider:SetPoint("TOPLEFT",f.edit,"TOPRIGHT",5,-3);
	f.slider:SetPoint("BOTTOMRIGHT",0,-2);
	f.slider:SetScript("OnValueChanged",Slider_OnValueChanged);
	f.slider:SetScript("OnMouseWheel",Slider_OnMouseWheel);
	f.slider:EnableMouseWheel(1);

	f.text = _G["AzCastBarOptionsSlider"..index.."Text"];
	f.low = _G["AzCastBarOptionsSlider"..index.."Low"];
	f.low:ClearAllPoints();
	f.low:SetPoint("BOTTOMLEFT",f.slider,"TOPLEFT",0,0);
	f.high = _G["AzCastBarOptionsSlider"..index.."High"];
	f.high:ClearAllPoints();
	f.high:SetPoint("BOTTOMRIGHT",f.slider,"TOPRIGHT",0,0);

	return f;
end

--------------------------------------------------------------------------------------------------------
--                                           Check Buttons                                            --
--------------------------------------------------------------------------------------------------------

local function CheckButton_OnEnter(self)
	self.text:SetTextColor(1,1,1);
	if (self.option.tip) then
		GameTooltip:SetOwner(self,"ANCHOR_RIGHT");
		GameTooltip:SetText(self.option.tip,nil,nil,nil,nil,1);
	end
end

local function CheckButton_OnLeave(self)
	self.text:SetTextColor(1,0.82,0);
	GameTooltip:Hide();
end

local function CheckButton_OnClick(self)
	ChangeSetting(self.option.var,self:GetChecked() == 1);
end

-- New CheckButton
ACBFactory.Check = function(index)
	local f = CreateFrame("CheckButton","AzCastBarCheckButton"..index,AzCastBarOptions,"OptionsCheckButtonTemplate");
	f:SetWidth(26);
	f:SetHeight(26);
	f:SetScript("OnEnter",CheckButton_OnEnter);
	f:SetScript("OnClick",CheckButton_OnClick);
	f:SetScript("OnLeave",CheckButton_OnLeave);

	f.text = _G["AzCastBarCheckButton"..index.."Text"];

	return f;
end

--------------------------------------------------------------------------------------------------------
--                                           Color Buttons                                            --
--------------------------------------------------------------------------------------------------------

-- Color Picker Function
local function ColorButton_ColorPickerFunc(prevVal,...)
	local r, g, b, a;
	if (prevVal) then
		r, g, b, a  = unpack(prevVal);
	else
		r, g, b = ColorPickerFrame:GetColorRGB();
		a = (1 - OpacitySliderFrame:GetValue());
	end
	ColorPickerFrame.frame.texture:SetVertexColor(r,g,b,a);
	if (ColorPickerFrame.frame.option.subType == 2) then
		ChangeSetting(ColorPickerFrame.frame.option.var,format("|c%.2x%.2x%.2x%.2x",a * 255,r * 255,g * 255,b * 255));
	else
		ChangeSetting(ColorPickerFrame.frame.option.var,{ r, g, b, a });
	end
end

-- OnClick
local function ColorButton_OnClick(self,button)
	local r, g, b, a;
	if (self.option.subType == 2) then
		r, g, b, a = AzCastBarOptions:HexStringToRGBA(cfg[f.activeBar.token][self.option.var]);
	else
		r, g, b, a = unpack(cfg[f.activeBar.token][self.option.var]);
	end

	ColorPickerFrame.frame = self;
	ColorPickerFrame.func = ColorButton_ColorPickerFunc;
	ColorPickerFrame.cancelFunc = ColorButton_ColorPickerFunc;
	ColorPickerFrame.opacityFunc = ColorButton_ColorPickerFunc;
	ColorPickerFrame.hasOpacity = true;
	ColorPickerFrame.opacity = (1 - a);
	ColorPickerFrame.previousValues = { r, g, b, a };

	OpacitySliderFrame:SetValue(1 - a);
	ColorPickerFrame:SetColorRGB(r,g,b);
	ColorPickerFrame:Show();
end

-- OnEnter
local function ColorButton_OnEnter(self)
	self.text:SetTextColor(1,1,1);
	self.border:SetVertexColor(1,1,0);
	if (self.option.tip) then
		GameTooltip:SetOwner(self,"ANCHOR_RIGHT");
		GameTooltip:SetText(self.option.tip,nil,nil,nil,nil,1);
	end
end

-- OnLeave
local function ColorButton_OnLeave(self)
	self.text:SetTextColor(1,0.82,0);
	self.border:SetVertexColor(1,1,1);
	GameTooltip:Hide();
end

-- New ColorButton
ACBFactory.Color = function(index)
	local f = CreateFrame("Button",nil,AzCastBarOptions);
	f:SetWidth(18);
	f:SetHeight(18);
	f:SetScript("OnEnter",ColorButton_OnEnter);
	f:SetScript("OnLeave",ColorButton_OnLeave)
	f:SetScript("OnClick",ColorButton_OnClick);

	f.texture = f:CreateTexture();
	f.texture:SetPoint("TOPLEFT",-1,1);
	f.texture:SetPoint("BOTTOMRIGHT",1,-1);
	f.texture:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch");
	f:SetNormalTexture(f.texture);

	f.border = f:CreateTexture(nil,"BACKGROUND");
	f.border:SetPoint("TOPLEFT");
	f.border:SetPoint("BOTTOMRIGHT");
	f.border:SetTexture(1,1,1,1);

	f.text = f:CreateFontString(nil,"ARTWORK","GameFontNormal");
	f.text:SetPoint("LEFT",f,"RIGHT",4,1);

	return f;
end

--------------------------------------------------------------------------------------------------------
--                                           DropDown Frame                                           --
--------------------------------------------------------------------------------------------------------

local menu;
local DropDown_MaxItems = 10;
local DropDown_ItemHeight = 16;

-- Item OnClick
local function DropDown_MenuItem_OnClick(self,button)
	local dropDown = menu.dropDown;
	local table = menu.list[self.index];
	dropDown.label:SetText(table.text);
	dropDown.SelectedValue = table.value;
	if (dropDown.SelectValueFunc) then
		dropDown.SelectValueFunc(dropDown,table);
	end
	menu:Hide();
end

-- MakeItem
local function DropDown_MakeItem()
	local item = CreateFrame("Button",nil,menu);
	item:SetHeight(DropDown_ItemHeight);
	item:SetHitRectInsets(-12,-10,0,0);
	item:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");
	item:SetScript("OnClick",DropDown_MenuItem_OnClick);

	item.text = item:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall");
	item.text:SetPoint("LEFT",2,0);

	if (#menu.items == 0) then
		item:SetPoint("TOPLEFT",20,-8);
	else
		item:SetPoint("TOPLEFT",menu.items[#menu.items],"BOTTOMLEFT");
		item:SetPoint("TOPRIGHT",menu.items[#menu.items],"BOTTOMRIGHT");
	end

	tinsert(menu.items,item);
	return item;
end

-- Update
local function DropDown_UpdateList()
	FauxScrollFrame_Update(menu.scroll,#menu.list,DropDown_MaxItems,DropDown_ItemHeight);
	menu.check:Hide();
	local index, item;
	-- Loop
	for i = 1, DropDown_MaxItems do
		index = (FauxScrollFrame_GetOffset(menu.scroll) + i);
		item = menu.items[i] or DropDown_MakeItem();
		if (index <= #menu.list) then
			item.text:SetText(menu.list[index].text);
			item.index = index;
			if (menu.list[index].value == menu.dropDown.SelectedValue) then
				menu.check:ClearAllPoints();
				menu.check:SetPoint("RIGHT",item,"LEFT");
				menu.check:Show();
			end
			item:Show();
		else
			item:Hide();
		end
	end
end

-- Create
local function DropDown_CreateMenu()
	menu = CreateFrame("Frame",nil,AzCastBarOptions);
	menu:SetBackdrop(AzCastBarOptions:GetBackdrop());
	menu:SetBackdropColor(0.1,0.1,0.1,1);
	menu:SetBackdropBorderColor(0.4,0.4,0.4,1);
	menu:SetToplevel(1);
	menu:SetClampedToScreen(1);
	menu:SetFrameStrata("FULLSCREEN_DIALOG");
	menu:Hide();

	menu.check = menu:CreateTexture(nil,"ARTWORK");
	menu.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check");
	menu.check:SetWidth(14);
	menu.check:SetHeight(14);

	menu.text = menu:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall");
	menu.text:Hide();

	menu.scroll = CreateFrame("ScrollFrame","AzCastBarOptionsDropDownScroll",menu,"FauxScrollFrameTemplate");
	menu.scroll:SetScript("OnVerticalScroll",function() FauxScrollFrame_OnVerticalScroll(DropDown_ItemHeight,DropDown_UpdateList); end);

	menu.items = {};
	menu.list = {};
end

-- Init
local function DropDown_InitList(parent)
	if (not menu) then
		DropDown_CreateMenu();
	end

	for n in pairs(menu.list) do
		menu.list[n] = nil;
	end

	if (parent.InitFunc) then
		parent.InitFunc(parent,menu.list);
	end

	menu.dropDown = parent;
	DropDown_UpdateList();

	menu:SetParent(parent);

	menu:ClearAllPoints();
	menu:SetPoint("TOPRIGHT",parent,"BOTTOMRIGHT");

	menu.scroll:ClearAllPoints();
	menu.scroll:SetPoint("TOPLEFT",menu.items[1]);
	menu.scroll:SetPoint("BOTTOMRIGHT",menu.items[min(#menu.list,DropDown_MaxItems)]);

	local maxItemWidth = 0;
	for _, table in ipairs(menu.list) do
		menu.text:SetText(table.text);
		maxItemWidth = max(maxItemWidth,menu.text:GetWidth() + 10);
	end
	if (#menu.list > DropDown_MaxItems) then
		maxItemWidth = (maxItemWidth + 12);
		menu.items[1]:SetPoint("TOPRIGHT",-28,-8);
	else
		menu.items[1]:SetPoint("TOPRIGHT",-16,-8);
	end

	menu:SetWidth(maxItemWidth + 38);
	menu:SetHeight(min(#menu.list,DropDown_MaxItems) * DropDown_ItemHeight + 16);
	menu:Hide();
end

-- OnClick
local function DropDown_OnClick(self,button)
	PlaySound("igMainMenuOptionCheckBoxOn");
	if (menu) and (menu:IsShown()) and (menu.dropDown == self:GetParent()) then
		menu:Hide();
	else
		DropDown_InitList(self:GetParent());
		menu:Show();
	end
end

-- Init Selected
ACBFactory.DropDown_InitSelected = function(dropDown,selectedValue)
	DropDown_InitList(dropDown);
	if (selectedValue) then
		dropDown.SelectedValue = selectedValue;
	end
	for _, table in ipairs(menu.list) do
		if (table.value == dropDown.SelectedValue) then
			dropDown.label:SetText(table.text);
			return;
		end
	end
	dropDown.label:SetText("|cff00ff00Select Value...");
end

-- New DropDown
ACBFactory.DropDown = function(index)
	local f = CreateFrame("Frame",nil,AzCastBarOptions);
	f:SetWidth(180);
	f:SetHeight(24);
	f:SetBackdrop(AzCastBarOptions:GetBackdrop());
	f:SetBackdropColor(0.1,0.1,0.1,1);
	f:SetBackdropBorderColor(0.4,0.4,0.4,1);

	f.button = CreateFrame("Button",nil,f);
	f.button:SetPoint("TOPRIGHT");
	f.button:SetPoint("BOTTOMRIGHT");
	f.button:SetWidth(24);
	f.button:SetHitRectInsets(-156,0,0,0);

	f.button:SetScript("OnClick",DropDown_OnClick);

	f.button:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up");
	f.button:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down");
	f.button:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled");
	f.button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");

	f.text = f:CreateFontString(nil,"ARTWORK","GameFontNormalSmall");
	f.text:SetPoint("LEFT",-302 + f:GetWidth(),0);

	f.label = f:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall");
	f.label:SetPoint("RIGHT",f.button,"LEFT",-2,0);
	f.label:SetText("Option");

	return f;
end