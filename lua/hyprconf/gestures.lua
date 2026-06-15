local ctx = require("hyprconf.context")
local util = require("hyprconf.util")

---@class Hyprconf.Gestures
---@field setup fun()
local M = {}

-- luacheck: push ignore
local zoom_in =
  [[hyprctl keyword cursor:zoom_factor "$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor * 1.5}')"]]
local zoom_out =
  [[hyprctl keyword cursor:zoom_factor "$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor / 1.5}')"]]
-- luacheck: pop

---@return nil
function M.setup()
  hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
  hl.gesture({
    fingers = 4,
    direction = "up",
    action = util.dispatch_exec(zoom_in),
  })
  hl.gesture({
    fingers = 4,
    direction = "down",
    action = util.dispatch_exec(zoom_out),
  })
  hl.gesture({
    fingers = 3,
    direction = "up",
    action = util.dispatch_exec(ctx.hypr_lua .. " overview"),
  })
end

return M
