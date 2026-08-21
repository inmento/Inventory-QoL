local Bulk = {}
local Strings = require("src.core.Strings")

local PERMANENT = {
  RARE_CANDY = "candy",
  PP_UP = "pp",
  HP_UP = "vitamin", PROTEIN = "vitamin", IRON = "vitamin",
  CARBOS = "vitamin", CALCIUM = "vitamin", ZINC = "vitamin",
}

local VITAMIN_STAT = {
  HP_UP = "hp", PROTEIN = "attack", IRON = "defense",
  CARBOS = "speed", CALCIUM = "special", ZINC = "special",
}

local function itemName(game, itemId)
  local def = game and game.data and game.data.items and game.data.items[itemId]
  return (def and def.name) or tostring(itemId):gsub("_", " ")
end

function Bulk.kind(itemId)
  return PERMANENT[itemId]
end

function Bulk.isPermanent(itemId)
  return Bulk.kind(itemId) ~= nil
end

function Bulk.maxFor(game, itemId, mon, moveIndex)
  local owned = math.max(0, ((game.save or {}).inventory or {})[itemId] or 0)
  if owned == 0 or not mon or mon.isEgg then return 0 end
  local kind = Bulk.kind(itemId)
  if kind == "candy" then
    return math.min(owned, math.max(0, 100 - (mon.level or 1)))
  end
  if kind == "vitamin" then
    local stat = VITAMIN_STAT[itemId]
    local current = ((mon.statExp or {})[stat] or 0)
    -- Gen 1/2 vitamins add 2560 and refuse at the 25600 pre-cap.  A value
    -- below the threshold gets one final legal use, even if it clamps above it.
    return math.min(owned, math.max(0, math.ceil((25600 - current) / 2560)))
  end
  if kind == "pp" then
    local move = (mon.moves or {})[moveIndex or 1]
    if not move or move.id == "SKETCH" then return 0 end
    return math.min(owned, math.max(0, 3 - (move.ppUps or 0)))
  end
  return 0
end

local function pushQuantity(game, max, onDone)
  local QuantityBox = require("src.ui.QuantityBox")
  game.stack:push(QuantityBox.new(game, { max = max, onDone = onDone }))
end

local function text(game, message, onDone)
  local TextBox = require("src.render.TextBox")
  game.stack:push(TextBox.new(game, Strings(message), onDone))
end

local function monName(game, mon)
  local def = game.data.pokemon and game.data.pokemon[mon.species]
  return mon.nickname or (def and def.name) or mon.species or "POKéMON"
end

local function summary(game, itemId, used, mon)
  local item = itemName(game, itemId)
  local count = used == 1 and "1" or tostring(used)
  text(game, string.format("Used %s %s\non %s!", count, item, monName(game, mon)))
end

-- Gen 1's post-candy logic lives partly in BagMenu.  This reproduces the
-- native order (level move(s), then evolution) but deliberately omits the
-- repeated per-level message; interactive move/evolution screens remain.
local function gen1AfterLevel(game, mon, level, done)
  local Experience = require("src.battle.Experience")
  local Evolution = require("src.pokemon.Evolution")
  local TextBox = require("src.render.TextBox")
  local def = game.data.pokemon[mon.species]
  local moves = Experience.movesLearnedAt(def, level)
  local i = 0
  local function evolve()
    local evoTo, evo = Evolution.pendingFor(game, mon, { kind = "levelup" })
    if evoTo then
      Evolution.evolve(game, mon, evoTo, done, evo and evo.method)
    else
      done()
    end
  end
  local function nextMove()
    i = i + 1
    local moveId = moves[i]
    if not moveId then return evolve() end
    for _, known in ipairs(mon.moves or {}) do
      if known.id == moveId then return nextMove() end
    end
    local moveDef = game.data.moves[moveId]
    if not moveDef then return nextMove() end
    if #(mon.moves or {}) < 4 then
      mon.moves = mon.moves or {}
      table.insert(mon.moves, { id = moveId, pp = moveDef.pp })
      text(game, string.format("%s learned\n%s!", monName(game, mon), moveDef.name), nextMove,
           TextBox.soundOpts(game, "Get_Item1"))
    else
      require("src.ui.Screens").push(game, "MoveLearnMenu", mon, moveId, nextMove)
    end
  end
  nextMove()
end

