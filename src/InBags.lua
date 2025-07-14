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
	["bank"] = { -1, 6, 7, 8, 9, 10, 11, 12, -2 },
	["wbb"] = { 13, 14, 15, 16, 17 },
}

function InBags.Print( msg, showName)
	-- print to the chat frame
	-- set showName to false to suppress the addon name printing
	if (showName == nil) or (showName) then
		msg = InBags.COLOR_ORANGE..InBags.MSG_ADDONNAME.."> "..InBags.COLOR_END..msg
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg )
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
	InBags_Frame:RegisterEvent( "BAG_UPDATE" )

-- 	InBags_Frame:RegisterEvent( "PLAYER_LEAVING_WORLD" )
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
function InBags.onTooltipSetItem( tooltip, tooltipdata )
	itemID = tonumber(tooltipdata.id)


end
function InBags.GetFirstOpenSlot( searchBags )
	-- Set this up to scan both bags and the bank in the future
	if not searchBags then
		searchBags = InBags.bagIDs.bags
	end
	for _, bag in ipairs( searchBags ) do
		print( bag )
		for slot = 1, C_Container.GetContainerNumSlots( bag ) do
			local itemStruct = C_Container.GetContainerItemInfo( bag, slot )
			if not itemStruct then
				return bag, slot
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
	InBags.Print( "Bank opened" )
	if not InBags.bagIDs.bags then
		InBags.bagIDs.bags = {}
		for bag = 0, NUM_BAG_SLOTS+1 do
			table.insert( InBags.bagIDs.bags, bag )
		end
	end
	-- make action structure
	InBags.actions = {}

	for _, bag in pairs( InBags.bagIDs.bags ) do  -- scan your bags
		for slot = 1, C_Container.GetContainerNumSlots( bag ) do
			local itemStruct = C_Container.GetContainerItemInfo( bag, slot ) -- get the item info (stackCount is how many are here)
			if( itemStruct ) then -- an item is found at (bag, slot)
				local inBags = C_Item.GetItemCount( itemStruct.itemID ) -- only in bags
				local inBank = C_Item.GetItemCount( itemStruct.itemID, true, false, true ) - inBags -- in bank and reagent Bank
				local inWBB = C_Item.GetItemCount( itemStruct.itemID, true, false, true, true ) - inBags - inBank
				local youHave = C_Item.GetItemCount( itemStruct.itemID, true, true, true, true ) -- include bank, uses, reagent, not account
				-- InBags.Print( itemStruct.itemID.."("..bag..", "..slot.."): bags: "..inBags.." bank: "..inBank.." wbb: "..inWBB.." total: "..youHave  )
				-- Do I have my target amount in the bags?
				local wantInBags = ( InBags.me[itemStruct.itemID] and InBags.me[itemStruct.itemID].bags or nil )
				local wantInBank = ( InBags.me[itemStruct.itemID] and InBags.me[itemStruct.itemID].bank or nil )
				local wantInWBB = ( InBags_data[itemStruct.itemID] or nil )
				local countToMove = 0
				if( wantInBags and wantInBags < inBags or not wantInBags ) then
					-- I want it in the bags and I have more than needed, or I don't want in bags
					-- print( "I can move some of "..itemStruct.hyperlink )
					if( wantInBank and wantInBank > inBank ) then -- put it in the bank
						print( wantInBank - inBank, inBags - (wantInBags or 0), itemStruct.stackCount )
						countToMove = math.min( wantInBank - inBank, inBags - (wantInBags or 0), itemStruct.stackCount )
						InBags.AddAction( itemStruct.itemID, itemStruct.hyperlink, bag, slot, countToMove, "bank" )
					end
					if( wantInWBB and wantInWBB > inWBB ) then -- put it in the WBB
						countToMove = math.min( wantInWBB - inWBB, inBags - (wantInBags or 0) - countToMove, itemStruct.stackCount )
						InBags.AddAction( itemStruct.itemID, itemStruct.hyperlink, bag, slot, countToMove, "wbb" )
					end
				end
			end
		end
	end
	for _, bag in pairs( InBags.bagIDs.bank ) do
		for slot = 1, C_Container.GetContainerNumSlots( bag ) do
			local itemStruct = C_Container.GetContainerItemInfo( bag, slot ) -- get the item info (stackCount is how many are here)
			if( itemStruct ) then
				local inBags = C_Item.GetItemCount( itemStruct.itemID ) -- only in bags
				local inBank = C_Item.GetItemCount( itemStruct.itemID, true, false, true ) - inBags -- in bank and reagent Bank
				local inWBB = C_Item.GetItemCount( itemStruct.itemID, true, false, true, true ) - inBags - inBank
				local youHave = C_Item.GetItemCount( itemStruct.itemID, true, true, true, true ) -- include bank, uses, reagent, not account
				-- InBags.Print( itemStruct.itemID.."("..bag..", "..slot.."): bags: "..inBags.." bank: "..inBank.." wbb: "..inWBB.." total: "..youHave  )
				-- Do I have my target amount in the bank?
				local wantInBags = ( InBags.me[itemStruct.itemID] and InBags.me[itemStruct.itemID].bags or nil )
				local wantInBank = ( InBags.me[itemStruct.itemID] and InBags.me[itemStruct.itemID].bank or nil )
				local wantInWBB = ( InBags_data[itemStruct.itemID] or nil )
				local countToMove = 0
				if( wantInBank and wantInBank < inBank or not wantInBank ) then
					-- I want it in the bank and I have more than I need, or I don't want it in the bank
					-- print( "I can move some of "..itemStruct.hyperlink )
					if( wantInBags and wantInBags > inBags ) then -- put in bags
						countToMove = math.min( (wantInBags or 0) - inBags, inBank - wantInBank, itemStruct.stackCount )
						InBags.AddAction( itemStruct.itemID, itemStruct.hyperlink, bag, slot, countToMove, "bags" )
					end
					if( wantInWBB and wantInWBB > inWBB ) then -- put it in the WBB
						countToMove = math.min( wantInWBB - inWBB, inBags - (wantInBags or 0) - countToMove, itemStruct.stackCount )
						InBags.AddAction( itemStruct.itemID, itemStruct.hyperlink, bag, slot, countToMove, "wbb" )
					end
				end
			end
		end
	end
	for _, bag in pairs( InBags.bagIDs.wbb ) do
		for slot = 1, C_Container.GetContainerNumSlots( bag ) do
			local itemStruct = C_Container.GetContainerItemInfo( bag, slot ) -- get the item info (stackCount is how many are here)
			if( itemStruct ) then
				local inBags = C_Item.GetItemCount( itemStruct.itemID ) -- only in bags
				local inBank = C_Item.GetItemCount( itemStruct.itemID, true, false, true ) - inBags -- in bank and reagent Bank
				local inWBB = C_Item.GetItemCount( itemStruct.itemID, true, false, true, true ) - inBags - inBank
				local youHave = C_Item.GetItemCount( itemStruct.itemID, true, true, true, true ) -- include bank, uses, reagent, not account
				-- InBags.Print( itemStruct.itemID.."("..bag..", "..slot.."): bags: "..inBags.." bank: "..inBank.." wbb: "..inWBB.." total: "..youHave  )
				-- Do I have my target amount in the wbb?
				local wantInBags = ( InBags.me[itemStruct.itemID] and InBags.me[itemStruct.itemID].bags or nil )
				local wantInBank = ( InBags.me[itemStruct.itemID] and InBags.me[itemStruct.itemID].bank or nil )
				local wantInWBB = ( InBags_data[itemStruct.itemID] or nil )
				local countToMove = 0
				-- I want it in the bank and I have more than I need, or I don't want it in the bank
				-- print( "I can move some of "..itemStruct.hyperlink )
				if( wantInBags and wantInBags > inBags and countToMove ) then -- put in bags
					countToMove = wantInBags - inBags
					InBags.Print( itemStruct.itemID.."("..bag..", "..slot.."): bags: "..inBags.." bank: "..inBank.." wbb: "..inWBB.." total: "..youHave  )
					print( "I think I want to move "..countToMove.." to my bags.")
					InBags.AddAction( itemStruct.itemID, itemStruct.hyperlink, bag, slot, countToMove, "bags" )
				end
				if( wantInBank and wantInBank > inBank ) then -- put it in the WBB
					countToMove = math.min( wantInBank - inBank, inBags - wantInBags - countToMove )
					InBags.AddAction( itemStruct.itemID, itemStruct.hyperlink, bag, slot, countToMove, "bank" )
				end
			end
		end
	end
	print("Scan ended:")
	InBags.BAG_UPDATE( nil, nil )
