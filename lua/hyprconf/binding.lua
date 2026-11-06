-- Build compositor bindings and expand trusted application commands.
local ctx = require("hyprconf.context")
local shell = require("hyprconf.util.shell")

-- Helpers for building the configuration inside Hyprland, where `hl` exists.

---@alias Hyprconf.KeyChord string

---@class Hyprconf.BindOptions: HL.BindOptions
---@field mouse? boolean Not an HL.BindOptions field: `hyprctl binds` lists these binds with mouse false.

---@class Hyprconf.Binding
local M = {}

---@type table<string, string>
local placeholders = {
  hyprLua = ctx.hypr_lua,
  vicinae = ctx.vicinae,
  term = ctx.term,
  files = ctx.files,
}

-- Replaces `$name` placeholders with context values; unknown names stay.
---@param command string
---@return string
function M.expand(command)
  return (
    command:gsub("%$([%w_]+)", function(name)
      return placeholders[name] or ("$" .. name)
    end)
  )
end

---@param command string
---@return HL.Dispatcher
function M.exec(command)
  return hl.dsp.exec_raw(M.expand(command))
end

---@param command string
---@return fun()
function M.dispatch_exec(command)
  return function()
    hl.dispatch(M.exec(command))
  end
end

---@param keys Hyprconf.KeyChord
---@param dispatcher HL.Dispatcher|function
---@param description? string
---@param opts? Hyprconf.BindOptions
---@return any
function M.bind(keys, dispatcher, description, opts)
  opts = opts or {}
  if description then
    opts.description = description
  end
  return hl.bind(keys, dispatcher, opts)
end

---@param keys Hyprconf.KeyChord
---@param description string?
---@param command string
---@param opts? Hyprconf.BindOptions
---@return any
function M.bind_exec(keys, description, command, opts)
  return M.bind(keys, M.exec(command), description, opts)
end

---@param name string
---@param arg? string
---@return HL.Dispatcher
function M.raw_dispatch(name, arg)
  local command = "hyprctl dispatch " .. name
  if arg and arg ~= "" then
    command = command .. " " .. arg
  end
  return M.exec(command)
end

-- Preserve scaling in the checked helper; Lua configurations reject keyword writes.
---@param operator "*"|"/"
---@param factor string Multiplier as written in the command, such as "2.0".
---@return string
function M.zoom_command(operator, factor)
  return ctx.hypr_lua .. " zoom " .. shell.quote(operator) .. " " .. shell.quote(factor)
end

return M
