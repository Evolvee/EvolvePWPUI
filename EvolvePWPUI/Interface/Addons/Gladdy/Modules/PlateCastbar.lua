local AddOn = "PlateCastBar"
local Gladdy = LibStub("Gladdy")
local WorldFrame = WorldFrame
local select = select
local pairs = pairs

-- TODO: this needs channeling spells again
local Table = {
	["Nameplates"] = {},
	["CheckButtons"] = {
		["Test"] = {
			["PointX"] = 170,
			["PointY"] = -10,
		},
		["Player Pet"] = {
			["PointX"] = 300,
			["PointY"] = -90,
		},
		["Icon"] = {
			["PointX"] = 300,
			["PointY"] = -120,
		},
		["Timer"] = {
			["PointX"] = 300,
			["PointY"] = -150,
		},
		["Spell"] = {
			["PointX"] = 300,
			["PointY"] = -180,
		},
	},
}
local Textures = {
	Font = "Interface\\AddOns\\Gladdy\\Images\\DorisPP.ttf",
	CastBar = "Interface\\AddOns\\Gladdy\\Images\\LiteStep.tga",
}
_G[AddOn .. "_SavedVariables"] = {
	["CastBar"] = {
		["Width"] = 105,
		["PointX"] = 15,
		["PointY"] = -5,
	},
	["Icon"] = {
		["PointX"] = -62,
		["PointY"] = 0,
	},
	["Timer"] = {
		["Anchor"] = "RIGHT",
		["PointX"] = 52,
		["PointY"] = 0,
		["Format"] = "LEFT"
	},
	["Spell"] = {
		["Anchor"] = "LEFT",
		["PointX"] = -53,
		["PointY"] = 0,
	},
	["Enable"] = {
		["Test"] = false,
		["Player Pet"] = true,
		["Icon"] = true,
		["Timer"] = true,
		["Spell"] = true,
	},
}

local unitsToCheck = {
	["mouseover"] = true,
	["mouseovertarget"] = true,
	["mouseovertargettarget"] = true,
	["target"] = true,
	["targettarget"] = true,
	["targettargettarget"] = true,
	["focus"] = true,
	["focustargettarget"] = true,
	["focustarget"] = true,
	["pet"] = true,
	["pettarget"] = true,
	["pettargettarget"] = true,
	["party1"] = true,
	["party2"] = true,
	["party3"] = true,
	["party4"] = true,
	["party1target"] = true,
	["party2target"] = true,
	["party3target"] = true,
	["party4target"] = true,
	["partypet1target"] = true,
	["partypet2target"] = true,
	["partypet3target"] = true,
	["partypet4target"] = true,
	["party1targettarget"] = true,
	["party2targettarget"] = true,
	["party3targettarget"] = true,
	["party4targettarget"] = true,
	["raid1"] = true,
	["raid2"] = true,
	["raid3"] = true,
	["raid4"] = true,
	["raid1target"] = true,
	["raid2target"] = true,
	["raid3target"] = true,
	["raid4target"] = true,
	["raidpet1target"] = true,
	["raidpet2target"] = true,
	["raidpet3target"] = true,
	["raidpet4target"] = true,
	["raid1targettarget"] = true,
	["raid2targettarget"] = true,
	["raid3targettarget"] = true,
	["raid4targettarget"] = true,
}

local Frame = CreateFrame("Frame")
Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
local function Frame_RegisterEvents()
	Frame:RegisterEvent("UNIT_SPELLCAST_START")
	Frame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
	Frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	Frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
	Frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	Frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
	Frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	Frame:RegisterEvent("PLAYER_TARGET_CHANGED")
	Frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
end

