local shell = require("hyprconf.util.shell")

---@alias Hyprconf.NotifyUrgency "low"|"normal"|"critical"

---@class Hyprconf.NotifyOptions
---@field urgency? Hyprconf.NotifyUrgency Defaults to "low".
---@field tag? string Notifications sharing a tag replace each other.
---@field timeout? integer Milliseconds; defaults to 3000.
---@field actions? string[] `id=Label` pairs; makes the call wait for a choice.

---@class Hyprconf.Runtime.Notify
local M = {}

---@param title string
---@param body? string
---@param opts? Hyprconf.NotifyOptions
---@return string action Chosen action id, or "" without actions.
function M.send(title, body, opts)
  opts = opts or {}
  local args = {
    "notify-send",
    "-a Hyprland",
    "-u " .. shell.quote(opts.urgency or "low"),
    "-t " .. tostring(opts.timeout or 3000),
    "-h "
      .. shell.quote(
        "string:x-canonical-private-synchronous:" .. (opts.tag or "hypr-notify")
      ),
  }
  if opts.actions then
    args[#args + 1] = "-e"
    for _, action in ipairs(opts.actions) do
      args[#args + 1] = "-A " .. shell.quote(action)
    end
  end
  args[#args + 1] = shell.quote(title)
  args[#args + 1] = shell.quote(body or "")

  local command = table.concat(args, " ")
  if opts.actions then
    return shell.capture(command)
  end
  os.execute(command .. " >/dev/null 2>&1 || true")
  return ""
end

---@param title string
---@param body? string
---@param tag? string
---@return nil
function M.info(title, body, tag)
  M.send(title, body, { tag = tag or "hypr-info" })
end

---@param title string
---@param body? string
---@param tag? string
---@return nil
function M.warn(title, body, tag)
  M.send(title, body, { urgency = "normal", tag = tag or "hypr-warn" })
end

---@param title string
---@param body? string
---@param tag? string
---@return nil
function M.error(title, body, tag)
  M.send(title, body, { urgency = "critical", tag = tag or "hypr-error" })
end

---@param command string
---@param hint? string Notification body when the command is missing.
---@return boolean
function M.require_command(command, hint)
  if shell.command_exists(command) then
    return true
  end
  M.error("Missing Dependency", hint or ("Install " .. command .. " first."))
  return false
end

return M
