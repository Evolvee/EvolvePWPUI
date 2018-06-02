----------------------------------------------------------------------------------------------------
-- Settings
----------------------------------------------------------------------------------------------------
-- The maximum quantity of an item you can enter - if you're afraid of accidentally buying 1,000
-- instead of 100, you could lower this.
local MAX_BUY_AMOUNT = 50000

-- If true, then if you can't afford to buy MAX_BUY_AMOUNT of an item then the maximum will be set
-- to however many you can afford.
local LIMIT_CAN_AFFORD = true

-- If buying an item that comes in batches, like 5x vials, and you pick a number like 7, this
-- decides if it would buy 5 or 10. If set to true, it would buy 10. If false, it would buy 5. When
-- rounding down, it will always buy at least 1 batch.
local ROUND_UP_BATCH = true

----------------------------------------------------------------------------------------------------
-- Helper functions
----------------------------------------------------------------------------------------------------
--------------------------------------------------
-- Convert a total amount to how many batches to buy in case it's something like 5x vials each.
--------------------------------------------------
local function ConvertBatchAmount(amount, itemID)
	local batchQuantity = select(4, GetMerchantItemInfo(itemID))
	if batchQuantity > 1 then
		if ROUND_UP_BATCH then
			amount = ceil(amount / batchQuantity)
		else
			amount = floor(amount / batchQuantity)
			if (amount == 0) then
				amount = 1
			end
		end
	end
	return amount
end

----------------------------------------------------------------------------------------------------
-- Update an item's price to show the total cost and close the popup when switching store pages.
----------------------------------------------------------------------------------------------------
local currentItemPage       = 0   -- which page the item is on
local currentItemIndex      = 0   -- which item slot it is on the page (1 to 10)
local currentItemID         = 0   -- which item it is in the entire store inventory
local currentItemAmount     = 0   -- the last quantity that has been updated so far
local currentItemPrice      = 0   -- how much a single unit of the item costs
local currentItemMoneyFrame = nil -- frame displaying the item's money cost, if it uses normal money
local currentItemTokenFrame = nil -- frame displaying the item's alt currency cost, if it uses any

--------------------------------------------------
-- Overwritten Blizzard function - handles displaying alternative currency on shop items. This
-- version accepts a quantity argument to modify the item's cost
--------------------------------------------------
function MerchantFrame_UpdateAltCurrency(index, i, quantity)
	quantity = quantity or 1
	local itemTexture, itemValue, pointsTexture, button
	local honorPoints, arenaPoints, itemCount = GetMerchantItemCostInfo(index)
	local frameName = "MerchantItem" .. i .. "AltCurrencyFrame"
	button = getglobal(frameName .. "Points")
	-- update Alt Currency Frame with pointsValues
	if honorPoints and honorPoints ~= 0 then
		local factionGroup = UnitFactionGroup("player")
		if factionGroup then
			pointsTexture = "Interface\\TargetingFrame\\UI-PVP-" .. factionGroup
		end
		button.pointType = HONOR_POINTS
		AltCurrencyFrame_Update(frameName .. "Points", pointsTexture, honorPoints * quantity)
		button:Show()
	elseif arenaPoints and arenaPoints ~= 0 then
		button.pointType = ARENA_POINTS
		AltCurrencyFrame_Update(frameName .. "Points", "Interface\\PVPFrame\\PVP-ArenaPoints-Icon", arenaPoints * quantity)
		button:Show()
	else
		button:Hide()
	end
	-- update Alt Currency Frame with itemValues
	if itemCount > 0 then
		for i = 1 , MAX_ITEM_COST do
			button = getglobal(frameName .. "Item" .. i)
			button.index = index
			button.item = i

			itemTexture, itemValue, button.itemLink = GetMerchantItemCostItem(index, i)
			AltCurrencyFrame_Update(frameName .. "Item" .. i, itemTexture, itemValue * quantity)

			-- Anchor items based on how many item costs there are.
			if i > 1 then
				button:SetPoint("LEFT", frameName .. "Item" .. i - 1, "RIGHT", 4, 0)
			elseif i == 1 and arenaPoints and honorPoints == 0 then
				button:SetPoint("LEFT", frameName .. "Points", "LEFT", 0, 0)
			else
				button:SetPoint("LEFT", frameName .. "Points", "RIGHT", 4, 0)
			end
			if not itemTexture then
				button:Hide()
			else
				button:Show()
			end
		end
	else
		for i = 1, MAX_ITEM_COST do
			getglobal(frameName .. "Item" .. i):Hide()
		end
	end
