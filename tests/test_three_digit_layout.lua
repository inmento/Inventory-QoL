local engineRoot = assert(arg[1], "engine root is required")
local modPath = assert(arg[2], "relative staged mod path is required")
local generation = tonumber(arg[3] or "1")

package.path = engineRoot .. "/?.lua;" .. engineRoot .. "/?/init.lua;" .. package.path
love = { graphics = { setColor = function() end, rectangle = function() end } }

local T = require("tests.modkit")
local run = T.sdk.loadMods({ modPath }, { root = engineRoot, generation = generation })
assert(#run.errors == 0, table.concat(run.errors, "\n"))

local game = {
  save = { inventory = { POTION = 999 }, bagOrder = { "POTION" } },
  data = run.data,
  stack = { top = function() return nil end, push = function() end, pop = function() end },
}

local Font = require("src.render.Font")
local original = { draw = Font.draw, drawBox = Font.drawBox, drawCode = Font.drawCode, width = Font.width }
local calls = {}
Font.draw = function(text, x, y) calls[#calls + 1] = { text = text, x = x, y = y } end
Font.drawBox = function() end
Font.drawCode = function() end
Font.width = function(text) return #tostring(text) * 8 end

local bag = assert(run.loader.content.screens:get("BagMenu")).new(game, {})
bag:drawItemBox()
local multiplier, digits
for _, call in ipairs(calls) do
  if call.text == "x" then multiplier = call end
  if call.text == "999" then digits = call end
end
assert(multiplier and multiplier.x == 104, "Gen 1 × must shift left at three digits")
assert(digits and digits.x == 112, "Gen 1 three digits must retain the fixed right edge")

local Chrome = require("src.ui.gen2.Chrome")
local oldPrint, oldCursor = Chrome.print, Chrome.cursor
local chromeCalls = {}
Chrome.print = function(text, x, y) chromeCalls[#chromeCalls + 1] = { text = text, x = x, y = y } end
Chrome.cursor = function() end
local pack = assert(run.loader.content.screens:get("Gen2PackMenu")).new(game, {
  save = game.save, items = game.data.items,
})
pack:drawList(8, 2)
local gen2Count
for _, call in ipairs(chromeCalls) do if call.text == "×999" then gen2Count = call end end
assert(gen2Count and gen2Count.x == 8, "Gen 2 three-digit stack must render from the dedicated quantity column")

Font.draw, Font.drawBox, Font.drawCode, Font.width = original.draw, original.drawBox, original.drawCode, original.width
Chrome.print, Chrome.cursor = oldPrint, oldCursor
run.release()
print(("Inventory QoL three-digit layout Gen %d: PASS"):format(generation))
