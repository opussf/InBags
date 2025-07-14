InBags_SLUG, InBags  = ...
InBags.MSG_ADDONNAME = C_AddOns.GetAddOnMetadata( InBags_SLUG, "Title" )
InBags.MSG_VERSION   = C_AddOns.GetAddOnMetadata( InBags_SLUG, "Version" )
InBags.MSG_AUTHOR    = C_AddOns.GetAddOnMetadata( InBags_SLUG, "Author" )

-- Colours
-- InBags.COLOR_RED = "|cffff0000"
-- COLOR_GREEN = "|cff00ff00"
-- COLOR_BLUE = "|cff0000ff"
-- COLOR_PURPLE = "|cff700090"
-- COLOR_YELLOW = "|cffffff00"
InBags.COLOR_ORANGE = "|cffff6d00"
-- COLOR_GREY = "|cff808080"
-- COLOR_GOLD = "|cffcfb52b"
-- COLOR_NEON_BLUE = "|cff4d4dff"
InBags.COLOR_END = "|r"

InBags_data = {}  -- [realm][name][itemid] = {}
InBags.bagIDs = {
	["bank"] = { -1, 6, 7, 8, 9, 10, 11, 12, -3 }, -- -1 is main bank slot, -3 is reagent bank bag
	["wbb"] = { 13, 14, 15, 16, 17 },
}
InBags.verbosity = 1 -- 0 = off, 1 = normal, 2 = info, 3 = Debug

function InBags.Print( msg, showName)
	-- print to the chat frame
	-- set showName to false to suppress the addon name printing
	if (showName == nil) or (showName) then
		msg = InBags.COLOR_ORANGE..InBags.MSG_ADDONNAME.."> "..InBags.COLOR_END..msg
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg )
end
function InBags.Debug(level, msg, showName )
	if level <= InBags.verbosity then
		InBags.Print( msg, showName )
	end
end
function InBags.OnLoad()
	SLASH_IC1 = "/ic"
	SlashCmdList["IC"] = function( msg ) InBags.Command( msg ); end
	-- SLASH_INBAGS1 = "/INBAGS"
	-- SlashCmdList["INBAGS"] = function( msg ) InBags.Command( "bags", msg ); end
	-- SLASH_INBANK1 = "/INBANK"
	-- SlashCmdList["INBANK"] = function( msg ) InBags.Command( "bank", msg ); end
	-- SLASH_INWBB1 = "/INWBB"
	-- SlashCmdList["INWBB"] = function( msg ) InBags.Command( "wbb", msg ); end

	InBags_Frame:RegisterEvent( "ADDON_LOADED" )
	InBags_Frame:RegisterEvent( "VARIABLES_LOADED" )
	InBags_Frame:RegisterEvent( "BANKFRAME_OPENED" )
	InBags_Frame:RegisterEvent( "BANKFRAME_CLOSED" )
	InBags_Frame:RegisterEvent( "BAG_UPDATE_DELAYED" )
	InBags_Frame:RegisterEvent( "PLAYER_LEAVING_WORLD" )
end
function InBags.ADDON_LOADED()
	InBags_Frame:UnregisterEvent( "ADDON_LOADED" )
	InBags.realm = GetRealmName()
	InBags.name = UnitName("player")
	TooltipDataProcessor.AddTooltipPostCall( Enum.TooltipDataType.Item, InBags.onTooltipSetItem )
end
function InBags.VARIABLES_LOADED()
	InBags_Frame:UnregisterEvent( "VARIABLES_LOADED" )
	InBags_data[InBags.realm] = InBags_data[InBags.realm] or {}
	InBags_data[InBags.realm][InBags.name] = InBags_data[InBags.realm][InBags.name] or {}
	InBags.me = InBags_data[InBags.realm][InBags.name]
	InBags.Print( "Loaded v"..InBags.MSG_VERSION )
end
function InBags.PLAYER_LEAVING_WORLD()
	local itemCount = 0
	for i in pairs( InBags.me ) do
		local destCount = 0
		for dest, _ in pairs( InBags.me[i] ) do
			destCount = destCount + 1
		end
		if destCount == 0 then
			InBags.me[i] = nil
		else
			itemCount = itemCount + 1
		end
	end
	if itemCount == 0 then
		InBags_data[InBags.realm][InBags.name] = nil
	end
	itemCount = 0
	for name in pairs( InBags_data[InBags.realm] ) do
		itemCount = itemCount + 1
	end
	if itemCount == 0 then
		InBags_data[InBags.realm] = nil
	end
