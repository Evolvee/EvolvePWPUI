--[[
Author: Massiner of Nathrezim
Date: 20-May-2009

Notes:
- The local ConfigLib stores all the functions to be externally exposed
- A global table is set to be the same as ConfigLib so that it can be used outside of this file
- Most functions in here use : both for declaration and for calling, this facilitates further setup such as calling ConfigLib functions inside here (actually not certain what the scope rules are on this but better safe than sorry)
- Functions that are intended to execute for created frames are setup in a seperate table simply to help keep things tidy
- Objects created here only rely on Blizzard Templates or Lua code, no new xml templates are generated to avoid putting them into the global namespace (particularly because this file will accompany mods I release)
- I'm avoiding inline functions... (I don't really understand how they are handled and they seem to have strange scope characteristics)
]]

local ConfigLib = {};
local ConfigPage = {};
local Icon = {};
local IconButton = {};
local CheckBox = {};
local Slider = {};

ExtraBarConfigLib = ConfigLib;


--[[
Creates a config page and associates it in the interfaceoptions menu
]]
function ConfigLib:CreateConfigPage(name, parent, title, text, inherits)
	local page = CreateFrame("Frame", name, parent, inherits);
	local pageTitle = page:CreateFontString(name.."Title", "ARTWORK", "GameFontNormalLarge");
	local pageText = page:CreateFontString(name.."Text", "ARTWORK", "GameFontHighlightSmall");

	pageTitle:SetPoint("TOPLEFT", page, "TOPLEFT", 16, -16);
	pageText:SetPoint("TOPLEFT", pageTitle, "BOTTOMLEFT", 0, -8);

	page.name = title;
	pageTitle:SetText(title);
	pageText:SetText(text);
	
	--page.okay = ConfigPage.Okay;	--This is not needed since changes are instantly accepted
	page.cancel = ConfigPage.Cancel;
	page.default = ConfigPage.Default;
	
	InterfaceOptions_AddCategory(page);
	
	return page;
end

function ConfigPage:Cancel()
	--If cancel values are available attempt to revert to them (cancel values only last while the configpage is still in view, flicking to another and back
	-- performs as an implicit ok... this should actually suffice and is simple to achieve)
	local controls = {self:GetChildren()};
	for i,v in ipairs(controls) do
		local objectType = v:GetObjectType();
		if (objectType == "CheckButton") then
		
		elseif (objectType == "Slider") then
			v:SetValue(v.cancelValue);
			v:OnValueChanged();
		end
	end
end

function ConfigPage:Default()
	local controls = {self:GetChildren()};
	for i,v in ipairs(controls) do
		local objectType = v:GetObjectType();
		if (objectType == "CheckButton") then
		
		elseif (objectType == "Slider") then
			v:SetValue(v.default);
			v:OnValueChanged();
		end
	end
end






function ConfigLib:CreateIcon(name, parent, texture, width, height)
	local icon = CreateFrame("Frame", name, parent);
	
	local iconTexture = icon:CreateTexture(name.."Icon");
	iconTexture:SetPoint("TOPLEFT", icon, "TOPLEFT");
	icon.sets = {};
	icon.AddState = Icon.AddState;
	icon.SetState = Icon.SetState;
	icon:AddState("original", texture, width, height);
	icon:SetState("original");
	return icon;

end

function Icon:AddState(name, texture, width, height)
	self.sets[name] = {["texture"] = texture, ["width"] = width, ["height"] = height};
end

function Icon:SetState(name)
	local icon = _G[self:GetName().."Icon"];
	local width = self.sets[name]["width"];
	local height = self.sets[name]["height"];
	local texture = self.sets[name]["texture"];
	
	self:SetWidth(width);
	self:SetHeight(height);
	icon:SetWidth(width);
	icon:SetHeight(height);
	icon:SetTexture(texture);
end






--[[
Creates a toggle icon button, that will call the passed function.
Note: The toggling can be blocked by the function not returning true
]]
function ConfigLib:CreateIconButton(name, parent, offTexture, onTexture, width, height, GetFunc, SetFunc, ...)
	local button = CreateFrame("Button", name, parent);
	
	button.offTexture = offTexture;
	button.onTexture = onTexture;

	button.GetFunc = GetFunc;
	button.SetFunc = SetFunc;
	button.funcParams = {...};
	button.Refresh = IconButton.Refresh;
	button:SetWidth(width);
	button:SetHeight(height);		

	button.OnClick = IconButton.OnClick;
	button:SetScript("OnClick", button.OnClick);
	button:RegisterForClicks("AnyUp");
	
	button:Refresh();
	
	return button;
end

