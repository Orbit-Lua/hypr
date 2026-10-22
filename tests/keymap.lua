-- Prints every keybind as one line, in registration order, so a refactor can
-- be checked against tests/keymap.snapshot.
local root = (debug.getinfo(1, "S").source:sub(2):match("(.+)/tests/[^/]+$"))
  or "."
package.path = table.concat({
  root .. "/lua/?.lua",
  root .. "/lua/?/init.lua",
  package.path,
}, ";")

local getenv = os.getenv
---@diagnostic disable: duplicate-set-field
-- luacheck: push ignore 122
os.getenv = function(name)
  local fixed = { HOME = "/home/test", HYPR_CONFIG_DIR = "/config/hypr" }
  if fixed[name] then
    return fixed[name]
  end
  return getenv(name)
end
-- luacheck: pop

local keymap = require("hyprconf.keymap")
local serialize = keymap.serialize

local workspace
local dispatched = {}
local stub = {
  dispatch = function(dispatcher)
    dispatched[#dispatched + 1] = serialize(dispatcher)
  end,
  get_active_workspace = function()
    return workspace
  end,
  get_active_special_workspace = function()
    return nil
  end,
}

-- A function bind is described by what it dispatches in each probe state.
local probes = {
  { id = 1, tiled_layout = "dwindle" },
  { id = 5, tiled_layout = "master" },
  { id = 5, tiled_layout = "scrolling" },
  { id = 10, tiled_layout = "dwindle" },
}

local function describe(dispatcher)
  if type(dispatcher) ~= "function" then
    return serialize(dispatcher)
  end
  local results = {}
  for _, probe in ipairs(probes) do
    workspace, dispatched = probe, {}
    dispatcher()
    results[#results + 1] = probe.id
      .. "/"
      .. probe.tiled_layout
      .. ":"
      .. table.concat(dispatched, ";")
  end
  return "fn[" .. table.concat(results, " ") .. "]"
end

local binds = keymap.collect(stub)
-- Function binds read the global `hl` when they run.
-- luacheck: globals hl
hl = stub

for _, bind in ipairs(binds) do
  local opts = {}
  for key, value in pairs(bind.opts) do
    if key ~= "description" then
      opts[key] = value
    end
  end
  print(table.concat({
    bind.keys,
    bind.description or "-",
    describe(bind.dispatcher),
    serialize(opts),
  }, "\t"))
end
