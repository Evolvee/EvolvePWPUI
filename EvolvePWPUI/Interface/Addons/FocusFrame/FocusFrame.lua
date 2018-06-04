
-- Localize it for non-English clients.
FOCUSFRAME_TITLE = "Focus";
FOCUSFRAME_DRAG = "Drag to move";
FOCUSFRAME_DRAG_LOCKED = "Use /focusframe unlock to move.";

-- Packages all local variables of FocusFrame Addon.
FocusFrameLocalVariables = {};
local l = FocusFrameLocalVariables;
local i,j,k;

l.MAX_FOCUS_DEBUFFS = 16;
l.MAX_FOCUS_BUFFS = 32;
l.CURRENT_FOCUS_NUM_DEBUFFS = 0;
l.TARGET_BUFFS_PER_ROW = 8;
l.TARGET_DEBUFFS_PER_ROW = 8;
l.LARGE_BUFF_SIZE = 21;
l.LARGE_BUFF_FRAME_SIZE = 23;
l.SMALL_BUFF_SIZE = 17;
l.SMALL_BUFF_FRAME_SIZE = 19;

l.FocusUnitReactionColor = {
	{ r = 1.0, g = 0.0, b = 0.0 },
	{ r = 1.0, g = 0.0, b = 0.0 },
	{ r = 1.0, g = 0.5, b = 0.0 },
	{ r = 1.0, g = 1.0, b = 0.0 },
	{ r = 0.0, g = 1.0, b = 0.0 },
	{ r = 0.0, g = 1.0, b = 0.0 },
	{ r = 0.0, g = 1.0, b = 0.0 },
	{ r = 0.0, g = 1.0, b = 0.0 },
};

l.largeBuffList = {};
l.largeDebuffList = {};

-- Saved variables
FocusFrameOptions = FocusFrameOptions or {};

local function FocusFrame_SlashCommand(msg)
  local cmd,var = strsplit(' ', msg or "")
  if cmd == "scale" and tonumber(var) then
    FocusFrame_SetScale(var);
  elseif cmd == "reset" then
    FocusFrame_Reset();
  elseif cmd == "lock" then
    FocusFrameOptions.lockpos = true;
  elseif cmd == "unlock" then
    FocusFrameOptions.lockpos = nil;
  elseif cmd == "hidewhendead" then
    FocusFrame_HideWhenDead(true);
  else
    FocusFrame_Help();
  end
end
SlashCmdList["FOCUSFRAME"] = FocusFrame_SlashCommand;
SLASH_FOCUSFRAME1 = "/focusframe";

function FocusFrame_Help()
  DEFAULT_CHAT_FRAME:AddMessage('FocusFrame usage:');
  DEFAULT_CHAT_FRAME:AddMessage('/focusframe scale <num> : Set scale (e.g. /focusframe scale 0.7).');
  DEFAULT_CHAT_FRAME:AddMessage('/focusframe reset : Reset position.');
  DEFAULT_CHAT_FRAME:AddMessage('/focusframe lock : Lock position.');
  DEFAULT_CHAT_FRAME:AddMessage('/focusframe unlock : Unlock position.');
  DEFAULT_CHAT_FRAME:AddMessage('/focusframe hidewhendead : Hide when focused enemy target is dead. ['..((FocusFrameOptions.hidewhendead and 'ON') or 'OFF')..']');
end

function FocusFrame_SetScale(scale)
  if InCombatLockdown() then
    DEFAULT_CHAT_FRAME:AddMessage('FocusFrame: You cannot change scale while in combat.');
    return;
  end

  scalenum = tonumber(scale);
  if scalenum and scalenum <= 10 then
    FocusFrameOptions.scale = scalenum;
    local os = FocusFrame:GetScale();
    local ox = FocusFrame:GetLeft();
    local oy = FocusFrame:GetTop();
    FocusFrame:SetScale(scale);
    FocusFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ox*os/scale, oy*os/scale);
  else
    DEFAULT_CHAT_FRAME:AddMessage('Usage: /focusframe scale <num> : Set scale (e.g. /focusframe scale 0.7).');
  end
end

function FocusFrame_Reset()
    FocusFrame:SetPoint("TOPLEFT", UIParent, "CENTER", 0, 0);
end

