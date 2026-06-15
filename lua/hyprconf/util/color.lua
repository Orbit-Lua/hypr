---@alias Hyprconf.HexColor string Hex color in "#rrggbb" form.
---@alias Hyprconf.RgbColor string Hyprland rgb color in "rgb(rrggbb)" form.

---@class Hyprconf.ColorChannels
---@field r integer Red channel from 0 to 255.
---@field g integer Green channel from 0 to 255.
---@field b integer Blue channel from 0 to 255.

---@class Hyprconf.MaterialSourceColors
---@field mSurface? Hyprconf.HexColor
---@field mSurfaceVariant? Hyprconf.HexColor
---@field mOnSurface? Hyprconf.HexColor
---@field mOnSurfaceVariant? Hyprconf.HexColor
---@field mPrimary? Hyprconf.HexColor
---@field mSecondary? Hyprconf.HexColor
---@field mTertiary? Hyprconf.HexColor
---@field mError? Hyprconf.HexColor
---@field mOnPrimary? Hyprconf.HexColor
---@field mOnSecondary? Hyprconf.HexColor
---@field mOnTertiary? Hyprconf.HexColor
---@field mOnError? Hyprconf.HexColor
---@field mHover? Hyprconf.HexColor
---@field mOnHover? Hyprconf.HexColor
---@field mOutline? Hyprconf.HexColor
---@field mShadow? Hyprconf.HexColor

---@class Hyprconf.MaterialPalette
---@field surface Hyprconf.HexColor
---@field surface_variant Hyprconf.HexColor
---@field shadow Hyprconf.HexColor
---@field on_surface Hyprconf.HexColor
---@field on_surface_variant Hyprconf.HexColor
---@field primary Hyprconf.HexColor
---@field secondary Hyprconf.HexColor
---@field tertiary Hyprconf.HexColor
---@field error Hyprconf.HexColor
---@field outline Hyprconf.HexColor
---@field on_primary Hyprconf.HexColor
---@field on_secondary Hyprconf.HexColor
---@field on_tertiary Hyprconf.HexColor
---@field on_error Hyprconf.HexColor
---@field hover Hyprconf.HexColor
---@field on_hover Hyprconf.HexColor

---@class Hyprconf.TerminalPalette
---@field background Hyprconf.HexColor
---@field foreground Hyprconf.HexColor
---@field color0 Hyprconf.HexColor
---@field color1 Hyprconf.HexColor
---@field color2 Hyprconf.HexColor
---@field color3 Hyprconf.HexColor
---@field color4 Hyprconf.HexColor
---@field color5 Hyprconf.HexColor
---@field color6 Hyprconf.HexColor
---@field color7 Hyprconf.HexColor
---@field color8 Hyprconf.HexColor
---@field color9 Hyprconf.HexColor
---@field color10 Hyprconf.HexColor
---@field color11 Hyprconf.HexColor
---@field color12 Hyprconf.HexColor
---@field color13 Hyprconf.HexColor
---@field color14 Hyprconf.HexColor
---@field color15 Hyprconf.HexColor

---@class Hyprconf.Util.Color
---@field normalize fun(value: string?, fallback?: string): Hyprconf.HexColor
---@field strip fun(value: string?, fallback?: string): string
---@field rgb fun(value: string?, fallback?: string): Hyprconf.RgbColor
---@field mix fun(left: string, right: string, amount?: number): Hyprconf.HexColor
---@field lighten fun(value: string, amount?: number): Hyprconf.HexColor
---@field darken fun(value: string, amount?: number): Hyprconf.HexColor
---@field luminance fun(value: string): number
---@field contrast_text fun(value: string): Hyprconf.HexColor
---@field material fun(values: Hyprconf.MaterialSourceColors): Hyprconf.MaterialPalette
---@field material_terminal_palette fun(values: Hyprconf.MaterialSourceColors): Hyprconf.TerminalPalette
local M = {}

---@param value number
---@param min number
---@param max number
---@return number
local function clamp(value, min, max)
  if value < min then
    return min
  end
  if value > max then
    return max
  end
  return value
end

---@param value string?
---@param fallback? string
---@return Hyprconf.ColorChannels
local function parse(value, fallback)
  local hex = tostring(value or ""):match("#?(%x%x%x%x%x%x)")
  if not hex and fallback then
    hex = tostring(fallback):match("#?(%x%x%x%x%x%x)")
  end
  hex = hex or "000000"

  return {
    r = tonumber(hex:sub(1, 2), 16),
    g = tonumber(hex:sub(3, 4), 16),
    b = tonumber(hex:sub(5, 6), 16),
  }
end

