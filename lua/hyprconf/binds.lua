local ctx = require("hyprconf.context")
local util = require("hyprconf.util")

---@class Hyprconf.Binds
---@field setup fun()
local M = {}

local mod = ctx.main_mod
local bind = util.bind
local bind_exec = util.bind_exec
local raw_dispatch = util.raw_dispatch
local min_workspace = 1
local max_workspace = 10

---@param dispatchers table<string, Hyprconf.Dispatcher>
---@return fun()
local function layout_bind(dispatchers)
  return function()
    local workspace = hl.get_active_special_workspace()
      or hl.get_active_workspace()
    if not workspace then
      return
    end

    local dispatcher = dispatchers[workspace.tiled_layout]
    if dispatcher then
      hl.dispatch(dispatcher)
    end
  end
end

---@param offset integer
---@param move_window? boolean
---@return fun()
local function workspace_step(offset, move_window)
  return function()
    local workspace = hl.get_active_workspace()
    if not workspace then
      return
    end

    local target = workspace.id + offset
    if target < min_workspace or target > max_workspace then
      return
    end

    if move_window then
      hl.dispatch(hl.dsp.window.move({ workspace = target }))
    else
      hl.dispatch(hl.dsp.focus({ workspace = target }))
    end
  end
end

-- luacheck: push ignore
local zoom_in =
  [[hyprctl keyword cursor:zoom_factor "$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor * 2.0}')"]]
local zoom_out =
  [[hyprctl keyword cursor:zoom_factor "$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor / 2.0}')"]]
-- luacheck: pop

---@return nil
local function applications()
  bind_exec(
    mod .. " + D",
    "application launcher",
    "$vicinae 'vicinae://toggle'"
  )
  bind_exec(mod .. " + B", "open default browser", [[xdg-open "https://"]])
  bind_exec(mod .. " + A", "desktop overview", "$hyprLua overview")
  bind_exec(mod .. " + Return", "open terminal", "$term")
  bind_exec(mod .. " + E", "file manager", "$files")
  bind_exec(mod .. " + slash", "cheat sheet", "$hyprLua key-hints")
  bind_exec(mod .. " + SHIFT + E", "quick settings", "$hyprLua quick-settings")
  bind_exec(mod .. " + S", "web search", "$hyprLua web-search")
  bind_exec(
    mod .. " + CTRL + S",
    "window switcher",
    "$vicinae 'vicinae://launch/wm/switch-windows?toggle=true'"
  )
  bind_exec(
    mod .. " + F",
    "file search",
    "$vicinae 'vicinae://launch/files/search?toggle=true'"
  )
  bind_exec(
    mod .. " + period",
    "emoji picker",
    "$vicinae 'vicinae://launch/core/search-emojis?toggle=true'"
  )
  bind_exec(mod .. " + ALT + O", "toggle blur", "$hyprLua change-blur")
  bind_exec(mod .. " + SHIFT + G", "toggle game mode", "$hyprLua game-mode")
  bind_exec(mod .. " + ALT + L", "toggle layout", "$hyprLua change-layout")
  bind_exec(
    mod .. " + ALT + V",
    "clipboard history",
    "$vicinae 'vicinae://launch/clipboard/history?toggle=true'"
  )
  bind_exec(mod .. " + N", "open obsidian", "obsidian")
  bind(
    mod .. " + CTRL + O",
    raw_dispatch("setprop", "active opaque toggle"),
    "toggle active window opacity"
  )
  bind_exec(mod .. " + SHIFT + slash", "search keybinds", "$hyprLua keybinds")
  bind_exec(
    mod .. " + SHIFT + A",
    "profile selector",
    "$hyprLua profile-selector"
  )
  bind_exec(
    mod .. " + SHIFT + O",
    "change oh-my-zsh theme",
    "$hyprLua zsh-theme"
  )
end