function FocusFrame_HideWhenDead(toggle)
	if FocusFrameOptions.hidewhendead == nil then
		-- Default is ON
		FocusFrameOptions.hidewhendead = true;
	end
	if toggle then
		if InCombatLockdown() then
			DEFAULT_CHAT_FRAME:AddMessage('FocusFrame: You cannot toggle hidewhendead while in combat.');
			return;
		end
		if FocusFrameOptions.hidewhendead then
			FocusFrameOptions.hidewhendead = false;
		    DEFAULT_CHAT_FRAME:AddMessage('FocusFrame: hidewhendead is now [OFF]. FocusFrame will be always shown.');
		else
			FocusFrameOptions.hidewhendead = true;
		    DEFAULT_CHAT_FRAME:AddMessage('FocusFrame: hidewhendead is now [ON]. FocusFrame will be hide when enemy target is dead.');
		end
	end
	if FocusFrameOptions.hidewhendead then
		RegisterStateDriver(FocusFrame, "visibility", "[target=focus,noexists][target=focus,harm,dead]hide;show");
	else
		RegisterStateDriver(FocusFrame, "visibility", "[target=focus,noexists]hide;show");
	end
end

function FocusFrame_OnLoad()
	this.statusCounter = 0;
	this.statusSign = -1;
	this.unitHPPercent = 1;

	this.buffStartX = 5;
	this.buffStartY = 32;
	this.buffSpacing = 3;

	FocusFrame_Update();
	this:RegisterEvent("PLAYER_ENTERING_WORLD");
	this:RegisterEvent("PLAYER_FOCUS_CHANGED");
	this:RegisterEvent("UNIT_HEALTH");
	this:RegisterEvent("UNIT_LEVEL");
	this:RegisterEvent("UNIT_FACTION");
	this:RegisterEvent("UNIT_CLASSIFICATION_CHANGED");
	this:RegisterEvent("UNIT_AURA");
	this:RegisterEvent("PLAYER_FLAGS_CHANGED");
	this:RegisterEvent("PARTY_MEMBERS_CHANGED");
	this:RegisterEvent("RAID_TARGET_UPDATE");
	this:RegisterEvent("VARIABLES_LOADED");

	local frameLevel = FocusFrameTextureFrame:GetFrameLevel();
	FocusFrameHealthBar:SetFrameLevel(frameLevel-1);
	FocusFrameManaBar:SetFrameLevel(frameLevel-1);
	FocusFrameSpellBar:SetFrameLevel(frameLevel-1);

	local showmenu = function()
		ToggleDropDownMenu(1, nil, FocusFrameDropDown, "FocusFrame", 120, 10);
	end
	SecureUnitButton_OnLoad(this, "focus", showmenu);

    ClickCastFrames = ClickCastFrames or { };
    ClickCastFrames[this] = true;
end

function FocusFrame_Update()
	-- This check is here so the frame will hide when the focus goes away
	-- even if some of the functions below are hooked by addons.
	if ( UnitExists("focus") ) then
		TargetofFocus_Update();

		UnitFrame_Update();
		FocusFrame_CheckLevel();
		FocusFrame_CheckFaction();
		FocusFrame_CheckClassification();
		FocusFrame_CheckDead();
		if ( UnitIsPartyLeader("focus") ) then
			FocusLeaderIcon:Show();
		else
			FocusLeaderIcon:Hide();
		end
		FocusDebuffButton_Update();
		FocusPortrait:SetAlpha(1.0);
	end
end

function FocusFrame_OnEvent(event)
	UnitFrame_OnEvent(event);

	if ( event == "PLAYER_ENTERING_WORLD" ) then
		FocusFrame_Update();
	elseif ( event == "PLAYER_FOCUS_CHANGED" ) then
		FocusFrame_Update();
		FocusFrame_UpdateRaidTargetIcon();
		CloseDropDownMenus();

--		if ( UnitExists("focus") ) then
--			if ( UnitIsEnemy("focus", "player") ) then
--				PlaySound("igCreatureAggroSelect");
--			elseif ( UnitIsFriend("player", "focus") ) then
--				PlaySound("igCharacterNPCSelect");
--			else
--				PlaySound("igCreatureNeutralSelect");
--			end
--		end
	elseif ( event == "UNIT_HEALTH" ) then
		if ( arg1 == "focus" ) then
			FocusFrame_CheckDead();
		end
	elseif ( event == "UNIT_LEVEL" ) then
		if ( arg1 == "focus" ) then
			FocusFrame_CheckLevel();
		end
	elseif ( event == "UNIT_FACTION" ) then
		if ( arg1 == "focus" or arg1 == "player" ) then
			FocusFrame_CheckFaction();
			FocusFrame_CheckLevel();
		end
	elseif ( event == "UNIT_CLASSIFICATION_CHANGED" ) then
		if ( arg1 == "focus" ) then
			FocusFrame_CheckClassification();
		end
	elseif ( event == "UNIT_AURA" ) then
		if ( arg1 == "focus" ) then
			FocusDebuffButton_Update();
		end
	elseif ( event == "PLAYER_FLAGS_CHANGED" ) then
		if ( arg1 == "focus" ) then
			if ( UnitIsPartyLeader("focus") ) then
				FocusLeaderIcon:Show();
			else
				FocusLeaderIcon:Hide();
			end
		end
	elseif ( event == "PARTY_MEMBERS_CHANGED" ) then
		TargetofFocus_Update();
		FocusFrame_CheckFaction();
	elseif ( event == "RAID_TARGET_UPDATE" ) then
		FocusFrame_UpdateRaidTargetIcon();
    elseif ( event == "VARIABLES_LOADED" ) then
        FocusFrameOptions.scale = FocusFrameOptions.scale or 1;
		FocusFrame_SetScale(FocusFrameOptions.scale);
		FocusFrame_HideWhenDead(false);
	end
