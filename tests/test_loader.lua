local engineRoot = assert(arg[1], "engine root is required")
local modRoot = assert(arg[2], "mod root is required")
local generation = tonumber(arg[3] or "1")

package.path = engineRoot .. "/?.lua;" .. engineRoot .. "/?/init.lua;" .. package.path

local T = require("tests.modkit")
local Bag = require("src.inventory.Bag")

local run = T.sdk.loadMods({ modRoot }, {
  root = engineRoot,
  generation = generation,
})

assert(#run.errors == 0, table.concat(run.errors, "\n"))
assert(run.loader.content.screens:get("BagMenu"), "Gen 1 Bag screen override was not registered")
assert(run.loader.content.screens:get("Gen2PackMenu"), "Gen 2 Pack screen override was not registered")

local save = { inventory = {}, bagOrder = {} }
assert(Bag.add(save, "POTION", 999, run.data), "a normal item should fit at the 999 cap")
assert(save.inventory.POTION == 999, "the 999 count was not stored")
assert(not Bag.add(save, "POTION", 1, run.data), "the 1000th item should be refused")

run.release()
print(("Inventory QoL loader Gen %d: PASS"):format(generation))