end

--------------------------------------------------
-- When the stack split popup opens, an event is created to watch for page and quantity changes.
--------------------------------------------------
StackSplitFrame:SetScript("OnShow", function()
	if currentItemMoneyFrame == nil and currentItemTokenFrame == nil then
		return -- either no cost or not a merchant item, so don't bother watching
	end

	StackSplitFrame:SetScript("OnUpdate", function()
		-- if no longer on the same page then force the popup to close
		if currentItemPage ~= MerchantFrame.page then
			StackSplitFrame:Hide()
		else
			local amount = ConvertBatchAmount(StackSplitText:GetText() or 0, currentItemID)
			if amount ~= currentItemAmount then
				currentItemAmount = amount
				if currentItemMoneyFrame then
					MoneyFrame_Update(currentItemMoneyFrame:GetName(), currentItemAmount * currentItemPrice)
				end
				if currentItemTokenFrame then
					MerchantFrame_UpdateAltCurrency(currentItemID, currentItemIndex, currentItemAmount)
				end
			end
		end
	end)
end)

--------------------------------------------------
-- When the stack split popup closes, disable the watching script and reset the item's price.
--------------------------------------------------
StackSplitFrame:SetScript("OnHide", function()
	StackSplitFrame:SetScript("OnUpdate", nil)
	if currentItemPage == MerchantFrame.page then
		if currentItemMoneyFrame then
			MoneyFrame_Update(currentItemMoneyFrame:GetName(), currentItemPrice)
			currentItemMoneyFrame = nil
		end
		if currentItemTokenFrame then
			MerchantFrame_UpdateAltCurrency(currentItemID, currentItemIndex)
			currentItemTokenFrame = nil
		end
	end
end)

----------------------------------------------------------------------------------------------------
-- Overwritten Blizzard function from inside MerchantItemButton_OnLoad() - handles buying the items
-- when using the "split stack" popup window. This version handles items that come in batches.
----------------------------------------------------------------------------------------------------
local function NewSplitStack(button, amount)
	if button.extendedCost then
		MerchantFrame_ConfirmExtendedItemCost(button, amount)
	elseif amount > 0 then
		amount = ConvertBatchAmount(amount, button:GetID())
		-- BuyMerchantItem() can only buy up to 255 at once, so a loop will buy stacks instead
		local itemID = button:GetID()
		local maxStackSize = GetMerchantItemMaxStack(itemID)
		while amount > maxStackSize do
			BuyMerchantItem(itemID, maxStackSize)
			amount = amount - maxStackSize
		end
		if amount > 0 then
			BuyMerchantItem(itemID, amount)
		end
	end
end

-- set the 10 merchant item buttons to use the new version
for i = 1,10 do
	_G["MerchantItem" .. i .. "ItemButton"].SplitStack = NewSplitStack
end

