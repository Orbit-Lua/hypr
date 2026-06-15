local profile = require("hyprconf.profile")

---@class Hyprconf.Animations
---@field setup fun()
local M = {}

---@return nil
function M.setup()
  profile.load("animation")
end

return M