---@return nil
local function windows()
  bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen(), "fullscreen")
  bind(mod .. " + CTRL + F", raw_dispatch("fullscreen", "1"), "maximize window")
  bind(
    mod .. " + SPACE",
    hl.dsp.window.float({ action = "toggle" }),
    "toggle floating"
  )
  bind(
    mod .. " + ALT + SPACE",
    raw_dispatch("workspaceopt", "allfloat"),
    "float all windows"
  )
  bind("CTRL + ALT + Delete", hl.dsp.exit(), "exit hyprland")
  bind(mod .. " + Q", hl.dsp.window.close(), "close window")
  bind_exec(mod .. " + SHIFT + Q", "kill process", "$hyprLua kill-active")
  bind_exec(
    "CTRL + ALT + L",
    "session menu",
    "noctalia msg panel-toggle session"
  )

  bind("ALT + tab", hl.dsp.window.cycle_next(), "cycle next window")
  bind("ALT + tab", hl.dsp.window.bring_to_top(), "bring active to top")
  bind(mod .. " + left", hl.dsp.focus({ direction = "left" }), "focus left")
  bind(mod .. " + right", hl.dsp.focus({ direction = "right" }), "focus right")
  bind(mod .. " + up", hl.dsp.focus({ direction = "up" }), "focus up")
  bind(mod .. " + down", hl.dsp.focus({ direction = "down" }), "focus down")
  bind(
    mod .. " + SHIFT + left",
    hl.dsp.window.resize({ x = -50, y = 0, relative = true }),
    "resize left",
    { repeating = true }
  )
  bind(
    mod .. " + SHIFT + right",
    hl.dsp.window.resize({ x = 50, y = 0, relative = true }),
    "resize right",
    { repeating = true }
  )
  bind(
    mod .. " + SHIFT + up",
    hl.dsp.window.resize({ x = 0, y = -50, relative = true }),
    "resize up",
    { repeating = true }
  )
  bind(
    mod .. " + SHIFT + down",
    hl.dsp.window.resize({ x = 0, y = 50, relative = true }),
    "resize down",
    { repeating = true }
  )
  bind(
    mod .. " + CTRL + left",
    hl.dsp.window.move({ direction = "left" }),
    "move left"
  )
  bind(
    mod .. " + CTRL + right",
    hl.dsp.window.move({ direction = "right" }),
    "move right"
  )
  bind(
    mod .. " + CTRL + up",
    hl.dsp.window.move({ direction = "up" }),
    "move up"
  )
  bind(
    mod .. " + CTRL + down",
    hl.dsp.window.move({ direction = "down" }),
    "move down"
  )
  bind(
    mod .. " + ALT + left",
    hl.dsp.window.swap({ direction = "left" }),
    "swap left"
  )
  bind(
    mod .. " + ALT + right",
    hl.dsp.window.swap({ direction = "right" }),
    "swap right"
  )
  bind(
    mod .. " + ALT + up",
    hl.dsp.window.swap({ direction = "up" }),
    "swap up"
  )
  bind(
    mod .. " + ALT + down",
    hl.dsp.window.swap({ direction = "down" }),
    "swap down"
  )

  bind(mod .. " + G", hl.dsp.group.toggle(), "toggle group")
  bind(mod .. " + Tab", raw_dispatch("changegroupactive", "f"), "next in group")
  bind(
    mod .. " + CTRL + tab",
    raw_dispatch("changegroupactive"),
    "change group active"
  )
  bind(
    mod .. " + SHIFT + Tab",
    raw_dispatch("changegroupactive", "b"),
    "prev in group"
  )
  bind(
    mod .. " + CTRL + K",
    hl.dsp.group.move_window("l"),
    "move into group left"
  )
  bind(
    mod .. " + CTRL + L",
    hl.dsp.group.move_window("r"),
    "move into group right"
  )
  bind(
    mod .. " + CTRL + H",
    raw_dispatch("moveoutofgroup"),
    "move out of group"
  )
end

