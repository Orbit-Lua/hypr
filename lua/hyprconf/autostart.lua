local ctx = require("hyprconf.context")
local toml = require("hyprconf.util.toml")

---@class Hyprconf.AutostartCommand
---@field run string Command to run when Hyprland starts.
---@field enabled? boolean False disables the command.

---@class Hyprconf.AutostartConfig
---@field command? Hyprconf.AutostartCommand[]

---@class Hyprconf.Autostart
---@field setup fun()
local M = {}

---@type string
local autostart_config = ctx.config_dir .. "/lua/config/autostart.toml"

---@param command string
---@return string
local function expand(command)
  return command:gsub("%$configDir", ctx.config_dir)
end

---@return string[]
local function autostart_commands()
  local result = {}
  local ok, data = pcall(toml.read, autostart_config)
  if ok then
    ---@cast data Hyprconf.AutostartConfig
    for _, item in ipairs(data.command or {}) do
      if item.enabled ~= false and item.run then
        result[#result + 1] = expand(item.run)
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
