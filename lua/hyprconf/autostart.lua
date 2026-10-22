local ctx = require("hyprconf.context")
local toml = require("hyprconf.util.toml")
local util = require("hyprconf.util")

---@class Hyprconf.AutostartCommand
---@field run string Command to run when Hyprland starts.
---@field enabled? boolean False disables the command.

---@class Hyprconf.AutostartConfig
---@field command? Hyprconf.AutostartCommand[]

---@class Hyprconf.Autostart
---@field setup fun()
local M = {}

---@return string[]
local function autostart_commands()
  local result = {}
  local ok, data = pcall(toml.read, ctx.config_file("autostart"))
  if ok then
    ---@cast data Hyprconf.AutostartConfig
    for _, item in ipairs(data.command or {}) do
      if item.enabled ~= false and item.run then
        result[#result + 1] = util.expand(item.run)
      end
    end
  end

  return result
end

---@return nil
function M.setup()
  hl.on("hyprland.start", function()
    for _, command in ipairs(autostart_commands()) do
      hl.exec_cmd(command, {})
    end
  end)

  hl.on("config.reloaded", function()
    hl.exec_cmd(ctx.hypr_lua .. " refresh", {})
  end)

  hl.on("monitor.added", function()
    hl.exec_cmd("hyprctl reload", {})
  end)
end

return M
