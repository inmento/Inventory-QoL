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
run.data.items.TM_04 = { id = "TM_04", name = "TM04", machine = { move = "WHIRLWIND" } }
run.data.moves.WHIRLWIND = { id = "WHIRLWIND", name = "WHIRLWIND" }
local stack = setmetatable({}, { __index = StateStack })
stack:init()
local game = {
  save = { inventory = { POTION = 125, TM_04 = 1 }, bagOrder = { "POTION", "TM_04" }, money = 0 },
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

-- The companion's own ticker redraw used legacy x=16/y=8+row*16 coordinates,
-- which put long TM labels over the border in the current renderer.  The outer
-- Inventory QoL decorator must retain the TMs pocket and redraw the long label
-- inside the actual Bag item row at x=48/y=32 instead.
run.loader.exports.useful_bag.switchPocket(list, 1) -- MEDICINE -> POKé BALLS
run.loader.exports.useful_bag.switchPocket(list, 1) -- POKé BALLS -> TMs / HMs
assert(list.__pocketIndex == 4 and list.items[1].value == "TM_04",
  "Useful Bag's TMs/HMs pocket must remain active under the compatibility layer")
local Font = require("src.render.Font")
local oldLove = love
local oldDraw, oldBox, oldCode, oldWidth = Font.draw, Font.drawBox, Font.drawCode, Font.width
local drawn = {}
love = { graphics = { setColor = function() end, setScissor = function() end } }
Font.draw = function(text, x, y) drawn[#drawn + 1] = { text = text, x = x, y = y } end
Font.drawBox = function() end
Font.drawCode = function() end
Font.width = function(text) return #tostring(text) * 8 end
list:draw()
Font.draw, Font.drawBox, Font.drawCode, Font.width = oldDraw, oldBox, oldCode, oldWidth
love = oldLove
local prefix, move, legacy = nil, nil, false
for _, call in ipairs(drawn) do
  if call.text == "TM04 " then prefix = call end
  if call.text == "WHIRLWIND" then move = call end
  if call.x == 16 or call.y == 24 then legacy = true end
end
assert(prefix and prefix.x == 48 and prefix.y == 32,
  "long TM label prefix must begin inside the current Bag item row")
assert(move and move.x == 88 and move.y == 32,
  "long TM move name must redraw inside the current Bag item row")
assert(not legacy, "Useful Bag's legacy ticker coordinates must not be used")

run.release()
print("Inventory QoL Useful Bag compatibility: PASS")
