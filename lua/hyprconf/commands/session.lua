local ctx = require("hyprconf.context")
local fs = require("hyprconf.util.fs")
local hyprctl = require("hyprconf.runtime.hyprctl")
local notify = require("hyprconf.runtime.notify")
local shell = require("hyprconf.util.shell")

---@class Hyprconf.Commands.Session
local M = {}

---@return nil
function M.overview()
  if
    shell.command_exists("qs")
    and os.execute(
      "qs ipc --newest --any-display -c overview call overview toggle >/dev/null 2>&1"
    )
  then
    os.exit(0)
  end

  notify.error(
    "Overview",
    "Quickshell overview is unavailable. Check quickshell-overview.service.",
    "overview"
  )
  os.exit(1)
end

---@return nil
function M.kill_active()
  ---@type Hyprconf.HyprWindow
  local active = hyprctl.json("activewindow") or {}
  local pid = tonumber(active.pid)
  -- `kill 0` and `kill -1` would signal the process group or every process.
  if not pid or pid <= 1 then
    notify.error(
      "Kill Active Window",
      "No active window PID found.",
      "kill-active-window"
    )
    os.exit(1)
  end
  os.execute("kill " .. tostring(pid))
end

---@return nil
function M.touchpad()
  -- A missing file means enabled, as at session start.
  local current = fs.read(ctx.touchpad_state)
  local enabled = current ~= nil and current:match("^false") ~= nil

  fs.write(ctx.touchpad_state, tostring(enabled))
  hyprctl.eval(
    string.format(
      "hl.device({ name = %q, enabled = %s })",
      ctx.touchpad_device,
      tostring(enabled)
    )
  )
  notify.info("Touchpad", enabled and "Enabled" or "Disabled", "touchpad")
end

return M
