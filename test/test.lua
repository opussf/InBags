#!/usr/bin/env lua

require "wowTest"

test.outFileName = "testOut.xml"
test.coberturaFileName = "../coverage.xml"  -- to enable coverage output

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
	chatLog = {}
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
------------------------------------------
function test.test_noCommand()
	InBags.Command( "" )
end
function test.test_bags_Itemlink()
	InBags.Command( "bags |cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r 10" )
	assertEquals( 10, InBags_data["Test Realm"]["testPlayer"][7073].bags )
end
function test.test_bags_Itemlink_remove()
	InBags.Command( "bags |cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r 10" )
	InBags.Command( "bags |cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r 0" )
	assertIsNil( InBags_data["Test Realm"]["testPlayer"][7073].bags )
end
function test.test_bank_Itemlink()
	InBags.Command( "bank |cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r 10" )
	assertEquals( 10, InBags_data["Test Realm"]["testPlayer"][7073].bank )
end
function test.test_bank_Itemlink_remove()
	InBags.Command( "bank |cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r 10" )
	InBags.Command( "bank |cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r 0" )
	assertIsNil( InBags_data["Test Realm"]["testPlayer"][7073].bank )
end
function test.test_openBank()
	InBags.BANKFRAME_OPENED()
	test.dump( chatLog )
end

-- Add Item
------------------------------------------
-- Add an item to manage
-- function test.test_addItem_link()
-- 	InBags.Command( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r" )
-- 	assertEquals( 1, InBags_data["Test Realm"]["testPlayer"][7073].inBags )
-- end
-- function test.test_addItem_text()
-- 	InBags.Command( "item:7073" )
-- 	assertEquals( 1, InBags_data["Test Realm"]["testPlayer"][7073].inBags )
-- end
-- function test.test_addItem_link_quanity()
-- 	InBags.Command( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r 10" )
-- 	assertEquals( 10, InBags_data["Test Realm"]["testPlayer"][7073].inBags )
-- end
-- function test.test_addItem_text_quanity()
-- 	InBags.Command( "item:7073 12" )
-- 	assertEquals( 12, InBags_data["Test Realm"]["testPlayer"][7073].inBags )
-- end
-- function test.test_addItem_link_quanity_flag()
-- 	InBags.Command( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r 14 once" )
-- 	test.dump(InBags_data)
-- end
-- function test.test_addItem_text_quanity_flag()
-- 	InBags.Command( "item:7073 16 once" )
-- end
-- function test.test_listItems()
-- 	InBags.Command( "list" )
-- end




test.run()
