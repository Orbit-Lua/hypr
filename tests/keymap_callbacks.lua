local root = debug.getinfo(1, "S").source:sub(2):match("(.+)/tests/[^/]+$")
  or "."
package.path = root
  .. "/lua/?.lua;"
  .. root
  .. "/lua/?/init.lua;"
  .. package.path

local keymap = require("hyprconf.keymap")
local workspace, special
local dispatched = {}
local stub = {
  get_active_workspace = function()
    return workspace
  end,
  get_active_special_workspace = function()
    return special
  end,
  dispatch = function(value)
    dispatched[#dispatched + 1] = keymap.serialize(value)
  end,
}
local entries = keymap.collect(stub)
-- luacheck: globals hl
hl = stub

for _, entry in ipairs(entries) do
  if type(entry.dispatcher) == "function" then
    entry.dispatcher()
    assert(#dispatched == 0, "callback dispatched without an active workspace")
  end
end

workspace = { id = 5, tiled_layout = "dwindle" }
special = { id = -99, tiled_layout = "scrolling" }
for _, entry in ipairs(entries) do
  if entry.keys == "SUPER + H" then
    entry.dispatcher()
    assert(
      dispatched[1] == 'dsp.layout{"focus l"}',
      "layout action must follow the active special workspace"
    )
  end
end
