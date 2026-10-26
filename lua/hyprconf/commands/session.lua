local ctx = require("hyprconf.context")
local fs = require("hyprconf.util.fs")
local hyprctl = require("hyprconf.runtime.hyprctl")
local notify = require("hyprconf.runtime.notify")
local process = require("hyprconf.runtime.process")

---@class Hyprconf.Commands.Session
local M = {}

---@return nil
function M.overview()
  process.check(
    process.run({
      "qs",
      "ipc",
      "--newest",
      "--any-display",
      "-c",
      "overview",
      "call",
      "overview",
      "toggle",
    }),
    "Quickshell overview"
  )
end

---@return nil
function M.kill_active()
  ---@type Hyprconf.HyprWindow
  local active = hyprctl.active_window()
  local pid = tonumber(active.pid)
  -- `kill 0` and `kill -1` would signal the process group or every process.
  if not pid or pid <= 1 or pid % 1 ~= 0 then
    notify.error(
      "Kill Active Window",
      "No active window PID found.",
      "kill-active-window"
    )
    os.exit(1)
  end
  process.check(
    process.run({ "kill", "--", tostring(pid) }),
    "kill active window"
  )
end

---@return nil
function M.touchpad()
  local native = hyprctl.device_enabled(ctx.touchpad_device)
  local receipt = fs.read(ctx.touchpad_state)
  assert(
    receipt == nil or receipt == "true" or receipt == "false",
    "invalid touchpad state"
  )
  local previous = native
  if previous == nil then
    previous = receipt ~= "false"
  end
  local enabled = not previous
  hyprctl.set_device(ctx.touchpad_device, enabled)
  local saved, err =
    pcall(fs.atomic_write, ctx.touchpad_state, tostring(enabled))
  if not saved then
    local restored, restore_error =
      pcall(hyprctl.set_device, ctx.touchpad_device, previous)
    error(
      tostring(err)
        .. (
          restored and "; previous device state restored"
          or ("; device recovery failed: " .. tostring(restore_error))
        ),
      0
    )
  end
  notify.info("Touchpad", enabled and "Enabled" or "Disabled", "touchpad")
end

return M
