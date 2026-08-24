local engineRoot = assert(arg[1], "engine root is required")
local modRoot = assert(arg[2], "Inventory QoL mod root is required")

package.path = engineRoot .. "/?.lua;" .. engineRoot .. "/?/init.lua;" .. package.path

local GameVersion = require("src.core.GameVersion")
local T = require("tests.modkit")

assert(GameVersion.generation("crystal") == 2,
  "official Crystal runtime metadata must identify Crystal as Generation 2")
assert(GameVersion.engine("crystal") == "crystal",
  "official Crystal runtime metadata must retain the Crystal engine identity")

local previousVersion = GameVersion.get()
GameVersion.set("crystal")
local run = T.sdk.loadMods({ modRoot }, {
  root = engineRoot,
  generation = GameVersion.generation("crystal"),
})

assert(#run.errors == 0, table.concat(run.errors, "\n"))
local inventoryMod = run.mods.inventory_qol
assert(inventoryMod and inventoryMod.state == "loaded",
  "Inventory QoL must load for Crystal through its existing gen2 manifest scope; state="
    .. tostring(inventoryMod and inventoryMod.state))
assert(run.loader.content.screens:get("Gen2PackMenu"),
  "Inventory QoL must register its Gen 2 PackMenu override for Crystal")

run.release()
GameVersion.set(previousVersion)
print("Inventory QoL Crystal Gen 2 PackMenu loader smoke: PASS")