local function applyGen1(game, itemId, mon, moveIndex, qty, onDone)
  local Bag = require("src.inventory.Bag")
  local ItemEffects = require("src.inventory.ItemEffects")
  local remaining, used = qty, 0
  local function finish()
    if used > 0 then summary(game, itemId, used, mon) end
    if onDone then onDone(used) end
  end
  local function step()
    if remaining <= 0 then return finish() end
    local result, _, extra = ItemEffects.use(game.data, game.save, itemId, mon,
      nil, moveIndex, game.overworld)
    if result ~= "consumed" then return finish() end
    Bag.remove(game.save, itemId, 1)
    used, remaining = used + 1, remaining - 1
    if itemId == "RARE_CANDY" and extra and extra.leveledTo then
      -- Defer only at a real interaction boundary; otherwise continue in the
      -- same flow so a large legal batch does not require one confirm per level.
      gen1AfterLevel(game, mon, extra.leveledTo, step)
    else
      step()
    end
  end
  step()
end

local function applyGen2(game, itemId, mon, moveIndex, qty, onDone)
  local Bag = require("src.inventory.Bag")
  local Effects = require("src.core.gen2.ItemEffects")
  local remaining, used = qty, 0
  local function finish()
    if used > 0 then summary(game, itemId, used, mon) end
    if onDone then onDone(used) end
  end
  local function step()
    if remaining <= 0 then return finish() end
    local result
    if itemId == "PP_UP" then
      result = Effects.usePpItem(itemId, mon, moveIndex, game.data)
    else
      result = Effects.useOnMon(itemId, mon, game.data)
    end
    if not result or not result.used then return finish() end
    Bag.remove(game.save, itemId, 1)
    used, remaining = used + 1, remaining - 1
    if itemId == "RARE_CANDY" then
      -- Game2 owns its real level-move/evolution continuation.  Supplying a
      -- callback resumes the batch only after all interactive native screens
      -- have completed.
      game:afterRareCandy(mon, result, step)
    else
      step()
    end
  end
  step()
end

local function chooseGen1Move(game, itemId, mon, onChosen)
  local ListMenu = require("src.ui.ListMenu")
  local rows = {}
  for index, move in ipairs(mon.moves or {}) do
    local def = game.data.moves[move.id]
    rows[#rows + 1] = {
      value = index,
      label = (def and def.name) or move.id,
      right = tostring(move.pp or 0),
    }
  end
  game.stack:push(ListMenu.new(game, "Which move?", rows, {
    onChoose = function(row, list)
      list:close()
      onChosen(row.value)
    end,
  }))
end

function Bulk.openGen1(game, itemId, bagList)
  local Screens = require("src.ui.Screens")
  Screens.push(game, "PartyMenu", {
    pickOnly = true,
    onSwitch = function(mon)
      local function selected(moveIndex)
        local max = Bulk.maxFor(game, itemId, mon, moveIndex)
        if max < 1 then
          return text(game, "It won't have\nany effect.")
        end
        pushQuantity(game, max, function(qty)
          if qty then
            applyGen1(game, itemId, mon, moveIndex, qty, function()
              if bagList and bagList.items then
                for _, row in ipairs(bagList.items) do
                  if row.value == itemId then row.right = "x" .. (game.save.inventory[itemId] or 0) end
                end
              end
            end)
          end
        end)
      end
      if itemId == "PP_UP" then chooseGen1Move(game, itemId, mon, selected) else selected(nil) end
    end,
  })
end

function Bulk.openGen2(game, itemId, pack)
  local Screens = require("src.ui.Screens")
  Screens.push(game, "Gen2PartyMenu", {
    prompt = "useItem",
    onCancel = function() game.stack:pop() end,
    onChoose = function(_, mon)
      game.stack:pop()
      local function selected(moveIndex)
        local max = Bulk.maxFor(game, itemId, mon, moveIndex)
        if max < 1 then return game:say("It won't have\nany effect.") end
        pushQuantity(game, max, function(qty)
          if qty then
            applyGen2(game, itemId, mon, moveIndex, qty, function()
              if pack and pack.rebuild then pack:rebuild() end
            end)
          end
        end)
      end
      if itemId ~= "PP_UP" then return selected(nil) end
      Screens.push(game, "Gen2MoveDeleter", {
        mon = mon,
        moves = game.data.moves,
        onCancel = function() game.stack:pop() end,
        onChoose = function(slot)
          game.stack:pop()
          selected(slot)
        end,
      })
    end,
  })
end

return Bulk
