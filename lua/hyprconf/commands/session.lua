local cli = require("hyprconf.cli")

---@class Hyprconf.Commands.Session
---@field overview fun()
---@field kill_active fun()
---@field touchpad fun()
local M = {}

---@return nil
function M.overview()
  if cli.command_exists("qs") then
    cli.exec_bg("env -u GBM_BACKEND qs -c overview")
    if
      os.execute("qs ipc -c overview call overview toggle >/dev/null 2>&1")
    then
      os.exit(0)
    end
  end

  if cli.command_exists("ags") then
    if os.execute("ags -t overview >/dev/null 2>&1") then
      os.exit(0)
    end
    cli.exec_bg("ags")
    os.execute("sleep 0.6")
    if os.execute("ags -t overview >/dev/null 2>&1") then
      os.exit(0)
    end
  end

  cli.notify_error(
    "Overview",
    "Neither Quickshell nor AGS is available.",
    "overview"
  )
  os.exit(1)
end

---@return nil
function M.kill_active()
  ---@type Hyprconf.HyprWindow
  local active = cli.hypr_json("activewindow") or {}
  local pid = tonumber(active.pid)
  if not pid then
    cli.notify_error(
      "Kill Active Window",
      "No active window PID found.",
      "kill-active-window"
    )
    os.exit(1)
  end
  cli.exec("kill " .. tostring(pid))
end

---@return nil
function M.touchpad()
  local ctx = require("hyprconf.context")
  local device = os.getenv("TOUCHPAD_DEVICE") or ctx.touchpad_device
  if not device or device == "" then
    cli.notify_error(
      "Touchpad",
      "Device name not set. Check lua/hyprconf/context.lua.",
      "touchpad"
    )
    os.exit(1)
  end

  local status_file = (os.getenv("XDG_RUNTIME_DIR") or "/tmp")
    .. "/touchpad.status"
  local current = cli.read_file(status_file)
  local enabled = not (current and current:match("^true"))

  cli.write_file(status_file, enabled and "true" or "false")
  cli.hypr_eval(
    "hl.device({ name = "
      .. cli.lua_string(device)
      .. ", enabled = "
      .. tostring(enabled)
      .. " })"
  )
  if enabled then
    cli.notify_success("Touchpad", "Enabled", "touchpad")
  else
    cli.notify_info("Touchpad", "Disabled", "touchpad")
  end
end

return M
