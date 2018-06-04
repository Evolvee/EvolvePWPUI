--[[ Code Credits - to the people whose code I borrowed and learned from:
Wowwiki
Kollektiv
Tuller
ckknight
The authors of Nao!!
And of course, Blizzard

Thanks! :)
]]

local L = "LoseControl"
local function log(msg) DEFAULT_CHAT_FRAME:AddMessage(msg) end -- alias for convenience
log("|cffFF7D0ALoseControl|r type /LC for config");
-------------------------------------------------------------------------------
local CC      = LOSECONTROL["CC"]
local Silence = LOSECONTROL["Silence"]
local Disarm  = LOSECONTROL["Disarm"]
local Root    = LOSECONTROL["Root"]
local Snare   = LOSECONTROL["Snare"]
local Immune  = LOSECONTROL["Immune"]
local PvE     = LOSECONTROL["PvE"]

local spellIds = {
	-- Druid
	[8983] = "CC", -- Bash
	[33786] = "CC", -- Cyclone
	[19675] = "Root", -- Feral Charge Efect
	[18658] = "CC", -- Hibernate
	[22570] = "CC", -- Maim
	[27006] = "CC", -- Pounce
	[16922] = CC, -- Starfire Stun
	-- Hunter
	[27753] = "CC", -- Freezing Trap
	[19577] = "CC", -- Intimidation
	[14327] = "CC", -- Scare Beast
	[19503] = "CC", -- Scatter Shot
	[27068] = "CC", -- Wyvern Sting; requires a hack to be removed later
	[19410] = CC, -- Improved Concussive Shot
	-- Mage
	[10230] = "Root", -- Frost Nova
	[12826] = "CC", -- Polymorph
	[33043] = "CC", -- Dragon's Breath
	[18469] = "Silence", -- Counterspell - Silenced
	-- Paladin
	[10308] = "CC", -- Hammer of Justice
	[20066] = "CC", -- Repentance
	-- Priest
	[10912] = "CC", -- Mind Control
	[10890] = "CC", -- Psychic Scream
	[15487] = "Silence", -- Silence
	-- Rogue
	[1330] = "Silence", -- Garrote - Silence
	[2094] = "CC", -- Blind
	[1833] = "CC", -- Cheap Shot
	[38764] = "CC", -- Gouge
	[8643] = "CC", -- Kidney shot; the buff is 30621
	[11297] = "CC", -- Sap
	-- Warlock
	[27223] = "CC", -- Death Coil
	[6215] = "CC", -- Fear
	[17928] = "CC", -- Howl of Terror
	[6358] = "CC", -- Seduction
	[30414] = "CC", -- Shadowfury
	-- Warrior
	[7922] = "CC", -- Charge Stun
	[12809] = "CC", -- Concussion Blow
	[25274] = "CC", -- Intercept Stun
	[5246] = "CC", -- Intimidating Shout
	[676]   = "Disarm",	-- Disarm
	[5530] = CC, -- Mace Stun Effect
	[34510] = CC, -- Stormherald/Deep Thunder
	-- other
	[30217] = "CC", -- Adamantite Grenade
	[30216] = "CC", -- Fel Iron Bomb
	[20549] = "CC", -- War Stomp
	-- immunities/buffs
	[642]   = "Immune",	-- Divine Shield (Paladin)
	[45438] = "Immune",	-- Ice Block (Mage)
	[34692] = "Immune",	-- The Beast Within (Hunter)
	[33206] = "Immune", -- Pain Suppression
	[12292] = "Immune", -- Death Wish
	[10278] = "Immune", -- Blessing of Protection
	[31884] = "Immune", -- Avenging Wrath
	[26669] = "Immune", -- Evasion
	[11305] = "Immune", -- Sprint
	[32182] = "Immune", -- Heroism
	[2825] = "Immune", -- Bloodlust
	[31224] = "Immune", -- Cloak of Shadows
	[3411] = "Immune", -- Intervene
	[20594] = "Immune", -- Stoneform
	[29166] = "Immune", -- Innervate
	[16689] = "Immune", -- Nature's Grasp
	[23920] = "Immune", -- Spell Reflection
	[1044] = "Immune", -- Blessing of Freedom
	[6940] = "Immune", -- Blessing of Sacrifice
}

local abilities = {} -- localized names are saved here
for k, v in pairs(spellIds) do
	local name = GetSpellInfo(k)
	if name then
		abilities[name] = v
	else -- Thanks to inph for this idea.
		log(L .. " unknown spellId: " .. k)
	end
end

