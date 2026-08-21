local engineRoot = assert(arg[1], "engine root is required")
local inventoryRoot = assert(arg[2], "Inventory QoL mod root is required")
local usefulRoot = assert(arg[3], "Useful Bag mod root is required")

package.path = engineRoot .. "/?.lua;" .. engineRoot .. "/?/init.lua;" .. package.path

local T = require("tests.modkit")

local run = T.sdk.loadMods({ usefulRoot, inventoryRoot }, {
  root = engineRoot,
  generation = 2,
})

assert(#run.errors == 0, table.concat(run.errors, "\n"))
assert(run.mods.useful_bag and run.mods.useful_bag.state == "wrong_generation",
  "Useful Bag must be safely skipped in Gen 2 because it is not marked gen2compat")
assert(run.mods.inventory_qol and run.mods.inventory_qol.state == "loaded",
  "Inventory QoL must load normally when Useful Bag is skipped in Gen 2")
assert(run.loader.content.screens:get("Gen2PackMenu"),
  "Inventory QoL's Gen 2 Pack override must remain registered")

run.release()
print("Inventory QoL Useful Bag Gen 2 loader compatibility: PASS")
