local engineRoot = assert(arg[1], "engine root is required")
local modPath = assert(arg[2], "relative staged mod path is required")
package.path = engineRoot .. "/?.lua;" .. engineRoot .. "/?/init.lua;" .. package.path

local T = require("tests.modkit")
local Bag = require("src.inventory.Bag")
local run = T.sdk.loadMods({ modPath }, { root = engineRoot, generation = 1 })
assert(#run.errors == 0, table.concat(run.errors, "\n"))

local started = os.clock()
for _ = 1, 1000 do
  local save = { inventory = {}, bagOrder = {} }
  assert(Bag.add(save, "POTION", 1, run.data))
  for _ = 2, 999 do assert(Bag.add(save, "POTION", 1, run.data)) end
  assert(not Bag.add(save, "POTION", 1, run.data))
end
local elapsed = os.clock() - started
-- A deliberately generous guard for the VM: this protects against a future
-- regression that repeatedly scans a 999-count stack or rebuilds a bag list
-- on every successful add, while avoiding hardware-specific micro-benchmarking.
assert(elapsed < 3, ("999-stack hot path regressed: %.3fs"):format(elapsed))
run.release()
print(("Inventory QoL stack hot path: PASS (%.3fs)"):format(elapsed))
