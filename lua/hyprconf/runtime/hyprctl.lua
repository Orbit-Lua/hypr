local json = require("hyprconf.util.json")
local process = require("hyprconf.runtime.process")

---@class Hyprconf.HyprOption
---@field int? integer
---@field str? string
---@field float? number
---@field set? boolean
---@field bool? boolean
---@field custom? string

---@class Hyprconf.HyprWindow
---@field pid? integer|string
---@field at? integer[]
---@field size? integer[]
---@field class? string

-- Talks to the running compositor from outside the configuration.
---@class Hyprconf.Runtime.Hyprctl
local M = {}

---@param value any
---@return string
local function literal(value)
  if type(value) == "string" then
    return string.format("%q", value)
  end
  if type(value) == "number" then
    assert(
      value == value and math.abs(value) ~= math.huge,
      "invalid config number"
    )
    return tostring(value)
  end
  if type(value) == "boolean" then
    return tostring(value)
  end
  assert(type(value) == "table", "invalid config value")
  local keys, parts = {}, {}
  for key in pairs(value) do
    keys[#keys + 1] = key
  end
  table.sort(keys, function(a, b)
    return tostring(a) < tostring(b)
  end)
  for _, key in ipairs(keys) do
    parts[#parts + 1] = "[" .. literal(key) .. "]=" .. literal(value[key])
  end
  return "{" .. table.concat(parts, ",") .. "}"
end

---@param code string Lua evaluated inside Hyprland.
---@return nil
function M.eval(code)
  local result =
    process.check(process.run({ "hyprctl", "eval", code }), "hyprctl eval")
  assert(
    result.stdout:match("^%s*ok%s*$"),
    "hyprctl eval failed: " .. result.stdout:gsub("%s+$", "")
  )
end

---@param options HL.ConfigOpt
---@return nil
function M.config(options)
  M.eval("hl.config(" .. literal(options) .. ")")
  M.check_errors()
end

---@param command string
---@param ... string
---@return any
function M.json(command, ...)
  local result = process.check(
    process.run({ "hyprctl", "-j", command, ... }),
    "hyprctl query"
  )
  local ok, value = pcall(json.decode, result.stdout)
  assert(ok, "hyprctl returned malformed JSON")
  return value
end

---@param option string
---@return Hyprconf.HyprOption
function M.option(option)
  local value = M.json("getoption", option)
  assert(
    type(value) == "table"
      and (
        type(value.int) == "number"
        or type(value.str) == "string"
        or type(value.float) == "number"
        or type(value.bool) == "boolean"
        or type(value.custom) == "string"
      ),
    "hyprctl returned an invalid option value"
  )
  return value
end

---@return Hyprconf.HyprWindow
function M.active_window()
  local value = M.json("activewindow")
  assert(
    type(value) == "table" and value ~= json.null,
    "hyprctl returned an invalid window"
  )
  for _, field in ipairs({ "at", "size" }) do
    if value[field] ~= nil then
      assert(
        type(value[field]) == "table" and #value[field] == 2,
        "hyprctl returned invalid window geometry"
      )
      for _, number in ipairs(value[field]) do
        assert(
          type(number) == "number" and number % 1 == 0,
          "hyprctl returned invalid window coordinates"
        )
      end
    end
  end
  assert(
    value.class == nil or type(value.class) == "string",
    "hyprctl returned an invalid window class"
  )
  return value
end

---@return nil
function M.check_errors()
  local errors = M.json("configerrors")
  assert(
    type(errors) == "table" and errors ~= json.null,
    "invalid Hyprland configuration diagnostics"
  )
  local messages = {}
  for index, message in pairs(errors) do
    assert(
      type(index) == "number"
        and index % 1 == 0
        and index >= 1
        and index <= #errors
        and type(message) == "string",
      "invalid Hyprland configuration diagnostics"
    )
    -- Hyprland can encode an empty diagnostic response as a blank line.
    if message:find("%S") then
      messages[#messages + 1] = message
    end
  end
  assert(
    #messages == 0,
    "Hyprland rejected the reloaded configuration: "
      .. table.concat(messages, "\n")
  )
end

---@return nil
function M.reload()
  process.check(process.run({ "hyprctl", "reload" }), "hyprctl reload")
  M.check_errors()
end

---@param name string
---@return boolean? Native state when this Hyprland version exposes it.
function M.device_enabled(name)
  local devices = M.json("devices")
  assert(
    type(devices) == "table" and type(devices.mice) == "table",
    "invalid Hyprland device reply"
  )
  for _, device in ipairs(devices.mice) do
    if device.name == name then
      if type(device.enabled) == "boolean" then
        return device.enabled
      end
      return nil
    end
  end
  error("declared touchpad is unavailable", 0)
end

---@param name string
---@param enabled boolean
function M.set_device(name, enabled)
  M.eval(
    string.format(
      "hl.device({ name = %q, enabled = %s })",
      name,
      tostring(enabled)
    )
  )
  M.check_errors()
end

---@param enabled boolean
function M.game_opacity(enabled)
  M.eval("require('hyprconf.rules').set_game_mode(" .. tostring(enabled) .. ")")
  M.check_errors()
end

return M