end

function FocusFrame_OnHide()
	PlaySound("INTERFACESOUND_LOSTTARGETUNIT");
	CloseDropDownMenus();
end

function FocusFrame_CheckLevel()
	local targetLevel = UnitLevel("focus");
	
	if ( UnitIsCorpse("focus") ) then
		FocusLevelText:Hide();
		FocusHighLevelTexture:Show();
	elseif ( targetLevel > 0 ) then
		-- Normal level target
		FocusLevelText:SetText(targetLevel);
		-- Color level number
		if ( UnitCanAttack("player", "focus") ) then
			local color = GetDifficultyColor(targetLevel);
			FocusLevelText:SetVertexColor(color.r, color.g, color.b);
		else
			FocusLevelText:SetVertexColor(1.0, 0.82, 0.0);
		end
		FocusLevelText:Show();
		FocusHighLevelTexture:Hide();
	else
		-- Focus is too high level to tell
		FocusLevelText:Hide();
		FocusHighLevelTexture:Show();
	end
end

function FocusFrame_CheckFaction()
	if ( UnitPlayerControlled("focus") ) then
		local r, g, b;
		if ( UnitCanAttack("focus", "player") ) then
			-- Hostile players are red
			if ( not UnitCanAttack("player", "focus") ) then
				r = 0.0;
				g = 0.0;
				b = 1.0;
			else
				r = l.FocusUnitReactionColor[2].r;
				g = l.FocusUnitReactionColor[2].g;
				b = l.FocusUnitReactionColor[2].b;
			end
		elseif ( UnitCanAttack("player", "focus") ) then
			-- Players we can attack but which are not hostile are yellow
			r = l.FocusUnitReactionColor[4].r;
			g = l.FocusUnitReactionColor[4].g;
			b = l.FocusUnitReactionColor[4].b;
		elseif ( UnitIsPVP("focus") and not UnitIsPVPSanctuary("focus") and not UnitIsPVPSanctuary("player") ) then
			-- Players we can assist but are PvP flagged are green
			r = l.FocusUnitReactionColor[6].r;
			g = l.FocusUnitReactionColor[6].g;
			b = l.FocusUnitReactionColor[6].b;
		else
			-- All other players are blue (the usual state on the "blue" server)
			r = 0.0;
			g = 0.0;
			b = 1.0;
		end
		FocusFrameNameBackground:SetVertexColor(r, g, b);
		FocusPortrait:SetVertexColor(1.0, 1.0, 1.0);
	elseif ( UnitIsTapped("focus") and not UnitIsTappedByPlayer("focus") ) then
		FocusFrameNameBackground:SetVertexColor(0.5, 0.5, 0.5);
		FocusPortrait:SetVertexColor(0.5, 0.5, 0.5);
	else
		local reaction = UnitReaction("focus", "player");
		if ( reaction ) then
			local r, g, b;
			r = l.FocusUnitReactionColor[reaction].r;
			g = l.FocusUnitReactionColor[reaction].g;
			b = l.FocusUnitReactionColor[reaction].b;
			FocusFrameNameBackground:SetVertexColor(r, g, b);
		else
			FocusFrameNameBackground:SetVertexColor(0, 0, 1.0);
		end
		FocusPortrait:SetVertexColor(1.0, 1.0, 1.0);
	end

	local factionGroup = UnitFactionGroup("focus");
	if ( UnitIsPVPFreeForAll("focus") ) then
		FocusPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA");
		FocusPVPIcon:Show();
	elseif ( factionGroup and UnitIsPVP("focus") ) then
		FocusPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup);
		FocusPVPIcon:Show();
	else
		FocusPVPIcon:Hide();
	end
end

function FocusFrame_CheckClassification()
	local classification = UnitClassification("focus");
	if ( classification == "worldboss" ) then
		FocusFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite");
	elseif ( classification == "rareelite"  ) then
		FocusFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare-Elite");
	elseif ( classification == "elite"  ) then
		FocusFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite");
	elseif ( classification == "rare"  ) then
		FocusFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare");
	else
		FocusFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame");
	end
end

function FocusFrame_CheckDead()
	if ( (MobHealthDB == nil) and (UnitHealth("focus") <= 0) and UnitIsConnected("focus") ) then
		FocusDeadText:Show();
	else
		FocusDeadText:Hide();
	end
