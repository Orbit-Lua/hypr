-- Validate helper declarations before commands consume their settings.
local ctx = require("hyprconf.context")
local toml = require("hyprconf.util.toml")
---@class Hyprconf.Config
local M = {}

---@type Hyprconf.ProfileCategory[]
M.profile_categories = { "animation", "monitor" }
---@type [Hyprconf.RainbowBorderMode, string][]
M.border_modes = {
  { "disabled", "Disabled" },
  { "material_random", "Material Color" },
  { "rainbow", "Original Rainbow" },
  { "gradient_flow", "Gradient Flow" },
}

---@param value any
---@param schema table<string, string>
---@param location string
local function fields(value, schema, location)
  assert(type(value) == "table", location .. ": expected a table")
  for key, item in pairs(value) do
    assert(schema[key], location .. ": unknown field " .. tostring(key))
    assert(type(item) == schema[key], location .. "." .. key .. ": expected " .. schema[key])
  end
end

---@param value any
---@param location string
local function nonempty(value, location)
  assert(type(value) == "string" and value ~= "", location .. ": expected a nonempty string")
end

---@param value any
---@return boolean
function M.profile_name(value)
  return type(value) == "string" and value:match("^[%w_-]+$") ~= nil
end

---@param value any
---@return boolean
function M.border_mode(value)
  for _, mode in ipairs(M.border_modes) do
    if mode[1] == value then
      return true
    end
  end
  return false
end

---@param modes table
local function validate_border_modes(modes)
  local seen = {}
  for index, mode in pairs(modes) do
    assert(
      type(index) == "number" and index % 1 == 0 and index >= 1 and index <= #modes,
      "border modes must be an array"
    )
    assert(M.border_mode(mode), "invalid border mode")
    assert(not seen[mode], "duplicate border mode")
    seen[mode] = true
  end
end

---@param data table
local function validate_effects(data)
  fields(data.rainbow or {}, { default = "string", modes = "table" }, "effects.rainbow")
  fields(data.sounds or {}, {
    mute = "boolean",
    mute_screenshots = "boolean",
    mute_volume = "boolean",
    theme = "string",
  }, "effects.sounds")
  if data.rainbow and data.rainbow.default then
    assert(M.border_mode(data.rainbow.default), "invalid default border mode")
  end
  validate_border_modes((data.rainbow or {}).modes or {})
  if (data.sounds or {}).theme then
    assert(M.profile_name(data.sounds.theme), "invalid sound theme name")
  end
end

---@param data table
local function validate_profiles(data)
  fields(data.default, { animation = "string", monitor = "string" }, "profiles.default")
  for _, category in ipairs(M.profile_categories) do
    assert(M.profile_name(data.default[category]), "invalid default " .. category .. " profile")
  end
end

---@param row table
---@param seen table<string, boolean>
local function validate_quick_setting(row, seen)
  nonempty(row.label, "quick setting label")
  assert(not seen[row.label], "duplicate quick setting label")
  seen[row.label] = true
  assert(
    ({ header = true, edit = true, exec = true, action = true })[row.kind],
    "invalid quick setting kind"
  )
  if row.kind == "edit" then
    nonempty(row.path, "quick setting path")
    assert(
      row.path:sub(1, 1) ~= "/" and not ("/" .. row.path .. "/"):find("/../", 1, true),
      "quick setting path escapes configuration"
    )
  elseif row.kind == "exec" or row.kind == "action" then
    nonempty(row.command, "quick setting command")
  end
end

-- Each declaration owns its top-level fields and, where applicable, its row schema.
local schemas = {
  autostart = { command = "table" },
  effects = { rainbow = "table", sounds = "table" },
  ["key-hints"] = { row = "table" },
  ["quick-settings"] = { item = "table" },
  profiles = { default = "table" },
}
local row_declarations = {
  autostart = { key = "command", fields = { run = "string", enabled = "boolean" } },
  ["key-hints"] = {
    key = "row",
    fields = { key = "string", description = "string", command = "string" },
  },
  ["quick-settings"] = {
    key = "item",
    fields = {
      label = "string",
      kind = "string",
      path = "string",
      require = "string",
      command = "string",
    },
  },
}

---@param name string
---@param data table
local function validate_rows(name, data)
  local declaration = row_declarations[name]
  local rows = data[declaration.key] or {}
  local seen = {}
  for index, row in pairs(rows) do
    assert(
      type(index) == "number" and index >= 1 and index <= #rows and index % 1 == 0,
      name .. ": expected an array"
    )
    fields(row, declaration.fields, name .. "." .. declaration.key)
    if name == "autostart" then
      nonempty(row.run, "autostart command")
    elseif name == "quick-settings" then
      validate_quick_setting(row, seen)
    end
  end
end

---@param name string
---@return table
function M.read(name)
  assert(schemas[name], "unknown configuration declaration")
  local data = toml.read(ctx.config_file(name))
  fields(data, schemas[name], name)
  if name == "effects" then
    validate_effects(data)
  elseif name == "profiles" then
    validate_profiles(data)
  else
    validate_rows(name, data)
  end
  return data
end

return M