end
function InBags.onTooltipSetItem( tooltip, tooltipdata )
	local itemID = tonumber(tooltipdata.id)
	local addLine = false
	if InBags.me[itemID] then
		InBags.lineData = {
			["leftText"] = "InventoryControl",
			["rightText"] = (InBags.me[itemID].bags and "Bags: "..InBags.me[itemID].bags.." " or "")
					..(InBags.me[itemID].bank and "Bank: "..InBags.me[itemID].bank.." " or "")
		}
		addLine = true
	end

	if addLine then tooltip:AddLineDataText( InBags.lineData ) end
end
function InBags.GetFirstOpenSlot( searchBags )
	-- Set this up to scan both bags and the bank in the future
	if not searchBags then
		searchBags = InBags.bagIDs.bags
	end
	for _, bag in ipairs( searchBags ) do
		InBags.Debug( 3, "Search bag: "..bag.." for an open slot", false )
		for slot = 1, C_Container.GetContainerNumSlots( bag ) do
			local itemStruct = C_Container.GetContainerItemInfo( bag, slot )
			if not itemStruct then
				return bag, slot
			end
		end
	end
end
function InBags.BuildGearSets()
	InBags.itemsInSets = {}
	for setNum = 0, C_EquipmentSet.GetNumEquipmentSets(), 1 do
		equipmentSetName = C_EquipmentSet.GetEquipmentSetInfo( setNum )
		if( equipmentSetName ) then
			local setItemArray = C_EquipmentSet.GetItemIDs( setNum )
			for i, itemID in pairs( setItemArray ) do
				if( not InBags.itemsInSets[itemID] ) then
					InBags.itemsInSets[itemID] = {}
				end
				table.insert( InBags.itemsInSets[itemID], equipmentSetName )
			end
		end
	end
end
----
function InBags.AddAction( itemID, link, bag, slot, quantity, dest )
	-- this adds an action to the InBags.actions
	-- move quantity of item from bag-slot to destination
	table.insert( InBags.actions, {
			["itemID"] = itemID, ["link"] = link, ["bag"] = bag, ["slot"] = slot, ["quantity"] = quantity, ["dest"] = dest } )
end
function InBags.BANKFRAME_OPENED()
	InBags.bankOpen = true
	InBags.Debug( 2, "Bank opened" )
	if not InBags.bagIDs.bags then
		InBags.bagIDs.bags = {}
		for bag = 0, NUM_BAG_SLOTS+1 do
			table.insert( InBags.bagIDs.bags, bag )
		end
	end
	InBags.BuildGearSets()
	-- make action structure
	InBags.actions = {}
	if IsShiftKeyDown() then
		InBags.toScan = "bags"
		InBags.Scan()
	end
