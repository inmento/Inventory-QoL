local engineRoot = assert(arg[1], "engine root is required")
local modPath = assert(arg[2], "relative staged mod path is required")
package.path = engineRoot .. "/?.lua;" .. engineRoot .. "/?/init.lua;" .. package.path

local T = require("tests.modkit")
local run = T.sdk.loadMods({ modPath }, { root = engineRoot, generation = 1 })
assert(#run.errors == 0, table.concat(run.errors, "\n"))

local game = {
  save = {
    inventory = { POTION = 1, ANTIDOTE = 1, AWAKENING = 1, BURN_HEAL = 1 },
    bagOrder = { "POTION", "ANTIDOTE", "AWAKENING", "BURN_HEAL" },
  },
  data = run.data,
}
game.stack = {
  current = nil,
  top = function(self) return self.current end,
  pop = function(self) self.current = nil end,
  push = function(self, state) self.current = state end,
}

local factory = assert(run.loader.content.screens:get("BagMenu"))
local first = factory.new(game, {})
first.index, first.scroll = 4, 1
game.stack.current = first
first:close()
assert(game.inventoryQolBagCursor and game.inventoryQolBagCursor.index == 4,
  "closing the Gen 1 Bag must retain the current session cursor")
assert(game.save.inventory.POTION == 1 and game.save.bagOrder[1] == "POTION",
  "cursor persistence must not mutate save inventory or order")
local reopened = factory.new(game, {})
assert(reopened.index == 4 and reopened.scroll == 1,
  "the next Gen 1 Bag open must restore the remembered cursor and scroll")

run.release()
print("Inventory QoL Gen 1 cursor memory: PASS")