end

function InBags.BAG_UPDATE( self, bagID )
	if InBags.bankOpen then
		print( "BAG_UPDATE: "..( bagID or "nil" ) )
		for i, a in ipairs( InBags.actions ) do
			print( string.format( "%i: move %2i of %s at (%i,%i) to %s",
					i, a.quantity, a.link, a.bag, a.slot, a.dest ) )
		end
		local idx
		local action
		if bagID then -- find the index and structure of the first action for that bag
			for idx, action in ipairs( InBags.actions ) do
				if action.bag == bagID then
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
				print( "Search "..action.dest.." for an open slot. Got ("..(targetBag or "nil")..", "..(targetSlot or "nil")..")" )
				if targetBag and targetSlot then
					print( string.format( "%i: move %2i of %s at (%i,%i) to %s (%i,%i)",
							idx, action.quantity, action.link, action.bag, action.slot, action.dest, targetBag, targetSlot ) )
					if( action.quantity < itemStruct.stackCount ) then -- split
						C_Container.SplitContainerItem( action.bag, action.slot, action.quantity )
						C_Container.PickupContainerItem( targetBag, targetSlot )
					else
						C_Container.PickupContainerItem( action.bag, action.slot )
						C_Container.PickupContainerItem( targetBag, targetSlot )
					end
				end
				table.remove( InBags.actions, idx )
			end
		end
		print( "BAG_UPDATE DONE: "..(idx or "nil") )
	end
