---@class Hyprconf.Module
---@field setup fun()

---@class Hyprconf
---@field setup fun()
local M = {}

---@type string[]
local modules = {
  "hyprconf.env",
  "hyprconf.deps",
  "hyprconf.monitors",
  "hyprconf.autostart",
  "hyprconf.options",
  "hyprconf.gestures",
  "hyprconf.animations",
  "hyprconf.binds",
  "hyprconf.rules",
}

---@return nil
function M.setup()
  for _, name in ipairs(modules) do
    require(name).setup()
  end
end

return M