-------------------------------------------------------------------------------
-- Global references for attaching icons to various unit frames
local anchors = {
	None = {}, -- empty but necessary
	Blizzard = {
		player = "PlayerPortrait",
		target = "TargetPortrait",
		focus  = "FocusPortrait",
		party1 = "PartyMemberFrame1Portrait",
		party2 = "PartyMemberFrame2Portrait",
		party3 = "PartyMemberFrame3Portrait",
		party4 = "PartyMemberFrame4Portrait",
		arena1 = "ArenaEnemyFrame1ClassPortrait", -- could be replaced by Gladdy eventually or a backport of Arena Unitframes (3.3.5 default UI)
		arena2 = "ArenaEnemyFrame2ClassPortrait",
		arena3 = "ArenaEnemyFrame3ClassPortrait",
		arena4 = "ArenaEnemyFrame4ClassPortrait",
		arena5 = "ArenaEnemyFrame5ClassPortrait",
	},
	Perl = {
		player = "Perl_Player_Portrait",
		target = "Perl_Target_Portrait",
		focus  = "Perl_Focus_Portrait",
		party1 = "Perl_Party_MemberFrame1_Portrait",
		party2 = "Perl_Party_MemberFrame2_Portrait",
		party3 = "Perl_Party_MemberFrame3_Portrait",
		party4 = "Perl_Party_MemberFrame4_Portrait",
	},
	XPerl = {
		player = "XPerl_PlayerportraitFrameportrait",
		target = "XPerl_TargetportraitFrameportrait",
		focus  = "XPerl_FocusportraitFrameportrait",
		party1 = "XPerl_party1portraitFrameportrait",
		party2 = "XPerl_party2portraitFrameportrait",
		party3 = "XPerl_party3portraitFrameportrait",
		party4 = "XPerl_party4portraitFrameportrait",
	},
	-- more to come here?
}

-------------------------------------------------------------------------------
-- Default settings
local DBdefaults = {
	version = 3.31,
	noCooldownCount = false,
	tracking = { -- order = priority?
		CC      = true,
		Silence = true,
		Disarm  = true,
		Root    = false,
		Snare   = false,
		Immune  = false,
	},
	frames = {
		player = {
			enabled = true,
			size = 36,
			alpha = 1,
			anchor = "None",
		},
		target = {
			enabled = true,
			size = 56,
			alpha = 1,
			anchor = "Blizzard",
		},
		focus = {
			enabled = true,
			size = 56,
			alpha = 1,
			anchor = "Blizzard",
		},
		party1 = {
			enabled = true,
			size = 36,
			alpha = 1,
			anchor = "Blizzard",
		},
		party2 = {
			enabled = true,
			size = 36,
			alpha = 1,
			anchor = "Blizzard",
		},
		party3 = {
			enabled = true,
			size = 36,
			alpha = 1,
			anchor = "Blizzard",
		},
		party4 = {
			enabled = true,
			size = 36,
			alpha = 1,
			anchor = "Blizzard",
		},
	},
}
local LoseControlDB -- local reference to the addon settings. this gets initialized when the ADDON_LOADED event fires

-------------------------------------------------------------------------------
-- Create the main class
local LoseControl = CreateFrame("Cooldown", nil, UIParent) -- Exposes the SetCooldown method

LibStub("AceComm-3.0"):Embed(LoseControl)
function LoseControl:OnCommReceived(prefix, message, dest, sender)
if sender == UnitName("player") then return end
	if prefix == "LoseControl_Party" then
		local duration, expirationTime = strsplit(',', message)
		for i=1, 5 do
			if UnitName("party"..i) == sender then
				self:UNIT_AURA("party"..i, tonumber(duration), tonumber(expirationTime))
			end
		end
	end
end

function LoseControl:OnEvent(event, ...) -- functions created in "object:method"-style have an implicit first parameter of "self", which points to object
	self[event](self, ...) -- route event parameters to LoseControl:event methods
end
LoseControl:SetScript("OnEvent", LoseControl.OnEvent)

-- Handle default settings
function LoseControl:ADDON_LOADED(arg1)
	if arg1 == L then
		if _G.LoseControlDB then
			if _G.LoseControlDB.version < DBdefaults.version then
				if _G.LoseControlDB.version >= 3.22 then -- minor changes, so try to update without losing settings
					_G.LoseControlDB.tracking = {
						Immune  = true, --100
						CC      = true,  -- 90
						PvE     = false,  -- 80
						Silence = true,  -- 70
						Disarm  = true,  -- 60
						Root    = true, -- 50
						Snare   = false, -- 40
					}
					_G.LoseControlDB.version = 3.31
				else -- major changes, must reset settings
					_G.LoseControlDB = CopyTable(DBdefaults)
					log(LOSECONTROL["LoseControl reset."])
				end
			end
		else -- never installed before
			_G.LoseControlDB = CopyTable(DBdefaults)
			log(LOSECONTROL["LoseControl reset."])
		end
		LoseControlDB = _G.LoseControlDB
		LoseControl.noCooldownCount = LoseControlDB.noCooldownCount
	end
