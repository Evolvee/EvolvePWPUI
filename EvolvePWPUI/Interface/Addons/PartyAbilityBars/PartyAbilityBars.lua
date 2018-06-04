
local lower = string.lower
local match = string.match
local remove = table.remove
local GetSpellInfo = GetSpellInfo
local UnitClass = UnitClass
local UnitGUID = UnitGUID
local UnitName = UnitName
local IsInInstance = IsInInstance  
local SendAddonMessage = SendAddonMessage
local GetNumPartyMembers = GetNumPartyMembers
local CooldownFrame_SetTimer = CooldownFrame_SetTimer

local SPELLIDUPPER = 60000
local CommPrefix  = "PABx39dkes8xj" -- Receive ability and cooldown
local CommPrefix2 = "PAB935ndd8xid" -- Send GUID for syncing
local CommPrefix3 = "PABkd8cjnwuid" -- Receive GUID for syncing

local db
local pGUID
local pName

local PAB = CreateFrame("Frame","PAB",UIParent)
local PABIcons = CreateFrame("Frame",nil,UIParent)
local PABAnchor = CreateFrame("Frame",nil,UIParent)

local iconlist = {}
local anchors = {}
local syncGUIDS = {}
local activeGUIDS = {}

local function log(msg) DEFAULT_CHAT_FRAME:AddMessage(msg) end -- alias for convenience

local function print(...)
	for i=1,select('#',...) do
		ChatFrame1:AddMessage("|cff33ff99PAB|r: " .. select(i,...))
	end
end

local InArena = function() return (select(2,IsInInstance()) == "arena") end

local function wipe(t)
	for k,v in pairs(t) do
		t[k]=nil
	end
end

local _iconPaths = {}
local iconPaths = {
	[20594] = 1, -- Stoneform
	[25275] = 15, -- Intercept
	[43443] = 10, -- Spell Reflection
	[3411] = 30, -- Intervene
	[29166] = 360, -- Innervate
	[8983] = 60, -- Bash
	[14311] = 30, -- Freezing Trap
	[19503] = 30, -- Scatter Shot
	[27068] = 180, -- Wyvern Sting
	[2139] = 24, -- Counterspell
	[45438] = 300, -- Ice Block
	[27088] = 21, -- Frostnova
	[11958] = 384, -- Cold Snap
	[10308] = 50, -- Hammer of Justice
	[1044] = 25, -- Hand of Freedom
	[27148] = 30, -- Blessing of Sacrifice
	[10278] = 180, -- Blessing of Protection
	[1020] = 300, -- Divine Shield
	[25454] = 6, -- Earth Shock
	[16190] = 300, -- Manatide
	[10890] = 27, -- Psychic Scream
	[33206] = 120, -- Pain Suppression
	[10060] = 180, -- Power Infusion
	[34433] = 300, -- Shadowfiend
	[2094] = 90, -- Blind
	[26889] = 210, -- Vanish
	[14185] = 600, -- Preparation
	[31224] = 60, -- Cloak of Shadows	
	[19647] = 24, -- Spell Lock
	[17925] = 120, -- Death Coil
	[7744] = 120, -- Will of the Forsaken
	[28730] = 120, -- Arcane Torrent
	[20549] = 120, -- War Stomp
	[20594] = 180, -- Stoneform
}
for k in pairs(iconPaths) do _iconPaths[GetSpellInfo(k)] = select(3,GetSpellInfo(k)) end
iconPaths = _iconPaths

