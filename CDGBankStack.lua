local CDGBS = ZO_Object:Subclass()

local CDGBankStack = {
	general = {
		addonName = "CDGBankStack"
	},
	defaults = {
		logToDefaultChat = false
	}
}

function CDGBS:eventBankOpen(...)
	local _, bankSlots = GetBagInfo(BAG_BANK)
	local _, bagSlots = GetBagInfo(BAG_BACKPACK)

	for bankSlot = 1, bankSlots do
		local bankItemName = GetItemName(BAG_BANK, bankSlot)
		local bankStack,bankMaxStack = GetSlotStackSize(BAG_BANK, bankSlot)
		for bagSlot = 1, bagSlots do
			local bagItemName = GetItemName(BAG_BACKPACK, bagSlot)
			local bagStack,bagMaxStack = GetSlotStackSize(BAG_BACKPACK, bagSlot)
			local bagItemLink = GetItemLink(BAG_BACKPACK, bagSlot, LINK_STYLE_DEFAULT)
			
			if bankItemName == bagItemName and bagItemName~=nil and bagItemName ~= "" then
				local quantity = bagStack
				if (bankMaxStack-bankStack) < bagStack then
					quantity = bankMaxStack-bankStack
				end
				
				if bankStack ~= bankMaxStack then
					msg = "Banked " .. quantity.."/"..bagStack .. " " ..bagItemLink
					d(msg)
					if CDGLibGui ~= nil then
						CDGLibGui.addMessage(msg)
					end
					CallSecureProtected("PickupInventoryItem",BAG_BACKPACK, bagSlot, bankMaxStack-bankStack)
					CallSecureProtected("PlaceInTransfer")
				end
				--PlaceInInventory(INVENTORY_BANK, bankSlot)
			end
		end
	end
end

function CDGBS_OnInitialized()
	EVENT_MANAGER:RegisterForEvent("CDGBankStack", EVENT_OPEN_BANK, function(...) CDGBS:eventBankOpen(...) end)	
end