end
function InBags.Scan()
	local markedToMove = {}
	InBags.Debug( 2, "SCAN: "..InBags.toScan )
	if InBags.toScan == "bags" then  -- figure out what to move to the bank
		for _, bag in pairs( InBags.bagIDs.bags ) do -- scan your bags
			for slot = 1, C_Container.GetContainerNumSlots( bag ) do
				local itemStruct = C_Container.GetContainerItemInfo( bag, slot ) -- get the item info (stackCount is how many are here)
				if( itemStruct ) then -- an item is found at (bag, slot)
					local inBags = C_Item.GetItemCount( itemStruct.itemID ) -- only in bags
					local inBank = C_Item.GetItemCount( itemStruct.itemID, true, false, true ) - inBags -- in bank and reagent Bank
					local inWBB = C_Item.GetItemCount( itemStruct.itemID, true, false, true, true ) - inBags - inBank
					local youHave = C_Item.GetItemCount( itemStruct.itemID, true, true, true, true ) -- include bank, uses, reagent, not account
					local wantInBags = ( not InBags.itemsInSets[itemStruct.itemID] and InBags.me[itemStruct.itemID] and
							InBags.me[itemStruct.itemID].bags or (inWBB > 0 and 0) or nil )
					local wantInBank = ( InBags.me[itemStruct.itemID] and InBags.me[itemStruct.itemID].bank or nil )
					markedToMove[itemStruct.itemID] = markedToMove[itemStruct.itemID] or 0
					local toMove = 0
					if( wantInBags and wantInBags < inBags or wantInBank ) then
						toMove = math.min( itemStruct.stackCount, inBags-wantInBags-markedToMove[itemStruct.itemID] )
						InBags.Debug( 3, itemStruct.hyperlink.." Bags: ("..inBags.."/"..wantInBags..") move: "..toMove.." marked: "..markedToMove[itemStruct.itemID], false )
						if toMove > 0 then
							InBags.AddAction( itemStruct.itemID, itemStruct.hyperlink, bag, slot, toMove, "bank" )
							markedToMove[itemStruct.itemID] = markedToMove[itemStruct.itemID]+toMove
						end
					end
				end
			end
		end
		InBags.toScan = "bank"
	elseif InBags.toScan == "bank" then  -- figure out what to move to the bags or the WBB
		for _, bag in pairs( InBags.bagIDs.bank ) do
			for slot = 1, C_Container.GetContainerNumSlots( bag ) do
				local itemStruct = C_Container.GetContainerItemInfo( bag, slot )
				if( itemStruct ) then
					local inBags = C_Item.GetItemCount( itemStruct.itemID ) -- only in bags
					local inBank = C_Item.GetItemCount( itemStruct.itemID, true, false, true ) - inBags -- in bank and reagent Bank
					local inWBB = C_Item.GetItemCount( itemStruct.itemID, true, false, true, true ) - inBags - inBank
					local youHave = C_Item.GetItemCount( itemStruct.itemID, true, true, true, true ) -- include bank, uses, reagent, not account
					local wantInBags = ( InBags.me[itemStruct.itemID] and InBags.me[itemStruct.itemID].bags or
							(inWBB > 0 and 0) or nil )
					local wantInBank = ( InBags.me[itemStruct.itemID] and InBags.me[itemStruct.itemID].bank or
							(inWBB > 0 and 0) or nil )
					local wantInWBB = ( not InBags.itemsInSets[itemStruct.itemID] and (inWBB > 0) )
					markedToMove[itemStruct.itemID] = markedToMove[itemStruct.itemID] or 0
					local toMove = 0
					if( wantInBank and wantInBank < inBank or not wantInBank ) then
						-- I want it in the bank and I have more than I want, or I don't want it in the bank
						if( wantInBags and inBags < wantInBags ) then -- put some in bags
							toMove = math.min( itemStruct.stackCount, wantInBags-inBags-markedToMove[itemStruct.itemID] )
							InBags.Debug( 3, itemStruct.hyperlink.." Bags: ("..inBags.."/"..wantInBags..") toBags: "..toMove.." marked: "..markedToMove[itemStruct.itemID], false )
							if toMove > 0 then
								InBags.AddAction( itemStruct.itemID, itemStruct.hyperlink, bag, slot, toMove, "bags" )
								markedToMove[itemStruct.itemID] = markedToMove[itemStruct.itemID]+toMove
							end
						end
						if( wantInWBB and not InBags.itemsInSets[itemStruct.itemID] ) then -- put some in the wbb
							toMove = math.min( itemStruct.stackCount, inBank-wantInBank-markedToMove[itemStruct.itemID] )
							InBags.Debug( 3, itemStruct.hyperlink.." Bank: ("..inBank.."/"..wantInBank..") toWBB: "..toMove.." marked: "..markedToMove[itemStruct.itemID], false )
							if toMove > 0 then
								InBags.AddAction( itemStruct.itemID, itemStruct.hyperlink, bag, slot, toMove, "wbb" )
								markedToMove[itemStruct.itemID] = markedToMove[itemStruct.itemID]+toMove
							end
						end
					end
				end
			end
		end
		InBags.toScan = "wbb"
	elseif InBags.toScan == "wbb" then
		for _, bag in pairs( InBags.bagIDs.wbb ) do
			for slot = 1, C_Container.GetContainerNumSlots( bag ) do
				local itemStruct = C_Container.GetContainerItemInfo( bag, slot )
				if( itemStruct ) then
					local inBags = C_Item.GetItemCount( itemStruct.itemID ) -- only in bags
					local inBank = C_Item.GetItemCount( itemStruct.itemID, true, false, true ) - inBags -- in bank and reagent Bank
					local inWBB = C_Item.GetItemCount( itemStruct.itemID, true, false, true, true ) - inBags - inBank
					local youHave = C_Item.GetItemCount( itemStruct.itemID, true, true, true, true ) -- include bank, uses, reagent, not account
					local wantInBags = ( InBags.me[itemStruct.itemID] and InBags.me[itemStruct.itemID].bags or
							(inWBB > 0 and 0) or nil )
					local wantInBank = ( InBags.me[itemStruct.itemID] and InBags.me[itemStruct.itemID].bank or
							(inWBB > 0 and 0) or nil )
					-- InBags.Print( itemStruct.itemID.."("..bag..", "..slot.."): bags: "..inBags.." bank: "..inBank.." wbb: "..inWBB.." total: "..youHave  )
					markedToMove[itemStruct.itemID] = markedToMove[itemStruct.itemID] or 0
					local toMove = 0
					if( wantInBags and inBags < wantInBags ) then
						toMove = math.min( itemStruct.stackCount, wantInBags-inBags-markedToMove[itemStruct.itemID] )
						InBags.Debug( 3, itemStruct.hyperlink.." Bags: ("..inBags.."/"..wantInBags..") toBags: "..toMove.." marked: "..markedToMove[itemStruct.itemID], false )
						if toMove > 0 then
							InBags.AddAction( itemStruct.itemID, itemStruct.hyperlink, bag, slot, toMove, "bags" )
							markedToMove[itemStruct.itemID] = markedToMove[itemStruct.itemID]+toMove
						end
					end
					if( wantInBank and inBank < wantInBags ) then
						toMove = math.min( itemStruct.stackCount, wantInBank-inBank-markedToMove[itemStruct.itemID] )
						InBags.Debug( 3, itemStruct.hyperlink.." Bank: ("..inBank.."/"..wantInBank..") toBank: "..toMove.." marked: "..markedToMove[itemStruct.itemID], false )
						if toMove > 0 then
							InBags.AddAction( itemStruct.itemID, itemStruct.hyperlink, bag, slot, toMove, "bank" )
							markedToMove[itemStruct.itemID] = markedToMove[itemStruct.itemID]+toMove
						end
					end
				end
			end
		end
		InBags.toScan = nil
	end
	InBags.Debug( 3, "Scan ended:" )
	InBags.BAG_UPDATE_DELAYED( nil, nil )
