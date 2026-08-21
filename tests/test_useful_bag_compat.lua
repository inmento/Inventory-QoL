local engineRoot = assert(arg[1], "engine root is required")
local inventoryRoot = assert(arg[2], "Inventory QoL mod root is required")
local usefulRoot = assert(arg[3], "Useful Bag mod root is required")

package.path = engineRoot .. "/?.lua;" .. engineRoot .. "/?/init.lua;" .. package.path

local T = require("tests.modkit")
local Bag = require("src.inventory.Bag")
local StateStack = require("src.core.StateStack")
local Screens = require("src.ui.Screens")

local run = T.sdk.loadMods({ usefulRoot, inventoryRoot }, {
  root = engineRoot,
  generation = 1,
})

assert(#run.errors == 0, table.concat(run.errors, "\n"))
assert(run.mods.useful_bag and run.mods.useful_bag.state == "loaded",
  "Useful Bag must load instead of colliding with Inventory QoL")
assert(run.mods.inventory_qol and run.mods.inventory_qol.state == "loaded",
  "Inventory QoL must load with Useful Bag enabled")

-- Both mods intentionally raise normal stacks; one shared Bag.add wrapper must
-- still accept the documented 999 cap after both entry chunks execute.
local save = { inventory = {}, bagOrder = {} }
assert(Bag.add(save, "POTION", 999, run.data), "999 Potions must fit with both mods")
assert(not Bag.add(save, "POTION", 1, run.data), "a 1000th Potion must be refused with both mods")

run.data.items.POTION = { id = "POTION", name = "Potion" }
local stack = setmetatable({}, { __index = StateStack })
stack:init()
local game = {
  save = { inventory = { POTION = 125 }, bagOrder = { "POTION" }, money = 0 },
  data = run.data,
  stack = stack,
  input = {
    wasPressed = function() return false end,
    isDown = function() return false end,
  },
}
run.loader.events:emit("game.ready", { game = game })

-- The registry must expose Inventory QoL's outer decorator, which delegates to
-- Useful Bag's previously registered factory.  This proves the list preserves
-- its pocket projection while receiving Inventory QoL's cursor wrapper.
Screens.invalidate()
local factory = assert(run.loader.content.screens:get("BagMenu"))
local list = factory.new(game, {})
assert(list.__pocketIndex == 1 and list.title == "ITEMS",
  "Useful Bag must retain its initial ITEMS pocket on the combined BagMenu")
run.loader.exports.useful_bag.switchPocket(list, 1)
assert(list.__pocketIndex == 2 and list.title == "MEDICINE",
  "Useful Bag pocket cycling must remain active on the combined BagMenu")
assert(list.items[1] and list.items[1].value == "POTION",
  "Useful Bag's MEDICINE projection must remain visible")
assert(list.items[1].right == "x125",
  "the combined BagMenu must retain the three-digit quantity row")
list.onSelectKey(nil, list)
assert(game.inventoryQolBagCursor and game.inventoryQolBagCursor.index == list.index,
  "Inventory QoL cursor memory must decorate Useful Bag's list")

run.release()
print("Inventory QoL Useful Bag compatibility: PASS")
