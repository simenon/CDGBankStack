local LAM = LibStub:GetLibrary("LibAddonMenu-1.0")
local CDGBS = ZO_Object:Subclass()

local CDGBankStack = {
	general = {
		addonName = "CDGBankStack"
	},
	defaults = {
		logToDefaultChat = true,
		logToCDGShowLoot = true,
	}
}

local CDGBS_SV = {}

local function InitializeLAMSettings()
	local lamID = CDGBankStack.general.addonName .."LAM"
	local panelID = LAM:CreateControlPanel(lamID, "CDG Bank Stack")
	LAM:AddHeader(panelID, lamID.."Header".."GO", "General Options")
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."LogDefault", "Log to default chat", nil, function() return CDGBS_SV.logToDefaultChat end, function(value) CDGBS_SV.logToDefaultChat = value end,  false, nil)
	LAM:AddCheckbox(panelID, lamID.."CheckBox".."LogToCDGShowLoot", "Log to CDG Show Loot", nil, function() return CDGBS_SV.logToCDGShowLoot end, function(value) CDGBS_SV.logToCDGShowLoot = value end,  false, nil)
end

local function logActionToChat(msg)
	if CDGBS_SV.logToDefaultChat then
		d(msg)
	end
	if CDGBS_SV.logToCDGShowLoot and CDGLibGui then
		CDGLibGui.addMessage(msg)
	end
end

function CDGBS:EVENT_OPEN_BANK(...)
	local _, bankSlots = GetBagInfo(BAG_BANK)
	local _, bagSlots = GetBagInfo(BAG_BACKPACK)
	--
	-- Loop over all the bankslots and get the info needed
	--
	for bankSlot = 0, bankSlots do
		local bankItemName = GetItemName(BAG_BANK, bankSlot)
		local bankStack,bankMaxStack = GetSlotStackSize(BAG_BANK, bankSlot)
		--
		-- For each bankslot, look in our bagslot if we have an item corresponding 
		-- and see if we can stack onto it. This could be more efficiently, but 
		-- for these purposes it works good enough.
		--
		for bagSlot = 0, bagSlots do
			local bagItemName = GetItemName(BAG_BACKPACK, bagSlot)
			local bagStack,bagMaxStack = GetSlotStackSize(BAG_BACKPACK, bagSlot)
			local bagItemLink = GetItemLink(BAG_BACKPACK, bagSlot, LINK_STYLE_DEFAULT)
			
			if bankItemName == bagItemName and bagItemName~=nil and bagItemName ~= "" then
				local quantity = bagStack
				if (bankMaxStack-bankStack) < bagStack then
					quantity = bankMaxStack-bankStack
				end
				
				if bankStack ~= bankMaxStack then
					-- Small thanks to Garkin for pointing me to the zo_strformat routine
					logActionToChat(zo_strformat("Banked <<2[1/$d]>>/<<3>> <<tm:1>>", bagItemLink, quantity, bagStack))
					CallSecureProtected("PickupInventoryItem",BAG_BACKPACK, bagSlot, bankMaxStack-bankStack)
					CallSecureProtected("PlaceInTransfer")
				end
				--
				-- Stack is updated, if we find another same item to stack in the bank, then we need to update our reference of the bankstack, else we might get stuck
				--
				bagStack,bagMaxStack = GetSlotStackSize(BAG_BACKPACK, bagSlot)
			end
		end
	end
end

function CDGBS:EVENT_ADD_ON_LOADED(eventCode, addOnName, ...)
	if(addOnName == CDGBankStack.general.addonName) then
		--
		-- Initialize our saved variabeles, if needed
		--
		CDGBS_SV = ZO_SavedVars:New(CDGBankStack.general.addonName.."_SV", 1, nil, CDGBankStack.defaults)
		--
		-- Register our stuff in the addon settings
		--
		InitializeLAMSettings()
		--
		-- Register on all the other events we want to listen on
		--
		EVENT_MANAGER:RegisterForEvent(CDGBankStack.general.addonName, EVENT_OPEN_BANK, function(...) CDGBS:EVENT_OPEN_BANK(...) end)
		--
		-- A nice message to say the addon is loaded
		--
		logActionToChat("|cFF2222CrazyDutchGuy's|r Bank Stacker |c0066990.2|r Loaded")
		--
		-- Done loading myself. Deregister Event
		--
		EVENT_MANAGER:UnregisterForEvent(CDGBankStack.general.addonName, EVENT_ADD_ON_LOADED)
	end
end

function CDGBS_OnInitialized()
	EVENT_MANAGER:RegisterForEvent(CDGBankStack.general.addonName, EVENT_ADD_ON_LOADED, function(...) CDGBS:EVENT_ADD_ON_LOADED(...) end )	
end
