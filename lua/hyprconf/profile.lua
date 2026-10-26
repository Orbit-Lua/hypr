local ctx = require("hyprconf.context")
local fs = require("hyprconf.util.fs")
local declarations = require("hyprconf.config")

-- A profile is a Lua file under profiles/<category>/ whose first line may be
-- `-- profile: <label>`. The state directory records only the selected name,
-- so a selection always loads the deployed revision of that file.

---@alias Hyprconf.ProfileCategory "animation"|"monitor"

---@class Hyprconf.AnimationCurve
---@field name string Curve name passed to hl.curve.
---@field points [number, number][] Bezier control points.

---@class Hyprconf.AnimationSpec
---@field leaf string Hyprland animation leaf.
---@field enabled boolean
---@field speed? number
---@field bezier? string
---@field style? string

---@class Hyprconf.AnimationProfile
---@field enabled? boolean
---@field curves? Hyprconf.AnimationCurve[]
---@field animations? Hyprconf.AnimationSpec[]

---@class Hyprconf.Profile
local M = {}
---@type table<Hyprconf.ProfileCategory, string>
M.loaded = {}

---@type Hyprconf.ProfileCategory[]
M.categories = declarations.profile_categories

---@param category Hyprconf.ProfileCategory
---@param name string
---@return string
function M.path(category, name)
  assert(
    category == "animation" or category == "monitor",
    "invalid profile category"
  )
  assert(declarations.profile_name(name), "invalid profile name")
  return ctx.config_dir .. "/profiles/" .. category .. "/" .. name .. ".lua"
end

---@param category Hyprconf.ProfileCategory
---@return string
function M.selection_file(category)
  assert(
    category == "animation" or category == "monitor",
    "invalid profile category"
  )
  return ctx.state_dir .. "/profiles/selected/" .. category
end

-- The selected profile if its file still exists, else the configured default.
---@param category Hyprconf.ProfileCategory
---@return string
function M.active_name(category)
  local defaults = declarations.read("profiles")
  local raw = fs.read(M.selection_file(category))
  local selected = raw and raw:match("^%s*([%w_-]+)%s*$")
  if selected and fs.exists(M.path(category, selected)) then
    return selected
  end
  if raw then
    print(
      "[WARN] Saved "
        .. category
        .. " profile is invalid or unavailable; using the declared default"
    )
  end
  return defaults.default[category]
end

---@param path string
---@return string
function M.label(path)
  return (fs.read(path) or ""):match("^%-%- profile:%s*([^\n]+)")
    or fs.stem(path)
end

---@param category Hyprconf.ProfileCategory
---@return boolean
function M.load(category)
  local path = M.path(category, M.active_name(category))
  local ok, err = pcall(dofile, path)
  if ok then
    M.loaded[category] = M.active_name(category)
  end
  if not ok then
    if category == "monitor" then
      error(err, 0)
    end
    print(
      "[WARN] Unable to load " .. category .. " profile " .. path .. ": " .. err
    )
  end
  return ok
end

---@param spec Hyprconf.AnimationProfile
---@return nil
function M.apply_animation(spec)
  if spec.enabled ~= nil then
    hl.config({ animations = { enabled = spec.enabled } })
  end

  for _, curve in ipairs(spec.curves or {}) do
    hl.curve(curve.name, { type = "bezier", points = curve.points })
  end

  for _, animation in ipairs(spec.animations or {}) do
    hl.animation(animation)
  end
end

return M
