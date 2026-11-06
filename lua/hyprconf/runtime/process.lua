-- Run checked native commands with bounded waits and captured failure streams.
local shell = require("hyprconf.util.shell")

---@class Hyprconf.ProcessOptions
---@field stdin? string
---@field timeout? number|false Seconds; false leaves interactive operations unbounded.

---@class Hyprconf.ProcessResult
---@field ok boolean
---@field code integer
---@field signal? integer Signal inferred from a POSIX 128+N exit status.
---@field timed_out boolean
---@field stdout string
---@field stderr string

---@class Hyprconf.Runtime.Process
local M = {}

---@param path string
---@return string
local function read(path)
  local file = assert(io.open(path, "rb"))
  local value = assert(file:read("*a"))
  assert(file:close())
  return value
end

---@param argv string[]
---@param timeout number|false
---@return string
local function process_command(argv, timeout)
  local command = {}
  if timeout ~= false then
    assert(type(timeout) == "number" and timeout > 0, "invalid timeout")
    command = { "timeout", "--kill-after=1", tostring(timeout) .. "s" }
  end
  for _, value in ipairs(argv) do
    assert(type(value) == "string", "process arguments must be strings")
    command[#command + 1] = value
  end
  for index, value in ipairs(command) do
    command[index] = shell.quote(value)
  end
  return table.concat(command, " ")
end

---@class Hyprconf.ProcessFiles
---@field stdin string
---@field stdout string
---@field stderr string
---@field status string

---@param files Hyprconf.ProcessFiles
---@param timeout number|false
---@return Hyprconf.ProcessResult
local function captured_result(files, timeout)
  local status = assert(tonumber(read(files.status)), "invalid native command status")
  assert(status >= 0 and status <= 255 and status % 1 == 0, "invalid native command status")
  return {
    ok = status == 0,
    code = status,
    signal = status > 128 and status <= 192 and status - 128 or nil,
    timed_out = timeout ~= false and (status == 124 or status == 137),
    stdout = read(files.stdout),
    stderr = read(files.stderr),
  }
end

---@param argv string[]
---@param opts Hyprconf.ProcessOptions
---@param files Hyprconf.ProcessFiles
---@return Hyprconf.ProcessResult
local function run_captured(argv, opts, files)
  local input = assert(io.open(files.stdin, "wb"))
  assert(input:write(opts.stdin or ""))
  assert(input:close())
  local timeout = opts.timeout
  if timeout == nil then
    timeout = 10
  end
  local command = process_command(argv, timeout)
  -- Lua can report errno instead of a nonzero child status. Keep the shell
  -- successful and record the native command status independently.
  local success, reason, shell_status = os.execute(
    command
      .. " < "
      .. shell.quote(files.stdin)
      .. " > "
      .. shell.quote(files.stdout)
      .. " 2> "
      .. shell.quote(files.stderr)
      .. "; status=$?; printf '%s' \"$status\" > "
      .. shell.quote(files.status)
  )
  assert(
    success,
    "native command shell failed: " .. tostring(reason) .. " " .. tostring(shell_status)
  )
  return captured_result(files, timeout)
end

---@param argv string[]
---@param opts? Hyprconf.ProcessOptions
---@return Hyprconf.ProcessResult
function M.run(argv, opts)
  opts = opts or {}
  assert(#argv > 0, "an executable is required")
  local temporary = assert(io.popen("mktemp -d", "r"))
  local directory = assert(temporary:read("*l"))
  assert(temporary:close(), "could not create process temporary directory")
  ---@type Hyprconf.ProcessFiles
  local files = {
    stdin = directory .. "/in",
    stdout = directory .. "/out",
    stderr = directory .. "/err",
    status = directory .. "/status",
  }
  local ok, result = pcall(run_captured, argv, opts, files)
  for _, path in pairs(files) do
    os.remove(path)
  end
  local removed, remove_error = os.remove(directory)
  if not ok then
    error(result, 0)
  end
  if not removed then
    error("process cleanup failed: " .. tostring(remove_error), 0)
  end
  return result
end

---@param result Hyprconf.ProcessResult
---@param operation string
---@return Hyprconf.ProcessResult
function M.check(result, operation)
  if not result.ok then
    local details = result.stderr:gsub("%s+$", "")
    error(
      string.format(
        "%s %s (exit %d)%s",
        operation,
        result.timed_out and "timed out" or "failed",
        result.code,
        details ~= "" and (": " .. details) or ""
      ),
      0
    )
  end
  return result
end

---@param command string Trusted configuration command; arguments must already be quoted.
---@param opts? Hyprconf.ProcessOptions
---@return Hyprconf.ProcessResult
function M.shell(command, opts)
  return M.run({ "sh", "-c", command }, opts)
end

return M