local function UnitCastBar_Create(unit)
	_G[AddOn .. "_Frame_" .. unit .. "CastBar"] = CreateFrame("Frame",nil);
	local CastBar = _G[AddOn .. "_Frame_" .. unit .. "CastBar"]
	CastBar:SetFrameStrata("BACKGROUND");
	CastBar:SetWidth(_G[AddOn .. "_SavedVariables"]["CastBar"]["Width"]);
	CastBar:SetHeight(11);
	CastBar:SetPoint("CENTER");
	CastBar:Hide();

	_G[AddOn .. "_Texture_" .. unit .. "CastBar_CastBar"] = CastBar:CreateTexture(nil,"ARTWORK");
	local Texture = _G[AddOn .. "_Texture_" .. unit .. "CastBar_CastBar"]
	Texture:SetHeight(11);
	Texture:SetTexture(Textures.CastBar);
	Texture:SetPoint("CENTER",AddOn .. "_Frame_" .. unit .. "CastBar","CENTER");

	_G[AddOn .. "_Texture_" .. unit .. "CastBar_Icon"] = CastBar:CreateTexture(nil,"ARTWORK");
	local Icon = _G[AddOn .. "_Texture_" .. unit .. "CastBar_Icon"]
	Icon:SetHeight(13);
	Icon:SetWidth(13);
	Icon:SetPoint("CENTER",AddOn .. "_Frame_" .. unit .. "CastBar","CENTER",
		_G[AddOn .. "_SavedVariables"]["Icon"]["PointX"],
		_G[AddOn .. "_SavedVariables"]["Icon"]["PointY"]);
	if ( _G[AddOn .. "_SavedVariables"]["Enable"]["Icon"] ) then
		Icon:Show()
	else
		Icon:Hide()
	end

	_G[AddOn .. "_Texture_" .. unit .. "CastBar_IconBorder"] = CastBar:CreateTexture(nil,"BACKGROUND");
	local IconBorder = _G[AddOn .. "_Texture_" .. unit .. "CastBar_IconBorder"]
	IconBorder:SetHeight(16);
	IconBorder:SetWidth(16);
	IconBorder:SetPoint("CENTER",Icon,"CENTER");
	if ( _G[AddOn .. "_SavedVariables"]["Enable"]["Icon"] ) then
		IconBorder:Show()
	else
		IconBorder:Hide()
	end

	_G[AddOn .. "_FontString_" .. unit .. "CastBar_SpellName"] = CastBar:CreateFontString(nil)
	local SpellName = _G[AddOn .. "_FontString_" .. unit .. "CastBar_SpellName"]
	SpellName:SetFont(Textures.Font,9,"OUTLINE")
	SpellName:SetPoint(_G[AddOn .. "_SavedVariables"]["Spell"]["Anchor"],
		AddOn .. "_Frame_" .. unit .. "CastBar","CENTER",
		_G[AddOn .. "_SavedVariables"]["Spell"]["PointX"],
		_G[AddOn .. "_SavedVariables"]["Spell"]["PointY"]);
	if ( _G[AddOn .. "_SavedVariables"]["Enable"]["Spell"] ) then
		SpellName:Show()
	else
		SpellName:Hide()
	end

	_G[AddOn .. "_FontString_" .. unit .. "CastBar_CastTime"] = CastBar:CreateFontString(nil)
	local CastTime = _G[AddOn .. "_FontString_" .. unit .. "CastBar_CastTime"]
	CastTime:SetFont(Textures.Font,9,"OUTLINE")
	CastTime:SetPoint(_G[AddOn .. "_SavedVariables"]["Timer"]["Anchor"],
		AddOn .. "_Frame_" .. unit .. "CastBar","CENTER",
		_G[AddOn .. "_SavedVariables"]["Timer"]["PointX"],
		_G[AddOn .. "_SavedVariables"]["Timer"]["PointY"]);
	if ( _G[AddOn .. "_SavedVariables"]["Enable"]["Timer"] ) then
		CastTime:Show()
	else
		CastTime:Hide()
	end

	_G[AddOn .. "_Texture_" .. unit .. "CastBar_Border"] = CastBar:CreateTexture(nil,"BACKGROUND");
	local Border =_G[AddOn .. "_Texture_" .. unit .. "CastBar_Border"]
	Border:SetPoint("CENTER",AddOn .. "_Frame_" .. unit .. "CastBar","CENTER");
	Border:SetWidth(_G[AddOn .. "_SavedVariables"]["CastBar"]["Width"]+5);
	Border:SetHeight(16);

	local Background = CastBar:CreateTexture(nil,"BORDER");
	Background:SetTexture(1/10, 1/10, 1/10, 1);
	Background:SetAllPoints(AddOn .. "_Frame_" .. unit .. "CastBar");