end
LoseControl:RegisterEvent("ADDON_LOADED")

function LoseControl:PLAYER_TARGET_CHANGED()
	self:UNIT_AURA("target")
end
function LoseControl:PLAYER_FOCUS_CHANGED()
	self:UNIT_AURA("focus")
end

-- Initialize a frame's position
function LoseControl:PLAYER_ENTERING_WORLD() -- this correctly anchors enemy arena frames that aren't created until you zone into an arena
	self.frame = LoseControlDB.frames[self.unitId] -- store a local reference to the frame's settings
	local frame = self.frame
	self.anchor = _G[anchors[frame.anchor][self.unitId]] or UIParent
	self:SetParent(self.anchor:GetParent()) -- or LoseControl) -- If Hide() is called on the parent frame, its children are hidden too. This also sets the frame strata to be the same as the parent's.
	--self:SetFrameStrata(frame.strata or "LOW")
	self:ClearAllPoints() -- if we don't do this then the frame won't always move
	self:SetWidth(frame.size)
	self:SetHeight(frame.size)
	self:SetPoint(
		frame.point or "CENTER",
		self.anchor,
		frame.relativePoint or "CENTER",
		frame.x or 0,
		frame.y or 0
	)
	--self:SetAlpha(frame.alpha) -- doesn't seem to work; must manually set alpha after the cooldown is displayed, otherwise it doesn't apply.
end

function LoseControl:COMBAT_LOG_EVENT_UNFILTERED(event , ...)
local event, sourceGUID,sourceName,sourceFlags,destGUID,destName,destFlags,spellID,spellName = select ( 1 , ... );
	if (event == "SPELL_AURA_REFRESH") then
		for i = 1, 40 do
            name, _, icon, _, _, duration, expirationTime = UnitDebuff(self.unitId, i)
            if name==spellName then
				self:UNIT_AURA(self.unitId)
				--self:SendCommMessage("LoseControl_Party", GetTime()..","..expirationTime, "PARTY", nil, "ALERT")
				--self:SendCommMessage("LoseControl_Enemy", GetTime()..","..expirationTime, "PARTY", nil, "ALERT")
            end
		end
	end		
end

local WYVERN_STING = GetSpellInfo(19386)

