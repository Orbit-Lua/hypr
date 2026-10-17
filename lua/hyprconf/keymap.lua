-- Reads the keymap outside Hyprland: binds.lua runs against a stub `hl` that
-- records each bind and describes dispatchers instead of executing them.

---@class Hyprconf.KeymapEntry
---@field keys string
---@field description? string
---@field dispatcher any
---@field opts table

---@class Hyprconf.Keymap
local M = {}

---@param value any
---@return string
function M.serialize(value)
  if type(value) ~= "table" then
    return type(value) == "string" and string.format("%q", value)
      or tostring(value)
  end
  if value.dispatcher then
    return value.dispatcher
  end
  local keys = {}
  for key in pairs(value) do
    keys[#keys + 1] = key
  end
  table.sort(keys, function(a, b)
    return tostring(a) < tostring(b)
  end)
  local parts = {}
  for _, key in ipairs(keys) do
    local prefix = type(key) == "number" and "" or (tostring(key) .. "=")
    parts[#parts + 1] = prefix .. M.serialize(value[key])
  end
  return "{" .. table.concat(parts, ",") .. "}"
end

---@param path string
---@return table
local function dispatchers(path)
  return setmetatable({}, {
    __index = function(_, name)
      return dispatchers(path .. "." .. name)
    end,
    __call = function(_, ...)
      return { dispatcher = path .. M.serialize({ ... }) }
    end,
  })
end

---@param stub? table Extra `hl` fields, such as probes for function binds.
---@return Hyprconf.KeymapEntry[]
function M.collect(stub)
  stub = stub or {}
  local entries = {}
  stub.dsp = dispatchers("dsp")
  stub.bind = function(keys, dispatcher, opts)
    opts = opts or {}
    entries[#entries + 1] = {
      keys = keys,
      description = opts.description,
      dispatcher = dispatcher,
      opts = opts,
    }
  end

  local saved = rawget(_G, "hl")
  rawset(_G, "hl", stub)
  package.loaded["hyprconf.binds"] = nil
  local ok, err = pcall(function()
    require("hyprconf.binds").setup()
  end)
  package.loaded["hyprconf.binds"] = nil
  rawset(_G, "hl", saved)
  if not ok then
    error(err, 0)
  end
  return entries
end

return M
