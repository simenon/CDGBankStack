local LAM2 = LibStub:GetLibrary("LibAddonMenu-2.0")
local CDGBS = ZO_Object:Subclass()

local Addon =
{
    Name = "CDGBankStack",
    NameSpaced = "CDG Bank Stacker",
    Author = "CrazyDutchGuy",
    Version = "0.7",
}

local CDGBankStack =
{ 
	defaults = 
	{
		logToDefaultChat = true,
		logToCDGShowLoot = true,
	}
}

local CDGBS_SV = {}

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
					CallSecureProtected("PlaceInInventory", BAG_BANK, bankSlot)
					--CallSecureProtected("PlaceInTransfer")
				end
				--
				-- Stack is updated, if we find another same item to stack in the bank, then we need to update our reference of the bankstack, else we might get stuck
				--
				bagStack,bagMaxStack = GetSlotStackSize(BAG_BACKPACK, bagSlot)
			end
		end
	end
end


local function createLAM2Panel()
    local panelData = 
    {
        type = "panel",
        name = Addon.NameSpaced,
        displayName = "|cFFFFB0" .. Addon.NameSpaced .. "|r",
        author = Addon.Author,
        version = Addon.Version,        
    }

    local optionsData = 
    {
        [1] = 
        {
            type = "checkbox",
            name = "Log to default chat",
            tooltip = "Log to default chat.",
            getFunc = function() return CDGBS_SV.logToDefaultChat end,
            setFunc = function(value) CDGBS_SV.logToDefaultChat = value end,
        },
        [2] =
        {
            type = "checkbox",
            name = "Log to CDG Show Loot",
            tooltip = "Log to CDG Show Loot.",
            getFunc = function() return CDGBS_SV.logToCDGShowLoot end,
            setFunc = function(value) CDGBS_SV.logToCDGShowLoot = value end,
        },
        [3] =
        {
            type = "description",
            text = "|cFF2222CrazyDutchGuy's|r Bank Stack is an addon that automatically moves items from your backpack onto unfilled stacks in your bank.",
        }
    } 

   	LAM2:RegisterAddonPanel(Addon.Name.."LAM2Options", panelData)    
    LAM2:RegisterOptionControls(Addon.Name.."LAM2Options", optionsData)
end 

function CDGBS:EVENT_ADD_ON_LOADED(eventCode, addOnName, ...)
	if(addOnName == Addon.Name) then
		--
		-- Initialize our saved variabeles, if needed
		--
		CDGBS_SV = ZO_SavedVars:New(Addon.Name.."_SV", 1, nil, CDGBankStack.defaults)
		--
		-- Register our stuff in the addon settings
		--
		createLAM2Panel()
		--
		-- Register on all the other events we want to listen on
		--
		EVENT_MANAGER:RegisterForEvent(Addon.Name, EVENT_OPEN_BANK, function(...) CDGBS:EVENT_OPEN_BANK(...) end)		
		--
		-- Done loading myself. Deregister Event
		--
		EVENT_MANAGER:UnregisterForEvent(Addon.Name, EVENT_ADD_ON_LOADED)
	end
end

function CDGBS_OnInitialized()
	EVENT_MANAGER:RegisterForEvent(Addon.Name, EVENT_ADD_ON_LOADED, function(...) CDGBS:EVENT_ADD_ON_LOADED(...) end )		
end
