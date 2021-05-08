--[[
Author: Massiner of Nathrezim
Date: 03-May-2009
Acknowledgements: Blizzard (most of this is file is a reworking of the ActionButton in order to try and keep functionaly close)

Hacks and other notes:
1. It would be possible to use a secure handler for drag drop of buttons except that in the case of spells we need to do a lookup of the spell name to be able
	to use the base button handler to respond to clicks which cannot be directly done in a secure handle
	a. Work around 1 would be to load (and maintain!!!) the secure environment with a spell lookup table
	b. We could override the base click method with one of our own, although this may lead back to needing a lookup anyway
	c. At this point in time the most practical solution is to prevent draggin actions on the button while in combat and use a normal method for updating
2. Since grid display is based off the cursor picking up an item or spell, I don't believe there is a way to secure handle toggling grid display
	a. Unless the problem above is solved then there is no need to anyway
3. Items, these are simply stored as the itemname or id - the blizzard code will search and execute the first item in the players bag that matches (same as the default buttons)
4. OnClick may sometimes trigger the action when holding an item (a macro it seems??), so we need to remove the item in this case 
	a. This may be a good canidate to move into a secure pre/post click secure snippet
5. OnClick throws the item away, so we temp store the item against the button for use after the click (if we can use it).
	a. This may be more appropriate to fully handle in the pre click??
6. ACTIONBAR_SLOT_CHANGED is a heavy handed event to be using here - it triggers for each Blizzard action button in a lot of cases, the reason it is in use here is primarily to keep the
	macro icon updated correctly
	a. There are issues with lagged statechanges that make checking events that could cause a macro change tricky, but this could be investigated if there is a need to improve performance
	b. A possible alternative that I have not checked into much yet is to create a state handler that can respond to each conditional and trigger an update
7. The buttons array below stores all buttons, some events only make sense to process on certain buttons, if performance needs improving different arrays can be made and maintained for these buttons...
8. There is a need to scan spells and macros incase there has been a change at points in time (this will also be needed for mounts and critters when they are introduced)
]]

local function GetActiveTalentGroup()
	return 1
end

ABTFrame = CreateFrame("FRAME"); -- This a base frame that will handle event logic
ABTFrame.buttons = {};
ABTFrame.showGrid = false;
ABTFrame.worldLoaded = false;


--Set a state value so we know if the player is in the world or not (this is used to prevent checking macros since they may not be loaded yet)
ABTFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
ABTFrame:RegisterEvent("PLAYER_EXITING_WORLD");

--Here we piggy back off events meant for the default buttons in the UI, the SLOT_CHANGED event is expensive as it
--can be invoked per enabled button, we use it since it keeps the macro display upto date (I suspect a state driver may be able to take over this task)
ABTFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED");
ABTFrame:RegisterEvent("ACTIONBAR_UPDATE_STATE");
ABTFrame:RegisterEvent("ACTIONBAR_UPDATE_USABLE");
ABTFrame:RegisterEvent("SPELL_UPDATE_USABLE");
ABTFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
ABTFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN");
ABTFrame:RegisterEvent("BAG_UPDATE_COOLDOWN");
ABTFrame:RegisterEvent("ACTIONBAR_SHOWGRID");
ABTFrame:RegisterEvent("ACTIONBAR_HIDEGRID");

--We check the cursor since the cursor can pickup items that may not trigger a show grid for the action bar
ABTFrame:RegisterEvent("CURSOR_UPDATE");

--We check learned spells to make sure we always have the highest level on the button (and also in the case of respecs we can hold onto spells in the bar)
--IMPORTANT - there isn't an option to disable this since for some spells only the highest rank is available
ABTFrame:RegisterEvent("LEARNED_SPELL_IN_TAB");

--This allows me to catch if the player resets talents, in which case they may lose a bunch of spells (we mark spells with a faded ? so they can stay in the bar)
ABTFrame:RegisterEvent("PLAYER_TALENT_UPDATE");

--If the talent group changes switch the buttons action
ABTFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");

