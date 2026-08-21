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
local moveId, moveDef = next(run.data.moves)
assert(moveId and moveDef and moveDef.pp, "fixture needs one move with PP")
local mon = {
  species = species, level = 25, hp = 50,
  dvs = { attack = 7, defense = 7, speed = 7, special = 7, hp = 7 },
  statExp = {}, moves = { { id = moveId, pp = moveDef.pp, maxPp = moveDef.pp, ppUps = 2 } },
}
local game = {
  save = { inventory = { PP_UP = 2 }, party = { mon } },
  data = run.data,
  stack = stack,
  overworld = {},
  say = function(self, message, onDone) self.stack:push({ message = message, onDone = onDone }) end,
}

if generation == 1 then
  Bulk.openGen1(game, "PP_UP")
  local party = stack:top()
  party.onSwitch(mon)
  local moves = stack:top()
  moves.onChoose(moves.items[1], moves)
else
  Bulk.openGen2(game, "PP_UP")
  local party = stack:top()
  party.onChoose(1, mon)
  local moves = stack:top()
  moves.onChoose(1)
end
local qty = stack:top()
assert(qty and qty.max == 1, "PP Up selector must stop at the third PP Up")
qty.onDone(1)
assert(mon.moves[1].ppUps == 3, "PP Up batch must use the native per-move counter")
assert(game.save.inventory.PP_UP == 1, "PP Up batch must consume exactly the confirmed quantity")

run.release()
print(("Inventory QoL PP Up Gen %d: PASS"):format(generation))