local defaultAbilities = {
	["DRUID"] = {
		[29166] = 360, -- Innervate
		[8983] = 60, -- Bash	
	},
	["HUNTER"] = {
		[14311] = 30, -- Freezing Trap
		[19503] = 30, -- Scatter Shot
		[27068] = 180, -- Wyvern Sting
	},
	["MAGE"] = 	{
		[2139] = 24, -- Counterspell
		[45438] = 300, -- Ice Block
		[27088] = 21, -- Frostnova
		[11958] = 384, -- Cold Snap
	},
	["PALADIN"] = {
		[10308] = 50, -- Hammer of Justice
		[1044] = 25, -- Hand of Freedom
		[27148] = 30, -- Blessing of Sacrifice
		[10278] = 180, -- Blessing of Protection
		[1020] = 300, -- Divine Shield
	},
	["PRIEST"] = {
		[10890] = 27, -- Psychic Scream
		[33206] = 120, -- Pain Suppression
		[10060] = 180, -- Power Infusion
		[34433] = 300, -- Shadowfiend
	}, 	
	["ROGUE"] = {
		[2094] = 90, -- Blind
		[26889] = 210, -- Vanish
		[14185] = 600, -- Preparation
		[31224] = 60, -- Cloak of Shadows
	},
	["SHAMAN"] = {
		[25454] = 6, -- Earth Shock
		[16190] = 300 -- Manatide
	},
	["WARLOCK"] = {
		[19647] = 24, -- Spell Lock
		[17925] = 120, -- Death Coil
	},
	["WARRIOR"] = {
		[25275] = 15, -- Intercept
		[43443] = 10, -- Spell Reflection
		[3411] = 30, -- Intervene
	},
	["Scourge"] = {
		[7744] = 120, -- Will of the Forsaken
	},
	["BloodElf"] = {
		[28730] = 120, -- Arcane Torrent
	},
	["Tauren"] = {
		[20549] = 120, -- War Stomp
	},
	["Orc"] = {
		
	},
	["Troll"] = {
		
	},
	["NightElf"] = {
		
	},
	["Draenei"] = {
		
	},
	["Human"] = {
		
	},
	["Gnome"] = {
		
	},
	["Dwarf"] = {
		[20594] = 180, -- Stoneform
	},
}

function convertspellids(t)
	local temp = {}
	for class,table in pairs(t) do
		temp[class] = {}
		for k,v in pairs(table) do
			temp[class][GetSpellInfo(k)] = v
		end
	end
	return temp
end

defaultAbilities = convertspellids(defaultAbilities)

local groupedCooldowns = {
	["SHAMAN"] = {
		[25454] = 1, -- Earth Shock
		[25457] = 1, -- Flame Shock
		[25464] = 1, -- Frost Shock
	},
	["HUNTER"] = {
		[27025] = 1, -- Explosive Trap
		[27753] = 1, -- Freezing Trap
		[13809] = 1, -- Frost Trap
		[27023] = 1, -- Immolation Trap
		[34600] = 1, -- Snake Trap
	},
	["MAGE"] = {
		[27128] = 1,  -- Fire Ward
		[32796] = 1,  -- Frost Ward
	},
}

groupedCooldowns = convertspellids(groupedCooldowns)

local cooldownResetters = {
	[11958] = { -- Cold Snap
		[27078] = 1, -- Cone of Cold
		[27088] = 1,  -- Frost Nova
		[32796] = 1,  -- Frost Ward
		[33405] = 1, -- Ice Barrier
		[45438] = 1,  -- Ice Block
		[31687] = 1, -- Summon Water Elemental
		[12472] = 1, -- Icy Veins
	},
	[14185] = { -- Preparation
		[14177] = 1, -- Cold Blood
		[26669] = 1,  -- Evasion
		[11305] = 1,  -- Sprint
		[26889] = 1, -- Vanish
		[36554] = 1, -- Shadowstep
	},
	[23989] = "ALL", -- Readiness
}

local temp = {}
for k,v in pairs(cooldownResetters) do
	temp[GetSpellInfo(k)] = {}
	if type(v) == "table" then
		for id in pairs(v) do
			temp[GetSpellInfo(k)][GetSpellInfo(id)] = 1
		end
	else
		temp[GetSpellInfo(k)] = v
	end
end

cooldownResetters = temp
temp = nil
convertspellids = nil