end

function FocusFrame_OnUpdate()
	if ( TargetofFocusFrame:IsShown() ~= UnitExists("focustarget") ) then
		TargetofFocus_Update();
	end
end

function FocusDebuffButton_Update()
	local button;
	local name, rank, icon, count, duration, timeLeft;
	local buffCount;
	local numBuffs = 0;
--	local largeBuffList = {};
	local playerIsFocus = UnitIsUnit("player", "focus");
	local cooldown, startCooldownTime;

	for i=1, l.MAX_FOCUS_BUFFS do
		name, rank, icon, count, duration, timeLeft = UnitBuff("focus", i);
		button = getglobal("FocusFrameBuff"..i);
		if ( not button ) then
			if ( not icon ) then
				break;
			else
				button = CreateFrame("Button", "FocusFrameBuff"..i, FocusFrame, "FocusBuffButtonTemplate");
			end
		end
		
		if ( icon ) then
			getglobal("FocusFrameBuff"..i.."Icon"):SetTexture(icon);
			buffCount = getglobal("FocusFrameBuff"..i.."Count");
			button:Show();
			if ( count > 1 ) then
				buffCount:SetText(count);
				buffCount:Show();
			else
				buffCount:Hide();
			end
			
			-- Handle cooldowns
			cooldown = getglobal("FocusFrameBuff"..i.."Cooldown");
			if ( duration ) then
				if ( duration > 0 ) then
					cooldown:Show();
					startCooldownTime = GetTime()-(duration-timeLeft);
					CooldownFrame_SetTimer(cooldown, startCooldownTime, duration, 1);
				else
					cooldown:Hide();
				end
				
				-- Set the buff to be big if the buff is cast by the player and the focus is not the player
				if ( not playerIsFocus ) then
					l.largeBuffList[i] = 1;
				else
					l.largeBuffList[i] = nil;
				end
			else
				cooldown:Hide();
			end

			button.id = i;
			numBuffs = numBuffs + 1; 
			button:ClearAllPoints();
		else
			button:Hide();
		end
	end

	local debuffType, color;
	local debuffCount;
	local numDebuffs = 0;
--	local largeDebuffList = {};
	for i=1, l.MAX_FOCUS_DEBUFFS do
		local debuffBorder = getglobal("FocusFrameDebuff"..i.."Border");
		name, rank, icon, count, debuffType, duration, timeLeft = UnitDebuff("focus", i);
		button = getglobal("FocusFrameDebuff"..i);
		if ( not button ) then
			if ( not icon ) then
				break;
			else
				button = CreateFrame("Button", "FocusFrameDebuff"..i, FocusFrame, "FocusDebuffButtonTemplate");
				debuffBorder = getglobal("FocusFrameDebuff"..i.."Border");
			end
		end
		if ( icon ) then
			getglobal("FocusFrameDebuff"..i.."Icon"):SetTexture(icon);
			debuffCount = getglobal("FocusFrameDebuff"..i.."Count");
			if ( debuffType ) then
				color = DebuffTypeColor[debuffType];
			else
				color = DebuffTypeColor["none"];
			end
			if ( count > 1 ) then
				debuffCount:SetText(count);
				debuffCount:Show();
			else
				debuffCount:Hide();
			end

			-- Handle cooldowns
			cooldown = getglobal("FocusFrameDebuff"..i.."Cooldown");
			if ( duration  ) then
				if ( duration > 0 ) then
					cooldown:Show();
					startCooldownTime = GetTime()-(duration-timeLeft);
					CooldownFrame_SetTimer(cooldown, startCooldownTime, duration, 1);
				else
					cooldown:Hide();
				end
				-- Set the buff to be big if the buff is cast by the player
				l.largeDebuffList[i] = 1;
			else
				cooldown:Hide();
				l.largeDebuffList[i] = nil;
			end
			
			debuffBorder:SetVertexColor(color.r, color.g, color.b);
			button:Show();
			numDebuffs = numDebuffs + 1;
			button:ClearAllPoints();
		else
			button:Hide();
		end
		button.id = i;
	end
	
	-- Figure out general information that affects buff sizing and positioning
	local numFirstRowBuffs;
	local buffSize = l.LARGE_BUFF_SIZE;
	local buffFrameSize = l.LARGE_BUFF_FRAME_SIZE;
	if ( TargetofFocusFrame:IsShown() ) then
		numFirstRowBuffs = 5;
	else
		numFirstRowBuffs = 6;
	end
	if ( getn(l.largeBuffList) > 0 or getn(l.largeDebuffList) > 0 ) then
		numFirstRowBuffs = numFirstRowBuffs - 1;
	end
	-- Shrink the buffs if there are too many of them
	if ( (numBuffs >= numFirstRowBuffs) or (numDebuffs >= numFirstRowBuffs) ) then
		buffSize = l.SMALL_BUFF_SIZE;
		buffFrameSize = l.SMALL_BUFF_FRAME_SIZE;
	end
		
	-- Reset number of buff rows
	FocusFrame.buffRows = 0;
	-- Position buffs
	local size;
	local previousWasPlayerCast;
	local offset;
	for i=1, numBuffs do
		if ( l.largeBuffList[i] ) then
			size = l.LARGE_BUFF_SIZE;
			offset = 3;
			previousWasPlayerCast = 1;
		else
			size = buffSize;
			offset = 3;
			if ( previousWasPlayerCast ) then
				offset = 6;
				previousWasPlayerCast = nil;
			end
		end
		FocusFrame_UpdateBuffAnchor("FocusFrameBuff", i, numFirstRowBuffs, numDebuffs, size, offset, TargetofFocusFrame:IsShown());
	end
	-- Position debuffs
	previousWasPlayerCast = nil;
	for i=1, numDebuffs do
		if ( l.largeDebuffList[i] ) then
			size = l.LARGE_BUFF_SIZE;
			offset = 4;
			previousWasPlayerCast = 1;
		else
			size = buffSize;
			offset = 4;
			if ( previousWasPlayerCast ) then
				offset = 6;
				previousWasPlayerCast = nil;
			end
		end
		FocusFrame_UpdateDebuffAnchor("FocusFrameDebuff", i, numFirstRowBuffs, numBuffs, size, offset, TargetofFocusFrame:IsShown());
 	end

	-- update the spell bar position
	Focus_Spellbar_AdjustPosition();
