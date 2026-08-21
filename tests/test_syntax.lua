local root = arg[1] or "."
local files = { "main.lua", "bulk.lua" }
for _, file in ipairs(files) do
  local chunk, err = loadfile(root .. "/" .. file)
  assert(chunk, file .. " failed to compile: " .. tostring(err))
end
print("Inventory QoL syntax: PASS")
