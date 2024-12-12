InBags_SLUG, InBags  = ...
InBags_MSG_ADDONNAME = C_AddOns.GetAddOnMetadata( InBags_SLUG, "Title" )
InBags_MSG_VERSION   = C_AddOns.GetAddOnMetadata( InBags_SLUG, "Version" )
InBags_MSG_AUTHOR    = C_AddOns.GetAddOnMetadata( InBags_SLUG, "Author" )

-- Colours
COLOR_RED = "|cffff0000"
COLOR_GREEN = "|cff00ff00"
COLOR_BLUE = "|cff0000ff"
COLOR_PURPLE = "|cff700090"
COLOR_YELLOW = "|cffffff00"
COLOR_ORANGE = "|cffff6d00"
COLOR_GREY = "|cff808080"
COLOR_GOLD = "|cffcfb52b"
COLOR_NEON_BLUE = "|cff4d4dff"
COLOR_END = "|r"

InBags_data = {}  -- [realm][name][itemid] = {}

function InBags.Print( msg, showName)
	-- print to the chat frame
	-- set showName to false to suppress the addon name printing
	if (showName == nil) or (showName) then
		msg = COLOR_ORANGE..InBags_MSG_ADDONNAME.."> "..COLOR_END..msg
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg )
end

function InBags.OnLoad()
	SLASH_INBAGS1 = "/INBAGS"
	SlashCmdList["INBAGS"] = function( msg ) InBags.Command( msg); end

	InBags_Frame:RegisterEvent( "BANKFRAME_OPENED" )
	InBags_Frame:RegisterEvent( "BANKFRAME_CLOSED" )
	InBags_Frame:RegisterEvent( "BAG_UPDATE" )
	InBags_Frame:RegisterEvent( "ADDON_LOADED" )
	InBags_Frame:RegisterEvent( "VARIABLES_LOADED" )
	InBags_Frame:RegisterEvent( "PLAYER_LEAVING_WORLD" )
end
function InBags.ADDON_LOADED()
	InBags_Frame:UnregisterEvent( "ADDON_LOADED" )
	InBags.realm = GetRealmName()
	InBags.name = UnitName("player")
end
function InBags.VARIABLES_LOADED()
	InBags_Frame:UnregisterEvent( "VARIABLES_LOADED" )
	InBags_data[InBags.realm] = InBags_data[InBags.realm] or {}
	InBags_data[InBags.realm][InBags.name] = InBags_data[InBags.realm][InBags.name] or {}
	InBags.me = InBags_data[InBags.realm][InBags.name]
	InBags.Print( "Loaded v"..InBags_MSG_VERSION )
end
function InBags.GetFirstOpenSlot()
	-- Set this up to scan both bags and the bank in the future
	for bag = NUM_BAG_SLOTS+1, 0, -1 do
	-- for _, bag in pairs({-1, 6, 7, 8, 9, 10, 11, 12, -2}) do
		for slot = 1, C_Container.GetContainerNumSlots( bag ) do
			local itemStruct = C_Container.GetContainerItemInfo( bag, slot )
			print( )
			if not itemStruct then
				return bag, slot
			end
		end
	end