end

function FocusFrame_UpdateBuffAnchor(buffName, index, numFirstRowBuffs, numDebuffs, buffSize, offset, hasTargetofFocus)
	local buff = getglobal(buffName..index);
	
	if ( index == 1 ) then
		if ( UnitIsFriend("player", "focus") ) then
			buff:SetPoint("TOPLEFT", FocusFrame, "BOTTOMLEFT", FocusFrame.buffStartX, FocusFrame.buffStartY);
		else
			if ( numDebuffs > 0 ) then
				buff:SetPoint("TOPLEFT", FocusFrameDebuffs, "BOTTOMLEFT", 0, -FocusFrame.buffSpacing);
			else
				buff:SetPoint("TOPLEFT", FocusFrame, "BOTTOMLEFT", FocusFrame.buffStartX, FocusFrame.buffStartY);
			end
		end
		FocusFrameBuffs:SetPoint("TOPLEFT", buff, "TOPLEFT", 0, 0);
		FocusFrameBuffs:SetPoint("BOTTOMLEFT", buff, "BOTTOMLEFT", 0, 0);
		FocusFrame.buffRows = FocusFrame.buffRows+1;
	elseif ( index == (numFirstRowBuffs+1) ) then
		buff:SetPoint("TOPLEFT", getglobal(buffName..1), "BOTTOMLEFT", 0, -FocusFrame.buffSpacing);
		FocusFrameBuffs:SetPoint("BOTTOMLEFT", buff, "BOTTOMLEFT", 0, 0);
		FocusFrame.buffRows = FocusFrame.buffRows+1;
	elseif ( hasTargetofFocus and index == (2*numFirstRowBuffs+1) ) then
		buff:SetPoint("TOPLEFT", getglobal(buffName..(numFirstRowBuffs+1)), "BOTTOMLEFT", 0, -FocusFrame.buffSpacing);
		FocusFrameBuffs:SetPoint("BOTTOMLEFT", buff, "BOTTOMLEFT", 0, 0);
		FocusFrame.buffRows = FocusFrame.buffRows+1;
	elseif ( (index > numFirstRowBuffs) and (mod(index+(l.TARGET_BUFFS_PER_ROW-numFirstRowBuffs), l.TARGET_BUFFS_PER_ROW) == 1) and not hasTargetofFocus ) then
		-- Make a new row, have to take the number of buffs in the first row into account
		buff:SetPoint("TOPLEFT", getglobal(buffName..(index-l.TARGET_BUFFS_PER_ROW)), "BOTTOMLEFT", 0, -FocusFrame.buffSpacing);
		FocusFrameBuffs:SetPoint("BOTTOMLEFT", buff, "BOTTOMLEFT", 0, 0);
		FocusFrame.buffRows = FocusFrame.buffRows+1;
	else
		-- Just anchor to previous
		buff:SetPoint("TOPLEFT", getglobal(buffName..(index-1)), "TOPRIGHT", offset, 0);
	end

	-- Resize
	buff:SetWidth(buffSize);
	buff:SetHeight(buffSize);
end

