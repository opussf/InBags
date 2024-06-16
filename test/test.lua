#!/usr/bin/env lua

require "wowTest"

test.outFileName = "testOut.xml"

-- require the file to test
ParseTOC( "../src/InBags.toc" )

-- addon setup
-- INEED.name = "testName"
-- INEED.realm = "testRealm"

function test.before()
end
function test.after()
end

test.run()
