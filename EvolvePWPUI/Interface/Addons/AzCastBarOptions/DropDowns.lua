AzCastBarDropDowns = {};

local cfg = AzCastBar_Config;
local info = {};

-- Shared Media
local SML = LibStub and LibStub("LibSharedMedia-2.0",1) or nil;

-- DropDown Lists
AzCastBarDropDowns.FontFlags = {
	["None"] = "",
	["Outline"] = "OUTLINE",
	["Thick Outline"] = "THICKOUTLINE",
};

--------------------------------------------------------------------------------------------------------
--                                        Default DropDown Init                                       --
--------------------------------------------------------------------------------------------------------

local function Default_SelectValue(dropDown,table)
	cfg[AzCastBarOptions.activeBar.token][dropDown.option.var] = table.value;
	AzCastBar_ApplyBarSettings(AzCastBarOptions.activeBar);
end

function AzCastBarDropDowns.Default(dropDown,table)
	dropDown.SelectValueFunc = Default_SelectValue;
	for text, option in pairs(dropDown.option.list) do
		tinsert(table,{ text = text, value = option });
	end
end

--------------------------------------------------------------------------------------------------------
--                                          Shared Media Lib                                          --
--------------------------------------------------------------------------------------------------------

local SharedMediaLibSubstitute = not SML and {
	["font"] = {
		["Friz Quadrata TT"] = "Fonts\\FRIZQT__.TTF",
		["Arial Narrow"] = "Fonts\\ARIALN.TTF",
		["Skurri"] = "Fonts\\SKURRI.TTF",
		["Morpheus"] = "Fonts\\MORPHEUS.TTF",
	},
	["background"] = {
		["Blizzard Tooltip"] = "Interface\\Tooltips\\UI-Tooltip-Background",
		["Solid"] = "Interface\\ChatFrame\\ChatFrameBackground",
	},
	["border"] = {
		["None"] = "Interface\\None",
		["Blizzard Dialog"]  = "Interface\\DialogFrame\\UI-DialogBox-Border",
		["Blizzard Tooltip"] = "Interface\\Tooltips\\UI-Tooltip-Border",
	},
	["statusbar"] = {
		["Blizzard StatusBar"] = "Interface\\TargetingFrame\\UI-StatusBar",
	},
} or nil;


do
	local AZCB_Textures = {
		--"Interface\\Addons\\AzCastBar\\Textures\\test",
		"Interface\\Addons\\AzCastBar\\Textures\\HorizontalFade",
		"Interface\\Addons\\AzCastBar\\Textures\\Pale",
		"Interface\\Addons\\AzCastBar\\Textures\\Melli",
		"Interface\\Addons\\AzCastBar\\Textures\\test",
		"Interface\\Addons\\AzCastBar\\Textures\\Lines",
		"Interface\\Addons\\AzCastBar\\Textures\\SmoothBar",
		"Interface\\Addons\\AzCastBar\\Textures\\Streamline",
		"Interface\\Addons\\AzCastBar\\Textures\\Streamline-Inverted",
		"Interface\\Addons\\AzCastBar\\Textures\\Waterline",
	};
	local textureName;
	for _, texture in ipairs(AZCB_Textures) do
		textureName = texture:match("\\([^\\]+)$");
		if (SML) then
			SML:Register("statusbar","|cffffff00"..textureName,texture);
		else
			SharedMediaLibSubstitute["statusbar"][textureName] = texture;
		end
	end
end

function AzCastBarDropDowns.SharedMediaLib(dropDown,table)
	local query = dropDown.option.media;
	dropDown.SelectValueFunc = Default_SelectValue;
	if (SML) then
		for _, name in pairs(SML:List(query)) do
			tinsert(table,{ text = name, value = SML:Fetch(query,name) });
		end
	else
		for name, value in pairs(SharedMediaLibSubstitute[query]) do
			tinsert(table,{ text = name, value = value });
		end
	end
end