end
function InBags.BANKFRAME_CLOSED()
	InBags.Print( "Bank closed" )
	InBags.bankOpen = nil
	InBags.actions = {}
end
-- function InBags.PLAYER_LEAVING_WORLD()
-- end
function InBags.WBB( params )
	-- print( "WBB( "..params.." )" )
	local itemID, quantity = InBags.ParseParameters( params )
	-- print( itemID, type( itemID ), quantity )
	InBags_data[itemID] = ( quantity > 0) and quantity or nil
end
function InBags.Bank( params )
	-- print( "Bank( "..params.." )" )
	local itemID, quantity = InBags.ParseParameters( params )
	-- print( itemID, type( itemID ), quantity )
	InBags.me[itemID] = InBags.me[itemID] or {}
	InBags.me[itemID].bank = (quantity > 0) and quantity or nil
end
function InBags.Bags( params )
	-- print( "Bags( "..params.." )" )
	local itemID, quantity = InBags.ParseParameters( params )
	-- print( itemID, type( itemID ), quantity )
	InBags.me[itemID] = InBags.me[itemID] or {}
	InBags.me[itemID].bags = (quantity > 0) and quantity or nil
end

-- function InBags.AddItem( itemLink, p2 )
-- 	-- print( itemLink..":"..p2 )
-- 	quantity = p2 and tonumber(p2) or 1
-- 	local itemID = InBags.getItemIdFromLink( itemLink )
-- 	if itemID and string.len( itemID ) > 0 then
-- 		local youHave = GetItemCount( itemID, true ) -- include bank
-- 		local inBags = GetItemCount( itemID, false ) -- only in bags
-- 		InBags.Print( string.format( "You have %d (%d in bank), and you want %d in your bags.", youHave, youHave-inBags, quantity ) )
-- 		if (INEED and INEED.AddItem and quantity>youHave) then
-- 			INEED.AddItem( itemLink, quantity )
-- 		end
-- 		InBags.me[tonumber(itemID)] = {["inBags"] = quantity}
-- 	end
-- end
-- function InBags.List()
-- 	for itemID, struct in pairs( InBags.me ) do
-- 		link = select( 2, GetItemInfo( itemID ) )
-- 		InBags.Print( string.format( "%s inBags: %d", link, struct.inBags ) )
-- 	end
-- end
-- function InBags.Delete( itemLink )
-- 	print( "delete "..itemLink )
-- 	local itemID = InBags.getItemIdFromLink( itemLink )
-- 	if itemID and string.len( itemID ) > 0 then
-- 		itemID = tonumber(itemID)
-- 		if InBags.me[itemID] then
-- 			InBags.me[itemID] = nil
-- 		end
-- 	end
-- end

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
	["wbb"] = {
		["func"] = InBags.WBB,
		["help"] = { "[itemLink] quantity", "Keep quantity in your warband bank." },
	},
	["bank"] = {
		["func"] = InBags.Bank,
		["help"] = { "[itemLink] quantity", "Keep quantity in your bank." },
	},
	["bags"] = {
		["func"] = InBags.Bags,
		["help"] = { "[itemLink] quantity", "Keep quantity in your bags." },
	},
}