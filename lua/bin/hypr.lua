#!/usr/bin/env lua

---@type string
local config_dir = (debug.getinfo(1, "S").source:sub(2):match("(.+)/../..$"))
  or ((os.getenv("HOME") or "") .. "/.config/hypr")

package.path = table.concat({
  config_dir .. "/lua/?.lua",
  config_dir .. "/lua/?/init.lua",
  package.path,
}, ";")

local capture = require("hyprconf.commands.capture")
local deps = require("hyprconf.deps")
local effects = require("hyprconf.commands.effects")
local layout = require("hyprconf.commands.layout")
local menus = require("hyprconf.commands.menus")
local profiles = require("hyprconf.commands.profiles")
local services = require("hyprconf.commands.services")
local session = require("hyprconf.commands.session")

---@alias Hyprconf.CommandName
---| "change-blur"
---| "change-layout"
---| "clip-manager"
---| "game-mode"
---| "key-hints"
---| "keybinds"
---| "keybinds-layout-init"
---| "kill-active"
---| "kitty-themes"
---| "overview"
---| "polkit"
---| "portal-hyprland"
---| "profile-selector"
---| "quick-settings"
---| "rainbow-border"
---| "rainbow-menu"
---| "refresh"
---| "rofi-search"
---| "rofi-theme"
---| "screenshot"
---| "sound"
---| "sync-deps"
---| "touchpad"
---| "zsh-theme"

---@type table<string, fun(...: string)>
local commands = {
  ["change-blur"] = layout.change_blur,
  ["change-layout"] = layout.change_layout,
  ["clip-manager"] = menus.clip_manager,
  ["game-mode"] = layout.game_mode,
  ["key-hints"] = menus.key_hints,
  ["keybinds"] = menus.keybinds,
  ["keybinds-layout-init"] = layout.keybinds_layout_init,
  ["kill-active"] = session.kill_active,
  ["kitty-themes"] = menus.kitty_themes,
  ["overview"] = session.overview,
  ["polkit"] = services.polkit,
  ["portal-hyprland"] = services.portal_hyprland,
  ["profile-selector"] = profiles.profile_selector,
  ["quick-settings"] = menus.quick_settings,
  ["rainbow-border"] = effects.rainbow_border,
  ["rainbow-menu"] = effects.rainbow_menu,
  ["refresh"] = services.refresh,
  ["rofi-search"] = menus.rofi_search,
  ["rofi-theme"] = menus.rofi_theme,
  ["screenshot"] = capture.screenshot,
  ["sound"] = capture.sound,
  ["sync-deps"] = function()
    for _, path in ipairs(deps.sync()) do
      print(path)
    end
  end,
  ["touchpad"] = session.touchpad,
  ["zsh-theme"] = menus.zsh_theme,
}

---@return Hyprconf.CommandName[]
local function command_names()
  local names = {}
  for name in pairs(commands) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

---@type Hyprconf.CommandName?
local command = arg[1]
if not command or not commands[command] then
  io.stderr:write(
    "usage: hypr.lua <" .. table.concat(command_names(), "|") .. ">\n"
  )
  os.exit(1)
end

---@type string[]
local command_args = {}
for index = 2, #arg do
  command_args[#command_args + 1] = arg[index]
end

if command ~= "sync-deps" then
  deps.sync()
end

commands[command](table.unpack(command_args))
