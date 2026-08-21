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
  species = species, level = 99, exp = 0, hp = 50,
  dvs = { attack = 7, defense = 7, speed = 7, special = 7, hp = 7 },
  statExp = {}, stats = { hp = 50 }, moves = {},
}
local game = {
  save = { inventory = { RARE_CANDY = 1 }, party = { mon }, player = { name = "TEST", id = 1 } },
  data = run.data,
  stack = stack,
  overworld = {},
  say = function(self, message, onDone)
    self.stack:push({ message = message, onDone = onDone })
  end,
}
if generation == 2 then
  game.afterRareCandy = function(_, _, _, onDone) if onDone then onDone() end end
end

if generation == 1 then
  Bulk.openGen1(game, "RARE_CANDY")
  local party = stack:top()
  party.onSwitch(mon)
else
  Bulk.openGen2(game, "RARE_CANDY")
  local party = stack:top()
  party.onChoose(1, mon)
end
local qty = stack:top()
assert(qty and qty.max == 1, "Rare Candy selector must cap at level 100")
qty.onDone(1)
assert(mon.level == 100, "Rare Candy batch must use the native one-level increase")
assert(game.save.inventory.RARE_CANDY == nil, "Rare Candy batch must consume one successful use")

run.release()
print(("Inventory QoL Rare Candy Gen %d: PASS"):format(generation))
