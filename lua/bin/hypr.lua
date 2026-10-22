#!/usr/bin/env lua

-- Helper CLI behind the binds and menus: hypr.lua <command> [args...]

---@type string
local config_dir = debug
  .getinfo(1, "S").source
  :sub(2)
  :match("^(.-)/?lua/bin/[^/]+$") or "."
if config_dir == "" then
  config_dir = "."
end

package.path = table.concat({
  config_dir .. "/lua/?.lua",
  config_dir .. "/lua/?/init.lua",
  config_dir .. "/?.lua",
  package.path,
}, ";")

local capture = require("hyprconf.commands.capture")
local effects = require("hyprconf.commands.effects")
local layout = require("hyprconf.commands.layout")
local menus = require("hyprconf.commands.menus")
local profiles = require("hyprconf.commands.profiles")
local services = require("hyprconf.commands.services")
local session = require("hyprconf.commands.session")

---@type table<string, fun(...: string)>
local commands = {
  ["change-blur"] = layout.change_blur,
  ["change-layout"] = layout.change_layout,
  ["game-mode"] = layout.game_mode,
  ["key-hints"] = menus.key_hints,
  ["keybinds"] = menus.keybinds,
  ["kill-active"] = session.kill_active,
  ["overview"] = session.overview,
  ["portal-hyprland"] = services.portal_hyprland,
  ["profile-selector"] = profiles.profile_selector,
  ["quick-settings"] = menus.quick_settings,
  ["rainbow-border"] = effects.rainbow_border,
  ["rainbow-menu"] = effects.rainbow_menu,
  ["refresh"] = services.refresh,
  ["screenshot"] = capture.screenshot,
  ["sound"] = capture.sound,
  ["touchpad"] = session.touchpad,
  ["web-search"] = menus.web_search,
}

local command = commands[arg[1] or ""]
if not command then
  local names = {}
  for name in pairs(commands) do
    names[#names + 1] = name
  end
  table.sort(names)
  io.stderr:write("usage: hypr.lua <" .. table.concat(names, "|") .. ">\n")
  os.exit(1)
end

command(table.unpack(arg, 2))
