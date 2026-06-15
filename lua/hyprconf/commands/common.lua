local cli = require("hyprconf.cli")

---@class Hyprconf.Commands.Common
---@field bin_path string
---@field config fun(name: string): string
---@field split_lines fun(value?: string): string[]
---@field basename fun(path: string): string
---@field without_suffix fun(value: string, suffix: string): string
---@field lua_cmd fun(args: string): string
local M = {}

M.bin_path = cli.config_dir .. "/lua/bin/hypr.lua"

---@param name string
---@return string
function M.config(name)
  return cli.config_dir .. "/lua/config/" .. name .. ".toml"
end

---@param value? string
---@return string[]
function M.split_lines(value)
  local lines = {}
  for line in ((value or "") .. "\n"):gmatch("([^\n]*)\n") do
    if line ~= "" then
      lines[#lines + 1] = line
    end
  end
  return lines
end

---@param path string
---@return string
function M.basename(path)
  return (path:gsub("/+$", ""):match("([^/]+)$") or path)
end

---@param value string
---@param suffix string
---@return string
function M.without_suffix(value, suffix)
  if value:sub(-#suffix) == suffix then
    return value:sub(1, -#suffix - 1)
  end
  return value
end

---@param args string
---@return string
function M.lua_cmd(args)
  return "lua " .. cli.shell_quote(M.bin_path) .. " " .. args
end

return M
