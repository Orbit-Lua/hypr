local ctx = require("hyprconf.context")

---@alias Hyprconf.Dispatcher string
---@alias Hyprconf.KeyChord string

---@class Hyprconf.BindOptions
---@field description? string
---@field locked? boolean
---@field mouse? boolean
---@field repeating? boolean

---@class Hyprconf.Util
---@field trim fun(value: string): string
---@field split_csv fun(value: string): string[]
---@field file_exists fun(path: string): boolean
---@field expand fun(command: string): string
---@field exec fun(command: string): Hyprconf.Dispatcher
---@field dispatch_exec fun(command: string): fun()
---@field bind fun(keys: Hyprconf.KeyChord, dispatcher: any, description?: string, opts?: Hyprconf.BindOptions): any
---@field bind_exec fun(keys: string, description: string?, command: string, opts?: Hyprconf.BindOptions): any
---@field raw_dispatch fun(name: string, arg?: string): Hyprconf.Dispatcher
local M = {}

---@param value string
---@return string
function M.trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

---@param value string
---@return string[]
function M.split_csv(value)
  local fields = {}
  for field in value:gmatch("([^,]+)") do
    fields[#fields + 1] = M.trim(field)
  end
  return fields
end

---@param path string
---@return boolean
function M.file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

---@param command string
---@return string
function M.expand(command)
  local replacements = {
    HOME = ctx.home,
    configDir = ctx.config_dir,
    hyprLua = ctx.hypr_lua,
    vicinae = ctx.vicinae,
    term = ctx.term,
    files = ctx.files,
    Search_Engine = ctx.search_engine,
  }

  return (
    command:gsub("%$([%w_]+)", function(name)
      return replacements[name] or ("$" .. name)
    end)
  )
end

---@param command string
---@return Hyprconf.Dispatcher
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
---@param dispatcher Hyprconf.Dispatcher|function
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
---@return Hyprconf.Dispatcher
function M.raw_dispatch(name, arg)
  local command = "hyprctl dispatch " .. name
  if arg and arg ~= "" then
    command = command .. " " .. arg
  end
  return M.exec(command)
end

return M
