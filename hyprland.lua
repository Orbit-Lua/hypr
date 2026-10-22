---@type string
local config_dir = (debug.getinfo(1, "S").source:sub(2):match("(.+)/[^/]+$"))
  or "."

package.path = table.concat({
  config_dir .. "/lua/?.lua",
  config_dir .. "/lua/?/init.lua",
  config_dir .. "/?.lua",
  package.path,
}, ";")

require("hyprconf").setup()

-- Noctalia's generated theme sets the border and group colors last.
require("noctalia").apply_theme()
