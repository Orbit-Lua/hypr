local effects = require("hyprconf.commands.effects")
local process = require("hyprconf.runtime.process")

---@class Hyprconf.Commands.Services
local M = {}

---@return nil
function M.portal_hyprland()
  for _, unit in ipairs({
    "xdg-desktop-portal-hyprland.service",
    "xdg-desktop-portal.service",
  }) do
    process.check(
      process.run({ "systemctl", "--user", "restart", unit }, { timeout = 30 }),
      "restart " .. unit
    )
    process.check(
      process.run({ "systemctl", "--user", "is-active", "--quiet", unit }),
      "portal readiness"
    )
  end
end

-- Reapplies runtime effects that a config reload resets.
---@return nil
function M.refresh()
  effects.rainbow_border()
  require("hyprconf.commands.layout").reapply_game_mode()
end

return M
