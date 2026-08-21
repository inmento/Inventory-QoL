local engineRoot = assert(arg[1], "engine root is required")
local modPath = assert(arg[2], "relative staged mod path is required")
local generation = tonumber(arg[3] or "1")

package.path = engineRoot .. "/?.lua;" .. engineRoot .. "/?/init.lua;" .. package.path
local T = require("tests.modkit")

local run = T.sdk.loadMods({ modPath }, { root = engineRoot, generation = generation })
assert(#run.errors == 0, table.concat(run.errors, "\n"))
local source = assert(io.open("/home/ubuntu/inventory-qol-mod-wip/bulk.lua", "r")):read("*a")
local Bulk = assert(loadstring(source, "bulk.lua"))()

local stack = { states = {} }
function stack:push(state) self.states[#self.states + 1] = state end
function stack:pop() return table.remove(self.states) end
function stack:top() return self.states[#self.states] end

local species = assert(next(run.data.pokemon), "fixture needs one species")
local mon = {
  species = species, level = 25, hp = 50,
  dvs = { attack = 7, defense = 7, speed = 7, special = 7, hp = 7 },
  statExp = { special = 0 }, moves = { { id = "THUNDERSHOCK", pp = 30 } },
}
local game = {
  save = { inventory = { CALCIUM = 4 }, party = { mon } },
  data = run.data,
  stack = stack,
  overworld = {},
  say = function(self, message, onDone)
    self.stack:push({ message = message, onDone = onDone })
  end,
}

if generation == 1 then
  Bulk.openGen1(game, "CALCIUM")
  local party = stack:top()
  party.onSwitch(mon)
else
  Bulk.openGen2(game, "CALCIUM")
  local party = stack:top()
  party.onChoose(1, mon)
end
local qty = stack:top()
assert(qty and qty.max == 4, "the vitamin selector must use the owned and legal cap")
qty.onDone(3)
assert(game.save.inventory.CALCIUM == 1, "a vitamin batch must consume exactly the confirmed quantity")
assert(mon.statExp.special == 7680, "each vitamin use must retain the native 2560 stat-exp increase")

run.release()
print(("Inventory QoL vitamin batch Gen %d: PASS"):format(generation))
