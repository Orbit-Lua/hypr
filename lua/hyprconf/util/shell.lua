---@alias Hyprconf.CommandStatus boolean|integer|nil

---@class Hyprconf.Util.Shell
local M = {}

---@param value any
---@return string
function M.quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

---@param command string
---@return Hyprconf.CommandStatus
function M.exec_bg(command)
  return os.execute(command .. " >/dev/null 2>&1 &")
end

---@param command string
---@return string output Standard output without trailing whitespace.
function M.capture(command)
  local process = require("hyprconf.runtime.process")
  local output = process.check(process.shell(command), "command").stdout
  return (output:gsub("%s+$", ""))
end

---@param command string
---@return boolean
function M.command_exists(command)
  return os.execute("command -v " .. M.quote(command) .. " >/dev/null 2>&1")
    == true
end

return M