----------------------------------------------------------------------------------------------------
-- Overwritten Blizzard function - handles opening the "split stack" popup on an item. This version
-- sets the new limit instead of being based on the item's max stacking amount and it allows every
-- item in a store to use the popup even if they can't stack or come in batches.
----------------------------------------------------------------------------------------------------
function MerchantItemButton_OnModifiedClick(button)
	if MerchantFrame.selectedTab == 1 then -- is merchant frame
		if HandleModifiedItemClick(GetMerchantItemLink(this:GetID())) then
			return
		end

		if IsModifiedClick("SPLITSTACK") then
			-- changed: remove restriction for buying multiple items when stacking isn't possible
			-- changed: set the normal max stack value to whatever MAX_BUY_AMOUNT is
			local maxStack = MAX_BUY_AMOUNT
			local price, batch = select(3, GetMerchantItemInfo(this:GetID()))
			local honorPoints, arenaPoints, itemCount = GetMerchantItemCostInfo(this:GetID())

			-- changed: optionally lower the max stack value to the maximum that can be afforded.
			if LIMIT_CAN_AFFORD then
				local canAfford = maxStack
				local checkAfford

				if price and price > 0 then
					canAfford = floor(GetMoney() / price)
				end
				if honorPoints > 0 then
					local checkAfford = floor(GetHonorCurrency() / honorPoints)
					if checkAfford < canAfford then
						canAfford = checkAfford
					end
				end
				if arenaPoints > 0 then
					local checkAfford = floor(GetArenaCurrency() / arenaPoints)
					if checkAfford < canAfford then
						canAfford = checkAfford
					end
				end
				if itemCount > 0 then
					for i = 1, MAX_ITEM_COST do
						local _, cost, itemLink = GetMerchantItemCostItem(this:GetID(), i)
						if cost > 0 then
							local checkAfford = floor(GetItemCount(itemLink, false, false) / cost)
							if checkAfford < canAfford then
								canAfford = checkAfford
							end
						end
					end
				end

				canAfford = canAfford * batch
				if canAfford < maxStack then
					maxStack = canAfford
				end
			end

			-- changed: don't open the stack window if you can't afford at least 1 of the item
			if maxStack > 0 then
				-- changed: set up info about the item so that its total cost can be changed
				StackSplitFrame:Hide() -- to reset the cost of another item in case the popup is open
				currentItemPage = MerchantFrame.page
				currentItemIndex = this:GetID() - ((currentItemPage - 1) * 10)
				currentItemID = this:GetID()
				currentItemAmount = 0
				currentItemPrice = price
				if price and price > 0 then
					currentItemMoneyFrame = getglobal("MerchantItem" .. currentItemIndex .. "MoneyFrame")
				else
					currentItemMoneyFrame = nil
				end
				if honorPoints > 0 or arenaPoints > 0 or itemCount > 0 then
					currentItemTokenFrame = getglobal("MerchantItem" .. currentItemIndex .. "AltCurrencyFrame")
				else
					currentItemTokenFrame = nil
				end
				OpenStackSplitFrame(maxStack, this, "BOTTOMLEFT", "TOPLEFT")
			end
			return
		end
	else
		HandleModifiedItemClick(GetBuybackItemLink(this:GetID()))
	end
end

----------------------------------------------------------------------------------------------------
-- Overwritten Blizzard function - handles input in the "split stack" window including non-merchant
-- places. This version will set the max stack value when you try to type a number higher than it,
-- instead of ignoring any input that would go higher.
----------------------------------------------------------------------------------------------------
function StackSplitFrame_OnChar(self, text)
	if text < "0" or text > "9" then
		return
	end

	if self.typing == 0 then
		self.typing = 1
		self.split = 0
	end

	local split = (self.split * 10) + text
	if split == self.split then
		if self.split == 0 then
			self.split = 1
		end
		return
	end

	if split == 0 then
		self.split = 1
	else
		if split > self.maxStack then
			split = self.maxStack
		end
		self.split = split
		StackSplitText:SetText(split)

		if split == 1 then
			StackSplitLeftButton:Disable()
		else
			StackSplitLeftButton:Enable()
		end
		if split == self.maxStack then
			StackSplitRightButton:Disable()
		else
			StackSplitRightButton:Enable()
		end
	end
end
