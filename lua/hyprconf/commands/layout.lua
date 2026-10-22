local hyprctl = require("hyprconf.runtime.hyprctl")
local notify = require("hyprconf.runtime.notify")

---@class Hyprconf.Commands.Layout
local M = {}

---@return nil
function M.change_blur()
  if hyprctl.option("decoration:blur:passes").int == 2 then
    hyprctl.config("{ decoration = { blur = { size = 2, passes = 1 } } }")
    notify.info("Window Blur", "Reduced", "window-blur")
  else
    hyprctl.config("{ decoration = { blur = { size = 5, passes = 2 } } }")
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
  hyprctl.config('{ general = { layout = "' .. layout[1] .. '" } }')
  notify.info("Window Layout", layout[2], "window-layout")
end

---@return nil
function M.game_mode()
  if hyprctl.option("animations:enabled").int == 1 then
    hyprctl.config(table.concat({
      "{ animations = { enabled = false },",
      "decoration = { shadow = { enabled = false },",
      "blur = { enabled = false }, rounding = 0 },",
      "general = { gaps_in = 0, gaps_out = 0, border_size = 1 } }",
    }, " "))
    hyprctl.eval(table.concat({
      'hypr_game_mode_opacity = hl.window_rule({ name = "hypr-game-mode-opacity",',
      'match = { class = ".*" },',
      'opacity = "1 override 1 override 1 override" })',
    }, " "))
    notify.info("Game Mode", "Enabled", "game-mode")
  else
    os.execute("sleep 0.6")
    -- The reload hook reapplies runtime effects.
    hyprctl.reload()
    notify.info("Game Mode", "Disabled", "game-mode")
  end
end

return M
