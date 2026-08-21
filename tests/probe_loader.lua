local engineRoot = assert(arg[1])
local modRoot = assert(arg[2])
package.path = engineRoot .. "/?.lua;" .. engineRoot .. "/?/init.lua;" .. package.path
local T = require("tests.modkit")
local run = T.sdk.loadMods({ modRoot }, { root = engineRoot, generation = 1 })
print("errors=" .. #run.errors)
for _, err in ipairs(run.errors) do print("ERR: " .. err) end
for id, mod in pairs(run.loader.mods) do
  print("mod=" .. tostring(id) .. " enabled=" .. tostring(mod.enabled) .. " path=" .. tostring(mod.path))
end
local screens = run.loader.content.screens
print("bag=" .. tostring(screens:get("BagMenu")))
print("pack=" .. tostring(screens:get("Gen2PackMenu")))
run.release()