function FocusFrame_UpdateDebuffAnchor(buffName, index, numFirstRowBuffs, numBuffs, buffSize, offset, hasTargetofFocus)
	local buff = getglobal(buffName..index);

	if ( index == 1 ) then
		if ( UnitIsFriend("player", "focus") and (numBuffs > 0) ) then
			buff:SetPoint("TOPLEFT", FocusFrameBuffs, "BOTTOMLEFT", 0, -FocusFrame.buffSpacing);
		else
			buff:SetPoint("TOPLEFT", FocusFrame, "BOTTOMLEFT", FocusFrame.buffStartX, FocusFrame.buffStartY);
		end
		FocusFrameDebuffs:SetPoint("TOPLEFT", buff, "TOPLEFT", 0, 0);
		FocusFrameDebuffs:SetPoint("BOTTOMLEFT", buff, "BOTTOMLEFT", 0, 0);
		FocusFrame.buffRows = FocusFrame.buffRows+1;
	elseif ( index == (numFirstRowBuffs+1) ) then
		buff:SetPoint("TOPLEFT", getglobal(buffName..1), "BOTTOMLEFT", 0, -FocusFrame.buffSpacing);
		FocusFrameDebuffs:SetPoint("BOTTOMLEFT", buff, "BOTTOMLEFT", 0, 0);
		FocusFrame.buffRows = FocusFrame.buffRows+1;
	elseif ( hasTargetofFocus and index == (2*numFirstRowBuffs+1) ) then
		buff:SetPoint("TOPLEFT", getglobal(buffName..(numFirstRowBuffs+1)), "BOTTOMLEFT", 0, -FocusFrame.buffSpacing);
		FocusFrameDebuffs:SetPoint("BOTTOMLEFT", buff, "BOTTOMLEFT", 0, 0);
		FocusFrame.buffRows = FocusFrame.buffRows+1;
	elseif ( (index > numFirstRowBuffs) and (mod(index+(l.TARGET_DEBUFFS_PER_ROW-numFirstRowBuffs), l.TARGET_DEBUFFS_PER_ROW) == 1) and not hasTargetofFocus ) then
		-- Make a new row
		buff:SetPoint("TOPLEFT", getglobal(buffName..(index-l.TARGET_DEBUFFS_PER_ROW)), "BOTTOMLEFT", 0, -FocusFrame.buffSpacing);
		FocusFrameDebuffs:SetPoint("BOTTOMLEFT", buff, "BOTTOMLEFT", 0, 0);
		FocusFrame.buffRows = FocusFrame.buffRows+1;
	else
		-- Just anchor to previous
		buff:SetPoint("TOPLEFT", getglobal(buffName..(index-1)), "TOPRIGHT", offset, 0);
	end
	
	-- Resize
	buff:SetWidth(buffSize);
	buff:SetHeight(buffSize);
	local debuffFrame = getglobal(buffName..index.."Border");
	debuffFrame:SetWidth(buffSize+2);
	debuffFrame:SetHeight(buffSize+2);
end

function FocusFrame_HealthUpdate(elapsed, unit)
	if ( UnitIsPlayer(unit) ) then
		if ( (this.unitHPPercent > 0) and (this.unitHPPercent <= 0.2) ) then
			local alpha = 255;
			local counter = this.statusCounter + elapsed;
			local sign    = this.statusSign;
	
			if ( counter > 0.5 ) then
				sign = -sign;
				this.statusSign = sign;
			end
			counter = mod(counter, 0.5);
			this.statusCounter = counter;
	
			if ( sign == 1 ) then
				alpha = (127  + (counter * 256)) / 255;
			else
				alpha = (255 - (counter * 256)) / 255;
			end
			FocusPortrait:SetAlpha(alpha);
		end
	end
end

function FocusHealthCheck()
	if ( UnitIsPlayer("focus") ) then
		local unitHPMin, unitHPMax, unitCurrHP;
		unitHPMin, unitHPMax = this:GetMinMaxValues();
		unitCurrHP = this:GetValue();
		this:GetParent().unitHPPercent = unitCurrHP / unitHPMax;
		if ( UnitIsDead("focus") ) then
			FocusPortrait:SetVertexColor(0.35, 0.35, 0.35, 1.0);
		elseif ( UnitIsGhost("focus") ) then
			FocusPortrait:SetVertexColor(0.2, 0.2, 0.75, 1.0);
		elseif ( (this:GetParent().unitHPPercent > 0) and (this:GetParent().unitHPPercent <= 0.2) ) then
			FocusPortrait:SetVertexColor(1.0, 0.0, 0.0);
		else
			FocusPortrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
		end
	end
end

function FocusFrameDropDown_OnLoad()
	UIDropDownMenu_Initialize(this, FocusFrameDropDown_Initialize, "MENU");
end

