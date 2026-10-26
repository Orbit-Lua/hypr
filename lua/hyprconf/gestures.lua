local util = require("hyprconf.binding")

---@class Hyprconf.Gestures
---@field setup fun()
local M = {}

local zoom_in = util.zoom_command("*", "1.5")
local zoom_out = util.zoom_command("/", "1.5")

---@return nil
function M.setup()
  hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })
  hl.gesture({ fingers = 3, direction = "horizontal", action = "scroll_move" })
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
end

return M