end

local function CastBars_Create()
	for k,v in pairs(unitsToCheck) do
		UnitCastBar_Create(k)
	end
end

local function keepCastbar(unit, elapsed)

	local Texture = _G[AddOn .. "_Texture_" .. unit .. "CastBar_CastBar"]
	local CastTime = _G[AddOn .. "_FontString_" .. unit .. "CastBar_CastTime"]
	local CastBar = _G[AddOn .. "_Frame_" .. unit .. "CastBar"]
	local Border = _G[AddOn .. "_Texture_" .. unit .. "CastBar_Border"]
	local IconBorder = _G[AddOn .. "_Texture_" .. unit .. "CastBar_IconBorder"]
	local SpellName = _G[AddOn .. "_FontString_" .. unit .. "CastBar_SpellName"]
	local CastTime = _G[AddOn .. "_FontString_" .. unit .. "CastBar_CastTime"]
	local Icon = _G[AddOn .. "_Texture_" .. unit .. "CastBar_Icon"]
	local Width = _G[AddOn .. "_SavedVariables"]["CastBar"]["Width"]
	
	if( Gladdy.db.npCastbarGuess == false ) then
		CastBar:SetAlpha(0)
		CastBar:Hide()
	end
	
	if Texture.castTime and Texture.castTime < Texture.maxCastTime then
		local total = string.format("%.2f",Texture.maxCastTime)
		local left = string.format("%.1f",total - Texture.castTime/Texture.maxCastTime*total)
		Texture:SetWidth(Width*(Texture.castTime/Texture.maxCastTime))
		local point, relativeTo, relativePoint, xOfs, yOfs = Texture:GetPoint()
		Texture:SetPoint(point, relativeTo, relativePoint, -Width/2+Width/2*Texture.castTime/Texture.maxCastTime, yOfs)
		Texture:SetVertexColor(1, 0.5, 0)
		if ( _G[AddOn .. "_SavedVariables"]["Timer"]["Format"] == "LEFT" ) then
			CastTime:SetText(left)
		elseif ( _G[AddOn .. "_SavedVariables"]["Timer"]["Format"] == "TOTAL" ) then
			CastTime:SetText(total)
		elseif ( _G[AddOn .. "_SavedVariables"]["Timer"]["Format"] == "BOTH" ) then
			CastTime:SetText(left .. " /" .. total)
		end
		-- in case nameplate with matching name isn't found, hide castbar
		local found = false
		for plate, _ in pairs(Table["Nameplates"]) do
			local hpborder, cbborder, cbicon, overlay, oldname, level, bossicon, raidicon = plate:GetRegions()
			if(plate:IsVisible() and oldname:GetText() == CastBar.name) then
				found = true
				CastBar:SetPoint("TOP",hpborder,"BOTTOM",6,-4.5)
			end
		end
		if not found then
--			log("hiding castbar because no nameplate was found")
			CastBar:SetAlpha(0)
			CastBar:Hide()
		end
		Texture.castTime = Texture.castTime + elapsed
		
	elseif Texture.castTime and Texture.castTime > Texture.maxCastTime then
--		log("hiding castbar because cast finished")
		CastBar:SetAlpha(0)
		CastBar:Hide()
		Texture.castTime = Texture.castTime + elapsed
	end
end

local function keepCastbars(elapsed)
	for k,v in pairs(unitsToCheck) do
	-- double check that fallback function is only used if no info is pulled for unit
		if(not UnitCastingInfo(k)) then
			keepCastbar(k, elapsed)
		end
	end
end