function FocusFrameDropDown_Initialize()
	local menu;
	local name;
	local id = nil;
	if ( UnitIsUnit("focus", "player") ) then
		menu = "SELF";
	elseif ( UnitIsUnit("focus", "pet") ) then
		menu = "PET";
	elseif ( UnitIsPlayer("focus") ) then
		id = UnitInRaid("focus");
		if ( id ) then
			menu = "RAID_PLAYER";
		elseif ( UnitInParty("focus") ) then
			menu = "PARTY";
		else
			menu = "PLAYER";
		end
	else
		menu = "RAID_TARGET_ICON";
		name = RAID_TARGET_ICON;
	end
	if ( menu ) then
		UnitPopup_ShowMenu(FocusFrameDropDown, menu, "focus", name, id);
	end
end



-- Raid target icon function
function FocusFrame_UpdateRaidTargetIcon()
	local index = GetRaidTargetIndex("focus");
	if ( index ) then
		SetRaidTargetIconTexture(FocusRaidTargetIcon, index);
		FocusRaidTargetIcon:Show();
	else
		FocusRaidTargetIcon:Hide();
	end
end


function TargetofFocus_OnLoad()
	UnitFrame_Initialize("focustarget", TargetofFocusName, TargetofFocusPortrait, TargetofFocusHealthBar, TargetofFocusHealthBarText, TargetofFocusManaBar, TargetofFocusFrameManaBarText);
	SetTextStatusBarTextZeroText(TargetofFocusHealthBar, TEXT(DEAD));
	this:RegisterEvent("UNIT_AURA");

	SecureUnitButton_OnLoad(this, "focustarget");
	RegisterUnitWatch(TargetofFocusFrame);  
    ClickCastFrames = ClickCastFrames or { };
    ClickCastFrames[this] = true;
end

function TargetofFocus_OnHide()
	FocusDebuffButton_Update();
end

function TargetofFocus_Update()
	if ( TargetofFocusFrame:IsShown() ) then
		UnitFrame_Update();
		TargetofFocus_CheckDead();
		TargetofFocusHealthCheck();
		RefreshBuffs(TargetofFocusFrame, 0, "focustarget");
	end
end

function TargetofFocus_CheckDead()
	if ( (UnitHealth("focustarget") <= 0) and UnitIsConnected("focustarget") ) then
		TargetofFocusBackground:SetAlpha(0.9);
		TargetofFocusDeadText:Show();
	else
		TargetofFocusBackground:SetAlpha(1);
		TargetofFocusDeadText:Hide();
	end
end

function TargetofFocusHealthCheck()
	if ( UnitIsPlayer("focustarget") ) then
		local unitHPMin, unitHPMax, unitCurrHP;
		unitHPMin, unitHPMax = TargetofFocusHealthBar:GetMinMaxValues();
		unitCurrHP = TargetofFocusHealthBar:GetValue();
		TargetofFocusFrame.unitHPPercent = unitCurrHP / unitHPMax;
		if ( UnitIsDead("focustarget") ) then
			TargetofFocusPortrait:SetVertexColor(0.35, 0.35, 0.35, 1.0);
		elseif ( UnitIsGhost("focustarget") ) then
			TargetofFocusPortrait:SetVertexColor(0.2, 0.2, 0.75, 1.0);
		elseif ( (TargetofFocusFrame.unitHPPercent > 0) and (TargetofFocusFrame.unitHPPercent <= 0.2) ) then
			TargetofFocusPortrait:SetVertexColor(1.0, 0.0, 0.0);
		else
			TargetofFocusPortrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
		end
	end
end


function SetFocusSpellbarAspect()
	local frameText = getglobal(FocusFrameSpellBar:GetName().."Text");
	if ( frameText ) then
		frameText:SetTextHeight(10);
		frameText:ClearAllPoints();
		frameText:SetPoint("TOP", FocusFrameSpellBar, "TOP", 0, 4);
	end

	local frameBorder = getglobal(FocusFrameSpellBar:GetName().."Border");
	if ( frameBorder ) then
		frameBorder:SetTexture("Interface\\CastingBar\\UI-CastingBar-Border-Small");
		frameBorder:SetWidth(197);
		frameBorder:SetHeight(49);
		frameBorder:ClearAllPoints();
		frameBorder:SetPoint("TOP", FocusFrameSpellBar, "TOP", 0, 20);
	end

	local frameFlash = getglobal(FocusFrameSpellBar:GetName().."Flash");
	if ( frameFlash ) then
		frameFlash:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash-Small");
		frameFlash:SetWidth(197);
		frameFlash:SetHeight(49);
		frameFlash:ClearAllPoints();
		frameFlash:SetPoint("TOP", FocusFrameSpellBar, "TOP", 0, 20);
	end
end

