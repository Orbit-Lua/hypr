-- Toggle layout options and preserve the original game-mode state.
local hyprctl = require("hyprconf.runtime.hyprctl")
local notify = require("hyprconf.runtime.notify")

---@class Hyprconf.Commands.Layout
local M = {}

---@return nil
function M.change_blur()
  if hyprctl.option("decoration:blur:passes").int == 2 then
    hyprctl.config({ decoration = { blur = { size = 2, passes = 1 } } })
    notify.info("Window Blur", "Reduced", "window-blur")
  else
    hyprctl.config({ decoration = { blur = { size = 5, passes = 2 } } })
    notify.info("Window Blur", "Normal", "window-blur")
  end
end

---@param operator "*"|"/"
---@param factor string
---@return nil
function M.zoom(operator, factor)
  assert(operator == "*" or operator == "/", "invalid zoom operator")
  local multiplier = assert(tonumber(factor), "invalid zoom multiplier")
  assert(multiplier > 0 and multiplier < math.huge, "invalid zoom multiplier")
  local option = hyprctl.option("cursor:zoom_factor")
  local current = option.float or option.int
  assert(
    type(current) == "number" and current == current and math.abs(current) ~= math.huge,
    "invalid current zoom factor"
  )
  -- Keep the existing clamp before scaling, including division below 1.
  local value = math.max(1, current)
  if operator == "*" then
    value = value * multiplier
  else
    value = value / multiplier
  end
  hyprctl.config({ cursor = { zoom_factor = value } })
end

---@type table<string, [string, string]>
local next_layout = {
  dwindle = { "master", "Master" },
  master = { "scrolling", "Scrolling" },
  scrolling = { "dwindle", "Dwindle" },
}

---@return nil
function M.change_layout()
  local current = hyprctl.option("general:layout").str
  local layout = next_layout[current or "dwindle"] or next_layout.scrolling
  hyprctl.config({ general = { layout = layout[1] } })
  notify.info("Window Layout", layout[2], "window-layout")
end

local fs = require("hyprconf.util.fs")
local ctx = require("hyprconf.context")
local json = require("hyprconf.util.json")
local state = require("hyprconf.runtime.state")

local game_options = {
  ["animations:enabled"] = false,
  ["decoration:shadow:enabled"] = false,
  ["decoration:blur:enabled"] = false,
  ["decoration:rounding"] = 0,
  ["general:gaps_in"] = 0,
  ["general:gaps_out"] = 0,
  ["general:border_size"] = 1,
}

---@return string
local function game_path()
  local signature =
    assert(os.getenv("HYPRLAND_INSTANCE_SIGNATURE"), "Hyprland session identity is unavailable")
  assert(signature:match("^[%w_.-]+$"), "invalid Hyprland session identity")
  return (os.getenv("XDG_RUNTIME_DIR") or ctx.state_dir)
    .. "/hypr/game-mode-"
    .. signature
    .. ".json"
end

---@param values table<string, boolean|number|string>
local function apply_options(values)
  local nested = {}
  for name, value in pairs(values) do
    local parts = {}
    for part in name:gmatch("[^:]+") do
      parts[#parts + 1] = part
    end
    local target = nested
    for index = 1, #parts - 1 do
      local part = parts[index]
      target[part] = target[part] or {}
      target = target[part]
    end
    target[parts[#parts]] = value
  end
  ---@cast nested HL.ConfigOpt
  hyprctl.config(nested)
end

---@param contents string
---@return table<string, boolean|number|string>
local function original_options(contents)
  ---@type table<string, boolean|number|string>
  local values = json.decode(contents)
  assert(type(values) == "table", "invalid game mode state")
  for name, default in pairs(game_options) do
    local value = values[name]
    if type(default) == "boolean" then
      assert(type(value) == "boolean", "invalid saved game mode boolean")
    else
      assert(
        type(value) == "number" or (type(value) == "string" and value:match("^[%d%s.%-]+$")),
        "invalid saved game mode number"
      )
    end
  end
  for name in pairs(values) do
    assert(game_options[name] ~= nil, "unknown saved game mode option")
  end
  return values
end

---@return nil
function M.reapply_game_mode()
  local contents = fs.read(game_path())
  if not contents then
    return
  end
  original_options(contents)
  apply_options(game_options)
  hyprctl.game_opacity(true)
end

---@param name string
---@param default boolean|number
---@return boolean|number|string
local function current_game_option(name, default)
  local option = hyprctl.option(name)
  if type(default) == "boolean" then
    if type(option.bool) == "boolean" then
      return option.bool
    end
    assert(option.int == 0 or option.int == 1, "invalid game mode option")
    return option.int == 1
  end
  local value = option.custom or option.str or option.int or option.float
  assert(value ~= nil, "game mode option is unavailable")
  return value
end

---@return table<string, boolean|number|string>
local function capture_game_options()
  local original = {}
  for name, default in pairs(game_options) do
    original[name] = current_game_option(name, default)
  end
  return original_options(json.encode(original))
end

---@return nil
function M.game_mode()
  local path = game_path()
  local contents = fs.read(path)
  local original = contents and original_options(contents) or capture_game_options()
  state.change(path, not contents and json.encode(original) or nil, function()
    local enabled = fs.exists(path)
    apply_options(enabled and game_options or original)
    hyprctl.game_opacity(enabled)
  end)
  notify.info("Game Mode", contents and "Disabled" or "Enabled", "game-mode")
end

return M