end
function InBags.BANKFRAME_OPENED()
	InBags.bankOpen = true
	InBags.Print( "Bank opened" )
	-- make action structure
	InBags.actions = {}
	for itemID, itemInfo in pairs( InBags.me ) do
		local youHave = GetItemCount( itemID, true ) -- include bank
		local inBags = GetItemCount( itemID, false ) -- only in bags
		local inAccount = C_Item.GetItemCount( itemID, false, false, false, true ) - inBags  -- warband bank?
		InBags.Print( itemID.." you have: "..youHave..", of which "..inBags.."/"..itemInfo.inBags.." are in your bags." )
		if inBags > itemInfo.inBags then
			InBags.actions[itemID] = InBags.actions[itemID] or {}
			InBags.actions[itemID].toBank = inBags - itemInfo.inBags

		elseif inBags < itemInfo.inBags then
			InBags.actions[itemID] = InBags.actions[itemID] or {}
			InBags.actions[itemID].toBags = itemInfo.inBags - inBags
		end
	end

	-- scan bags, create events if needed
	InBags.actions.events = {}
	for bag = 0, NUM_BAG_SLOTS+1 do  -- loop through bag slots
		for slot = 1, C_Container.GetContainerNumSlots( bag ) do -- loop through slots in bag, if it is a bag
			local itemStruct = C_Container.GetContainerItemInfo( bag, slot )  -- get the item info
			if ( itemStruct ) then
				if ( InBags.actions[itemStruct.itemID] and InBags.actions[itemStruct.itemID].toBank ) then
					ClearCursor()
					if ( InBags.actions[itemStruct.itemID].toBank >= itemStruct.stackCount ) then  -- Need to move more than this stack has
						C_Container.UseContainerItem( bag, slot )  -- Moves entire stack to bank
						InBags.actions[itemStruct.itemID].toBank = InBags.actions[itemStruct.itemID].toBank - itemStruct.stackCount
					elseif ( InBags.actions[itemStruct.itemID].toBank > 0 ) then
						print( itemStruct.hyperlink..": only move "..InBags.actions[itemStruct.itemID].toBank )
						local targetBag, targetSlot = InBags.GetFirstOpenSlot()
						if targetBag then
							print( "Use ("..targetBag..", "..targetSlot..") as temp spot." )
							C_Container.SplitContainerItem( bag, slot, InBags.actions[itemStruct.itemID].toBank )
							PutItemInBag( targetBag + 30 )
							InBags.actions.events[targetBag] = InBags.actions.events[targetBag] or {}
							table.insert( InBags.actions.events[targetBag], {itemStruct.itemID} )
						end
					end
				end
			end
		end
	end

	-- move items from bank
	local inBags = {}
	for _, bag in pairs({-1, 6, 7, 8, 9, 10, 11, 12, -2}) do
		for slot = 0, C_Container.GetContainerNumSlots( bag ) do
			local itemStruct = C_Container.GetContainerItemInfo( bag, slot )
			if ( itemStruct ) then
				if (InBags.me[itemStruct.itemID]) then
					-- print( itemStruct.hyperlink.." is in ("..bag..", "..slot..") "..itemStruct.stackCount )
					inBags[itemStruct.itemID] = inBags[itemStruct.itemID] or GetItemCount( itemStruct.itemID, false ) -- only in bags
					inBags[itemStruct.itemID] = inBags[itemStruct.itemID] or 0 -- Assume that you have cleared out the bags
					local toMove = InBags.me[itemStruct.itemID].inBags - inBags[itemStruct.itemID]
					-- print( "inBags: "..inBags[itemStruct.itemID].."->"..toMove )
					if ( toMove > 0 ) then
						print( "I need to move "..toMove.." "..itemStruct.hyperlink )
						targetBagID = InBags.GetFirstOpenSlot()
						print( targetBagID.." has space.")
						local moving = min( toMove, itemStruct.stackCount )
						C_Container.SplitContainerItem( bag, slot, moving )	-- pick up an amount
						-- print( "pick up "..moving.." from "..bag..", "..slot )
						if( targetBagID == 0 and toMove > 0 ) then
							-- print( "put in backpack." )
							PutItemInBackpack()
						else
							-- print( "put in bag: "..targetBagID )
							PutItemInBag( targetBagID + 30 )
						end

						inBags[itemStruct.itemID] = inBags[itemStruct.itemID] + moving
						local freeSlots, _ = C_Container.GetContainerNumFreeSlots( targetBagID )
						if freeSlots == 0 then
							bagsWithSpace[targetBagID] = nil
						end
					end
				end
			end
		end
	end