function Focus_Spellbar_OnLoad()
	this:RegisterEvent("PLAYER_FOCUS_CHANGED");
	this:RegisterEvent("CVAR_UPDATE");

	CastingBarFrame_OnLoad("focus", false);

	local barIcon = getglobal(this:GetName().."Icon");
	barIcon:Show();

	-- check to see if the castbar should be shown
	if (GetCVar("ShowTargetCastbar") == "0") then
		this.showCastbar = false;
	end
	SetFocusSpellbarAspect();
end

function Focus_Spellbar_OnEvent()
	local newevent = event;
	local newarg1 = arg1;
	--	Check for target specific events
	if ( (event == "CVAR_UPDATE") and (arg1 == "SHOW_TARGET_CASTBAR") ) then
		if (GetCVar("ShowTargetCastbar") == "0") then
			this.showCastbar = false;
		else
			this.showCastbar = true;
		end

		if ( not this.showCastbar ) then
			this:Hide();
		elseif ( this.casting or this.channeling ) then
			this:Show();
		end
		return;
	elseif ( event == "PLAYER_FOCUS_CHANGED" ) then
		-- check if the new target is casting a spell
		local nameChannel  = UnitChannelInfo(this.unit);
		local nameSpell  = UnitCastingInfo(this.unit);
		if ( nameChannel ) then
			newevent = "UNIT_SPELLCAST_CHANNEL_START";
			newarg1 = "focus";
		elseif ( nameSpell ) then
			newevent = "UNIT_SPELLCAST_START";
			newarg1 = "focus";
		else
			this.casting = nil;
			this.channeling = nil;
			this:SetMinMaxValues(0, 0);
			this:SetValue(0);
			this:Hide();
			return;
		end
		-- The position depends on the classification of the target
		Target_Spellbar_AdjustPosition();
	end

	if ( UnitIsUnit("player", "focus") ) then
		return;
	end
	CastingBarFrame_OnEvent(newevent, newarg1);
end

function Focus_Spellbar_AdjustPosition()
	local yPos = 5;
	if ( FocusFrame.buffRows and FocusFrame.buffRows <= 2 ) then
		yPos = 38;
	elseif ( FocusFrame.buffRows ) then
		yPos = 19 * FocusFrame.buffRows;
	end
	if ( TargetofFocusFrame:IsShown() ) then
		if ( yPos <= 25 ) then
			yPos = yPos + 25;
		end
	else
		yPos = yPos - 5;
		local classification = UnitClassification("focus");
		if ( (yPos < 17) and ((classification == "worldboss") or (classification == "rareelite") or (classification == "elite") or (classification == "rare")) ) then
			yPos = 17;
		end
	end
	FocusFrameSpellBar:SetPoint("BOTTOM", "FocusFrame", "BOTTOM", -15, -yPos);
end

function FocusFrameHealthBarText_UpdateTextString(textStatusBar)
	if ( not textStatusBar ) then
		textStatusBar = this;
	end
	local string = FocusFrameHealthBarText;
		local value = textStatusBar:GetValue();
		local valueMin, valueMax = textStatusBar:GetMinMaxValues();
		if ( valueMax > 0 ) then
			if (MobHealthDB) then
				-- No longer use default health bar text functions.
				FocusFrameHealthBar.TextString = nil;

				if (not UnitIsPlayer("focus") and not UnitIsUnit("focus", "pet")) then
					local focusName,focusLevel = UnitName("focus"),UnitLevel("focus");
					if (focusName == nil or focusLevel == nil) then
						return;
					end
					local ppp = MobHealth_PPP(focusName..":"..focusLevel);
					local curHP = math.floor(value * ppp + 0.5);
					local maxHP = math.floor(100 * ppp + 0.5);
					if (ppp and ppp ~= 0) then
					   string:SetText(curHP.." / "..maxHP);
					else
					   string:SetText(value.."%");
					end
				else
					string:SetText(value.." / "..valueMax);
				end
				string:Show();
			end
		end
end

function FocusFrameHealthBar_OnValueChanged(value)
	FocusFrameHealthBarText_UpdateTextString();
	HealthBar_OnValueChanged(value);
end

function FocusFrame_OnDragStart()
	if (not FocusFrameOptions.lockpos) then
		this:GetParent():StartMoving();
		this.isMoving = true;
	end
end

function FocusFrame_OnDragStop()
	 this:GetParent():StopMovingOrSizing();
	 this.isMoving = false;
end

function FocusFrame_OnEnter()
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
	if (not FocusFrameOptions.lockpos) then
		GameTooltip:SetText(FOCUSFRAME_DRAG, nil, nil, nil, nil, 1);
	else
		GameTooltip:SetText(FOCUSFRAME_DRAG_LOCKED, nil, nil, nil, nil, 1);
	end
end