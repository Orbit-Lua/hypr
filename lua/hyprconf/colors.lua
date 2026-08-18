local ctx = require("hyprconf.context")

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

---@class Hyprconf.ColorCache
---@field version integer
---@field source string
---@field colors table<string, Hyprconf.HexColor>

---@class Hyprconf.Colors
---@field get fun(name: string, fallback?: Hyprconf.RgbColor|string): Hyprconf.RgbColor|string|nil
---@field border_gradient fun(mode: Hyprconf.RainbowBorderMode, count?: integer): string[]
local M = {}

local effects_dir = os.getenv("EFFECTS_DIR") or (ctx.config_dir .. "/effects")
local cache_path = effects_dir .. "/colors-cache.lua"
local source_path = ctx.config_dir .. "/noctalia.lua"
local cache_version = 1

---@type table<string, Hyprconf.HexColor>?
local loaded_colors

---@type string[]
local color_keys = {
  "surface",
  "surface_variant",
  "shadow",
  "on_surface",
  "on_surface_variant",
  "primary",
  "secondary",
  "tertiary",
  "error",
  "outline",
  "on_primary",
  "on_secondary",
  "on_tertiary",
  "on_error",
  "hover",
  "on_hover",
  "background",
  "foreground",
  "color0",
  "color1",
  "color2",
  "color3",
  "color4",
  "color5",
  "color6",
  "color7",
  "color8",
  "color9",
  "color10",
  "color11",
  "color12",
  "color13",
  "color14",
  "color15",
}

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
  local function parse_hex(candidate)
    local text = tostring(candidate or "")
    return text:match("#(%x%x%x%x%x%x)")
      or text:match("rgb%((%x%x%x%x%x%x)%)")
      or text:match("0x%x%x(%x%x%x%x%x%x)")
      or text:match("(%x%x%x%x%x%x)")
  end

  local value_hex = parse_hex(value) or parse_hex(fallback) or "000000"
  return {
    r = tonumber(value_hex:sub(1, 2), 16),
    g = tonumber(value_hex:sub(3, 4), 16),
    b = tonumber(value_hex:sub(5, 6), 16),
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
local function normalize(value, fallback)
  return hex(parse(value, fallback))
end

---@param value string?
---@param fallback? string
---@return string
local function strip(value, fallback)
  return normalize(value, fallback):sub(2)
end

---@param value string?
---@param fallback? string
---@return Hyprconf.RgbColor
local function rgb(value, fallback)
  return "rgb(" .. strip(value, fallback) .. ")"
end

---@param left string
---@param right string
---@param amount? number
---@return Hyprconf.HexColor
local function mix(left, right, amount)
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
local function lighten(value, amount)
  return mix(value, "#ffffff", amount)
end

---@param value string
---@param amount? number
---@return Hyprconf.HexColor
local function darken(value, amount)
  return mix(value, "#000000", amount)
end

---@param value string
---@return number
local function luminance(value)
  local color = parse(value)
  local function channel(channel_value)
    channel_value = channel_value / 255
    if channel_value <= 0.03928 then
      return channel_value / 12.92
    end
    return ((channel_value + 0.055) / 1.055) ^ 2.4
  end

  return 0.2126 * channel(color.r)
    + 0.7152 * channel(color.g)
    + 0.0722 * channel(color.b)
end

---@param value string
---@return Hyprconf.HexColor
local function contrast_text(value)
  return luminance(value) > 0.45 and "#000000" or "#ffffff"
end

---@param values Hyprconf.MaterialSourceColors
---@return table<string, Hyprconf.HexColor>
local function material(values)
  local result = {}

  result.surface = normalize(values.mSurface, "#000000")
  result.surface_variant =
    normalize(values.mSurfaceVariant, lighten(result.surface, 0.1))
  result.shadow = normalize(values.mShadow, darken(result.surface, 0.25))
  result.on_surface =
    normalize(values.mOnSurface, contrast_text(result.surface))
  result.on_surface_variant = normalize(
    values.mOnSurfaceVariant,
    mix(result.on_surface, result.surface_variant, 0.25)
  )
  result.primary = normalize(values.mPrimary, result.on_surface)
  result.secondary = normalize(values.mSecondary, result.primary)
  result.tertiary = normalize(values.mTertiary, result.secondary)
  result.error = normalize(values.mError, "#f38ba8")
  result.outline = normalize(
    values.mOutline,
    mix(result.surface_variant, result.on_surface, 0.35)
  )
  result.on_primary =
    normalize(values.mOnPrimary, contrast_text(result.primary))
  result.on_secondary =
    normalize(values.mOnSecondary, contrast_text(result.secondary))
  result.on_tertiary =
    normalize(values.mOnTertiary, contrast_text(result.tertiary))
  result.on_error = normalize(values.mOnError, contrast_text(result.error))
  result.hover = normalize(values.mHover, lighten(result.tertiary, 0.08))
  result.on_hover = normalize(values.mOnHover, contrast_text(result.hover))

  return result
end

---@param values Hyprconf.MaterialSourceColors
---@return table<string, Hyprconf.HexColor>
local function material_terminal_palette(values)
  local colors = material(values)
  local yellow = mix(colors.tertiary, colors.error, 0.34)
  local cyan = mix(colors.primary, colors.tertiary, 0.5)

  return {
    background = colors.surface,
    foreground = colors.on_surface,
    color0 = colors.shadow,
    color1 = colors.error,
    color2 = colors.tertiary,
    color3 = yellow,
    color4 = colors.primary,
    color5 = colors.secondary,
    color6 = cyan,
    color7 = mix(colors.on_surface, "#ffffff", 0.12),
    color8 = colors.outline,
    color9 = lighten(colors.error, 0.18),
    color10 = lighten(colors.tertiary, 0.16),
    color11 = lighten(yellow, 0.18),
    color12 = lighten(colors.primary, 0.16),
    color13 = lighten(colors.secondary, 0.16),
    color14 = lighten(cyan, 0.16),
    color15 = lighten(colors.on_surface, 0.25),
  }
end

---@param path string
---@return string?
local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  file:close()
  return content
end

---@param value any
---@return string
local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

---@param source string
---@param colors table<string, Hyprconf.HexColor>
---@return nil
local function write_cache(source, colors)
  os.execute("mkdir -p " .. shell_quote(effects_dir))
  local file = io.open(cache_path, "w")
  if not file then
    return
  end

  file:write("return {\n  version = ", cache_version, ",\n")
  file:write("  source = ", string.format("%q", source), ",\n")
  file:write("  colors = {\n")
  for _, key in ipairs(color_keys) do
    file:write("    ", key, " = ", string.format("%q", colors[key]), ",\n")
  end
  file:write("  },\n}\n")
  file:close()
end

---@param value any
---@return boolean
local function valid_colors(value)
  if type(value) ~= "table" then
    return false
  end
  for _, key in ipairs(color_keys) do
    if type(value[key]) ~= "string" then
      return false
    end
  end
  return true
end

---@return Hyprconf.ColorCache?
local function read_cache()
  local chunk = loadfile(cache_path, "t", {})
  if not chunk then
    return nil
  end
  local ok, value = pcall(chunk)
  if
    not ok
    or type(value) ~= "table"
    or value.version ~= cache_version
    or type(value.source) ~= "string"
    or not valid_colors(value.colors)
  then
    return nil
  end
  return value
end

---@param source string
---@return table<string, string>
local function source_colors(source)
  local fallback = {
    primary = "#7aa2f7",
    surface = "#1a1b26",
    secondary = "#bb9af7",
    error = "#f7768e",
  }
  local chunk = load(source, "@" .. source_path, "t", _G)
  if not chunk then
    return fallback
  end
  local ok, theme = pcall(chunk)
  if not ok or type(theme) ~= "table" or type(theme.colors) ~= "table" then
    return fallback
  end

  return {
    primary = normalize(theme.colors.primary, fallback.primary),
    surface = normalize(theme.colors.surface, fallback.surface),
    secondary = normalize(theme.colors.secondary, fallback.secondary),
    error = normalize(theme.colors.error, fallback.error),
  }
end

---@param source string
---@return table<string, Hyprconf.HexColor>
local function build_colors(source)
  local base = source_colors(source)
  local input = {
    mSurface = base.surface,
    mPrimary = base.primary,
    mSecondary = base.secondary,
    mTertiary = base.secondary,
    mError = base.error,
  }
  local colors = material(input)
  for name, value in pairs(material_terminal_palette(input)) do
    colors[name] = value
  end
  return colors
end

---@return table<string, Hyprconf.HexColor>
local function colors()
  if loaded_colors then
    return loaded_colors
  end

  local source = read_file(source_path) or ""
  local cache = read_cache()
  if cache and cache.source == source then
    loaded_colors = cache.colors
    return loaded_colors
  end

  loaded_colors = build_colors(source)
  write_cache(source, loaded_colors)
  return loaded_colors
end

---@param value string
---@return string
local function argb(value)
  return "0xff" .. strip(value)
end

---@param name string
---@param fallback? Hyprconf.RgbColor|string
---@return Hyprconf.RgbColor|string|nil
function M.get(name, fallback)
  local value = colors()[name]
  if not value and not fallback then
    return nil
  end
  return rgb(value, fallback)
end

---@param mode Hyprconf.RainbowBorderMode
---@param count? integer
---@return string[]
function M.border_gradient(mode, count)
  count = math.max(count or 10, 0)
  if mode == "disabled" or count == 0 then
    return {}
  end

  local palette = colors()
  local result = {}
  math.randomseed()

  if mode == "material_random" then
    local pool = { palette.background, palette.foreground }
    for index = 0, 15 do
      pool[#pool + 1] = palette["color" .. index]
    end
    for index = 1, count do
      result[index] = argb(pool[math.random(1, #pool)])
    end
    return result
  end

  if mode == "gradient_flow" then
    for index = 1, count do
      local distance = index - 1
      if distance > count / 2 then
        distance = distance - count
      end
      distance = math.abs(distance)
      local name = "color8"
      if distance == 0 then
        name = "color13"
      elseif distance == 1 then
        name = "color12"
      elseif distance == 2 then
        name = "color11"
      end
      result[index] = argb(palette[name])
    end
    return result
  end

  for index = 1, count do
    result[index] = string.format("0xff%06x", math.random(0, 0xffffff))
  end
  return result
end

return M
