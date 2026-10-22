local json = require("hyprconf.util.json")
local shell = require("hyprconf.util.shell")

---@class Hyprconf.HyprOption
---@field int? integer
---@field str? string
---@field float? number
---@field set? boolean

---@class Hyprconf.HyprWindow
---@field pid? integer|string
---@field at? integer[]
---@field size? integer[]
---@field class? string

-- Talks to the running compositor from outside the configuration.
---@class Hyprconf.Runtime.Hyprctl
local M = {}

---@param code string Lua evaluated inside Hyprland.
---@return Hyprconf.CommandStatus
function M.eval(code)
  return os.execute("hyprctl eval " .. shell.quote(code) .. " >/dev/null 2>&1")
end

---@param code string Lua table literal passed to `hl.config`.
---@return Hyprconf.CommandStatus
function M.config(code)
  return M.eval("hl.config(" .. code .. ")")
end

---@param command string Arguments after `hyprctl -j`.
---@return Hyprconf.JsonValue?
function M.json(command)
  local ok, value = pcall(json.decode, shell.capture("hyprctl -j " .. command))
  if ok then
    return value
  end
end

---@param option string
---@return Hyprconf.HyprOption
function M.option(option)
  return M.json("getoption " .. shell.quote(option)) or {}
end

---@return nil
function M.reload()
  os.execute("hyprctl reload >/dev/null 2>&1 || true")
end

return M