function PAB:SavePositions()
	for k,anchor in ipairs(anchors) do
		local scale = anchor:GetEffectiveScale()
		local worldscale = UIParent:GetEffectiveScale()
		local x = anchor:GetLeft() * scale
		local y = (anchor:GetTop() * scale) - (UIParent:GetTop() * worldscale)
	
		if not db.positions[k] then
			db.positions[k] = {}
		end
	
		db.positions[k].x = x
		db.positions[k].y = y
	end
end

function PAB:LoadPositions()
	db.positions = db.positions or {}
	for k,anchor in ipairs(anchors) do
		if db.positions[k] then
			local x = db.positions[k].x
			local y = db.positions[k].y
			local scale = anchors[k]:GetEffectiveScale()
			anchors[k]:SetPoint("TOPLEFT", UIParent,"TOPLEFT", x/scale, y/scale)
		else
			anchors[k]:SetPoint("CENTER", UIParent, "CENTER")
		end
	end
end

local backdrop = {bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="", tile=false,}
function PAB:CreateAnchors()
	for i=1,4 do
		local anchor = CreateFrame("Frame","PABAnchor"..i ,PABAnchor)
		anchor:SetBackdrop(backdrop)
		anchor:SetHeight(15)
		anchor:SetWidth(15)
		anchor:SetBackdropColor(1,0,0,1)
		anchor:EnableMouse(true)
		anchor:SetMovable(true)
		anchor:Show()
		anchor.icons = {}
		anchor.HideIcons = function() for k,icon in ipairs(anchor.icons) do icon:Hide(); icon.shouldShow = nil end end
		anchor:SetScript("OnMouseDown",function(self,button) if button == "LeftButton" then self:StartMoving() end end)
		anchor:SetScript("OnMouseUp",function(self,button) if button == "LeftButton" then self:StopMovingOrSizing(); PAB:SavePositions() end end)
		anchors[i] = anchor
		
		local index = anchor:CreateFontString(nil,"ARTWORK","GameFontNormal")
		index:SetPoint("CENTER")
		index:SetText(i)
	end
end

