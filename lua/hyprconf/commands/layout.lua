local cli = require("hyprconf.cli")
local common = require("hyprconf.commands.common")

---@alias Hyprconf.LayoutName "dwindle"|"master"|"scrolling"|string

---@class Hyprconf.Commands.Layout
---@field change_blur fun()
---@field keybinds_layout_init fun()
---@field change_layout fun(mode?: "init"|string)
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

---@param layout Hyprconf.LayoutName
---@return nil
local function bind_layout(layout)
  cli.hypr_unbind("SUPER + J")
  cli.hypr_unbind("SUPER + K")
  cli.hypr_unbind("SUPER + O")

  if layout == "master" then
    cli.hypr_bind("SUPER + J", 'hl.dsp.layout("cyclenext")')
    cli.hypr_bind("SUPER + K", 'hl.dsp.layout("cycleprev")')
  elseif layout == "scrolling" then
    cli.hypr_bind("SUPER + J", 'hl.dsp.layout("focus d")')
    cli.hypr_bind("SUPER + K", 'hl.dsp.layout("focus u")')
  else
    cli.hypr_bind("SUPER + J", "hl.dsp.window.cycle_next()")
    cli.hypr_bind("SUPER + K", "hl.dsp.window.cycle_next({ next = false })")
    cli.hypr_bind("SUPER + O", 'hl.dsp.layout("togglesplit")')
  end
end

---@return nil
function M.keybinds_layout_init()
  bind_layout("dwindle")
end

---@param mode? "init"|string
---@return nil
function M.change_layout(mode)
  local layout = cli.hypr_option("general:layout").str or "dwindle"
  if mode == "init" then
    bind_layout(layout)
    return
  end

  if layout == "dwindle" then
    cli.hypr_config('{ general = { layout = "master" } }')
    bind_layout("master")
    cli.notify_success("Window Layout", "Master", "window-layout")
  elseif layout == "master" then
    cli.hypr_config('{ general = { layout = "scrolling" } }')
    bind_layout("scrolling")
    cli.notify_success("Window Layout", "Scrolling", "window-layout")
  else
    cli.hypr_config('{ general = { layout = "dwindle" } }')
    bind_layout("dwindle")
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
