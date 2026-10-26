-- Prints every call hyprland.lua makes into Hyprland, binds excepted
-- (tests/keymap.snapshot owns those), so any change in effective behavior
-- shows up as a diff against tests/config.snapshot. Event handlers run once
-- after loading so their calls are recorded too.
--
-- Usage: lua tests/config.lua <state-dir>
local script = debug.getinfo(1, "S").source:sub(2)
if script:sub(1, 1) ~= "/" then
  script = assert(os.getenv("PWD")) .. "/" .. script
end
local root = assert(script:match("(.+)/tests/[^/]+$"))
local state_dir = assert(arg[1], "usage: lua tests/config.lua <state-dir>")
-- Noctalia rewrites noctalia.lua whenever the theme changes, so a fixed theme
-- keeps the snapshot about this configuration.
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

local function literal(text)
  return (text:gsub("%p", "%%%0"))
end

local lines = {}
local function emit(line)
  line = line:gsub(literal(root), "<config>")
  lines[#lines + 1] = (line:gsub(literal(state_dir), "<state>"))
end

os.execute = function(command)
  emit("os.execute " .. tostring(command))
  return true
end
io.popen = function(command)
  error("configuration ran a command while loading: " .. tostring(command))
end
-- luacheck: pop

local function sorted_keys(value)
  local keys = {}
  for key in pairs(value) do
    keys[#keys + 1] = key
  end
  table.sort(keys, function(a, b)
    if type(a) == type(b) then
      return a < b
    end
    return type(a) == "number"
  end)
  return keys
end

local function render(value, indent)
  if type(value) == "string" then
    return string.format("%q", value)
  elseif type(value) == "function" then
    return "<function>"
  elseif type(value) ~= "table" then
    return tostring(value)
  elseif rawget(value, "dispatcher") then
    return value.dispatcher
  end
  local keys = sorted_keys(value)
  if #keys == 0 then
    return "{}"
  end
  local inner = indent .. "  "
  local parts = {}
  for _, key in ipairs(keys) do
    local prefix = type(key) == "number" and "" or (tostring(key) .. " = ")
    parts[#parts + 1] = inner .. prefix .. render(value[key], inner) .. ","
  end
  return "{\n" .. table.concat(parts, "\n") .. "\n" .. indent .. "}"
end

local handlers = {}

local function recorder(path)
  return setmetatable({}, {
    __index = function(_, name)
      return recorder(path .. "." .. name)
    end,
    __call = function(_, ...)
      local args = table.pack(...)
      if path:match("^hl%.dsp%.") then
        local parts = {}
        for i = 1, args.n do
          parts[i] = render(args[i], "")
        end
        return { dispatcher = path .. "(" .. table.concat(parts, ", ") .. ")" }
      end
      if path == "hl.bind" then
        return nil
      end
      if path == "hl.on" then
        handlers[#handlers + 1] = { event = args[1], handler = args[2] }
      end
      local parts = {}
      for i = 1, args.n do
        parts[i] = render(args[i], "")
      end
      emit(path .. "(" .. table.concat(parts, ", ") .. ")")
      if path == "hl.timer" or path == "hl.on" then
        return recorder(path .. "_handle")
      end
      return nil
    end,
  })
end

-- luacheck: globals hl
hl = recorder("hl")
package.loaded.noctalia = dofile(theme)
dofile(root .. "/hyprland.lua")

for _, entry in ipairs(handlers) do
  emit("")
  emit("-- on " .. tostring(entry.event))
  entry.handler()
end

print(table.concat(lines, "\n"))
