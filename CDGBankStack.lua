local CDGBS = ZO_Object:Subclass()

CDGBS.Name = "CDGBankStack"
CDGBS.NameSpaced = "CDG Bank Stacker"
CDGBS.Author = "|cFFA500CrazyDutchGuy|r"
CDGBS.Version = "1.15"
CDGBS.defaults = {
	logToDefaultChat = true,
	logToCDGShowLoot = true,
	ignoreSavedItems = true,
}

CDGBS.SV = {}

function CDGBS:LogActionToChat(msg)
	if CDGBS.SV.logToDefaultChat then
		d(msg)
	end
	if CDGBS.SV.logToCDGShowLoot and CDGLibGui then
		CDGLibGui.addMessage(msg)
	end
end

function CDGBS:IsItemProtected(bagId, slotId)
	--Item Saver support
	if ItemSaver_IsItemSaved and ItemSaver_IsItemSaved(bagId, slotId) then
		return true
	end

	--FCO ItemSaver support
	if FCOIsMarked and FCOIsMarked(GetItemInstanceId(bagId, slotId), -1) then
		return true
	end

	--FilterIt support
	if FilterIt and FilterIt.AccountSavedVariables and FilterIt.AccountSavedVariables.FilteredItems then
		local sUniqueId = Id64ToString(GetItemUniqueId(bagId, slotId))
		if FilterIt.AccountSavedVariables.FilteredItems[sUniqueId] then
			return true
		end
	end

	return false
end

function CDGBS:EVENT_OPEN_BANK(...)
	local bankCache = SHARED_INVENTORY:GetOrCreateBagCache(BAG_BANK)
	local bagCache  = SHARED_INVENTORY:GetOrCreateBagCache(BAG_BACKPACK)

	for bankSlot, bankSlotData in pairs(bankCache) do
		if not (bankSlotData.itemType == ITEMTYPE_FOOD or bankSlotData.itemType == ITEMTYPE_DRINK or bankSlotData.itemType == ITEMTYPE_POTION or bankSlotData.itemType == ITEMTYPE_SOUL_GEM or bankSlotData.itemType == ITEMTYPE_TOOL) then
			local bankStack, bankMaxStack = GetSlotStackSize(BAG_BANK, bankSlot)

			if bankStack > 0 and bankStack < bankMaxStack then
				for bagSlot, bagSlotData in pairs(bagCache) do
					if not bagSlotData.stolen and bankSlotData.rawName == bagSlotData.rawName and (not self.SV.ignoreSavedItems or (self.SV.ignoreSavedItems and not self:IsItemProtected(BAG_BACKPACK, bagSlot))) then
						local bagStack, bagMaxStack = GetSlotStackSize(BAG_BACKPACK, bagSlot)
						local bagItemLink = GetItemLink(BAG_BACKPACK, bagSlot, LINK_STYLE_DEFAULT)
						local quantity = zo_min(bagStack, bankMaxStack - bankStack) 

						if IsProtectedFunction("RequestMoveItem") then
							CallSecureProtected("RequestMoveItem", BAG_BACKPACK, bagSlot, BAG_BANK, bankSlot, quantity)
						else
							RequestMoveItem(BAG_BACKPACK, bagSlot, BAG_BANK, bankSlot, quantity)
						end

						self:LogActionToChat(zo_strformat("Banked [<<1>>/<<2>>] <<t:3>>", quantity, bagStack, bagItemLink))

						bankStack = bankStack + quantity

						if bankStack == bankMaxStack then
							break
						end
					end
				end
			end
		end
	end
end


function CDGBS:CreateLAM2Panel()
	local panelData = {
		type = "panel",
		name = self.NameSpaced,
		displayName = ZO_HIGHLIGHT_TEXT:Colorize(self.NameSpaced),
		author = self.Author,
		version = self.Version,
	}

	local optionsData = {
		{
			type = "checkbox",
			name = "Log to default chat",
			tooltip = "Log to default chat.",
			getFunc = function() return self.SV.logToDefaultChat end,
			setFunc = function(value) self.SV.logToDefaultChat = value end,
		},
		{
			type = "checkbox",
			name = "Log to CDG Show Loot",
			tooltip = "Log to CDG Show Loot.",
			getFunc = function() return self.SV.logToCDGShowLoot end,
			setFunc = function(value) self.SV.logToCDGShowLoot = value end,
		},
		{
			type = "checkbox",
			name = "Don't move \"saved\" items",
			tooltip = "Don't touch items marked by ItemSaver, FCO ItemSaver or Circonians FilterIt.",
			getFunc = function() return self.SV.ignoreSavedItems end,
			setFunc = function(value) self.SV.ignoreSavedItems = value end,
		},
		{
			type = "description",
			text = "|cEFEBBECrazyDutchGuy's Bank Stacker|r is an addon that automatically moves items from your backpack onto unfilled stacks in your bank.",
		}
	}

	local LAM2 = LibAddonMenu2
	LAM2:RegisterAddonPanel(self.Name.."LAM2Options", panelData)
	LAM2:RegisterOptionControls(self.Name.."LAM2Options", optionsData)
end 

function CDGBS:EVENT_ADD_ON_LOADED(eventCode, addOnName, ...)
	if (addOnName == self.Name) then
		EVENT_MANAGER:UnregisterForEvent(self.Name, EVENT_ADD_ON_LOADED)

		self.SV = ZO_SavedVars:New(self.Name.."_SV", 1, nil, self.defaults)

		self:CreateLAM2Panel()

		EVENT_MANAGER:RegisterForEvent(self.Name, EVENT_OPEN_BANK, function(...) CDGBS:EVENT_OPEN_BANK(...) end)
	end
end

EVENT_MANAGER:RegisterForEvent(CDGBS.Name, EVENT_ADD_ON_LOADED, function(...) CDGBS:EVENT_ADD_ON_LOADED(...) end)
