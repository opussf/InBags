#!/usr/bin/env lua

require "wowTest"

test.outFileName = "testOut.xml"

-- require the file to test
ParseTOC( "../src/InBags.toc" )

function test.before()
	InBags_data = {}
	InBags.me = nil
	InBags.OnLoad()
	InBags.ADDON_LOADED()
	InBags.VARIABLES_LOADED()
end
function test.after()
end
-- Structure
------------------------------------------
-- ADDON_LOADED, and VARIABLES_LOADED should set up missing structure
function test.test_structure_setRealm()
	assertTrue( InBags_data["Test Realm"] )
end
function test.test_structure_setName()
	assertTrue( InBags_data["Test Realm"]["testPlayer"] )
end
function test.test_structure_setMe()
	assertTrue( InBags.me )
	assertEquals( InBags.me, InBags_data["Test Realm"]["testPlayer"], "InBags.me should point to InBags_data for current player." )
end
-- Add Item
------------------------------------------
-- Add an item to manage
function test.test_addItem_link()
	InBags.Command( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r" )
end
function test.test_addItem_text()
	InBags.Command( "item:7073" )
end
function test.test_addItem_link_quanity()
	InBags.Command( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r 10" )
end
function test.test_addItem_text_quanity()
	InBags.Command( "item:7073 12" )
end
function test.test_addItem_link_quanity_flag()
	InBags.Command( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r 14 once" )
end
function test.test_addItem_text_quanity_flag()
	InBags.Command( "item:7073 16 once" )
end




test.run()
