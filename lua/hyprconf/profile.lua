local ctx = require("hyprconf.context")
local util = require("hyprconf.util")

---@alias Hyprconf.ProfileCategory "animation"|"monitor"|string

---@class Hyprconf.ProfileCategoryConfig
---@field user_file string User-local profile filename under lua/user.
---@field fallback string Default profile path.

---@class Hyprconf.ProfileLoadOptions
---@field fallback? string Override fallback profile path.
---@field default? fun() Callback used when no file profile exists.

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
---@field load fun(category: Hyprconf.ProfileCategory, opts?: Hyprconf.ProfileLoadOptions): boolean
---@field apply_animation fun(spec: Hyprconf.AnimationProfile)
local M = {}

---@type table<string, Hyprconf.ProfileCategoryConfig>
local categories = {
  animation = {
    user_file = "animations.lua",
    fallback = ctx.config_dir .. "/profiles/animation/default.lua",
  },
  monitor = {
    user_file = "monitors.lua",
    fallback = ctx.config_dir .. "/profiles/monitor/default.lua",
  },
}

---@param message string
---@return nil
local function warn(message)
  print("[WARN] " .. message)
end

---@param category Hyprconf.ProfileCategory
---@return Hyprconf.ProfileCategoryConfig
local function category_config(category)
  return categories[category]
    or {
      user_file = category .. ".lua",
      fallback = ctx.config_dir .. "/profiles/" .. category .. "/default.lua",
    }
end

---@param path string
---@param label string
---@return boolean
local function load_file(path, label)
  local ok, err = pcall(dofile, path)
  if ok then
    return true
  end

  warn("Unable to load " .. label .. " from " .. path .. ": " .. tostring(err))
  return false
end

---@param category Hyprconf.ProfileCategory
---@param opts? Hyprconf.ProfileLoadOptions
---@return boolean
function M.load(category, opts)
  opts = opts or {}

  local config = category_config(category)
  local user_path = ctx.config_dir .. "/lua/user/" .. config.user_file

  if util.file_exists(user_path) then
    return load_file(user_path, "user " .. category .. " profile")
  end

  local fallback = opts.fallback or config.fallback
  if fallback and util.file_exists(fallback) then
    return load_file(fallback, "default " .. category .. " profile")
  end

  if opts.default then
    opts.default()
    return true
  end

  return false
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