---@return nil
local function layouts()
  bind(
    mod .. " + H",
    layout_bind({ scrolling = hl.dsp.layout("focus l") }),
    "focus scrolling column left"
  )
  bind(
    mod .. " + L",
    layout_bind({ scrolling = hl.dsp.layout("focus r") }),
    "focus scrolling column right"
  )
  bind(
    mod .. " + SHIFT + H",
    layout_bind({ scrolling = hl.dsp.layout("swapcol l") }),
    "swap scrolling column left"
  )
  bind(
    mod .. " + SHIFT + L",
    layout_bind({ scrolling = hl.dsp.layout("swapcol r") }),
    "swap scrolling column right"
  )
  bind(
    mod .. " + ALT + J",
    layout_bind({ scrolling = hl.dsp.layout("focus d") }),
    "focus next window in scrolling column"
  )
  bind(
    mod .. " + ALT + K",
    layout_bind({ scrolling = hl.dsp.layout("focus u") }),
    "focus previous window in scrolling column"
  )
  bind(
    mod .. " + O",
    layout_bind({ dwindle = hl.dsp.layout("togglesplit") }),
    "toggle split in dwindle layout"
  )

  bind(
    mod .. " + CTRL + D",
    layout_bind({ master = hl.dsp.layout("removemaster") }),
    "remove master in master layout"
  )
  bind(
    mod .. " + I",
    layout_bind({ master = hl.dsp.layout("addmaster") }),
    "add master in master layout"
  )
  bind(
    mod .. " + CTRL + Return",
    layout_bind({ master = hl.dsp.layout("swapwithmaster") }),
    "swap with master in master layout"
  )

  bind(
    mod .. " + SHIFT + I",
    layout_bind({ dwindle = hl.dsp.layout("togglesplit") }),
    "toggle split in dwindle layout"
  )
  bind(
    mod .. " + P",
    layout_bind({ dwindle = hl.dsp.window.pseudo() }),
    "toggle pseudo in dwindle layout"
  )
  bind(
    mod .. " + M",
    layout_bind({ dwindle = raw_dispatch("splitratio", "0.3") }),
    "set split ratio in dwindle layout"
  )

  bind(
    mod .. " + ALT + period",
    layout_bind({ scrolling = hl.dsp.layout("colresize +0.1") }),
    "resize scrolling column wider"
  )
  bind(
    mod .. " + ALT + comma",
    layout_bind({ scrolling = hl.dsp.layout("colresize -0.1") }),
    "resize scrolling column narrower"
  )
  bind(
    mod .. " + CTRL + period",
    layout_bind({ scrolling = hl.dsp.layout("promote") }),
    "promote window to scrolling column"
  )
  bind(
    mod .. " + ALT + F",
    layout_bind({ scrolling = hl.dsp.layout("fit visible") }),
    "fit visible scrolling columns"
  )
end

---@return nil
local function workspaces()
  bind(mod .. " + J", workspace_step(1), "next workspace")
  bind(mod .. " + K", workspace_step(-1), "previous workspace")
  bind(
    mod .. " + SHIFT + J",
    workspace_step(1, true),
    "move window to next workspace"
  )
  bind(
    mod .. " + SHIFT + K",
    workspace_step(-1, true),
    "move window to previous workspace"
  )

  for i = 1, 10 do
    local keycode = 9 + i
    bind(
      mod .. " + code:" .. keycode,
      hl.dsp.focus({ workspace = i }),
      "workspace " .. i
    )
    bind(
      mod .. " + SHIFT + code:" .. keycode,
      hl.dsp.window.move({ workspace = i }),
      "move to workspace " .. i
    )
    bind(
      mod .. " + CTRL + code:" .. keycode,
      raw_dispatch("movetoworkspacesilent", tostring(i)),
      "move silently to workspace " .. i
    )
  end

  bind(
    mod .. " + CTRL + F9",
    raw_dispatch("movecurrentworkspacetomonitor", "l"),
    "workspace to left monitor"
  )
  bind(
    mod .. " + CTRL + F10",
    raw_dispatch("movecurrentworkspacetomonitor", "r"),
    "workspace to right monitor"
  )
  bind(
    mod .. " + CTRL + F11",
    raw_dispatch("movecurrentworkspacetomonitor", "u"),
    "workspace to upper monitor"
  )
  bind(
    mod .. " + CTRL + F12",
    raw_dispatch("movecurrentworkspacetomonitor", "d"),
    "workspace to lower monitor"
  )
  bind(mod .. " + mouse_down", workspace_step(1), "next workspace")
  bind(mod .. " + mouse_up", workspace_step(-1), "previous workspace")

  bind(
    mod .. " + SHIFT + U",
    hl.dsp.window.move({ workspace = "special" }),
    "move to special"
  )
  bind(mod .. " + U", hl.dsp.workspace.toggle_special(), "toggle special")