function IconButton:OnClick()
	self.value = not self.value;
	--call the function, reverse if fail
	if (not self.SetFunc(self.value, unpack(self.funcParams))) then
		self.value = self.GetFunc(unpack(self.funcParams));
	end
	--otherwise update the texture
	if (self.value) then
		self:SetNormalTexture(self.onTexture);
	else
		self:SetNormalTexture(self.offTexture);
	end
end

function IconButton:Refresh()
	self.value = self.GetFunc(unpack(self.funcParams));
	if (self.value) then
		self:SetNormalTexture(self.onTexture);
	else
		self:SetNormalTexture(self.offTexture);
	end
end






function ConfigLib:CreateSecureIconButton(name, parent, texture, width, height, onClick)
	local button = CreateFrame("Button", name, parent, "SecureHandlerClickTemplate");
	
	button:SetWidth(width);
	button:SetHeight(height);
	button:RegisterForClicks("AnyUp");
	button:SetNormalTexture(texture);
	button:SetAttribute("_onclick", onClick);
	return button;
end




function ConfigLib:CreateCheckBox(name, parent, title, tooltip, default, GetFunc, SetFunc, ...)
	--Prepare the Slider and its value component
	local button = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate");
	
	_G[name.."Text"]:SetText(title);
	
	button.SetFunc = SetFunc;				--The function to excute when a value changes
	button.GetFunc = GetFunc;
	button.funcParams = {...};
	button.default = default;

	button.OnClick = CheckBox.OnClick;
	button.OnShow = CheckBox.OnShow;
	button.tooltipText = tooltip;
	button:SetScript("OnClick", button.OnClick);
	--button:SetScript("OnEnter", function() GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(tooltip); GameTooltip:Show(); end);
	--button:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	button:SetScript("OnShow", button.OnShow);
	button:Show();
	return button;
end

function CheckBox:OnClick()
	if (self:GetChecked()) then
		PlaySound("igMainMenuOptionCheckBoxOn");
	else
		PlaySound("igMainMenuOptionCheckBoxOff");
	end
	self.SetFunc(self:GetChecked(), unpack(self.funcParams));
	self:SetChecked(self.GetFunc(unpack(self.funcParams)));	--Make sure that the control continues to represent the correct val
end

function CheckBox:OnShow()
	self.cancelValue = self.GetFunc(unpack(self.funcParams));
	self:SetChecked(self.cancelValue);
end







--[[
Creates a Slider for use in config screens
Note: Although we could manage the storage of the setting from our passed func, it is better to do it here since
managing cancel commands and the default command can be automated
]]
function ConfigLib:CreateSlider(name, parent, title, tooltip, minv, maxv, step, default, GetFunc, SetFunc, ...)

	--Prepare the Slider and its value component
	local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate");
	local subText = slider:CreateFontString(name.."Value", "ARTWORK", "GameFontHighlight");
	subText:SetPoint("CENTER", slider, "CENTER", 0, -12);
	
	_G[name.."Text"]:SetText(title);
	_G[name.."Low"]:SetText(minv);
	_G[name.."High"]:SetText(maxv);
	slider.SetFunc = SetFunc;				--The function to excute when a value changes
	slider.GetFunc = GetFunc;
	slider.funcParams = {...};
	slider.default = default;

	slider:SetValueStep(step);
	slider:SetMinMaxValues(minv, maxv);

	slider.OnValueChanged = Slider.OnValueChanged;
	slider.OnShow = Slider.OnShow;
	slider.tooltipText = tooltip;
	--I have a feeling these functions would be better as standalone!
	slider:SetScript("OnValueChanged", slider.OnValueChanged);
	--slider:SetScript("OnEnter", function() GameTooltip:SetOwner(slider, "ANCHOR_RIGHT"); GameTooltip:SetText(tooltip); GameTooltip:Show(); end);
	--slider:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	slider:SetScript("OnShow", 	slider.OnShow);
	return slider;
end

function Slider:OnValueChanged()
	local name = self:GetName();

	self.SetFunc(self:GetValue(), unpack(self.funcParams));
	self:SetValue(self.GetFunc(unpack(self.funcParams)));	--Make sure that the control continues to represent the correct val
	_G[name.."Value"]:SetText(ConfigLib.round(self:GetValue(), 5));
end

function Slider:OnShow()
	self.cancelValue = self.GetFunc(unpack(self.funcParams));
	self:SetValue(self.cancelValue);
	_G[self:GetName().."Value"]:SetText(ConfigLib.round(self.cancelValue, 5)); 
end




--[[From Lua-users.org]]
function ConfigLib.round(num, idp)
  local mult = 10^(idp or 0);
  return math.floor(num * mult + 0.5) / mult;
end
