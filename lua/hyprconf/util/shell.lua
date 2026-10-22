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
function M.exec(command)
  return os.execute(command)
end

---@param command string
---@return Hyprconf.CommandStatus
function M.exec_bg(command)
  return os.execute(command .. " >/dev/null 2>&1 &")
end

---@param command string
---@return string output Standard output without trailing whitespace.
function M.capture(command)
  local handle = io.popen(command .. " 2>/dev/null")
  if not handle then
    return ""
  end
  local output = handle:read("*a") or ""
  handle:close()
  return (output:gsub("%s+$", ""))
end

---@param command string
---@return string[]
function M.capture_lines(command)
  local lines = {}
  for line in M.capture(command):gmatch("[^\n]+") do
    lines[#lines + 1] = line
  end
  return lines
end

---@param command string
---@return boolean
function M.command_exists(command)
  return os.execute("command -v " .. M.quote(command) .. " >/dev/null 2>&1")
    == true
end

---@param ... string Exact process names.
---@return nil
function M.kill(...)
  for _, name in ipairs({ ... }) do
    os.execute("pkill -x " .. M.quote(name) .. " 2>/dev/null || true")
  end
end

return M
