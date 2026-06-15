local profile = require("hyprconf.profile")

---@class Hyprconf.Monitors
---@field setup fun()
local M = {}

---@return nil
function M.setup()
  profile.load("monitor")
end

return M
