#!/usr/bin/env lua

-- Helper CLI behind the binds and menus: hypr.lua <command> [args...]

-- Invoked as <root>/lua/bin/hypr.lua, or as lua/bin/hypr.lua from the root.
local script = debug.getinfo(1, "S").source:sub(2)
---@type string
local config_dir = script:match("^(.*)/lua/bin/[^/]+$") or "."

package.path = table.concat({
  config_dir .. "/lua/?.lua",
  config_dir .. "/lua/?/init.lua",
  config_dir .. "/?.lua",
  package.path,
}, ";")

---@type table<string, {owner: string, action: string, lock?: boolean}>
local commands = {
  ["change-blur"] = { owner = "layout", action = "change_blur", lock = true },
  ["change-layout"] = {
    owner = "layout",
    action = "change_layout",
    lock = true,
  },
  ["game-mode"] = { owner = "layout", action = "game_mode", lock = true },
  ["key-hints"] = { owner = "menus", action = "key_hints" },
  ["keybinds"] = { owner = "menus", action = "keybinds" },
  ["kill-active"] = { owner = "session", action = "kill_active" },
  ["overview"] = { owner = "session", action = "overview" },
  ["portal-hyprland"] = { owner = "services", action = "portal_hyprland" },
  ["profile-selector"] = {
    owner = "profiles",
    action = "profile_selector",
    lock = true,
  },
  ["quick-settings"] = { owner = "menus", action = "quick_settings" },
  ["rainbow-border"] = { owner = "effects", action = "rainbow_border" },
  ["rainbow-menu"] = { owner = "effects", action = "rainbow_menu", lock = true },
  ["refresh"] = { owner = "services", action = "refresh" },
  ["screenshot"] = { owner = "screenshot", action = "screenshot" },
  ["sound"] = { owner = "sound", action = "sound" },
  ["touchpad"] = { owner = "session", action = "touchpad", lock = true },
  ["web-search"] = { owner = "menus", action = "web_search" },
}
local locked = arg[1] == "--locked"
if locked then
  table.remove(arg, 1)
end
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
local ok, err = pcall(function()
  if command.lock and not locked then
    local ctx = require("hyprconf.context")
    require("hyprconf.util.fs").mkdir_p(ctx.state_dir)
    local invocation = {
      "flock",
      "--nonblock",
      "--close",
      "--conflict-exit-code",
      "75",
      ctx.state_dir .. "/.operation.lock",
      "lua",
      script,
      "--locked",
    }
    for _, value in ipairs(arg) do
      invocation[#invocation + 1] = value
    end
    local result =
      require("hyprconf.runtime.process").run(invocation, { timeout = false })
    if result.code == 75 then
      error("another Hyprland setting change is in progress", 0)
    end
    io.stdout:write(result.stdout)
    io.stderr:write(result.stderr)
    os.exit(result.code)
  end
  require("hyprconf.commands." .. command.owner)[command.action](
    table.unpack(arg, 2)
  )
end)
if not ok then
  io.stderr:write("hypr: " .. tostring(err) .. "\n")
  pcall(require("hyprconf.runtime.notify").error, "Hyprland", tostring(err))
  os.exit(1)
end