-- This is the main event
function LoseControl:UNIT_AURA(unitId, commDur, commExp) -- fired when a (de)buff is gained/lost
local frame = LoseControlDB.frames[unitId]
	--party CC can't be seen in TBC, not even on bugged private servers
	--prevent unit_aura from firing outside of AceComm
	--see if we can steal timers from EnemyBuffTimers
	if not (unitId == self.unitId and frame.enabled and self.anchor:IsVisible()) then return end
		local maxExpirationTime = 0
		local _, name, icon, Icon, duration, Duration, expirationTime, wyvernsting
		local currentSpell
		local EBFrame
		
		for i = 1, 40 do
			name, rank, icon, count, debuffType, duration, expirationTime, isMine = UnitDebuff(unitId, i)
			if not name then break end -- no more debuffs, terminate the loop
			if expirationTime == nil or expirationTime == 0 then
				if commExp then
					expirationTime = commExp
					duration = commDur
				else
					-- getting wrong timer sometimes (overwriting?)
					EBFrame = getglobal(name.."_"..UnitGUID(unitId).."Target")
					if EBFrame ~=nil and LoseControlDB.tracking[abilities[name]] then
						--log("found debuff")
						expirationTime = EBFrame.endTime-(GetTime()-EBFrame.startTime)
						--log(name.."  "..expirationTime)
						duration = EBFrame.endTime
					end
				end
			end

			-- exceptions
			if name == WYVERN_STING then
				wyvernsting = 1
				if not self.wyvernsting then
					self.wyvernsting = 1 -- this is the first time the debuff has been applied
				elseif expirationTime > self.wyvernsting_expirationTime then
					self.wyvernsting = 2 -- this is the second time the debuff has been applied
				end
				self.wyvernsting_expirationTime = expirationTime
				if self.wyvernsting == 2 then
					name = nil -- hack to skip the next if condition since LUA doesn't have a "continue" statement
				end
			end
			if expirationTime and maxExpirationTime then
				if LoseControlDB.tracking[abilities[name]] and expirationTime >= maxExpirationTime then
					maxExpirationTime = expirationTime
					Duration = duration
					Icon = icon
					currentSpell = name
				end
			end
		end
		-- continue hack for Wyvern Sting
		if self.wyvernsting == 2 and not wyvernsting then -- dot either removed or expired
			self.wyvernsting = nil
		end

		-- Track Immunities
		if not Icon and LoseControlDB.tracking[Immune] and unitId ~= "player" then -- only bother checking for immunities if there were no debuffs found
			for i = 1, 40 do
				name, rank, icon, count, duration, expirationTime, isMine = UnitBuff(unitId, i)
				if not name then break end
				if expirationTime == nil or expirationTime == 0 then
					EBFrame = getglobal(name.."_"..UnitGUID(unitId).."Target")
					if EBFrame ~=nil and LoseControlDB.tracking[abilities[name]] then
						--log("found buff")
						expirationTime = EBFrame.endTime-(GetTime()-EBFrame.startTime)
						--log(name.."  "..expirationTime)
						duration = EBFrame.endTime
					end
				end
				if abilities[name] == "Immune" and expirationTime ~= nil and expirationTime >= maxExpirationTime then
					maxExpirationTime = expirationTime
					Duration = duration
					Icon = icon
					currentSpell = name
				end
			end
		end
		if maxExpirationTime == 0 or maxExpirationTime == nil then -- no (de)buffs found
			self.maxExpirationTime = 0
			self.currentSpell = ""
			if self.anchor ~= UIParent and self.drawlayer then
				self.anchor:SetDrawLayer(self.drawlayer) -- restore the original draw layer
			end
			-- needed to remove hide icon / basically sending empty UNIT_AURA
			if unitId == "player" then
				self:SendCommMessage("LoseControl_Party", "10"..","..maxExpirationTime, "PARTY", nil, "ALERT")
			end
				self:Hide()
		elseif maxExpirationTime ~= self.maxExpirationTime then -- this is a different (de)buff, so initialize the cooldown
			self.maxExpirationTime = maxExpirationTime
			if self.anchor ~= UIParent then
				self:SetFrameLevel(self.anchor:GetParent():GetFrameLevel()) -- must be dynamic, frame level changes all the time
				if not self.drawlayer then
					self.drawlayer = self.anchor:GetDrawLayer() -- back up the current draw layer
				end
				self.anchor:SetDrawLayer("BACKGROUND") -- Temporarily put the portrait texture below the debuff texture. This is the only reliable method I've found for keeping the debuff texture visible with the cooldown spiral on top of it.
			end
			if self.frame.anchor == "Blizzard" then
				SetPortraitToTexture(self.texture, Icon) -- Sets the texture to be displayed from a file applying a circular opacity mask making it look round like portraits. TO DO: mask the cooldown frame somehow so the corners don't stick out of the portrait frame. Maybe apply a circular alpha mask in the OVERLAY draw layer.
			else
				self.texture:SetTexture(Icon)
			end
			if commDur ~=nil then
				self:SetCooldown( GetTime() - (tonumber(commDur)-commExp), tonumber(commDur))
			end
			self:Show()	
			self:SetCooldown( GetTime() - (Duration-maxExpirationTime), Duration )
			if unitId == "player" then
				self:SendCommMessage("LoseControl_Party", Duration..","..maxExpirationTime, "PARTY", nil, "ALERT")					
			end
			self.unitName = UnitName(unitId)
			self.unitId = unitId
			self:SetAlpha(frame.alpha) -- hack to apply transparency to the cooldown time	
	end
end

local UnitDropDown -- declared here, initialized below in the options panel code
local AnchorDropDown
-- Handle mouse dragging
function LoseControl:StopMoving()
	local frame = LoseControlDB.frames[self.unitId]
	frame.point, frame.anchor, frame.relativePoint, frame.x, frame.y = self:GetPoint()
	if not frame.anchor then
		frame.anchor = "None"
		if UIDropDownMenu_GetSelectedValue(UnitDropDown) == self.unitId then
			UIDropDownMenu_SetSelectedValue(AnchorDropDown, "None") -- update the drop down to show that the frame has been detached from the anchor
		end
	end
	self.anchor = _G[anchors[frame.anchor][self.unitId]] or UIParent
	self:StopMovingOrSizing()
end