end

---@return nil
local function devices()
  bind(
    mod .. " + mouse:272",
    hl.dsp.window.drag(),
    "move window",
    { mouse = true }
  )
  bind(
    mod .. " + mouse:273",
    hl.dsp.window.resize(),
    "resize window",
    { mouse = true }
  )
  bind_exec(mod .. " + ALT + mouse_down", "zoom in", zoom_in)
  bind_exec(mod .. " + ALT + mouse_up", "zoom out", zoom_out)

  bind_exec(
    "XF86AudioLowerVolume",
    "volume down",
    "noctalia msg volume-down",
    { locked = true, repeating = true }
  )
  bind_exec(
    "XF86AudioRaiseVolume",
    "volume up",
    "noctalia msg volume-up",
    { locked = true, repeating = true }
  )
  bind_exec(
    "XF86AudioMicMute",
    "toggle mic mute",
    "noctalia msg mic-mute",
    { locked = true }
  )
  bind_exec(
    "XF86AudioMute",
    "toggle mute",
    "noctalia msg volume-mute",
    { locked = true }
  )
  bind_exec("XF86Sleep", "sleep", "systemctl suspend", { locked = true })
  bind_exec(
    "XF86AudioPause",
    "pause",
    "noctalia msg media pause",
    { locked = true }
  )
  bind_exec(
    "XF86AudioPlay",
    "play",
    "noctalia msg media play",
    { locked = true }
  )
  bind_exec(
    "XF86AudioNext",
    "next track",
    "noctalia msg media next",
    { locked = true }
  )
  bind_exec(
    "XF86AudioPrev",
    "prev track",
    "noctalia msg media previous",
    { locked = true }
  )
  bind_exec(
    "XF86AudioStop",
    "stop",
    "noctalia msg media stop",
    { locked = true }
  )

  bind_exec(mod .. " + Print", "screenshot now", "$hyprLua screenshot --now")
  bind_exec(
    mod .. " + SHIFT + Print",
    "screenshot area",
    "$hyprLua screenshot --area"
  )
  bind_exec(
    mod .. " + CTRL + Print",
    "screenshot in 5s",
    "$hyprLua screenshot --in5"
  )
  bind_exec(
    mod .. " + CTRL + SHIFT + Print",
    "screenshot in 10s",
    "$hyprLua screenshot --in10"
  )
  bind_exec(
    "ALT + Print",
    "screenshot active window",
    "$hyprLua screenshot --active"
  )
  bind_exec(
    mod .. " + SHIFT + S",
    "screenshot (swappy)",
    "$hyprLua screenshot --swappy"
  )
  bind_exec(
    "XF86MonBrightnessUp",
    "brightness up",
    "noctalia msg brightness-up",
    { locked = true, repeating = true }
  )
  bind_exec(
    "XF86MonBrightnessDown",
    "brightness down",
    "noctalia msg brightness-down",
    { locked = true, repeating = true }
  )
  bind_exec("XF86Launch1", nil, "rog-control-center")
  bind_exec("XF86Launch3", nil, "asusctl led-mode -n")
  bind_exec("XF86Launch4", nil, "asusctl profile -n")
  bind_exec("XF86TouchpadToggle", nil, "$hyprLua touchpad")
  bind_exec(mod .. " + F6", nil, "$hyprLua screenshot --now")
  bind_exec(mod .. " + SHIFT + F6", nil, "$hyprLua screenshot --area")
  bind_exec(mod .. " + CTRL + F6", nil, "$hyprLua screenshot --in5")
  bind_exec(mod .. " + ALT + F6", nil, "$hyprLua screenshot --in10")
  bind_exec("ALT + F6", nil, "$hyprLua screenshot --active")
end

---@return nil
function M.setup()
  applications()
  windows()
  layouts()
  workspaces()
  devices()
end

return M
