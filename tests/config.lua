-- Exercise the real configuration entry point with inert compositor declarations.
local script = debug.getinfo(1, "S").source:sub(2)
if script:sub(1, 1) ~= "/" then
  script = assert(os.getenv("PWD")) .. "/" .. script
end
local root = assert(script:match("(.+)/tests/[^/]+$"))
local state_dir = assert(arg[1], "usage: lua tests/config.lua <state-dir>")
-- Load only the public synthetic theme, independent from the desktop.
local theme = root .. "/tests/fixtures/noctalia.lua"

local getenv = os.getenv
---@diagnostic disable: duplicate-set-field
-- luacheck: push ignore 122 143
os.getenv = function(name)
  local fixed = {
    HOME = "/home/test",
    HYPR_CONFIG_DIR = root,
    HYPR_STATE_DIR = state_dir,
    XDG_RUNTIME_DIR = state_dir,
  }
  if fixed[name] then
    return fixed[name]
  end
  return getenv(name)
end

-- luacheck: pop

---@diagnostic disable: duplicate-set-field
-- luacheck: push ignore 122 143
os.execute = function(command)
  error("configuration launched a process while loading: " .. tostring(command))
end
io.popen = function(command)
  error(
    "configuration read command output while loading: " .. tostring(command)
  )
end
-- luacheck: pop

local function declaration(path)
  return setmetatable({}, {
    __index = function(_, name)
      return declaration(path .. "." .. name)
    end,
    __call = function()
      assert(
        path ~= "hl.exec_cmd" and path ~= "hl.dispatch",
        "configuration performed a runtime action while loading: " .. path
      )
      return declaration(path .. "_handle")
    end,
  })
end

-- luacheck: globals hl
hl = declaration("hl")
package.loaded.noctalia = dofile(theme)
dofile(root .. "/hyprland.lua")
print("Configuration loads without launching processes")
