local ctx = require("hyprconf.context")
local util = require("hyprconf.util")

---@class Hyprconf.Colors
---@field get fun(name: string, fallback?: Hyprconf.RgbColor|string): Hyprconf.RgbColor|string|nil
local M = {}
---@type table<string, Hyprconf.RgbColor|string>
local values = {}

---@param path string
---@return nil
local function load(path)
  if not util.file_exists(path) then
    return
  end

  for line in io.lines(path) do
    local name, value = line:match("^%s*%$([%w_]+)%s*=%s*(rgb%([^%)]+%))")
    if name then
      values[name] = value
    end
  end
end

load(ctx.config_dir .. "/effects/colors-hyprland.conf")

---@param name string
---@param fallback? Hyprconf.RgbColor|string
---@return Hyprconf.RgbColor|string|nil
function M.get(name, fallback)
  return values[name] or fallback
end

return M
