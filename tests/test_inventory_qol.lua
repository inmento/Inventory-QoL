local engineRoot = assert(arg[1], "engine root is required")
local modPath = assert(arg[2], "relative staged mod path is required")
local generation = tonumber(arg[3] or "1")

package.path = engineRoot .. "/?.lua;" .. engineRoot .. "/?/init.lua;" .. package.path

local T = require("tests.modkit")
local Bag = require("src.inventory.Bag")

local run = T.sdk.loadMods({ modPath }, { root = engineRoot, generation = generation })
assert(#run.errors == 0, table.concat(run.errors, "\n"))

local source = assert(io.open("/home/ubuntu/inventory-qol-mod-wip/bulk.lua", "r")):read("*a")
local Bulk = assert(loadstring(source, "bulk.lua"))()

local game = {
  save = { inventory = { RARE_CANDY = 99, PP_UP = 99, CALCIUM = 99 }, bagOrder = {} },
  data = run.data,
}
local mon = {
  species = "PIKACHU", level = 41, statExp = { special = 0 },
  moves = { { id = "THUNDERSHOCK", pp = 30, ppUps = 1 } },
}
assert(Bulk.maxFor(game, "RARE_CANDY", mon) == 59, "Rare Candy must cap at level 100")
assert(Bulk.maxFor(game, "CALCIUM", mon) == 10, "a fresh vitamin stat allows ten pre-Gen-III applications")
mon.statExp.special = 25600
assert(Bulk.maxFor(game, "CALCIUM", mon) == 0, "a capped vitamin stat must refuse batch use")
mon.moves[1].ppUps = 2
assert(Bulk.maxFor(game, "PP_UP", mon, 1) == 1, "PP Up batch cap must honor the third application")
mon.moves[1].ppUps = 3
assert(Bulk.maxFor(game, "PP_UP", mon, 1) == 0, "a maxed PP Up move must refuse batch use")

local save = { inventory = {}, bagOrder = {} }
assert(Bag.add(save, "POTION", 999, run.data), "999 Potions should fit")
assert(not Bag.add(save, "POTION", 1, run.data), "a 1000th Potion must be refused")

local function stackTop() return game.current end
game.stack = {
  top = stackTop,
  push = function(_, screen) game.current = screen end,
  pop = function() game.current = nil end,
}
game.save.inventory = { RARE_CANDY = 10 }
game.save.bagOrder = { "RARE_CANDY" }
local bagFactory = assert(run.loader.content.screens:get("BagMenu"))
local list = bagFactory.new(game, {})
game.current = list
assert(list.items[1].right == "x10", "Gen 1 Bag list must preserve quantity rows")
list.onChoose(list.items[1], list)
local menu = game.current
assert(#menu.items == 3 and menu.items[2].label == "USE MANY",
  "Gen 1 permanent consumables need a USE MANY field-menu row")

local packFactory = assert(run.loader.content.screens:get("Gen2PackMenu"))
local pack = packFactory.new(game, { save = game.save, items = game.data.items })
local rows = pack:submenuRows("RARE_CANDY")
local seen = false
for _, row in ipairs(rows) do if row == "many" then seen = true end end
assert(seen, "Gen 2 permanent consumables need a USE MANY Pack row")

run.release()
print(("Inventory QoL behavior Gen %d: PASS"):format(generation))
