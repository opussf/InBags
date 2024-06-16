InBags_SLUG, InBags = ...
InBags_MSG_ADDONNAME = GetAddOnMetadata( InBags_SLUG, "Title" )
InBags_MSG_VERSION   = GetAddOnMetadata( InBags_SLUG, "Version" )
InBags_MSG_AUTHOR    = GetAddOnMetadata( InBags_SLUG, "Author" )

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

InBags_data = {}

function InBags.Print( msg, showName)
	-- print to the chat frame
	-- set showName to false to suppress the addon name printing
	if (showName == nil) or (showName) then
		msg = COLOR_PURPLE..InBags_MSG_ADDONNAME.."> "..COLOR_END..msg
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg )
end

function InBags.OnLoad()
	SLASH_INBAGS1 = "/INBAGS"
	SlashCmdList["UNBAGS"] = function( msg ) InBags.Command( msg); end

	InBags_Frame:RegisterEvent( "BANKFRAME_OPENED" )
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
end
function InBags.BANKFRAME_OPENED()
end
function InBags.PLAYER_LEAVING_WORLD()
end

function InBags.AddItem( p1, p2 )
	print( p1..":"..p2 )
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
			SLASH_InBags1, cmd, info.help[1], info.help[2]))
	end
end

InBags.commandList = {

}