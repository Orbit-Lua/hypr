local cli = require("hyprconf.cli")
local common = require("hyprconf.commands.common")

---@class Hyprconf.Commands.Layout
---@field change_blur fun()
---@field change_layout fun()
---@field game_mode fun()
local M = {}

---@return nil
function M.change_blur()
  local state = cli.hypr_option("decoration:blur:passes").int
  if state == 2 then
    cli.hypr_config("{ decoration = { blur = { size = 2, passes = 1 } } }")
    cli.notify_info("Window Blur", "Reduced", "window-blur")
  else
    cli.hypr_config("{ decoration = { blur = { size = 5, passes = 2 } } }")
    cli.notify_success("Window Blur", "Normal", "window-blur")
  end
end

---@return nil
function M.change_layout()
  local layout = cli.hypr_option("general:layout").str or "dwindle"

  if layout == "dwindle" then
    cli.hypr_config('{ general = { layout = "master" } }')
    cli.notify_success("Window Layout", "Master", "window-layout")
  elseif layout == "master" then
    cli.hypr_config('{ general = { layout = "scrolling" } }')
    cli.notify_success("Window Layout", "Scrolling", "window-layout")
  else
    cli.hypr_config('{ general = { layout = "dwindle" } }')
    cli.notify_success("Window Layout", "Dwindle", "window-layout")
  end
end

---@return nil
function M.game_mode()
  local enabled = cli.hypr_option("animations:enabled").int
  if enabled == 1 then
    local game_mode_config = table.concat({
      "{ animations = { enabled = false },",
      "decoration = { shadow = { enabled = false },",
      "blur = { enabled = false }, rounding = 0 },",
      "general = { gaps_in = 0, gaps_out = 0, border_size = 1 } }",
    }, " ")
    local opacity_rule = table.concat({
      'hypr_game_mode_opacity = hl.window_rule({ name = "hypr-game-mode-opacity",',
      'match = { class = ".*" },',
      'opacity = "1 override 1 override 1 override" })',
    }, " ")

    cli.hypr_config(game_mode_config)
    cli.hypr_eval(opacity_rule)
    cli.notify_success("Game Mode", "Enabled", "game-mode")
  else
    os.execute("sleep 0.6")
    cli.exec("hyprctl reload >/dev/null 2>&1 || true")
    cli.exec_bg(common.lua_cmd("refresh"))
    cli.notify_info("Game Mode", "Disabled", "game-mode")
  end
end

return M
