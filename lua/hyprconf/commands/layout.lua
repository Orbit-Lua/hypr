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
  local signature = assert(
    os.getenv("HYPRLAND_INSTANCE_SIGNATURE"),
    "Hyprland session identity is unavailable"
  )
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
        type(value) == "number"
          or (type(value) == "string" and value:match("^[%d%s.%-]+$")),
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

---@return nil
function M.game_mode()
  local path = game_path()
  local contents = fs.read(path)
  local original = {}
  if contents then
    original = original_options(contents)
  else
    for name, default in pairs(game_options) do
      local option = hyprctl.option(name)
      if type(default) == "boolean" then
        if type(option.bool) == "boolean" then
          original[name] = option.bool
        else
          assert(option.int == 0 or option.int == 1, "invalid game mode option")
          original[name] = option.int == 1
        end
      else
        original[name] = option.custom
          or option.str
          or option.int
          or option.float
        assert(original[name] ~= nil, "game mode option is unavailable")
      end
    end
    original_options(json.encode(original))
  end
  state.change(path, not contents and json.encode(original) or nil, function()
    local enabled = fs.exists(path)
    apply_options(enabled and game_options or original)
    hyprctl.game_opacity(enabled)
  end)
  notify.info("Game Mode", contents and "Disabled" or "Enabled", "game-mode")
end

return M
