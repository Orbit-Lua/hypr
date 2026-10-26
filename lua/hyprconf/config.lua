local ctx = require("hyprconf.context")
local toml = require("hyprconf.util.toml")
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
    assert(
      type(item) == schema[key],
      location .. "." .. key .. ": expected " .. schema[key]
    )
  end
end

---@param value any
---@param location string
local function nonempty(value, location)
  assert(
    type(value) == "string" and value ~= "",
    location .. ": expected a nonempty string"
  )
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

---@param name string
---@return table
function M.read(name)
  local schemas = {
    autostart = { command = "table" },
    effects = { rainbow = "table", sounds = "table" },
    ["key-hints"] = { row = "table" },
    ["quick-settings"] = { item = "table" },
    profiles = { default = "table" },
  }
  assert(schemas[name], "unknown configuration declaration")
  local data = toml.read(ctx.config_file(name))
  fields(data, schemas[name], name)
  if name == "effects" then
    fields(
      data.rainbow or {},
      { default = "string", modes = "table" },
      "effects.rainbow"
    )
    fields(data.sounds or {}, {
      mute = "boolean",
      mute_screenshots = "boolean",
      mute_volume = "boolean",
      theme = "string",
    }, "effects.sounds")
    if data.rainbow and data.rainbow.default then
      assert(M.border_mode(data.rainbow.default), "invalid default border mode")
    end
    local modes = (data.rainbow or {}).modes or {}
    local seen = {}
    for index, mode in pairs(modes) do
      assert(
        type(index) == "number"
          and index % 1 == 0
          and index >= 1
          and index <= #modes,
        "border modes must be an array"
      )
      assert(M.border_mode(mode), "invalid border mode")
      assert(not seen[mode], "duplicate border mode")
      seen[mode] = true
    end
    if (data.sounds or {}).theme then
      assert(M.profile_name(data.sounds.theme), "invalid sound theme name")
    end
  elseif name == "profiles" then
    fields(
      data.default,
      { animation = "string", monitor = "string" },
      "profiles.default"
    )
    for _, category in ipairs(M.profile_categories) do
      assert(
        M.profile_name(data.default[category]),
        "invalid default " .. category .. " profile"
      )
    end
  else
    local key = name == "autostart" and "command"
      or name == "key-hints" and "row"
      or "item"
    local schema = name == "autostart"
        and { run = "string", enabled = "boolean" }
      or name == "key-hints" and {
        key = "string",
        description = "string",
        command = "string",
      }
      or {
        label = "string",
        kind = "string",
        path = "string",
        require = "string",
        command = "string",
      }
    local rows = data[key] or {}
    local seen = {}
    for index, row in pairs(rows) do
      assert(
        type(index) == "number"
          and index >= 1
          and index <= #rows
          and index % 1 == 0,
        name .. ": expected an array"
      )
      fields(row, schema, name .. "." .. key)
      if name == "autostart" then
        nonempty(row.run, "autostart command")
      end
      if name == "quick-settings" then
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
            row.path:sub(1, 1) ~= "/"
              and not ("/" .. row.path .. "/"):find("/../", 1, true),
            "quick setting path escapes configuration"
          )
        elseif row.kind == "exec" or row.kind == "action" then
          nonempty(row.command, "quick setting command")
        end
      end
    end
  end
  return data
end

return M
