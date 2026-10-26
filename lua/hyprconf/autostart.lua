local ctx = require("hyprconf.context")
local declarations = require("hyprconf.config")
local util = require("hyprconf.binding")

---@class Hyprconf.AutostartCommand
---@field run string Command to run when Hyprland starts.
---@field enabled? boolean False disables the command.

---@class Hyprconf.AutostartConfig
---@field command? Hyprconf.AutostartCommand[]

---@class Hyprconf.Autostart
---@field setup fun()
local M = {}
---@type HL.EventSubscription[]
local subscriptions = {}
---@type HL.Timer?
local reload_timer
local generation = 0

---@return string[]
local function autostart_commands()
  local result = {}
  local ok, data = pcall(declarations.read, "autostart")
  if ok then
    ---@cast data Hyprconf.AutostartConfig
    for _, item in ipairs(data.command or {}) do
      if item.enabled ~= false and item.run then
        result[#result + 1] = util.expand(item.run)
      end
    end
  else
    print("[WARN] Invalid autostart declaration: " .. tostring(data))
  end

  return result
end

---@return nil
function M.setup()
  generation = generation + 1
  local active_generation = generation
  for _, subscription in ipairs(subscriptions) do
    subscription:remove()
  end
  subscriptions = {}
  if reload_timer then
    reload_timer:set_enabled(false)
  end
  reload_timer = nil
  local pending = false
  local function reload()
    if generation ~= active_generation or not pending then
      return
    end
    pending = false
    assert(reload_timer):set_enabled(false)
    hl.exec_cmd("hyprctl reload", {})
  end
  subscriptions[#subscriptions + 1] = hl.on("hyprland.start", function()
    for _, command in ipairs(autostart_commands()) do
      hl.exec_cmd(command, {})
    end
  end)

  subscriptions[#subscriptions + 1] = hl.on("config.reloaded", function()
    hl.exec_cmd(ctx.hypr_lua .. " refresh", {})
  end)

  local function hotplug()
    if generation ~= active_generation then
      return
    end
    pending = true
    if not reload_timer then
      reload_timer = hl.timer(reload, { type = "oneshot", timeout = 200 })
    end
    assert(reload_timer):set_timeout(200)
    assert(reload_timer):set_enabled(true)
  end
  subscriptions[#subscriptions + 1] = hl.on("monitor.added", hotplug)
  subscriptions[#subscriptions + 1] = hl.on("monitor.removed", hotplug)
end

return M
