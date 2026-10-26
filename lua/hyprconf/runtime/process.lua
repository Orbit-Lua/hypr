local shell = require("hyprconf.util.shell")

---@class Hyprconf.ProcessOptions
---@field stdin? string
---@field timeout? number|false Seconds; false leaves interactive operations unbounded.

---@class Hyprconf.ProcessResult
---@field ok boolean
---@field code integer
---@field signal? integer
---@field timed_out boolean
---@field stdout string
---@field stderr string

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
---@param opts? Hyprconf.ProcessOptions
---@return Hyprconf.ProcessResult
function M.run(argv, opts)
  opts = opts or {}
  assert(#argv > 0, "an executable is required")
  local temporary = assert(io.popen("mktemp -d", "r"))
  local directory = assert(temporary:read("*l"))
  assert(temporary:close(), "could not create process temporary directory")
  local files = { directory .. "/in", directory .. "/out", directory .. "/err" }
  local ok, result = pcall(function()
    local input = assert(io.open(files[1], "wb"))
    assert(input:write(opts.stdin or ""))
    assert(input:close())
    local command = {}
    local timeout = opts.timeout == nil and 10 or opts.timeout
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
    local success, reason, status = os.execute(
      table.concat(command, " ")
        .. " < "
        .. shell.quote(files[1])
        .. " > "
        .. shell.quote(files[2])
        .. " 2> "
        .. shell.quote(files[3])
    )
    return {
      ok = success == true,
      code = status or (success and 0 or 1),
      signal = reason == "signal" and status or nil,
      timed_out = status == 124 or status == 137,
      stdout = read(files[2]),
      stderr = read(files[3]),
    }
  end)
  for _, path in ipairs(files) do
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