--[[


	-- scan bags
	local bagsWithSpace = {}   -- [bagnum] = true
	for bag = 0, NUM_BAG_SLOTS+1 do
		for slot = 1, C_Container.GetContainerNumSlots( bag ) do
			local itemStruct = C_Container.GetContainerItemInfo( bag, slot )
			if ( itemStruct ) then
				if ( InBags.actions[itemStruct.itemID] and InBags.actions[itemStruct.itemID].toBank ) then
					-- print( "Move "..itemStruct.hyperlink.." in ("..bag..", "..slot..") to bank" )
					ClearCursor()
					if ( InBags.actions[itemStruct.itemID].toBank >= itemStruct.stackCount ) then
						C_Container.UseContainerItem( bag, slot )
						InBags.actions[itemStruct.itemID].toBank = InBags.actions[itemStruct.itemID].toBank - itemStruct.stackCount
					elseif ( InBags.actions[itemStruct.itemID].toBank > 0 ) then
						-- print( "I need to only move "..InBags.actions[itemStruct.itemID].toBank )
						local targetBag, targetSlot = InBags.GetFirstOpenSlot()
						if targetBag then
							-- print( "Use ("..targetBag..", "..targetSlot..") as temp spot." )
							C_Container.SplitContainerItem( bag, slot, itemStruct.stackCount - InBags.actions[itemStruct.itemID].toBank )
							InBags.splitItems = true
							PutItemInBag( targetBag + 30 )
							ClearCursor()
							C_Container.UseContainerItem( bag, slot )
							InBags.actions[itemStruct.itemID].toBank = 0
						end
					end
				end
			end
		end
	end

]]

--[[

	-- move items to the bank
	local bagsWithSpace = {}
	for bag = 0, NUM_BAG_SLOTS+1 do
		for slot = 0, C_Container.GetContainerNumSlots( bag ) do
			local itemStruct = C_Container.GetContainerItemInfo( bag, slot )
			if ( itemStruct ) then
				if (InBags.me[itemStruct.itemID]) then
					print( itemStruct.hyperlink.." is in ("..bag..", "..slot..") "..itemStruct.stackCount )
					-- ClearCursor()
					-- C_Container.SplitContainerItem(bag, slot, InBags.me[itemStruct.itemID].inBags)
					-- cursorItem, i1, i2 = GetCursorInfo()
					-- if cursorItem then
					-- 	print( "Cursor has: "..cursorItem..":"..i1 )
					-- end
					-- --PutItemInBackpack()
					-- PutItemInBag( 4 + 30 )
					C_Container.UseContainerItem( bag, slot )
				end
			end
		end
		--print( "bagID to check for free slots: "..bag )
		local freeSlots, typeid = C_Container.GetContainerNumFreeSlots( bag )
		if freeSlots > 0 then
			bagsWithSpace[bag] = true
		end
	end


]]


	-- for itemID, itemInfo in pairs( InBags.me ) do
	-- 	local youHave = GetItemCount( itemID, true ) -- include bank
	-- 	local inBags = GetItemCount( itemID, false ) -- only in bags
	-- 	InBags.Print( string.format( "you have %d (%d in bank), and you want %d in your bags.", youHave, youHave-inBags, itemInfo.inBags ) )
	-- 	-- if (INEED and INEED.AddItem and quantity>youHave) then
	-- 	-- 	INEED.AddItem( itemLink, quantity )
	-- 	-- end
	-- end

-- /run for bag=1,4,1 do for slot=1,GetContainerNumSlots(bag),1 do local name=GetContainerItemLink(bag,slot)
-- if name and string.find(name,"1eff00") then DEFAULT_CHAT_FRAME:AddMessage("- Moving "..name) UseContainerItem(bag,slot) end end end