local function createCastbars(elapsed)
	-- decide whether castbar should be showing or not
	
	for frame, _ in pairs(Table["Nameplates"]) do
		if frame:IsVisible() then
			local hpborder, cbborder, cbicon, overlay, oldname, level, bossicon, raidicon = frame:GetRegions()
	
			for k, v in pairs(unitsToCheck) do
				local unit = k
				local name = oldname:GetText()
				local Texture = _G[AddOn .. "_Texture_" .. unit .. "CastBar_CastBar"]
				local CastTime = _G[AddOn .. "_FontString_" .. unit .. "CastBar_CastTime"]
				local CastBar = _G[AddOn .. "_Frame_" .. unit .. "CastBar"]
				local Border = _G[AddOn .. "_Texture_" .. unit .. "CastBar_Border"]
				local IconBorder = _G[AddOn .. "_Texture_" .. unit .. "CastBar_IconBorder"]
				local SpellName = _G[AddOn .. "_FontString_" .. unit .. "CastBar_SpellName"]
				local CastTime = _G[AddOn .. "_FontString_" .. unit .. "CastBar_CastTime"]
				local Icon = _G[AddOn .. "_Texture_" .. unit .. "CastBar_Icon"]
				local Width = _G[AddOn .. "_SavedVariables"]["CastBar"]["Width"]
				
				-- cast detected, display castbar 
				if ( name == UnitName(unit) and UnitCastingInfo(unit) ) then
					local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(unit);
					if ( string.len(name) > 12 ) then name = (string.sub(name,1,12) .. ".. ") end
					
					SpellName:SetText(name)
					Icon:SetTexture(texture)
					Border:SetTexture(0,0,0,1)
					IconBorder:SetTexture(0,0,0,1)
					Texture.castTime = (GetTime() - (startTime / 1000))
					Texture.maxCastTime = (endTime - startTime) / 1000
					Texture:SetWidth(Width*Texture.castTime/Texture.maxCastTime)
					local point, relativeTo, relativePoint, xOfs, yOfs = Texture:GetPoint()
					Texture:SetPoint(point, relativeTo, relativePoint, -Width/2+Width/2*Texture.castTime/Texture.maxCastTime, yOfs)
					Texture:SetVertexColor(1, 0.5, 0)
					
					CastBar.name = UnitName(unit)
					CastBar:SetAlpha(1)
					CastBar:SetPoint("TOP",hpborder,"BOTTOM",6,-4.5)
					CastBar:SetParent(frame)
					CastBar:Show()
					
					local total = string.format("%.2f", Texture.maxCastTime)
					local left = string.format("%.1f",total - Texture.castTime/Texture.maxCastTime*total)
					if ( _G[AddOn .. "_SavedVariables"]["Timer"]["Format"] == "LEFT" ) then
						CastTime:SetText(left)
					elseif ( _G[AddOn .. "_SavedVariables"]["Timer"]["Format"] == "TOTAL" ) then
						CastTime:SetText(total)
					elseif ( _G[AddOn .. "_SavedVariables"]["Timer"]["Format"] == "BOTH" ) then
						CastTime:SetText(left .. " /" .. total)
					end
				-- hide castbar if unit stops casting
				elseif ( name == UnitName(unit) and not UnitCastingInfo(unit)) then
	--				log("hiding castbar because unit stopped")
					CastBar:SetAlpha(0)
					CastBar:Hide()
				end
			end
		end	
	end
	--fallback function in case no casting information was found but we still want to display progress on the bar
	keepCastbars(elapsed)
end

local numChildren = -1
local function HookFrames(...)
	for index = 1, select('#', ...) do
		local frame = select(index, ...)
		local region = frame:GetRegions()
		if (  not frame:GetName() and region and region:GetObjectType() == "Texture" and region:GetTexture() == "Interface\\Tooltips\\Nameplate-Border" ) then
			Table["Nameplates"][frame] = true
		end
	end
end

local function Update(self, elapsed)
	if ( WorldFrame:GetNumChildren() ~= numChildren ) then
		if Gladdy.db.npCastbars then
			numChildren = WorldFrame:GetNumChildren()
			HookFrames(WorldFrame:GetChildren())
		end
	end
	createCastbars(elapsed)
end

Frame:SetScript("OnEvent",function(self,event,unitID,spell,...)
	local timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		if ( not _G[AddOn .. "_PlayerEnteredWorld"] ) then
			Frame_RegisterEvents()
			CastBars_Create()
			_G[AddOn .. "_PlayerEnteredWorld"] = true
			Frame:SetScript("OnUpdate", Update)			
		end
	end
end)