local function CreateIcon(anchor)
	local icon = CreateFrame("Frame",anchor:GetName().."Icon".. (#anchor.icons+1),PABIcons)
	icon:SetHeight(30)
	icon:SetWidth(30)
		
	local cd = CreateFrame("Cooldown",icon:GetName().."Cooldown",icon,"CooldownFrameTemplate")
	icon.cd = cd
	
	icon.Start = function(sentCD)
		icon.cooldown = tonumber(sentCD);
		CooldownFrame_SetTimer(cd,GetTime(),icon.cooldown,1); 
		icon:Show(); 
		icon.active = true; 
		icon.starttime = GetTime()+0.4 
		activeGUIDS[icon.GUID][icon.ability] = activeGUIDS[icon.GUID][icon.ability] or {}
		activeGUIDS[icon.GUID][icon.ability].starttime = icon.starttime
		activeGUIDS[icon.GUID][icon.ability].cooldown =  icon.cooldown
	end
	
	icon.Stop = function() 
		CooldownFrame_SetTimer(cd,0,0,0); 
		icon.starttime = 0
	end
	
	icon.SetTimer = function(starttime,cooldown)
		CooldownFrame_SetTimer(cd,starttime,cooldown,1)
		icon.active = true
		icon.starttime = starttime
		icon.cooldown = cooldown
	end
	
	local texture = icon:CreateTexture(nil,"ARTWORK")
	texture:SetAllPoints(true)
	texture:SetTexCoord(0.07,0.9,0.07,0.90)
	icon.texture = texture

	return icon
end

function PAB:AppendIcon(icons,anchor)
	local newicon = CreateIcon(anchor)
	iconlist[#iconlist+1] = newicon
	if #icons == 0 then
		newicon:SetPoint("TOPLEFT",anchor,"BOTTOMRIGHT")
	else
		newicon:SetPoint("LEFT",icons[#icons],"RIGHT")
	end
	icons[#icons+1] = newicon
	return newicon
end

function PAB:RequestSync()
	wipe(syncGUIDS)
	SendAddonMessage(CommPrefix2, pGUID, "PARTY")
end

function PAB:ShowUsedAnchors()
	for i=1,GetNumPartyMembers() do anchors[i]:Show() end
end

function PAB:HideUnusedAnchors()
	for k=GetNumPartyMembers()+1,#anchors do
		anchors[k]:Hide()
		anchors[k].HideIcons()
	end
end

function PAB:HideUnusedIcons(numIcons,icons)
	for j=numIcons,#icons do
		icons[j]:Hide()
		icons[j].shouldShow = nil
	end
end

function PAB:UpdateAnchors()
	for i=1,GetNumPartyMembers() do
		local _,class = UnitClass("party"..i)
		if not class then return end
		local anchor = anchors[i]
		anchor.GUID = UnitGUID("party"..i)
		anchor.class = select(2,UnitClass("party"..i))
		local abilities = db.abilities[class]
		-- uses races as well as classes no unique combinations of class+race like "Nightelf Priest" possible
		anchor.race = select(2,UnitRace("party"..i))
		local abilities = { }
		for k, v in pairs(db.abilities) do
			if k == class or k == anchor.race then
				for ke, va in pairs(v) do
					abilities[ke]=va
				end
			end
		end
		local icons = anchor.icons 
		local numIcons = 1
		for ability,cooldown in pairs(abilities) do
			local icon = icons[numIcons] or self:AppendIcon(icons,anchor)
			icon.texture:SetTexture(self:FindAbilityIcon(ability))
			icon.GUID = anchor.GUID
			icon.ability = ability
			icon.cooldown = cooldown
			icon.shouldShow = true
			activeGUIDS[icon.GUID] = activeGUIDS[icon.GUID] or {}
			if activeGUIDS[icon.GUID][icon.ability] then
				icon.SetTimer(activeGUIDS[icon.GUID][ability].starttime,activeGUIDS[icon.GUID][ability].cooldown)
			else
				icon.Stop()
			end
			numIcons = numIcons + 1
		end
		self:HideUnusedIcons(numIcons,icons)
	end
	self:ShowUsedAnchors()
	self:HideUnusedAnchors()

	self:ApplyAnchorSettings()
end

function PAB:ApplyAnchorSettings()
	PABIcons:SetScale(db.scale or 1)
	
	if db.arena then
		if InArena() then
			PABIcons:Show()
		else
			PABIcons:Hide()
		end
	else
		PABIcons:Show()
	end

	for k,v in ipairs(anchors) do
		for k,v in ipairs(v.icons) do
			if db.hidden and not v.active then
				v:Hide()
			elseif v.shouldShow then
				v:Show()
			end
		end
	end	
	
	if db.lock then PABAnchor:Hide() else PABAnchor:Show() end
end

function PAB:PARTY_MEMBERS_CHANGED()
	if not pGUID then pGUID = UnitGUID("player") end
	if not pName then pName = UnitName("player") end
	self:RequestSync()
	self:UpdateAnchors()
end

function PAB:PLAYER_ENTERING_WORLD()
	if InArena() then self:StopAllIcons() end -- Cooldowns reset when joining arena
	if not pGUID then pGUID = UnitGUID("player") end
	if not pName then pName = UnitName("player") end
	self:RequestSync()
	self:UpdateAnchors()
end

function PAB:CheckAbility(anchor,ability,cooldown,pIndex)
	if not cooldown then return end
	for k,icon in ipairs(anchor.icons) do
		-- Direct cooldown
		if icon.ability == ability and icon.shouldShow then icon.Start(cooldown) end
		-- Grouped Cooldowns
		if groupedCooldowns[anchor.class] and groupedCooldowns[anchor.class][ability] then
			for k in pairs(groupedCooldowns[anchor.class]) do
				if k == icon.ability and icon.shouldShow then icon.Start(cooldown); break end
			end
		end
		-- Cooldown resetters
		if cooldownResetters[ability] then
			if type(cooldownResetters[ability]) == "table" then
				for k in pairs(cooldownResetters[ability]) do
					if k == icon.ability then icon.Stop(); break end
				end
			else
				icon.Stop()
			end
		end
	end
end

function PAB:CHAT_MSG_ADDON(prefix, message, dist, sender)
	if dist == "PARTY" and sender ~= pName then
		if prefix == CommPrefix then
			local GUID,ability,cooldown = match(message,"(.+)|(.+)|(.+)")
			if syncGUIDS[GUID] then self:CheckAbility(syncGUIDS[GUID],ability,cooldown) end
		elseif prefix == CommPrefix2 then
			SendAddonMessage(CommPrefix3, pGUID, "PARTY")
		elseif prefix == CommPrefix3 then
			for i=1,GetNumPartyMembers() do if UnitGUID("party"..i) == message then syncGUIDS[message] = anchors[i] end end
		end
	end
end

function PAB:SendCooldownMessage(ability,cooldown)
	SendAddonMessage(CommPrefix, pGUID.."|"..ability.."|"..cooldown, "PARTY")
end

function PAB:SendCooldown(ability,rep)
	local start, duration, enabled = GetSpellCooldown(ability)
	if not start then return end
	if enabled == 0 or not rep then self:Schedule(0.1,self.SendCooldown,ability,true) return 
	elseif start > 0 and duration > 0 then
		self:SendCooldownMessage(ability,start + duration - GetTime())
	end
end

function PAB:UNIT_SPELLCAST_SUCCEEDED(unit,ability)
--works only for player in TBC??
	if syncGUIDS[UnitGUID(unit)] then return end
	if unit == "player" then self:SendCooldown(ability) return end
	local pIndex = match(unit,"party[pet]*([1-4])")
	if pIndex and ability then
		local _,class = UnitClass("party"..pIndex)
		local _,race = UnitRace("party"..pIndex)
		self:CheckAbility(anchors[tonumber(pIndex)],ability,db.abilities[class][ability],pIndex) 
		self:CheckAbility(anchors[tonumber(pIndex)],ability,db.abilities[race][ability],pIndex) 
	end
end

function PAB:COMBAT_LOG_EVENT_UNFILTERED(event , ...)
local event, sourceGUID,sourceName,sourceFlags,destGUID,destName,destFlags,spellID,spellName = select ( 1 , ... )
	if syncGUIDS[sourceGUID] then return end
	local pIndex
	for i=1, 4 do
		if sourceGUID == UnitGUID("party"..i) or sourceGUID == UnitGUID("partypet"..i) then
			pIndex = i
		end
	end
	if pIndex and spellName then
		local _,class = UnitClass("party"..pIndex)
		local _,race = UnitRace("party"..pIndex)
		self:CheckAbility(anchors[tonumber(pIndex)],spellName,db.abilities[class][spellName],pIndex) 
		self:CheckAbility(anchors[tonumber(pIndex)],spellName,db.abilities[race][spellName],pIndex) 
	end
end

local timers, timerfuncs, timerargs = {}, {}, {}
function PAB:Schedule(duration,func,...)
	timers[#timers+1] = duration
	timerfuncs[#timerfuncs+1] = func
	timerargs[#timerargs+1] = {...}
end

local time = 0
local function PAB_OnUpdate(self,elapsed)
	time = time + elapsed
	if time > 0.05 then
		--  Update Icons
		for k,icon in ipairs(iconlist) do
			if icon.active then
				icon.timeleft = icon.starttime + icon.cooldown - GetTime()
				if icon.timeleft <= 0 then
					if db.hidden then icon:Hide() end
					activeGUIDS[icon.GUID][icon.ability] = nil
					icon.active = nil
				end
			end
		end
		
		-- Update Timers
		if #timers > 0 then
			for i=#timers,1,-1 do 
				timers[i] = timers[i] - 0.05
				if timers[i] <= 0 then
					remove(timers,i)
					remove(timerfuncs,i)(PAB,unpack(remove(timerargs,i)))
				end
			end
		end
		
		time = 0
	end
end

function PAB:StopAllIcons()
	for k,v in ipairs(iconlist) do v.Stop() end
	wipe(activeGUIDS)
end

local function PAB_OnLoad(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:SetScript("OnEvent",function(self,event,...) if self[event] then self[event](self,...) end end)
	
	PABDB = PABDB or { abilities = defaultAbilities, scale = 1  }
	db = PABDB

	self:CreateAnchors()
	self:UpdateAnchors()
	self:LoadPositions()
	self:CreateOptions()
	
	self:SetScript("OnUpdate",PAB_OnUpdate)
	
	print("Party Ability Bars. Type /pab to open options")
end

function PAB:FindAbilityIcon(ability)
	if iconPaths[ability] then return iconPaths[ability] end
	for id=SPELLIDUPPER,1,-1 do
		local _ability,_,_icon = GetSpellInfo(id)
		if _ability and _ability == ability then
			iconPaths[ability] = _icon
			return _icon
		end
	end
end

function PAB:FormatAbility(s)
	s = s:gsub("(%a)(%a*)('*)(%a*)", function (a,b,c,d) return a:upper()..b:lower()..c..d:lower() end)
	s = s:gsub("(The)", string.lower)
	s = s:gsub("(Of)", string.lower)
	return s
end

-------------------------------------------------------------
-- Options
-------------------------------------------------------------

local SO = LibStub("LibSimpleOptions-1.0")

function PAB:CreateOptions()
	local panel = SO.AddOptionsPanel("PAB", function() end)
	self.panel = panel
	SO.AddSlashCommand("PAB","/pab")
	local title, subText = panel:MakeTitleTextAndSubText("Party Ability Bars","General settings")
	local scale = panel:MakeSlider(
	     'name', 'Scale',
	     'description', 'Adjust the scale of icons',
	     'minText', '0.1',
	     'maxText', '5',
	     'minValue', 0.1,
	     'maxValue', 5,
	     'step', 0.05,
	     'default', 1,
	     'current', db.scale,
	     'setFunc', function(value) db.scale = value; PAB:ApplyAnchorSettings() end,
	     'currentTextFunc', function(value) return string.format("%.2f",value) end)
	scale:SetPoint("TOPLEFT",subText,"TOPLEFT",16,-32)
	
	local lock = panel:MakeToggle(
	     'name', 'Lock',
	     'description', 'Show/hide anchors',
	     'default', false,
	     'getFunc', function() return db.lock end,
	     'setFunc', function(value) db.lock = value; PAB:ApplyAnchorSettings() end)
	     
	lock:SetPoint("TOP",panel,"TOP",10,-36)
	
	local arena = panel:MakeToggle(
	     'name', 'Arena',
	     'description', 'Show in arena only',
	     'default', false,
	     'getFunc', function() return db.arena end,
	     'setFunc', function(value) db.arena = value; PAB:ApplyAnchorSettings() end)
	arena:SetPoint("TOP",lock,"BOTTOM",0,-5)
	
	local hidden = panel:MakeToggle(
	     'name', 'Hidden',
	     'description', 'Show icon only when on cooldown',
	     'default', false,
	     'getFunc', function() return db.hidden end,
	     'setFunc', function(value) db.hidden = value; PAB:ApplyAnchorSettings() end)
	hidden:SetPoint("LEFT",lock,"RIGHT",50,0)
	
	local title2, subText2 = panel:MakeTitleTextAndSubText("Ability editor","Change what party member abilities are tracked")
	title2:ClearAllPoints()
	title2:SetPoint("LEFT",panel,"LEFT",16,80)
	subText2:ClearAllPoints()
	subText2:SetPoint("TOPLEFT",title2,"BOTTOMLEFT",0,-8)
	
	self:CreateAbilityEditor()
end

local function count(t) local i = 0 for k,v in pairs(t) do i = i + 1 end return i end

function PAB:UpdateScrollBar()
	local btns = self.btns
	local scrollframe = self.scrollframe
	local classSelectedTable = db.abilities[db.classSelected]
	local classSelectedTableLength = count(db.abilities[db.classSelected])
	FauxScrollFrame_Update(scrollframe,classSelectedTableLength,10,16,nil,nil,nil,nil,nil,nil,true);
	local line = 1
	for ability,cooldown in pairs(classSelectedTable) do
		lineplusoffset = line + FauxScrollFrame_GetOffset(scrollframe)
		btns[line]:SetText(ability)
		if btns[line]:GetText() ~= scrollframe.currentButton then
			btns[line]:SetNormalTexture("")
		else 
			btns[line]:SetNormalTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
			btns[line]:GetNormalTexture():SetBlendMode("ADD") 
			scrollframe.addeditbox:SetText(ability)
			scrollframe.cdeditbox:SetText(cooldown)
		end
		btns[line]:Show()
		line = line + 1
	end
	for i=line,10 do btns[i]:Hide() end
end

function PAB:OnVerticalScroll(offset,itemHeight)
	local scrollbar = _G[self.scrollframe:GetName().. "ScrollBar"]
	scrollbar:SetValue(offset);
	self.scrollframe.offset = floor((offset / itemHeight) + 0.5);
	self:UpdateScrollBar()
end

local function CreateListButton(parent,index)
	local button = CreateFrame("Button",parent:GetName()..index,parent)
	button:SetWidth(130)
	button:SetHeight(16)
	local font = CreateFont("PABListFont")
	font:SetFont(GameFontNormal:GetFont(),12)
	font:SetJustifyH("LEFT")
	button:SetFont(GameFontNormal:GetFont(), 12)
	button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
	button:SetScript("OnClick",function(self) parent.currentButton = self:GetText(); PAB:UpdateScrollBar() end)
	return button
end

local function CreateEditBox(name,parent,width,height)
	local editbox = CreateFrame("EditBox",parent:GetName()..name,parent,"InputBoxTemplate")
	editbox:SetHeight(height)
	editbox:SetWidth(width)
	editbox:SetAutoFocus(false)
	
	local label = editbox:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	label:SetText(name)
	label:SetPoint("BOTTOMLEFT", editbox, "TOPLEFT",-3,0)
	return editbox
end

function PAB:CreateAbilityEditor()
	local panel = self.panel
	local btns = {}
	self.btns = btns
	local scrollframe = CreateFrame("ScrollFrame", "PABScrollFrame",panel,"FauxScrollFrameTemplate")
	local button1 = CreateListButton(scrollframe,"1")
	button1:SetPoint("TOPLEFT",scrollframe,"TOPLEFT",11,0)
	btns[#btns+1] = button1
	for i=2,10 do
		local button = CreateListButton(scrollframe,tostring(i))
		button:SetPoint("TOPLEFT",btns[#btns],"BOTTOMLEFT")
		btns[#btns+1] = button
	end
	
	scrollframe:SetWidth(150); 
	scrollframe:SetHeight(160)
	scrollframe:SetPoint('LEFT',16,-45)
	scrollframe:SetBackdrop(backdrop)
	scrollframe:SetBackdropColor(.6,.6,.6,0.25)
	scrollframe:SetScript("OnVerticalScroll", function(self,offset) PAB:OnVerticalScroll(offset,16) end)
	scrollframe:SetScript("OnShow",function(self) if not db.classSelected then db.classSelected = "WARRIOR" end; PAB:UpdateScrollBar();  end)
	
	self.scrollframe = scrollframe
	
	local dropdown = panel:MakeDropDown(
       'name', 'Class',
	     'description', 'Pick a class to edit the ability list',
	     'values', {
					"WARRIOR", "Warrior",
					"PALADIN", "Paladin",
					"PRIEST", "Priest",
					"SHAMAN", "Shaman",
					"DRUID", "Druid",
					"ROGUE", "Rogue",
					"MAGE", "Mage",
					"WARLOCK", "Warlock",
					"HUNTER", "Hunter",
					"Dwarf", "Dwarf",
					"BloodElf", "Bloodelf",
					"Scourge", "Undead",
					"Tauren", "Tauren",
					"NightElf", "Nightelf",
					"Draenei", "Draenei",
					"Human", "Human",
					"Gnome", "Gnome",
					"Orc", "Orc",
					"Troll", "Troll",
	      },
	     'default', 'WARRIOR',
	     'getFunc', function() return db.classSelected end ,
	     'setFunc', function(value) db.classSelected = value; PAB:UpdateScrollBar(); end)
		
	dropdown:SetPoint("TOPLEFT",scrollframe,"TOPRIGHT",20,-8)
	local addeditbox = CreateEditBox("Ability name",scrollframe,120,25)
	scrollframe.addeditbox = addeditbox
	
	addeditbox:SetPoint("TOPLEFT",dropdown,"BOTTOMLEFT",20,-15)
	local cdeditbox = CreateEditBox("CD (s)",scrollframe,50,25)
	cdeditbox:SetPoint("LEFT",addeditbox,"RIGHT",15,0)
	scrollframe.cdeditbox = cdeditbox
	
	local addbutton = panel:MakeButton(
	     'name', 'Add/Edit',
	     'description', "Add a new ability with a specified cooldown. Don't worry about capitalization, the ability will be properly formatted",
	     'func', function() 
	     		local ability = PAB:FormatAbility(addeditbox:GetText())
	     		local iconfound = PAB:FindAbilityIcon(ability)
	     		local cdtext = cdeditbox:GetText():match("^[0-9]+$")
	     		if iconfound and cdtext then
	     			print("Added/updated "..ability)
	     			db.abilities[db.classSelected][ability] = tonumber(cdtext)
	     			scrollframe.currentButton = ability
	     			PAB:UpdateScrollBar()
	     			PAB:UpdateAnchors()
	     		else
	     			print("Invalid spell name and/or cooldown")
	     		end
	      end
	)
	addbutton:SetPoint("TOPLEFT",addeditbox,"BOTTOMLEFT",-5,0)
	
	local removebutton = panel:MakeButton(
	     'name', 'Remove',
	     'description', 'Remove the selected ability',
	     'func', function()
	     		 print("Removed " .. addeditbox:GetText())
	     		 db.abilities[db.classSelected][addeditbox:GetText()] = nil; 
	     		 addeditbox:SetText(""); 
	     		 cdeditbox:SetText(""); 
	     		 scrollframe.currentButton = nil; 
	     		 PAB:UpdateScrollBar(); 
	     		 PAB:UpdateAnchors() 
	     end
	)
	removebutton:SetPoint("TOPLEFT",addbutton,"BOTTOMLEFT",0,-5)
	
	local description =  panel:CreateFontString(nil,"ARTWORK","GameFontNormal")
	description:SetText("Don't worry about the CD number if your party member has the mod. It will ignore the stored CD and instead sync with your teammate.")
	description:SetNonSpaceWrap(true)
	description:SetJustifyH("LEFT")
	description:SetWidth(100)
	description:SetHeight(50)
	description:SetPoint("TOPLEFT",scrollframe,"BOTTOMLEFT",0,-10)
	description:SetPoint("RIGHT", -32, 0)
end

PAB:RegisterEvent("VARIABLES_LOADED")
PAB:SetScript("OnEvent",PAB_OnLoad)
