--[[
Finds enemies in Arena as soon as possible to prevent Gladdy from greying out and making it keybinds available at all times

TO DO:
- Find enemies even if never seen before, only important for Druids, Rogues + Mages
	- Try to find specifics from Combatlog
	- e.g. if casting Regrowth = druid
- let the user call RequestBattlefieldScoreData() by hand instead of when the doors open
- install menu that lets the user enter enemies (no GUID?) by hand
	- if no GUID, gladdy will add enemies twice, but "name" clicks work
- function that inserts your target in a certain bracket (2v2, 3v3)	

]]

local Gladdy = LibStub("Gladdy")
local ArenaIdentify = Gladdy:NewModule("ArenaIdentify", nil, {
    scanTable = {},
    guidsByName = {},
})
function ArenaIdentify:OnEvent(event, ...) -- functions created in "object:method"-style have an implicit first parameter of "self", which points to object
	self[event](self, ...) -- route event parameters to LoseControl:event methods
end
ArenaIdentify:SetScript("OnEvent", ArenaIdentify.OnEvent)
ArenaIdentify:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ArenaIdentify:RegisterEvent("PLAYER_ENTERING_WORLD")

local instanceType, bracket
local alreadyLoaded = {}
local alreadyFound = {}
local alreadySaved = {}

function ArenaIdentify:GuidInParty(guid)
	local inParty = 0
	for i=0, GetNumPartyMembers() do
		if UnitGUID("party"..i) == guid then
			inParty = 1
		end
	end
	return inParty
end


function ArenaIdentify:Initialise()
	if not Gladdy.db.scanTable[GetRealmName()] then
		Gladdy.db.scanTable[GetRealmName()] = {}
	end
	if not Gladdy.db.guidsByName[GetRealmName()] then
		Gladdy.db.guidsByName[GetRealmName()] = {}
	end
end

function ArenaIdentify:PLAYER_ENTERING_WORLD()
	self:ZONE_CHANGED_NEW_AREA()
end

function ArenaIdentify:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99ArenaIdentify|r: " .. msg)
end

function ArenaIdentify:SendGladdyMessage(msg)
	local name, guid, class, classLoc, raceLoc, race, health, healthMax, power, powerMax, powerType = string.split(",", msg)
    if (Gladdy.guids[guid]) then return end
	local unit = Gladdy:EnemySpotted(name, guid, class, classLoc, raceLoc)
	
    local button = Gladdy.buttons[unit]
    if (not button) then return end
    button.race = race
    button.lastCooldownSpell = 1
	button.health = health
    button.healthMax = healthMax
	Gladdy:SendMessage("UNIT_HEALTH", unit, tonumber(health), tonumber(healthMax))
	button.power = power
    button.powerMax = powerMax
    button.powerType = powerType
	Gladdy:SendMessage("UNIT_POWER", unit, tonumber(power), tonumber(powerMax), tonumber(powerType))
	Gladdy:UpdateCooldowns(button)
end

function ArenaIdentify:ScanUnits()
	if( not self.tooltip ) then
		self.tooltip = CreateFrame("GameTooltip", "ArenaIdentifyTooltip", UIParent, "GameTooltipTemplate")
		self.tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	end
	for _, data in pairs(Gladdy.db.scanTable[GetRealmName()]) do
		local name, guid, class, classLoc, raceLoc, spec, health, healthMax, power, powerMax, powerType = string.split(",", data)
		if( not alreadyFound[guid] and instanceType == "arena" ) then
			self.tooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
			self.tooltip:SetHyperlink(string.format("unit:%s", guid))
			
			
			local name, unitid = self.tooltip:GetUnit()
			self.tooltip:Hide()
			
			if( name and not UnitInParty(name) and self:GuidInParty(guid) == 0 ) then
				alreadyFound[guid] = true
				
				-- Send data to Gladdy
				self:SendGladdyMessage(data)
			end
		end
	end
end

-- Get enemy/team mate races
function ArenaIdentify:PLAYER_TARGET_CHANGED()
	self:ScanUnit("target")
end

function ArenaIdentify:UPDATE_MOUSEOVER_UNIT()
	self:ScanUnit("mouseover")
end

function ArenaIdentify:PLAYER_FOCUS_CHANGED()
	self:ScanUnit("focus")
end

function ArenaIdentify:ScanUnit(unit)
	local guid = UnitGUID(unit)
	if( not alreadySaved[guid] and UnitIsPlayer(unit) and UnitIsEnemy("player", unit) and not UnitIsCharmed(unit) and not UnitIsCharmed("player")) then
		local name, _ = UnitName(unit)
		local classLoc, class = UnitClass(unit)
		local powerType = UnitPowerType(unit) or 0
		local raceLoc, race = UnitRace(unit)
		Gladdy.db.scanTable[GetRealmName()][guid] = string.format("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s", name, guid, class, classLoc, raceLoc, race, "100", "100", "100", "100", powerType)
		Gladdy.db.guidsByName[GetRealmName()][name] = guid
		alreadySaved[guid] = true
	end