end
function InBags.BAG_UPDATE_DELAYED( self, bagID )
	if InBags.bankOpen then
		InBags.Debug( 3, "BAG_UPDATE: "..( bagID or "nil" ) )
		for i, a in ipairs( InBags.actions ) do
			InBags.Debug(3, string.format( "%i: move %2i of %s at (%i,%i) to %s",
					i, a.quantity, a.link, a.bag, a.slot, a.dest ), false )
		end
		local idx
		local action = nil
		if bagID then -- find the index and structure of the first action for that bag
			for idx, a in ipairs( InBags.actions ) do
				if a.bag == bagID then
					action = a
					break
				end
			end
		end
		if not idx then
			idx = 1
			action = InBags.actions[idx]
		end
		if action then
			local itemStruct = C_Container.GetContainerItemInfo( action.bag, action.slot )
			if itemStruct then
				ClearCursor()
				targetBag, targetSlot = InBags.GetFirstOpenSlot( InBags.bagIDs[action.dest] )
				InBags.Debug( 3, "Search "..action.dest.." for an open slot. Got ("..(targetBag or "nil")..", "..(targetSlot or "nil")..")" )
				if targetBag and targetSlot then
					InBags.Debug( 1, string.format( "Move %2i of %s from (%i,%i) to %s (%i,%i)",
							action.quantity, action.link, action.bag, action.slot, action.dest, targetBag, targetSlot ) )
					if( action.quantity < itemStruct.stackCount ) then -- split
						C_Container.SplitContainerItem( action.bag, action.slot, action.quantity )
						C_Container.PickupContainerItem( targetBag, targetSlot )
					else
						C_Container.PickupContainerItem( action.bag, action.slot )
						C_Container.PickupContainerItem( targetBag, targetSlot )
					end
				else
					InBags.Print( "Error moving "..action.link.." ("..action.bag..", "..action.slot..") to "..action.dest..": No free slots." )
					-- InBags.Print( "No Free slots found in "..action.dest.."." )
					InBags.actions = {}
					InBags.toScan = action.dest
					InBags.Scan()
				end
				table.remove( InBags.actions, idx )
			end
		else
			if InBags.toScan then
				InBags.Scan()
			end
		end
		InBags.Debug( 3, "BAG_UPDATE DONE: "..(idx or "nil") )
	end