--[[
function UnusedGear.GetLastFreeSlotInBag( bagID )
	freeSlots, typeid = C_Container.GetContainerNumFreeSlots( bagID )
	if( freeSlots > 0 ) then
		for slot = C_Container.GetContainerNumSlots( bagID ), 0, -1 do
			local texture = C_Container.GetContainerItemInfo( bagID, slot )
			if not texture then
				return bagID, slot
			end
		end
	end
end
function UnusedGear.ForAllGear( action, message )
	-- work through all the times
	moveCount = 0
	for bag = 0, NUM_BAG_SLOTS do
		-- if C_Container.GetContainerNumFreeSlots( bag ) > 0 then  -- This slot has a bag
			--if not GetBagSlotFlag( bag, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP ) then  -- this bag is not ignored
		for slot = 0, C_Container.GetContainerNumSlots( bag ) do -- work through this bag
			itemLog = {}
			toMove, moved = true, false  -- assume to moved
			local itemStruct = C_Container.GetContainerItemInfo( bag, slot )
			-- itemStruct{ itemID, quality, isBound }
			-- local itemID, link
			-- if( itemStruct ) then
			-- 	itemID = itemStruct.itemID
			-- 	link = itemStruct.hyperlink
			-- end

			if( itemStruct ) then  -- only do work with slots that have items
				--print( itemStruct.hyperlink.." is in ("..bag..", "..slot..") "..itemStruct.quality )
				test = 1
				while( toMove and test <= #moveTests ) do
					testStruct = moveTests[test]
					testResult = testStruct[1]( itemStruct )
					--print( "  is "..(testResult and "true" or "false") )
					toMove = toMove and testResult  -- any failure will set this to false
					testLog = testStruct[ testResult and 2 or 3 ]
					if testLog then table.insert( itemLog, testLog ) end
					--print( table.concat( itemLog, "-"))
					test = test + 1
				end
			end
			if toMove then
				targetBagID, targetSlot = UnusedGear.GetLastFreeSlotInBag( UnusedGear_Options.targetBag )
				if( targetBagID ) then
					ClearCursor()
					C_Container.PickupContainerItem( bag,  slot )
					if( targetBagID == 0 ) then
						PutItemInBackpack()
						table.insert( itemLog, "Moved to Backpack" )
					else
						PutItemInBag( targetBagID + 30 )
						table.insert( itemLog, "Moved to bag:"..targetBagID )
					end
					moveCount = moveCount + 1
					moved = true
				end
			end
			if( itemStruct ) then
				UnusedGear.myItemLog[itemStruct.itemID] = UnusedGear.myItemLog[itemStruct.itemID] or { ["countMoved"] = 0 }

				if( UnusedGear.myItemLog[itemStruct.itemID].countMoved >= UnusedGear_Options.moveLimit ) then
					table.insert( itemLog,
							string.format( "moved many times.\nI'm ignoring this item in the future.\nUse %s %s to toggle ignoring of this item",
								SLASH_UNUSEDGEAR1, itemStruct.hyperlink ) )
					UnusedGear.myIgnoreItems[tonumber( itemStruct.itemID )] = time()
				end
				UnusedGear.myItemLog[itemStruct.itemID]["log"] = table.concat( itemLog, "; " )
				UnusedGear.myItemLog[itemStruct.itemID]["lastSeen"] = time()
				UnusedGear.myItemLog[itemStruct.itemID]["link"] = itemStruct.hyperlink
				if moved then
					UnusedGear.myItemLog[itemStruct.itemID]["lastMoved"] = time()
					UnusedGear.myItemLog[itemStruct.itemID]["countMoved"] = UnusedGear.myItemLog[itemStruct.itemID].countMoved + 1
				end
			end
		end
			--end
		--end
	end
end
]]



end
function InBags.BAG_UPDATE( self, bagID )
	if InBags.bankOpen then
		print( "BAG_UPDATE: "..( bagID or "nil" ) )
		if InBags.actions.events[bagID] then
			--InBags.Print( "Event for "..bagID..": "..InBags.actions.events[bagID][1][1] )   --  [1] is first item, [1] is itemid
			for slot = 1, C_Container.GetContainerNumSlots( bagID ) do
				local itemStruct = C_Container.GetContainerItemInfo( bagID, slot )
				if ( itemStruct and #InBags.actions.events[bagID] > 1 and itemStruct.itemID == InBags.actions.events[bagID][1][1] ) then
					print( "Found a stack to move to the bank.")
					C_Container.UseContainerItem( bagID, slot )  -- Moves entire stack to bank
					table.remove( InBags.actions.events[bagID], 1 )
				end
			end
		end
	end
end
function InBags.BANKFRAME_CLOSED()
	print( "Bank closed" )
	InBags.bankOpen = nil
end
function InBags.PLAYER_LEAVING_WORLD()
end

function InBags.AddItem( itemLink, p2 )
	print( itemLink..":"..p2 )
	quantity = p2 and tonumber(p2) or 1
	local itemID = InBags.getItemIdFromLink( itemLink )
	if itemID and string.len( itemID ) > 0 then
		local youHave = GetItemCount( itemID, true ) -- include bank
		local inBags = GetItemCount( itemID, false ) -- only in bags
		InBags.Print( string.format( "You have %d (%d in bank), and you want %d in your bags.", youHave, youHave-inBags, quantity ) )
		if (INEED and INEED.AddItem and quantity>youHave) then
			INEED.AddItem( itemLink, quantity )
		end
		InBags.me[tonumber(itemID)] = {["inBags"] = quantity}
	end
end
function InBags.List()
	for itemID, struct in pairs( InBags.me ) do
		link = select( 2, GetItemInfo( itemID ) )
		InBags.Print( string.format( "%s inBags: %d", link, struct.inBags ) )
	end
end
function InBags.Delete( itemLink )
	print( "delete "..itemLink )
	local itemID = InBags.getItemIdFromLink( itemLink )
	if itemID and string.len( itemID ) > 0 then
		itemID = tonumber(itemID)
		if InBags.me[itemID] then
			InBags.me[itemID] = nil
		end
	end
end

function InBags.getItemIdFromLink( itemLink )
	-- returns just the integer itemID
	-- itemLink can be a full link, or just "item:999999999"
	if itemLink then
		return strmatch( itemLink, "item:(%d*)" )
	end
end

function InBags.ParseCmd(msg)
	if msg then
		local i,c,f = strmatch(msg, "^(|c.*|r)%s*(%d*)%s*(%S*)$")
		if i then  -- i is an item, c is a count or nil
			return i, c..(f and " "..f)
		else  -- Not a valid item link
			msg = string.lower(msg)
			local a,b,c = strfind(msg, "(%S+)")  --contiguous string of non-space characters
			if a then
				-- c is the matched string, strsub is everything after that, skipping the space
				return c, strsub(msg, b+2)
			else
				return ""
			end
		end
	end
end
function InBags.Command(msg)
	local cmd, param = InBags.ParseCmd(msg)
	-- print( cmd..":"..param )
	local cmdFunc = InBags.commandList[cmd]
	if cmdFunc then
		cmdFunc.func(param)
	elseif (cmd and cmd ~= "") then
		InBags.AddItem( cmd, param )
	else
		InBags.PrintHelp()
	end
end
function InBags.PrintHelp()
	InBags.Print(InBags_MSG_ADDONNAME.." ("..InBags_MSG_VERSION..") by "..InBags_MSG_AUTHOR)
	for cmd, info in pairs(InBags.commandList) do
		InBags.Print(string.format("%s %s %s -> %s",
			SLASH_INBAGS1, cmd, info.help[1], info.help[2]))
	end
end

InBags.commandList = {
	["help"] = {
		["func"] = InBags.PrintHelp,
		["help"] = {"", "Print this help"},
	},
	["list"] = {
		["func"] = InBags.List,
		["help"] = {"", "List the tracked items"},
	},
	["rm"] = {
		["func"] = InBags.Delete,
		["help"] = {"ItemLink", "Stop tracking item"},
	},
}