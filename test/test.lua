#!/usr/bin/env lua

require "wowTest"

test.outFileName = "testOut.xml"

-- require the file to test
ParseTOC( "../src/InBags.toc" )

function test.before()
end
function test.after()
end
function test.test_01()
end

test.run()