-- Constructor method
function LoseControl:new(unitId)
	local o = CreateFrame("Cooldown", L .. unitId) --, UIParent)
	setmetatable(o, self)
	self.__index = self

	-- Init class members
	o.unitId = unitId -- ties the object to a unit
	o.texture = o:CreateTexture(nil, "BORDER") -- displays the debuff; draw layer should equal "BORDER" because cooldown spirals are drawn in the "ARTWORK" layer.
	o.texture:SetAllPoints(o) -- anchor the texture to the frame
	o:SetReverse(true) -- makes the cooldown shade from light to dark instead of dark to light

	--[[ Rufio's code to make the frame border pretty. Maybe use this somehow to mask cooldown corners in Blizzard frames.
	o.overlay = o:CreateTexture(nil, "OVERLAY");
	o.overlay:SetTexture("Interface\\AddOns\\LoseControl\\gloss");
	o.overlay:SetPoint("TOPLEFT", -1, 1);
	o.overlay:SetPoint("BOTTOMRIGHT", 1, -1);
	o.overlay:SetVertexColor(0.25, 0.25, 0.25);]]
	o:Hide()

	-- Handle events
	o:SetScript("OnEvent", self.OnEvent)
	--o:SetScript("OnUpdate", self.Update)
	o:SetScript("OnDragStart", self.StartMoving) -- this function is already built into the Frame class
	o:SetScript("OnDragStop", self.StopMoving) -- this is a custom function
	o:RegisterEvent("PLAYER_ENTERING_WORLD")
	o:RegisterEvent("UNIT_AURA")
	o:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	o:RegisterComm("LoseControl_Party")
	o:RegisterComm("LoseControl_Enemy")
	
	if unitId == "focus" then
		o:RegisterEvent("PLAYER_FOCUS_CHANGED")
	elseif unitId == "target" then
		o:RegisterEvent("PLAYER_TARGET_CHANGED")
	end
	
	return o
end

-- Create new object instance for each frame
local LC = {}
for k in pairs(DBdefaults.frames) do
	LC[k] = LoseControl:new(k)
end

-------------------------------------------------------------------------------
-- Add main Interface Option Panel
local O = L .. "OptionsPanel"

local OptionsPanel = CreateFrame("Frame", O)
OptionsPanel.name = L

local title = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetText(L)

local subText = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
local notes = GetAddOnMetadata(L, "Notes-" .. GetLocale())
if not notes then
	notes = GetAddOnMetadata(L, "Notes")
end
subText:SetText(notes)