end
function InBags.BANKFRAME_CLOSED()
	InBags.Debug( 2, "Bank closed" )
	InBags.bankOpen = nil
	InBags.actions = {}
end
function InBags.Bank( params )
	-- print( "Bank( "..params.." )" )
	local itemID, quantity = InBags.ParseParameters( params )
	-- print( itemID, type( itemID ), quantity )
	InBags.me[itemID] = InBags.me[itemID] or {}
	InBags.me[itemID].bank = (quantity > 0) and quantity or nil
	InBags.Print( "Will try to maintain "..quantity.." in your BANK" )
end
function InBags.Bags( params )
	-- print( "Bags( "..params.." )" )
	local itemID, quantity = InBags.ParseParameters( params )
	-- print( itemID, type( itemID ), quantity )
	InBags.me[itemID] = InBags.me[itemID] or {}
	InBags.me[itemID].bags = (quantity > 0) and quantity or nil
	InBags.Print( "Will try to maintain "..quantity.." in your BAGS" )
end
function InBags.getItemIdFromLink( itemLink )
	-- returns just the integer itemID
	-- itemLink can be a full link, or just "item:999999999"
	if itemLink then
		return strmatch( itemLink, "item:(%d*)" )
	end
end
function InBags.ParseParameters( params )
	local item, quantity, all = strmatch( params, "^(|c.*|r)%s*(%d*)%s*$" )
	-- print( item, quantity, all )
	return tonumber( InBags.getItemIdFromLink( item ) ), (all or tonumber( quantity ) )
end
function InBags.ParseCmd(msg)
	msg = string.lower(msg)
	local a,b,c = strfind(msg, "(%S+)")  --contiguous string of non-space characters
	if a then
		-- c is the matched string, strsub is everything after that, skipping the space
		return c, strsub(msg, b+2)
	else
		return ""
	end
end
function InBags.Command( msg)
	local cmd, param = InBags.ParseCmd(msg)
	-- print( cmd..":"..param )
	local cmdFunc = InBags.commandList[cmd]
	if cmdFunc then
		cmdFunc.func(param)
	-- elseif (cmd and cmd ~= "") then
	-- 	InBags.AddItem( cmd, param )
	else
		InBags.PrintHelp()
	end
end
function InBags.PrintHelp()
	InBags.Print(InBags.MSG_ADDONNAME.." ("..InBags.MSG_VERSION..") by "..InBags.MSG_AUTHOR)
	for cmd, info in pairs(InBags.commandList) do
		InBags.Print(string.format("%s %s %s -> %s",
			SLASH_IC1, cmd, info.help[1], info.help[2]))
	end
end
InBags.commandList = {
	["help"] = {
		["func"] = InBags.PrintHelp,
		["help"] = {"", "Print this help"},
	},
	["bank"] = {
		["func"] = InBags.Bank,
		["help"] = { "[itemLink] quantity", "Keep quantity in your bank." },
	},
	["bags"] = {
		["func"] = InBags.Bags,
		["help"] = { "[itemLink] quantity", "Keep quantity in your bags." },
	},
	["ignore"] = {
		["func"] = InBags.Ignore,
		["help"] = { "[itemLink]", "Ignore this item for all chars"},
	},
	["v"] = {
		["func"] = function( v ) InBags.verbosity = tonumber(v) end,
		["help"] = { "level", "Set verbosity (0-3)" },
	},
}