---@param color Hyprconf.ColorChannels
---@return Hyprconf.HexColor
local function hex(color)
  return string.format(
    "#%02x%02x%02x",
    clamp(math.floor(color.r + 0.5), 0, 255),
    clamp(math.floor(color.g + 0.5), 0, 255),
    clamp(math.floor(color.b + 0.5), 0, 255)
  )
end

---@param value string?
---@param fallback? string
---@return Hyprconf.HexColor
function M.normalize(value, fallback)
  return hex(parse(value, fallback))
end

---@param value string?
---@param fallback? string
---@return string
function M.strip(value, fallback)
  return M.normalize(value, fallback):sub(2)
end

---@param value string?
---@param fallback? string
---@return Hyprconf.RgbColor
function M.rgb(value, fallback)
  return "rgb(" .. M.strip(value, fallback) .. ")"
end

---@param left string
---@param right string
---@param amount? number
---@return Hyprconf.HexColor
function M.mix(left, right, amount)
  local a = parse(left)
  local b = parse(right)
  local weight = clamp(amount or 0.5, 0, 1)

  return hex({
    r = a.r + (b.r - a.r) * weight,
    g = a.g + (b.g - a.g) * weight,
    b = a.b + (b.b - a.b) * weight,
  })
end

---@param value string
---@param amount? number
---@return Hyprconf.HexColor
function M.lighten(value, amount)
  return M.mix(value, "#ffffff", amount)
end

---@param value string
---@param amount? number
---@return Hyprconf.HexColor
function M.darken(value, amount)
  return M.mix(value, "#000000", amount)
end

---@param value string
---@return number
function M.luminance(value)
  local c = parse(value)
  local function channel(v)
    v = v / 255
    if v <= 0.03928 then
      return v / 12.92
    end
    return ((v + 0.055) / 1.055) ^ 2.4
  end

  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b)
end

---@param value string
---@return Hyprconf.HexColor
function M.contrast_text(value)
  return M.luminance(value) > 0.45 and "#000000" or "#ffffff"
end

---@param values Hyprconf.MaterialSourceColors
---@return Hyprconf.MaterialPalette
function M.material(values)
  local result = {}

  result.surface = M.normalize(values.mSurface, "#000000")
  result.surface_variant =
    M.normalize(values.mSurfaceVariant, M.lighten(result.surface, 0.1))
  result.shadow = M.normalize(values.mShadow, M.darken(result.surface, 0.25))
  result.on_surface =
    M.normalize(values.mOnSurface, M.contrast_text(result.surface))
  result.on_surface_variant = M.normalize(
    values.mOnSurfaceVariant,
    M.mix(result.on_surface, result.surface_variant, 0.25)
  )
  result.primary = M.normalize(values.mPrimary, result.on_surface)
  result.secondary = M.normalize(values.mSecondary, result.primary)
  result.tertiary = M.normalize(values.mTertiary, result.secondary)
  result.error = M.normalize(values.mError, "#f38ba8")
  result.outline = M.normalize(
    values.mOutline,
    M.mix(result.surface_variant, result.on_surface, 0.35)
  )
  result.on_primary =
    M.normalize(values.mOnPrimary, M.contrast_text(result.primary))
  result.on_secondary =
    M.normalize(values.mOnSecondary, M.contrast_text(result.secondary))
  result.on_tertiary =
    M.normalize(values.mOnTertiary, M.contrast_text(result.tertiary))
  result.on_error = M.normalize(values.mOnError, M.contrast_text(result.error))
  result.hover = M.normalize(values.mHover, M.lighten(result.tertiary, 0.08))
  result.on_hover = M.normalize(values.mOnHover, M.contrast_text(result.hover))

  return result
end

---@param values Hyprconf.MaterialSourceColors
---@return Hyprconf.TerminalPalette
function M.material_terminal_palette(values)
  local c = M.material(values)
  local yellow = M.mix(c.tertiary, c.error, 0.34)
  local cyan = M.mix(c.primary, c.tertiary, 0.5)

  return {
    background = c.surface,
    foreground = c.on_surface,
    color0 = c.shadow,
    color1 = c.error,
    color2 = c.tertiary,
    color3 = yellow,
    color4 = c.primary,
    color5 = c.secondary,
    color6 = cyan,
    color7 = M.mix(c.on_surface, "#ffffff", 0.12),
    color8 = c.outline,
    color9 = M.lighten(c.error, 0.18),
    color10 = M.lighten(c.tertiary, 0.16),
    color11 = M.lighten(yellow, 0.18),
    color12 = M.lighten(c.primary, 0.16),
    color13 = M.lighten(c.secondary, 0.16),
    color14 = M.lighten(cyan, 0.16),
    color15 = M.lighten(c.on_surface, 0.25),
  }
end

return M