end

--[[ Check if match has started -- this is blizzlike, however some servers let you target players and read the combatlog before the arena starts]]
function ArenaIdentify:CHAT_MSG_BG_SYSTEM_NEUTRAL(event, msg)
	if( msg == "The Arena battle has begun!" ) then
		-- new request to catch late joiners
		-- cannot request on every update for some reason
		RequestBattlefieldScoreData()
	end
end

-- Are we inside an arena?
local timeElapsed = 0
function ArenaIdentify:ZONE_CHANGED_NEW_AREA()
	local type = select(2, IsInInstance())
	-- Inside an arena, but wasn't already
	if( type == "arena" and type ~= instanceType --[[and select(2, IsActiveBattlefieldArena())]] ) then
		--self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
		self:RegisterEvent("PLAYER_FOCUS_CHANGED")
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
		
		-- Figure out the arena bracket
		bracket = 2
		for i=1, MAX_BATTLEFIELD_QUEUES do
			local status, _, _, _, _, teamSize = GetBattlefieldStatus(i)
			if( status == "active" and teamSize > 0 ) then
				bracket = teamSize
				break
			end
		end
		
	-- Was in an arena, but left it
	elseif( type ~= "arena" and instanceType == "arena" ) then
		self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
		self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
		
		for k in pairs(alreadyFound) do alreadyFound[k] = nil end
		for k in pairs(alreadySaved) do alreadySaved[k] = nil end
		
		if( self.frame ) then
			self.frame:Hide()
		end
	end
	
	instanceType = type
	if( not self.frame ) then
			self.frame = CreateFrame("Frame")
			self.frame:Hide()
			self.frame:SetScript("OnUpdate", function(self, elapsed)
				timeElapsed = timeElapsed + elapsed
				if( timeElapsed >= 0.1 ) then
					if( InCombatLockdown() ) then
						self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
						self:Hide()
						return
					end
					
					ArenaIdentify:ScanUnits()
					ArenaIdentify:Scoreboard()
					timeElapsed = 0
				end
			end)
		end
		
		timeElapsed = 0.1
		self.frame:Show()
end

function ArenaIdentify:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID,sourceName,sourceFlags,destGUID,destName,destFlags,spellID,spellName, ...)
		if( not alreadyFound[sourceGUID] and instanceType == "arena" and self:GuidInParty(sourceGUID)==0) then
				local data = Gladdy.db.scanTable[GetRealmName()][sourceGUID]
				if data ~= nil then
					local name, guid, class, classLoc, raceLoc, race, health, healthMax, power, powerMax, powerType = string.split(",", data)
					alreadyFound[sourceGUID] = true 
					--v.name, v.guid, v.class, v.classLoc, v.raceLoc, v.spec, v.health, v.healthMax, v.power, v.powerMax, v.powerType
					local msg = string.format("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s", name, guid, class, classLoc, raceLoc, race, health, healthMax, power, powerMax, powerType)
					self:SendGladdyMessage(msg)
				end		
		elseif( not alreadyFound[destGUID] and instanceType == "arena" and self:GuidInParty(destGUID)==0) then
				local data = Gladdy.db.scanTable[GetRealmName()][destGUID]
				if data ~= nil then
					local name, guid, class, classLoc, raceLoc, race, health, healthMax, power, powerMax, powerType = string.split(",", data)
					alreadyFound[destGUID] = true 
					--v.name, v.guid, v.class, v.classLoc, v.raceLoc, v.spec, v.health, v.healthMax, v.power, v.powerMax, v.powerType
					local msg = string.format("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s", name, guid, class, classLoc, raceLoc, race, health, healthMax, power, powerMax, powerType)
					self:SendGladdyMessage(msg)
				end	
		end
end

-- faction 1 = Alliance
-- faction 0 = Horde
function ArenaIdentify:Scoreboard()
	-- find player faction
	if bracket ~=nil then
		--self:Print(playerFaction)
		for i=1, bracket*2+1 do
			local name, killingBlows, honorKills, deaths, honorGained, faction, rank, raceLoc, classLoc, class, damageDone, healingDone = GetBattlefieldScore(i);
			if not name then return end
			local guid = Gladdy.db.guidsByName[GetRealmName()][name]
			if not alreadyFound[guid] and instanceType == "arena" and self:GuidInParty(guid)==0 and UnitGUID("player") ~= guid then
				alreadyFound[guid] = true
				local msg = Gladdy.db.guidsByName[GetRealmName()][guid]
				self:SendGladdyMessage(msg)
			end
		end
	end	
end

function ArenaIdentify:FindPlayerFaction()
	for i=1, bracket*2+1 do
		local name, _, _, _, _, faction =  GetBattlefieldScore(i)
		if name == UnitName("player") then
			return faction
		end
	end
end