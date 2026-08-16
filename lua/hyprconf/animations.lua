local profile = require("hyprconf.profile")

---@class Hyprconf.Animations
---@field setup fun()
local M = {}

local function apply_workspace_flow()
  hl.curve("workspaceFlow", {
    type = "bezier",
    points = { { 0.22, 1 }, { 0.36, 1 } },
  })

  for _, leaf in ipairs({ "workspaces", "workspacesIn", "workspacesOut" }) do
    hl.animation({
      leaf = leaf,
      enabled = true,
      speed = 3,
      bezier = "workspaceFlow",
      style = "slidevert",
    })
  end
end

---@return nil
function M.setup()
  profile.load("animation")
  apply_workspace_flow()
end

return M