-- "Unlock" checkbox - allow the frames to be moved
local Unlock = CreateFrame("CheckButton", O.."Unlock", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."UnlockText"]:SetText(LOSECONTROL["Unlock"])
function Unlock:OnClick()
	if self:GetChecked() then
		_G[O.."UnlockText"]:SetText(LOSECONTROL["Unlock"] .. LOSECONTROL[" (drag an icon to move)"])
		local keys = {} -- for random icon sillyness
		for k in pairs(spellIds) do
			tinsert(keys, k)
		end
		for k, v in pairs(LC) do
			local frame = LoseControlDB.frames[k]
			if _G[anchors[frame.anchor][k]] or frame.anchor == "None" then -- only unlock frames whose anchor exists
				v:UnregisterEvent("UNIT_AURA")
				v:UnregisterEvent("PLAYER_FOCUS_CHANGED")
				v:UnregisterEvent("PLAYER_TARGET_CHANGED")
				v:SetMovable(true)
				v:RegisterForDrag("LeftButton")
				v:EnableMouse(true)
				v.texture:SetTexture(select(3, GetSpellInfo(keys[random(#keys)])))
				v:SetParent(nil) -- detach the frame from its parent or else it won't show if the parent is hidden
				--v:SetFrameStrata(frame.strata or "MEDIUM")
				if v.anchor:GetParent() then
					v:SetFrameLevel(v.anchor:GetParent():GetFrameLevel())
				end
				v:Show()
				v:SetCooldown( GetTime(), 30 )
				v:SetAlpha(frame.alpha) -- hack to apply the alpha to the cooldown timer
			end
		end
	else
		_G[O.."UnlockText"]:SetText(LOSECONTROL["Unlock"])
		for k, v in pairs(LC) do
			local frame = LoseControlDB.frames[k]
			v:RegisterEvent("UNIT_AURA")	
			if k == "focus" then
				v:RegisterEvent("PLAYER_FOCUS_CHANGED")
			elseif k == "target" then
				v:RegisterEvent("PLAYER_TARGET_CHANGED")
			end
			v:SetMovable(false)
			v:RegisterForDrag()
			v:EnableMouse(false)
			v:SetParent(v.anchor:GetParent()) -- or UIParent)
			v:Hide()
			--v:SetFrameStrata(frame.strata or "LOW")
		end	
	end
end
Unlock:SetScript("OnClick", Unlock.OnClick)

local DisableCooldownCount = CreateFrame("CheckButton", O.."DisableCooldownCount", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."DisableCooldownCountText"]:SetText(LOSECONTROL["Disable OmniCC/CooldownCount Support"])
DisableCooldownCount:SetScript("OnClick", function(self)
	LoseControlDB.noCooldownCount = self:GetChecked()
	LoseControl.noCooldownCount = LoseControlDB.noCooldownCount
end)

local Tracking = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
Tracking:SetText(LOSECONTROL["Tracking"])

local TrackCCs = CreateFrame("CheckButton", O.."TrackCCs", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackCCsText"]:SetText(CC)
TrackCCs:SetScript("OnClick", function(self)
	LoseControlDB.tracking[CC] = self:GetChecked()
end)

local TrackSilences = CreateFrame("CheckButton", O.."TrackSilences", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackSilencesText"]:SetText(Silence)
TrackSilences:SetScript("OnClick", function(self)
	LoseControlDB.tracking[Silence] = self:GetChecked()
end)

local TrackDisarms = CreateFrame("CheckButton", O.."TrackDisarms", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackDisarmsText"]:SetText(Disarm)
TrackDisarms:SetScript("OnClick", function(self)
	LoseControlDB.tracking[Disarm] = self:GetChecked()
end)

local TrackRoots = CreateFrame("CheckButton", O.."TrackRoots", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackRootsText"]:SetText(Root)
TrackRoots:SetScript("OnClick", function(self)
	LoseControlDB.tracking[Root] = self:GetChecked()
end)

local TrackSnares = CreateFrame("CheckButton", O.."TrackSnares", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackSnaresText"]:SetText(Snare)
TrackSnares:SetScript("OnClick", function(self)
	LoseControlDB.tracking[Snare] = self:GetChecked()
end)

local TrackImmune = CreateFrame("CheckButton", O.."TrackImmune", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackImmuneText"]:SetText(Immune)
TrackImmune:SetScript("OnClick", function(self)
	LoseControlDB.tracking[Immune] = self:GetChecked()
end)

local TrackPvE = CreateFrame("CheckButton", O.."TrackPvE", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackPvEText"]:SetText(PvE)
TrackPvE:SetScript("OnClick", function(self)
	LoseControlDB.tracking[PvE] = self:GetChecked()
end)

-------------------------------------------------------------------------------
-- DropDownMenu helper function
local info = UIDropDownMenu_CreateInfo()
local function AddItem(owner, text, value)
	info.owner = owner
	info.func = owner.OnClick
	info.text = text
	info.value = value
	info.checked = nil -- initially set the menu item to being unchecked
	UIDropDownMenu_AddButton(info)
end

local UnitDropDownLabel = OptionsPanel:CreateFontString(O.."UnitDropDownLabel", "ARTWORK", "GameFontNormal")
UnitDropDownLabel:SetText(LOSECONTROL["Unit Configuration"])
UnitDropDown = CreateFrame("Frame", O.."UnitDropDown", OptionsPanel, "UIDropDownMenuTemplate")
function UnitDropDown:OnClick()
	UIDropDownMenu_SetSelectedValue(UnitDropDown, this.value)
	OptionsPanel.refresh() -- easy way to update all the other controls
end
UIDropDownMenu_Initialize(UnitDropDown, function() -- sets the initialize function and calls it
	for _, v in ipairs({ "player", "target", "focus", "party1", "party2", "party3", "party4"}) do -- indexed manually so they appear in order
		AddItem(UnitDropDown, LOSECONTROL[v], v)
	end
end)
UIDropDownMenu_SetSelectedValue(UnitDropDown, "player") -- set the initial drop down choice

local AnchorDropDownLabel = OptionsPanel:CreateFontString(O.."AnchorDropDownLabel", "ARTWORK", "GameFontNormal")
AnchorDropDownLabel:SetText(LOSECONTROL["Anchor"])
AnchorDropDown = CreateFrame("Frame", O.."AnchorDropDown", OptionsPanel, "UIDropDownMenuTemplate")
function AnchorDropDown:OnClick()
	UIDropDownMenu_SetSelectedValue(AnchorDropDown, this.value)
	
	local unit = UIDropDownMenu_GetSelectedValue(UnitDropDown)
	local frame = LoseControlDB.frames[unit]
	local icon = LC[unit]

	frame.anchor = this.value
	if this.value ~= "None" then -- reset the frame position so it centers on the anchor frame
		frame.point = nil
		frame.relativePoint = nil
		frame.x = nil
		frame.y = nil
	end

	icon.anchor = _G[anchors[frame.anchor][unit]] or UIParent

	if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
		icon:SetParent(icon.anchor:GetParent())
	end

	icon:ClearAllPoints() -- if we don't do this then the frame won't always move
	icon:SetPoint(
		frame.point or "CENTER",
		icon.anchor,
		frame.relativePoint or "CENTER",
		frame.x or 0,
		frame.y or 0
	)
end

function AnchorDropDown:initialize() -- called from OptionsPanel.refresh() and every time the drop down menu is opened
	local unit = UIDropDownMenu_GetSelectedValue(UnitDropDown)
	AddItem(AnchorDropDown, LOSECONTROL["None"], "None")
	AddItem(AnchorDropDown, "Blizzard", "Blizzard")
	if _G[anchors["Perl"][unit]] then AddItem(AnchorDropDown, "Perl", "Perl") end
	if _G[anchors["XPerl"][unit]] then AddItem(AnchorDropDown, "XPerl", "XPerl") end
end

local StrataDropDownLabel = OptionsPanel:CreateFontString(O.."StrataDropDownLabel", "ARTWORK", "GameFontNormal")
StrataDropDownLabel:SetText(LOSECONTROL["Strata"])
local StrataDropDown = CreateFrame("Frame", O.."StrataDropDown", OptionsPanel, "UIDropDownMenuTemplate")
function StrataDropDown:OnClick()
	local unit = UIDropDownMenu_GetSelectedValue(UnitDropDown)
	UIDropDownMenu_SetSelectedValue(StrataDropDown, this.value)
	LoseControlDB.frames[unit].strata = this.value
	LC[unit]:SetFrameStrata(this.value)
end
function StrataDropDown:initialize() -- called from OptionsPanel.refresh() and every time the drop down menu is opened
	for _, v in ipairs({ "HIGH", "MEDIUM", "LOW", "BACKGROUND" }) do -- indexed manually so they appear in order
		AddItem(this, v, v)
	end
end

-------------------------------------------------------------------------------
-- Slider helper function, thanks to Kollektiv
local function CreateSlider(text, parent, low, high, step)
	local name = parent:GetName() .. text
	local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
	slider:SetWidth(160)
	slider:SetMinMaxValues(low, high)
	slider:SetValueStep(step)
	--_G[name .. "Text"]:SetText(text)
	_G[name .. "Low"]:SetText(low)
	_G[name .. "High"]:SetText(high)
	return slider
end

local SizeSlider = CreateSlider(LOSECONTROL["Icon Size"], OptionsPanel, 16, 512, 4)
SizeSlider:SetScript("OnValueChanged", function(this, value)
	local unit = UIDropDownMenu_GetSelectedValue(UnitDropDown)
	_G[this:GetName() .. "Text"]:SetText(LOSECONTROL["Icon Size"] .. " (" .. value .. "px)")
	LoseControlDB.frames[unit].size = value
	LC[unit]:SetWidth(value)
	LC[unit]:SetHeight(value)
end)

local AlphaSlider = CreateSlider(LOSECONTROL["Opacity"], OptionsPanel, 0, 100, 5) -- I was going to use a range of 0 to 1 but Blizzard's slider chokes on decimal values
AlphaSlider:SetScript("OnValueChanged", function(this, value)
	local unit = UIDropDownMenu_GetSelectedValue(UnitDropDown)
	_G[this:GetName() .. "Text"]:SetText(LOSECONTROL["Opacity"] .. " (" .. value .. "%)")
	LoseControlDB.frames[unit].alpha = value / 100 -- the real alpha value
	LC[unit]:SetAlpha(value / 100)
end)

-------------------------------------------------------------------------------
-- Defined last because it references earlier declared variables
local Enabled = CreateFrame("CheckButton", O.."Enabled", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."EnabledText"]:SetText(LOSECONTROL["Enabled"])
function Enabled:OnClick()
	local enabled = self:GetChecked()
	LoseControlDB.frames[UIDropDownMenu_GetSelectedValue(UnitDropDown)].enabled = enabled
	if enabled then
		UIDropDownMenu_EnableDropDown(AnchorDropDown)
		UIDropDownMenu_EnableDropDown(StrataDropDown)
		--[[
		BlizzardOptionsPanel_Slider_Enable(SizeSlider)	2.4.3
		BlizzardOptionsPanel_Slider_Enable(AlphaSlider)]] 
	else
		UIDropDownMenu_DisableDropDown(AnchorDropDown)
		UIDropDownMenu_DisableDropDown(StrataDropDown)
		--[[BlizzardOptionsPanel_Slider_Disable(SizeSlider) 2.4.3
		BlizzardOptionsPanel_Slider_Disable(AlphaSlider)]]
	end
end
Enabled:SetScript("OnClick", Enabled.OnClick)

-------------------------------------------------------------------------------
-- Arrange all the options neatly
title:SetPoint("TOPLEFT", 16, -16)
subText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)

Unlock:SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -16)
DisableCooldownCount:SetPoint("TOPLEFT", Unlock, "BOTTOMLEFT", 0, -2)

Tracking:SetPoint("TOPLEFT", DisableCooldownCount, "BOTTOMLEFT", 0, -12)
TrackCCs:SetPoint("TOPLEFT", Tracking, "BOTTOMLEFT", 0, -4)
TrackSilences:SetPoint("TOPLEFT", TrackCCs, "TOPRIGHT", 100, 0)
TrackDisarms:SetPoint("TOPLEFT", TrackSilences, "TOPRIGHT", 100, 0)
TrackRoots:SetPoint("TOPLEFT", TrackCCs, "BOTTOMLEFT", 0, -2)
TrackSnares:SetPoint("TOPLEFT", TrackSilences, "BOTTOMLEFT", 0, -2)
TrackImmune:SetPoint("TOPLEFT", TrackDisarms, "BOTTOMLEFT", 0, -2)
TrackPvE:SetPoint("TOPLEFT", TrackRoots, "BOTTOMLEFT", 0, -2)

UnitDropDownLabel:SetPoint("TOPLEFT", TrackPvE, "BOTTOMLEFT", 0, -12)
UnitDropDown:SetPoint("TOPLEFT", UnitDropDownLabel, "BOTTOMLEFT", 0, -8)	Enabled:SetPoint("TOPLEFT", UnitDropDownLabel, "BOTTOMLEFT", 200, -8)

AnchorDropDownLabel:SetPoint("TOPLEFT", UnitDropDown, "BOTTOMLEFT", 0, -12)	--StrataDropDownLabel:SetPoint("TOPLEFT", UnitDropDown, "BOTTOMLEFT", 200, -12)
AnchorDropDown:SetPoint("TOPLEFT", AnchorDropDownLabel, "BOTTOMLEFT", 0, -8)	--StrataDropDown:SetPoint("TOPLEFT", StrataDropDownLabel, "BOTTOMLEFT", 0, -8)

SizeSlider:SetPoint("TOPLEFT", AnchorDropDown, "BOTTOMLEFT", 0, 0)		AlphaSlider:SetPoint("TOPLEFT", AnchorDropDown, "BOTTOMLEFT", 200, 0)

-------------------------------------------------------------------------------
OptionsPanel.default = function() -- This method will run when the player clicks "defaults".
	_G.LoseControlDB.version = nil
	LoseControl:ADDON_LOADED(L)
	for _, v in pairs(LC) do
		v:PLAYER_ENTERING_WORLD()
	end
end

OptionsPanel.refresh = function() -- This method will run when the Interface Options frame calls its OnShow function and after defaults have been applied via the panel.default method described above, and after the Unit Configuration dropdown is changed.
	local tracking = LoseControlDB.tracking
	local unit = UIDropDownMenu_GetSelectedValue(UnitDropDown)
	local frame = LoseControlDB.frames[unit]
	DisableCooldownCount:SetChecked(LoseControlDB.noCooldownCount)
	TrackCCs:SetChecked(tracking[CC])
	TrackSilences:SetChecked(tracking[Silence])
	TrackDisarms:SetChecked(tracking[Disarm])
	TrackRoots:SetChecked(tracking[Root])
	TrackSnares:SetChecked(tracking[Snare])
	TrackImmune:SetChecked(tracking[Immune])
	TrackPvE:SetChecked(tracking[PvE])
	if frame then
	Enabled:SetChecked(frame.enabled)
	Enabled:OnClick()
	AnchorDropDown:initialize()
	UIDropDownMenu_SetSelectedValue(AnchorDropDown, frame.anchor)
	StrataDropDown:initialize()
	UIDropDownMenu_SetSelectedValue(StrataDropDown, frame.strata or "LOW")
	SizeSlider:SetValue(frame.size)
	AlphaSlider:SetValue(frame.alpha * 100)
	end
end

InterfaceOptions_AddCategory(OptionsPanel)

-------------------------------------------------------------------------------
SLASH_LoseControl1 = "/lc"
SLASH_LoseControl2 = "/losecontrol"
SlashCmdList[L] = function(cmd)
	cmd = cmd:lower()
	if cmd == "reset" then
		OptionsPanel.default()
		OptionsPanel.refresh()
	elseif cmd == "lock" then
		Unlock:SetChecked(false)
		Unlock:OnClick()
		log(L .. " locked.")
	elseif cmd == "unlock" then
		Unlock:SetChecked(true)
		Unlock:OnClick()
		log(L .. " unlocked.")
	elseif cmd:sub(1, 6) == "enable" then
		local unit = cmd:sub(8, 14)
		if LoseControlDB.frames[unit] then
			LoseControlDB.frames[unit].enabled = true
			log(L .. ": " .. unit .. " frame enabled.")
		end
	elseif cmd:sub(1, 7) == "disable" then
		local unit = cmd:sub(9, 15)
		if LoseControlDB.frames[unit] then
			LoseControlDB.frames[unit].enabled = false
			log(L .. ": " .. unit .. " frame disabled.")
		end
	elseif cmd:sub(1, 4) == "help" then
		log(L .. " slash commands:")
		log("    reset")
		log("    lock")
		log("    unlock")
		log("    enable <unit>")
		log("    disable <unit>")
		log("<unit> can be: player, party1 ... party4, arena1 ... arena5")
	else
		log(L .. ": Type \"/lc help\" for more options.")
		InterfaceOptionsFrame_OpenToFrame(OptionsPanel)
	end
end