--We need to try and keep a handle on macros, this is a tough job, so we take the simple route and match by name
--this wont work so well with same name macros (although I've decided it is out of scope for this mod unless a good reason can be given to have same named macros)
ABTFrame:RegisterEvent("UPDATE_MACROS");

--For when the player changes a hotkey
ABTFrame:RegisterEvent("UPDATE_BINDINGS");

--React to changes in items
ABTFrame:RegisterEvent("UPDATE_INVENTORY_ALERTS");	--??
ABTFrame:RegisterEvent("BAG_UPDATE");

--Used for the range timer
ABTFrame:RegisterEvent("PLAYER_TARGET_CHANGED");

--This allows buttons which open skill windows to stayed checked while the window is open
ABTFrame:RegisterEvent("TRADE_SKILL_SHOW");
ABTFrame:RegisterEvent("TRADE_SKILL_CLOSE");

--For starting flashing on attack actions
ABTFrame:RegisterEvent("PLAYER_ENTER_COMBAT");
ABTFrame:RegisterEvent("PLAYER_LEAVE_COMBAT");
ABTFrame:RegisterEvent("START_AUTOREPEAT_SPELL");
ABTFrame:RegisterEvent("STOP_AUTOREPEAT_SPELL");

--Not sure about why these are monitored (note a lot of this code is based on Blizzs implementation of action buttons)
--It is monitored to update the checked state of buttons though (this does also cover the case of mounts... although since these aren't working yet there isn't much point?!)
ABTFrame:RegisterEvent("UNIT_ENTERED_VEHICLE");
ABTFrame:RegisterEvent("UNIT_EXITED_VEHICLE");
ABTFrame:RegisterEvent("COMPANION_UPDATE");
ABTFrame:RegisterEvent("COMPANION_LEARNED");



function ABTFrame:OnEvent(event, ...)
	arg1 = ...;

	if (event == "ACTIONBAR_SLOT_CHANGED") then
		for i,v in ipairs(self.buttons) do
			ABTMethods_Update(v);
		end
	
	elseif (event == "SPELL_UPDATE_COOLDOWN" or event == "BAG_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_COOLDOWN") then
		for i,v in ipairs(self.buttons) do
			ABTMethods_UpdateCooldown(v);
		end	

	elseif (event == "ACTIONBAR_UPDATE_USABLE" or event == "SPELL_UPDATE_USABLE") then
		for i,v in ipairs(self.buttons) do
			ABTMethods_UpdateUsable(v);
		end
		
	elseif (event == "PLAYER_TARGET_CHANGED") then
		for i,v in ipairs(self.buttons) do
			v.rangeTimer = -1;
		end
		
	elseif (event == "PLAYER_ENTER_COMBAT") then
		for i,v in ipairs(self.buttons) do
			local command, value = ABTMethods_GetCommand(v);
			if (command == "spell" and IsAttackSpell(value)) then
				ABTMethods_StartFlash(v);
			end
		end
	
	elseif (event == "PLAYER_LEAVE_COMBAT") then
		for i,v in ipairs(self.buttons) do
			local command, value = ABTMethods_GetCommand(v);
			if (command == "spell" and IsAttackSpell(value)) then
				ABTMethods_StopFlash(v);
			end
		end
	
	elseif (event == "START_AUTOREPEAT_SPELL") then
		for i,v in ipairs(self.buttons) do
			local command, value = ABTMethods_GetCommand(v);
			if (command == "spell" and IsAutoRepeatSpell(value)) then
				ABTMethods_StartFlash(v);
			end
		end
	
	elseif (event == "STOP_AUTOREPEAT_SPELL") then
		for i,v in ipairs(self.buttons) do
			local command, value = ABTMethods_GetCommand(v);
			if (v.flashing == 1 and not (command == "spell" and IsAttackSpell(value))) then
				ABTMethods_StopFlash(v);
			end
		end

	elseif (event == "CURSOR_UPDATE") then
		if (GetCursorInfo() == "item") then
			self.showGrid = true;				--This could be altered in the future to use a seperate value to showgrid like showgridalt, but appears to be fine in the event model for the moment
			for i,v in ipairs(self.buttons) do
				ABTMethods_UpdateShow(v);
			end
		elseif (self.showGrid) then
			self.showGrid = false;		
			for i,v in ipairs(self.buttons) do
				ABTMethods_UpdateShow(v);
			end
		end
		
	elseif (event == "ACTIONBAR_SHOWGRID") then
		ABTFrame.showGrid = true;
		for i,v in ipairs(self.buttons) do
			ABTMethods_UpdateShow(v);
		end
	
	elseif (event == "ACTIONBAR_HIDEGRID") then
		ABTFrame.showGrid = false;
		for i,v in ipairs(self.buttons) do
			ABTMethods_UpdateShow(v);
		end

	elseif (event == "BAG_UPDATE") then
		for i,v in ipairs(self.buttons) do
			ABTMethods_UpdateEquipped(v);
			ABTMethods_UpdateText(v);
		end

	elseif (event == "ACTIONBAR_UPDATE_STATE"
			or ((event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE") and arg1 == "player")
			or (event == "COMPANION_UPDATE")
			or event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_CLOSE") then
		for i,v in ipairs(self.buttons) do
			ABTMethods_UpdateChecked(v);
		end	

	elseif (event == "UPDATE_BINDINGS") then
		for i,v in ipairs(self.buttons) do
			ABTMethods_UpdateHotkeys(v);
		end

	elseif (event == "UPDATE_MACROS") then
		for i,v in ipairs(self.buttons) do
			ABTMethods_UpdateMacro(v);
		end
		
	elseif (event == "ACTIVE_TALENT_GROUP_CHANGED") then
		for i,v in ipairs(self.buttons) do
			ABTMethods_SetFromStoredCommand(v);
		end
		
	elseif (event == "LEARNED_SPELL_IN_TAB" or event == "PLAYER_TALENT_UPDATE") then
		for i,v in ipairs(self.buttons) do
			ABTMethods_UpdateSpell(v);
		end
	
	elseif (event == "COMPANION_LEARNED") then
		for i,v in ipairs(self.buttons) do
			ABTMethods_UpdateCompanion(v);
		end
		
	elseif (event == "PLAYER_ENTERING_WORLD") then
		self.worldLoaded = true;
		for i,v in ipairs(self.buttons) do
			ABTMethods_UpdateMacro(v);
			ABTMethods_UpdateCompanion(v);
			ABTMethods_UpdateSpell(v);
			ABTMethods_Update(v);
		end
	
	elseif (event == "PLAYER_EXITING_WORLD") then
		self.worldLoaded = false;
	end
end
ABTFrame:SetScript("OnEvent", ABTFrame.OnEvent);





function ABTMethods_PreClick(self)
	if (InCombatLockdown()) then
		return;
	end
	
	--Capture the cursor info here, the secure click handler will discard the contents of the cursor
	self.cursorCommand, self.cursorValue, self.cursorSubValue = GetCursorInfo();
	
	--if the cursor is holding something, we need to temporarily clear the button command as the secure handler will sometimes execute it
	if (self.cursorCommand) then
		self:SetAttribute("type", "none");
	end
end



function ABTMethods_PostClick(self)
	if (InCombatLockdown()) then
		return;
	end
	if (self.cursorCommand) then
		--set the button back to it's orginal command and swap the cursor contents to the button
		local set = 1
		self:SetAttribute("type", self["set"..set.."type"]);
		ABTMethods_SetFromCursorInfo(self, self.cursorCommand, self.cursorValue, self.cursorSubValue);
	end
end



function ABTMethods_OnDragStart(self)
	if (InCombatLockdown() or self.locked) then
		return;
	end
	
	local command, value = ABTMethods_GetCommand(self, true);
	
	ABTMethods_SetCursor(command, value);
	ABTMethods_SetCommand(self, "none", "", "", "", "");

end



function ABTMethods_OnReceiveDrag(self)
	local command, value, subValue = GetCursorInfo();
	if ((not InCombatLockdown()) and (command == "spell" or command == "item" or command == "macro" or command == "companion")) then
		ABTMethods_SetFromCursorInfo(self, command, value, subValue);
	end 
end



function ABTMethods_OnUpdate(self, elapsed)
	ABTMethods_AnimateFlash(self, elapsed);
	ABTMethods_RangeIndicator(self, elapsed);
end



function ABTMethods_Update(self)
	ABTMethods_UpdateTexture(self);
	ABTMethods_UpdateChecked(self);
	ABTMethods_UpdateCooldown(self);
	ABTMethods_UpdateUsable(self);
	ABTMethods_UpdateEquipped(self);
	ABTMethods_UpdateHotkeys(self);
	ABTMethods_UpdateText(self);

	if (GameTooltip:GetOwner() == self) then
		ABTMethods_UpdateTooltip(self);
	end
	
	ABTMethods_UpdateShow(self);
end



function ABTMethods_OnLoad(self)
	--Make it so that the button border is half transparent just like the normal bliz action bars.
	
	self:SetAttribute("checkselfcast", true);
	self:SetAttribute("checkfocuscast", true);
	self:SetAttribute("useparent-unit", true);			--??
	self:SetAttribute("useparent-actionpage", true);	--??
	
	self.set1type = "none";
	self.set1value = "";
	self.set1actualtype = "";
	self.set1name = "";
	self.set1id = "";
	
	self.set2type = "none";
	self.set2value = "";
	self.set2actualtype ="";
	self.set2name = "";
	self.set2id = "";
	
	self.enabled = true;
	self.alwaysShowGrid = false;
	self.locked = false;
	self.disableTooltip = false;
	self:RegisterForDrag("LeftButton", "RightButton");
	self:RegisterForClicks("AnyUp");
	
	_G[self:GetName().."NormalTexture"]:SetVertexColor(1.0, 1.0, 1.0, 0.5);
	table.insert(ABTFrame.buttons, self);
end



function ABTMethods_LoadAll(entries, settings)

	for k,v in pairs(entries) do
		local button = _G[k]; --Get the button specified by the key
		if (button) then
			
			button.set1type = settings[k.."Set1Type"];
			button.set1value = settings[k.."Set1Value"];
			button.set1actualtype = settings[k.."Set1ActualType"];
			button.set1name = settings[k.."Set1Name"];
			button.set1id = settings[k.."Set1Id"];
			
			button.set2type = settings[k.."Set2Type"];
			button.set2value = settings[k.."Set2Value"];
			button.set2actualtype = settings[k.."Set2ActualType"];
			button.set2name = settings[k.."Set2Name"];
			button.set2id = settings[k.."Set2Id"];
			ABTMethods_UpdateSpell(button);
			ABTMethods_UpdateMacro(button);
			ABTMethods_UpdateCompanion(button);
			ABTMethods_SetFromStoredCommand(button);

		end
	end

end



function ABTMethods_UpdateTexture(self)
	local icon = _G[self:GetName().."Icon"];
	local command, value = ABTMethods_GetCommand(self);
	local realCommand, realValue = ABTMethods_GetCommand(self, true);
	local texture = nil;
		
	if (command == "spell") then
		texture = GetSpellTexture(value);			
	elseif (command == "item") then
		texture = GetItemIcon(value);
		if (not texture) then
			texture = GetItemIcon(ABTMethods_GetId(self));
		end
	elseif (command == "MOUNT" or command == "CRITTER") then
		local id, name, spellId;
		id, name, spellId, texture = GetCompanionInfo(command, value);
	end

	--Handle if the real button type is macro and we should override the texture
	if (realCommand == "macro") then
		local macroName, macroTexture = GetMacroInfo(realValue);
		if (not texture or macroTexture ~= "Interface\\Icons\\INV_Misc_QuestionMark") then
			texture = macroTexture;
		end
	end
		
	--Set or unset the icon
	if (texture) then
		icon:SetTexture(texture);
		icon:SetVertexColor(1.0, 1.0, 1.0, 1.0);
		icon:Show();
		self:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2");

	elseif (command == "spell") then
		--This is a special state where the spell is no longer known by the player, we will keep the spell incase they relearn it though,
		-- but we can't get the correct texture back so we will show the '?' icon with half alpha
		icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
		icon:SetVertexColor(1.0, 1.0, 1.0, 0.5);
		icon:Show();
		self:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2");
		
	else
		--there is no texture to set for this button (should only happen when the button command is "none"
		local buttonCooldown = _G[self:GetName().."Cooldown"];
		icon:Hide();
		buttonCooldown:Hide();
		self:SetNormalTexture("Interface\\Buttons\\UI-Quickslot");
	end

end



--Updates the text on the button (in the case of macros) or alternately the count on the button
function ABTMethods_UpdateText(self)
	local text = _G[self:GetName().."Count"];
	local actionName = _G[self:GetName().."Name"];
	local command, value = ABTMethods_GetCommand(self);
	
	text:SetText("");
	actionName:SetText("");
	
	if (command == "spell" and IsConsumableSpell(value)) then
		text:SetText(GetSpellCount(value));
	elseif (command == "item" and IsConsumableItem(value)) then
		text:SetText(GetItemCount(value));
	elseif (command == "item" and GetItemCount(value) > 1) then
		text:SetText(GetItemCount(value));
	elseif (self:GetAttribute("type") == "macro") then					--this may need to be replaced with the safer set1actualtype (or set2) at a later date, but for now type and actualtype in the case of macros should match
		actionName:SetText(GetMacroInfo(self:GetAttribute("macro")));
	end
end



function ABTMethods_UpdateTooltip(self)
	local command, value = ABTMethods_GetCommand(self);
	
	if (self.disableTooltip) then
		self.UpdateTooltip = nil;
		return;
	end
	if (GetCVar("UberTooltips") == "1") then
		GameTooltip_SetDefaultAnchor(GameTooltip, self);
	else --This really needs to be updated, since we don't know what the parent might be!
		local parent = self:GetParent();
		if (parent == MultiBarBottomRight or parent == MultiBarRight or parent == MultiBarLeft) then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		else
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		end
	end

	if (command == "spell") then
		local spellId = ABTMethods_FindSpellID(value);
		if (spellId and GameTooltip:SetSpell(spellId, BOOKTYPE_SPELL)) then
			self.UpdateTooltip = ABTMethods_UpdateTooltip;
		else
			self.UpdateTooltip = nil;
		end
	elseif (command == "MOUNT" or command == "CRITTER") then
		local id, name, spellId = GetCompanionInfo(command, value);
		if (GameTooltip:SetHyperlink("spell:"..spellId)) then
			self.UpdateTooltip = ABTMethods_UpdateTooltip;
		else
			self.UpdateTooltip = nil;
		end
	elseif (command == "item") then
		local res = false;
		-- First look for the item in the players equipped items
		local EquipSlot = ABTMethods_FindItemEquipped(value);
		if (EquipSlot) then
			res = GameTooltip:SetInventoryItem("player", EquipSlot);
		else
			-- Now check if the item is in the players backpack/bags
			local bag, slot = ABTMethods_FindItemInv(value);
			if (bag) then
				res = GameTooltip:SetBagItem(bag, slot);
			else
				-- The item is not on the player so pull an itemlink from the api and display that
				local name, hyperLink = GetItemInfo(ABTMethods_GetId(self));
				if (hyperLink) then
					res = GameTooltip:SetHyperlink(hyperLink);
				end
			end
		end
		
		if (res) then
			self.UpdateTooltip = ABTMethods_UpdateTooltip;
		else
			self.UpdateTooltip = nil;
		end
		
	elseif (command == "macro") then
		local set = 1
		if (GameTooltip:SetText(self["set"..set.."name"], 1.0, 1.0, 1.0)) then
			self.UpdateTooltip = ABTMethods_UpdateTooltip;
		else
			self.UpdateTooltip = nil;
		end
	end
end



function ABTMethods_UpdateHotkeys(self)

	local hotkey = _G[self:GetName().."HotKey"];
	local key = GetBindingKey("CLICK "..self:GetName()..":LeftButton");

	local text = GetBindingText(key, "KEY_", 1);
	if (text == "") then
		hotkey:SetText(RANGE_INDICATOR);
		hotkey:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -2);
		hotkey:Hide();
	else
		hotkey:SetText(text);
		hotkey:SetPoint("TOPLEFT", self, "TOPLEFT", -2, -2);
		hotkey:Show();
	end
end



function ABTMethods_UpdateChecked(self)
	local command, value = ABTMethods_GetCommand(self);

	if (command == "spell" and (IsCurrentSpell(value) or IsAutoRepeatSpell(value))) then
		self:SetChecked(1);
	elseif (command == "item" and IsCurrentItem(value)) then
		self:SetChecked(1);
	elseif (command == "MOUNT" or command == "CRITTER") then
		local id, name, spellId, texture, isCurrent = GetCompanionInfo(command, value);
		self:SetChecked(isCurrent);
		local castName = UnitCastingInfo("player"); --this is a cheat to see if we are casting this companion since the api does not appear to expose the info via other methods?? (it has a marginal delay so should be replaced when possible)
		if (castName == name) then
			self:SetChecked(1);
		end
	else
		self:SetChecked(0);
	end

end



function ABTMethods_UpdateCooldown(self)
	local cooldown = _G[self:GetName().."Cooldown"];
	local start, duration, enable;
	local command, value = ABTMethods_GetCommand(self);
	
	if (command == "spell" and ABTMethods_FindSpellID(value)) then
		start, duration, enable = GetSpellCooldown(value);
	elseif (command == "item") then
		start, duration, enable = GetItemCooldown(value);
	elseif (command == "MOUNT" or command == "CRITTER") then
		start, duration, enable = GetCompanionCooldown(command, value);
	end
	
	if (start == nil) then
		start, duration, enable = 0, 0, 0;
	end
	CooldownFrame_SetTimer(cooldown, start, duration, enable);
end



function ABTMethods_UpdateUsable(self)
	local name = self:GetName();
	local icon = _G[name.."Icon"];
	local normalTexture = _G[name.."NormalTexture"];
	local isUsable, notEnoughMana = true, false;
	local command, value = ABTMethods_GetCommand(self);

	if (command == "spell") then
		isUsable, notEnoughMana = IsUsableSpell(value);
	elseif (command == "item" and GetItemCount(value) == 0) then
		isUsable = false;

	elseif (command == "MOUNT" or command == "CRITTER") then
		--we need to find a cheat to handle this, perhaps checking, indoors/outdoors/incombat - some pets have reagents too...
	end

	if (isUsable) then
		icon:SetVertexColor(1.0, 1.0, 1.0);
		normalTexture:SetVertexColor(1.0, 1.0, 1.0);
	elseif (notEnoughMana) then
		icon:SetVertexColor(0.5, 0.5, 1.0);
		normalTexture:SetVertexColor(0.5, 0.5, 1.0);
	else
		icon:SetVertexColor(0.4, 0.4, 0.4);
		normalTexture:SetVertexColor(1.0, 1.0, 1.0);
	end
end



-- Add a green border if button is an equipped item
function ABTMethods_UpdateEquipped(self)

	local command, value = ABTMethods_GetCommand(self);
	local border = _G[self:GetName().."Border"];
	
	if (command == "item" and IsEquippedItem(value)) then
		border:SetVertexColor(0, 1.0, 0, 0.35);
		border:Show();
	else
		border:Hide();
	end
end



function ABTMethods_UpdateShow(self)
	if (InCombatLockdown()) then
		return;
	end

	if (self:IsShown()) then
	--evaluate if the icon should be toggled hidden
		if (not self.enabled or
			not (self:GetAttribute("type") ~= "none" or self.alwaysShowGrid or ABTFrame.showGrid)) then
			self:Hide();
		end
		
	else
	--evaluate if the icon should be toggled shown
		if (self.enabled and
			(self:GetAttribute("type") ~= "none" or self.alwaysShowGrid or ABTFrame.showGrid)) then
			self:Show();
		end
	end
end



--Return the type and command value, setting real prevents macros from being interpreted
--Note that in both cases the real type will be returned for CRITTERS and MOUNTS even though they
--work as spells for the purpose of the secure click activating them
function ABTMethods_GetCommand(self, real)
	local set = 1
	local command = self["set"..set.."actualtype"];
	local value = self:GetAttribute(command);
	
	if (command == "macro" and not real) then
		local spellName, spellRank = GetMacroSpell(value);
		if (spellName) then
			command = "spell";
			value = spellName.."("..spellRank..")";
		else
			local itemName, itemLink = GetMacroItem(value);
			if (itemName) then
				command = "item";
				value = itemLink;
			end
		end
	elseif (command == "MOUNT" or command == "CRITTER") then
		value = self["set"..set.."id"];
	end
	
	return command, value;
end




function ABTMethods_GetId(self, set)
	if (not set) then
		set = 1
	end
	return self["set"..set.."id"];
end

function ABTMethods_SetCommand(self, command, value, actualType, name, id, noSave, set)
	if (InCombatLockdown()) then
		UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1.0, 0.1, 0.1, 1.0);
		return false;
	end
	
	--Store the button settings based on the current talent set
	local currentSet = 1
	if (not set) then
		set = currentSet;
	end

	self["set"..set.."type"] = command;
	self["set"..set.."value"] = value;
	self["set"..set.."actualtype"] = actualType;
	self["set"..set.."name"] = name;
	self["set"..set.."id"] = id;
	
	--Set the button to it's new command if we are updating the current set
	if (set == currentSet) then
		local currentCommand = self:GetAttribute("type");
		self:SetAttribute(command, value);
		self:SetAttribute("type", command);
	
		--Clear the existing command provided it is a different type
		if command ~= currentCommand then
			self:SetAttribute(currentCommand, "");
		end
		ABTMethods_Update(self);
	end
	
	if (not noSave) then
		ABTMethods_Save(self);
	end
	return true;
end



function ABTMethods_Save(self)
	local entries = _G[self:GetAttribute("saveentries")];
	local settings = _G[self:GetAttribute("savesettings")];
	if (not entries or not settings) then
		--we don't save in this case
		return;
	end
	
	local selfName = self:GetName();
	
	entries[selfName] = 1; --This makes sure we have a key with the button name
	
	settings[selfName.."Set1Type"] = self.set1type;
	settings[selfName.."Set1Value"] = self.set1value;
	settings[selfName.."Set1ActualType"] = self.set1actualtype;
	settings[selfName.."Set1Name"] = self.set1name;
	settings[selfName.."Set1Id"] = self.set1id;
	
	settings[selfName.."Set2Type"] = self.set2type;
	settings[selfName.."Set2Value"] = self.set2value;
	settings[selfName.."Set2ActualType"] = self.set2actualtype;
	settings[selfName.."Set2Name"] = self.set2name;
	settings[selfName.."Set2Id"] = self.set2id;

end



function ABTMethods_SetFromCursorInfo(self, command, value, subValue)
	local currentCommand, currentValue = ABTMethods_GetCommand(self, true);
	
	if (command == "spell") then
		local spellNameFull, spell = ABTMethods_GetSpellName(value, BOOKTYPE_SPELL);
		ABTMethods_SetCommand(self, command, spellNameFull, "spell", spell, "");	--could be worth while holding onto the id?
		
	elseif (command == "item") then
		local itemName = GetItemInfo(value);
		ABTMethods_SetCommand(self, command, itemName, "item" , subValue, value);
		
	elseif (command == "macro") then
		local macroName = GetMacroInfo(value);
		ABTMethods_SetCommand(self, command, value, "macro", macroName, "");	--could be worth while holding onto the id?
	
	elseif (command == "companion") then
		local id, name, spellId = GetCompanionInfo(subValue, value);
		local spellName = GetSpellInfo(spellId);
		ABTMethods_SetCommand(self, --button
							"spell", --command
							spellName, --value
							subValue, --actual type
							name, --name
							value); --id (we use the value here which is the companion slot num  since the actual id doesn't have much use for us)
	
	end
	-- We theoretically should be good to set the cursor here.
	ABTMethods_SetCursor(currentCommand, currentValue);
end



function ABTMethods_SetFromStoredCommand(self)
	local set = 1
	
	ABTMethods_SetCommand(self, self["set"..set.."type"],
								self["set"..set.."value"],
								self["set"..set.."actualtype"],
								self["set"..set.."name"],
								self["set"..set.."id"], true);
end



function ABTMethods_SetCursor(command, value)
	if (InCombatLockdown()) then
		return;
	end

	ClearCursor();
	if (command == "spell") then
		PickupSpell(value);
	elseif (command == "item") then
		PickupItem(value);
	elseif (command == "macro") then
		PickupMacro(value);
	elseif (command == "MOUNT" or command == "CRITTER") then
		PickupCompanion(command, value);
	end
end



function ABTMethods_GetSpellName(spell, ...)
	local name, rank = GetSpellName(spell, ...);
	if (name) then
		return name.."("..rank..")", name;
	end
	return nil, nil;
end



function ABTMethods_FindSpellID(spellName)
	local i = 1;
	while true do
		local spell = ABTMethods_GetSpellName(i, BOOKTYPE_SPELL);
		if (not spell) then
			break;
		end
		if (spellName == spell) then
			return i;
		end
		i = i + 1;
	end
	return nil;
end



function ABTMethods_FindCompanionID(compType, compName)
	for i = 1, GetNumCompanions(compType) do
		local id, name = GetCompanionInfo(compType, i);
		if (name == compName) then
			return i;
		end
	end
	return nil;
end


function ABTMethods_UpdateSpell(self)
	if (InCombatLockdown() or
		not ABTFrame.worldLoaded) then
		return;
	end
	
	if (self.set1actualtype == "spell") then
		local maxSpell = ABTMethods_GetSpellName(self.set1name);
		if (maxSpell and maxSpell ~= self.set1value) then
			ABTMethods_SetCommand(self, "spell", maxSpell, "spell", self.set1name, "", false, 1);
		end
	end
	if (self.set2actualtype == "spell") then
		local maxSpell = ABTMethods_GetSpellName(self.set2name);
		if (maxSpell and maxSpell ~= self.set2value) then
			ABTMethods_SetCommand(self, "spell", maxSpell, "spell", self.set2name, "", false, 2);
		end
	end

end



function ABTMethods_UpdateMacro(self)
	if (InCombatLockdown() or
		not ABTFrame.worldLoaded) then
		return;
	end

	-- There are a lot of things that can go wrong with tracking macros, without going to the extent of hooking the macro functions the below should do an adequate job
	if (self.set1actualtype == "macro") then
		local macroID = GetMacroIndexByName(self.set1name);
		if (macroID == 0) then
			ABTMethods_SetCommand(self, "none", "", "", "", "", false, 1);
		elseif (macroID ~= self.set1value) then
			ABTMethods_SetCommand(self, "macro", macroID, "macro", self.set1name, "", false, 1);
		end
	end
	if (self.set2actualtype == "macro") then
		local macroID = GetMacroIndexByName(self.set2name);
		if (macroID == 0) then
			ABTMethods_SetCommand(self, "none", "", "", "", "", false, 2);
		elseif (macroID ~= self.set2value) then
			ABTMethods_SetCommand(self, "macro", macroID, "macro", self.set2name, "", false, 2);
		end
	end
	
end



function ABTMethods_UpdateCompanion(self)
	if (InCombatLockdown() or
		not ABTFrame.worldLoaded) then
		return;
	end

	if (self.set1actualtype == "MOUNT" or self.set1actualtype == "CRITTER") then
		local id = ABTMethods_FindCompanionID(self.set1actualtype, self.set1name);
		if (id ~= self.set1id) then
			ABTMethods_SetCommand(self, "spell", self.set1value, self.set1actualtype, self.set1name, id, false, 1);
		end
	end
	if (self.set2actualtype == "MOUNT" or self.set2actualtype == "CRITTER") then
		local id = ABTMethods_FindCompanionID(self.set2actualtype, self.set2name);
		if (id ~= self.set2id) then
			ABTMethods_SetCommand(self, "spell", self.set2value, self.set2actualtype, self.set2name, id, false, 2);
		end
	end
end


function ABTMethods_UpdateFlash(self)
	local command, value = ABTMethods_GetCommand(self);
	
	if (command == "spell" and
		(IsAutoRepeatSpell(value) or (IsAttackSpell(value) and IsCurrentSpell(value)))) then
		ABTMethods_StartFlash(self);
	else
		ABTMethods_StopFlash(self);
	end
end



function ABTMethods_StartFlash(self)
	self.flashing = 1;
	self.flashtime = 0;
	ABTMethods_UpdateChecked(self);
end



function ABTMethods_StopFlash(self)
	self.flashing = 0;
	_G[self:GetName().."Flash"]:Hide();
	ABTMethods_UpdateChecked(self);
end



function ABTMethods_AnimateFlash(self, elapsed)
	if (self.flashing == 1) then
		local flashtime = self.flashtime;
		flashtime = flashtime - elapsed;
		
		if (flashtime <= 0) then
			local overtime = -flashtime;
			if (overtime >= ATTACK_BUTTON_FLASH_TIME) then
				overtime = 0;
			end
			flashtime = ATTACK_BUTTON_FLASH_TIME - overtime;

			local flashTexture = _G[self:GetName().."Flash"];
			if (flashTexture:IsShown()) then
				flashTexture:Hide();
			else
				flashTexture:Show();
			end
		end
		
		self.flashtime = flashtime;
	end
end



function ABTMethods_RangeIndicator(self, elapsed)
	-- Handle range indicator
	local rangeTimer = self.rangeTimer;
	if (rangeTimer) then
		rangeTimer = rangeTimer - elapsed;

		if (rangeTimer <= 0) then
			local count = _G[self:GetName().."HotKey"];
			local command, value = ABTMethods_GetCommand(self);
			local valid;
			if (command == "spell") then
				valid = IsSpellInRange(value);
			elseif (command == "item") then
				valid = IsItemInRange(value);
			end
			if (count:GetText() == RANGE_INDICATOR) then
				if (valid == 0) then
					count:Show();
					count:SetVertexColor(1.0, 0.1, 0.1);
				elseif (valid == 1) then
					count:Show();
					count:SetVertexColor(0.6, 0.6, 0.6);
				else
					count:Hide();
				end
			else
				if ( valid == 0 ) then
					count:SetVertexColor(1.0, 0.1, 0.1);
				else
					count:SetVertexColor(0.6, 0.6, 0.6);
				end
			end
			rangeTimer = TOOLTIP_UPDATE_TIME;
		end
		
		self.rangeTimer = rangeTimer;
	end
end



function ABTMethods_SetAlwaysShowGrid(self, value)
	self.alwaysShowGrid = value;
	ABTMethods_UpdateShow(self);
end

function ABTMethods_SetLockButton(self, value)
	self.locked = value;
end

function ABTMethods_SetDisableTooltip(self, value)
	self.disableTooltip = value;
end

function ABTMethods_SetEnabled(self, value)
	self.enabled = value;
	ABTMethods_UpdateShow(self);
end



--Update the supplied values for loading if they do not match the current version
function ABTMethods_UpdateSavedDataVersion(entries, settings)

	if (not settings["version"] or settings["version"]+0 < 0.6) then
		local tempSettings={};

		for k,v in pairs(entries) do
			
			tempSettings[k.."Set1Type"] = settings[k.."Set1Type"];
			tempSettings[k.."Set1Value"] = settings[k.."Set1Value"];
			local actualType = settings[k.."Set1Type"];
			local name, id;
			if (actualType == "spell") then
				name = settings[k.."Set1SpellName"];
			elseif (actualType == "item") then
				name = "";
			elseif (actualType == "macro") then
				name = settings[k.."Set1MacroName"];
			end
			tempSettings[k.."Set1ActualType"] = actualType;
			tempSettings[k.."Set1Name"] = name;
			tempSettings[k.."Set1Id"] = "";
			
			tempSettings[k.."Set2Type"] = settings[k.."Set2Type"];
			tempSettings[k.."Set2Value"] = settings[k.."Set2Value"];
			actualType = settings[k.."Set2Type"];
			if (actualType == "spell") then
				name = settings[k.."Set2SpellName"];
			elseif (actualType == "item") then
				name = "";
			elseif (actualType == "macro") then
				name = settings[k.."Set2MacroName"];
			end
			tempSettings[k.."Set2ActualType"] = actualType;
			tempSettings[k.."Set2Name"] = name;
			tempSettings[k.."Set2Id"] = "";
		end
		settings = tempSettings;
		settings["version"] = 0.6;
	end

	-- Note to self: linking the version number in the table to the v of the addon is going to cause headaches later on, I will need to start using a different numbering system here.
	if (settings["version"]+0 < 0.72) then

		for k,v in pairs(entries) do
			for s = 1, 2 do
				if (settings[k.."Set"..s.."Type"] == "item") then
					--strip the item id and name out of the link 
					settings[k.."Set"..s.."Id"], settings[k.."Set"..s.."Value"] = ABTMethods_GetItemInfoFromLink(settings[k.."Set"..s.."Value"]);
				end
			end
		end
		settings["version"] = 0.72;
	end
	
	if (settings["version"]+0 < 1) then
		
		for k,v in pairs(entries) do
			for s = 1, 2 do
				if (settings[k.."Set"..s.."ActualType"] == "MOUNT" or settings[k.."Set"..s.."ActualType"] == "CRITTER") then
					--Get the spell name rather than companion name for 'value' - using the id (which should be reliable)
					local creatureID, creatureName, spellID = GetCompanionInfo(settings[k.."Set"..s.."ActualType"], settings[k.."Set"..s.."Id"]);
					local name = GetSpellInfo(spellID);
					settings[k.."Set"..s.."Value"] = name;
				end
			end
		end
		settings["version"] = 1;
	end
	return entries, settings;
end


function ABTMethods_GetItemInfoFromLink(ItemLink)
	if (not ItemLink) then
		return nil, nil;
	end
	local s, e, id, name = strfind(ItemLink, "item:(%d+):.-h%[(.-)%]");
	
	return id, name;
end

function ABTMethods_FindItemInv(ItemName)
	for i = 0,4 do
		local size = GetContainerNumSlots(i);
		for s = 1,size do
			local id, name = ABTMethods_GetItemInfoFromLink(GetContainerItemLink(i, s));
			if (name == ItemName) then
				return i, s;
			end
		end
	end
	return nil, nil;
end

function ABTMethods_FindItemEquipped(ItemName)
	for i = 0,23 do
		local id, name = ABTMethods_GetItemInfoFromLink(GetInventoryItemLink("player", i));
		if (name == ItemName) then
			return i;
		end
	end
	return nil;
end
