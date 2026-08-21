-- Inventory QoL: 999-stack support, three-digit bag rendering, remembered Gen 1
-- bag cursor, and field-only cap-aware batch use for permanent consumables.

return function(mod)
  local function localModule(path)
    local source = mod:read(path)
    if not source then error(path .. " is missing; reinstall the mod") end
    local chunk, err = load(source, "@" .. mod.path .. "/" .. path)
    if not chunk then error(path .. " did not compile: " .. tostring(err)) end
    return chunk()
  end

  local Bulk = localModule("bulk.lua")
  local Bag = require("src.inventory.Bag")
  local Font = require("src.render.Font")
  local Theme = require("src.ui.Theme")
  local Strings = require("src.core.Strings")

  local STACK_CAP = 999

  local function singleton(id, data)
    local def = data and data.items and data.items[id]
    return Bag.isBadge(id) or (def and def.keyItem)
      or tostring(id):find("^HM_") ~= nil
  end

  -- Preserve Bag.add's pocket capacity and acquisition-order semantics while
  -- replacing only its per-stack 99 limit for ordinary stackable items.
  local originalAdd = Bag.add
  Bag.add = function(save, id, qty, data)
    qty = qty or 1
    if singleton(id, data) then return originalAdd(save, id, qty, data) end
    local inv = save.inventory
    local pocket = Bag.pocketOf(id, data)
    if not inv[id] and Bag.slots(save, data, pocket) >= Bag.capacity(data, pocket) then
      return false
    end
    if (inv[id] or 0) + qty > STACK_CAP then return false end
    if not inv[id] then table.insert(Bag.order(save, data), id) end
    inv[id] = (inv[id] or 0) + qty
    return true
  end

  -- QuantityBox already has correct input stepping for values above 99.  Its
  -- stock box is only three interior tiles wide, so enlarge it only when a
  -- 3-digit result is possible.
  local QuantityBox = require("src.ui.QuantityBox")
  local originalQuantityDraw = QuantityBox.draw
  QuantityBox.draw = function(self)
    if self.max <= 99 then return originalQuantityDraw(self) end
    local tx, tw, ty = self.unitPrice and 6 or 14, self.unitPrice and 14 or 6, 9
    Font.drawBox(tx, ty, tw, 3)
    love.graphics.setColor(0, 0, 0, 1)
    local value = "×" .. tostring(self.qty)
    if self.unitPrice then value = value .. (" ¥%d"):format(self.qty * self.unitPrice) end
    Font.draw(value, (tx + 1) * 8, (ty + 1) * 8)
    love.graphics.setColor(1, 1, 1, 1)
  end

  local function drawGen1Bag(self)
    love.graphics.setColor(1, 1, 1, 1)
    Font.drawBox(4, 2, 16, 11)
    love.graphics.setColor(0, 0, 0, 1)
    if #self.items == 0 then Font.draw(Strings("Nothing here."), 48, 32) end
    local shown = 0
    for row = 1, self.rows do
      local i = self.scroll + row
      local item = self.items[i]
      if not item then break end
      shown = shown + 1
      local y = 32 + (row - 1) * 16
      Font.draw(item.label, 48, y)
      if item.right then
        local count = item.right:sub(2)
        -- Vanilla's × is at column 14; move it one tile left at 100–999,
        -- reserving three digit cells before the same right edge.
        local multiplyX = (#count >= 3) and 104 or 112
        Font.draw(item.right:sub(1, 1), multiplyX, y + 8)
        Font.draw(count, 136 - Font.width(count), y + 8)
      end
      if i == self.index then
        Font.drawCode(self.hollowIndex == i and Theme.cursorHollow or Theme.cursor, 40, y)
      end
      if self.swapIndex == i and i ~= self.index then Font.drawCode(Theme.cursorHollow, 40, y) end
    end
    if shown == self.rows then Font.drawCode(Theme.moreArrow, 144, 88) end
    love.graphics.setColor(1, 1, 1, 1)
  end

  local function rememberGen1Cursor(game, list)
    game.inventoryQolBagCursor = { index = list.index, scroll = list.scroll }
  end

  local function installGen1Bag(list, game, opts)
    list.inventoryQoLBattle = opts and opts.battle or nil
    local saved = game.inventoryQolBagCursor
    if saved then
      list.index = math.max(1, math.min(saved.index or 1, math.max(1, #list.items)))
      list.scroll = math.max(0, saved.scroll or 0)
    end
    list.drawItemBox = drawGen1Bag
    local close = list.close
    list.close = function(self)
      rememberGen1Cursor(game, self)
      return close(self)
    end
    local choose, cancel, select = list.onChoose, list.onCancel, list.onSelectKey
    list.onChoose = function(item, self)
      rememberGen1Cursor(game, self)
      local result = choose(item, self)
      -- BagMenu's stock callback has now pushed its USE/TOSS Menu.  Add the
      -- one extra field-only row on that exact instance; this avoids changing
      -- the shared Menu constructor used by unrelated screens.
      if not self.inventoryQoLBattle and item and Bulk.isPermanent(item.value) then
        local menu = game.stack and game.stack:top()
        if menu and menu.items then
          local hasMany = false
          for _, row in ipairs(menu.items) do if row.label == "USE MANY" then hasMany = true end end
          if not hasMany then
            for i, row in ipairs(menu.items) do
              if row.label == "USE" then
                table.insert(menu.items, i + 1, { label = "USE MANY", onSelect = function()
                  Bulk.openGen1(game, item.value, self)
                end })
                menu.th = math.max(menu.th or 0, 7)
                break
              end
            end
          end
        end
      end
      return result
    end
    list.onCancel = function(...)
      rememberGen1Cursor(game, list)
      if cancel then return cancel(...) end
    end
    list.onSelectKey = function(item, self)
      rememberGen1Cursor(game, self)
      if select then return select(item, self) end
    end
    return list
  end

  mod.content.screens:override("BagMenu", {
    new = function(game, opts)
      local base = require("src.ui.BagMenu").new(game, opts)
      return installGen1Bag(base, game, opts)
    end,
  })

  mod.content.screens:override("Gen2PackMenu", {
    new = function(game, opts)
      local pack = require("src.ui.gen2.PackMenu").new(game, opts)
      local Chrome = require("src.ui.gen2.Chrome")
      local baseRows, baseChoose = pack.submenuRows, pack.chooseSubmenu
      local baseDrawList = pack.drawList
      pack.submenuRows = function(self, itemId)
        local rows = baseRows(self, itemId)
        if not self:inBattle() and not self.give and Bulk.isPermanent(itemId) then
          for i, id in ipairs(rows) do
            if id == "use" then table.insert(rows, i + 1, "many") break end
          end
        end
        return rows
      end
      pack.chooseSubmenu = function(self)
        local menu = self.submenu
        if menu and menu.rows[menu.index] == "many" then
          local row = menu.row
          self:closeSubmenu()
          return Bulk.openGen2(game, row.id, self)
        end
        return baseChoose(self)
      end
      -- The stock renderer accepts a wider numeric string but positions it for
      -- two digits. Redraw rows with a dedicated 3-digit quantity column.
      pack.drawList = function(self, listX, listY)
        local visibleRows, spacing = 5, 2
        for row = 1, visibleRows do
          local i, ty = row + self.scroll, listY + (row - 1) * spacing
          if i <= #self.rows then
            local entry = self.rows[i]
            if i == self.index then Chrome.cursor(listX - 1, ty)
            elseif i == self.switching then Chrome.cursor(listX - 1, ty, true) end
            Chrome.print(entry.name, listX, ty)
            if entry.teaches then
              Chrome.print(entry.teaches, listX + 1, ty + 1)
              if entry.showCount then Chrome.print("×" .. Chrome.number(entry.count, 3), listX + 8, ty) end
            elseif entry.showCount then
              Chrome.print("×" .. Chrome.number(entry.count, 3), listX, ty + 1)
            end
          elseif i == self:total() then
            if i == self.index then Chrome.cursor(listX - 1, ty) end
            Chrome.print("CANCEL", listX, ty)
          end
        end
      end
      pack.drawQuantity = function(self)
        local state = self.qtyState
        if state.max <= 99 then return require("src.ui.gen2.PackMenu").drawQuantity(self) end
        Chrome.box(14, 9, 6, 3)
        Chrome.print("×" .. Chrome.number(state.qty, 3, true), 15, 10)
      end
      return pack
    end,
  })

end
