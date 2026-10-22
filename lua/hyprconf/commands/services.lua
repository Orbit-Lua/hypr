local effects = require("hyprconf.commands.effects")
local fs = require("hyprconf.util.fs")
local shell = require("hyprconf.util.shell")

---@class Hyprconf.Commands.Services
local M = {}

---@param paths string[]
---@return nil
local function start_first(paths)
  for _, path in ipairs(paths) do
    if fs.exists(path) then
      shell.exec_bg(shell.quote(path))
      return
    end
  end
end

---@return nil
function M.portal_hyprland()
  os.execute("sleep 1")
  shell.kill(
    "xdg-desktop-portal-hyprland",
    "xdg-desktop-portal-wlr",
    "xdg-desktop-portal-gnome",
    "xdg-desktop-portal"
  )
  os.execute("sleep 1")
  start_first({
    "/usr/lib/xdg-desktop-portal-hyprland",
    "/usr/libexec/xdg-desktop-portal-hyprland",
  })
  os.execute("sleep 2")
  start_first({
    "/usr/lib/xdg-desktop-portal",
    "/usr/libexec/xdg-desktop-portal",
  })
end

-- Reapplies runtime effects that a config reload resets.
---@return nil
function M.refresh()
  effects.rainbow_border()
end

return M
