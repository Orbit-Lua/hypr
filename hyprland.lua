---@type string
local config_dir = (debug.getinfo(1, "S").source:sub(2):match("(.+)/[^/]+$"))
  or "."

package.path = table.concat({
  config_dir .. "/lua/?.lua",
  config_dir .. "/lua/?/init.lua",
  package.path,
}, ";")

require("hyprconf").setup()

-- For Noctalia Color templates
require("noctalia").apply_theme()
