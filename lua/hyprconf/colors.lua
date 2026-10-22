-- Derives a terminal-style palette from the Noctalia theme for shadows and
-- rainbow borders. Noctalia's own apply_theme sets the border and group colors.

---@alias Hyprconf.HexColor string Hex color in "#rrggbb" form.
---@alias Hyprconf.RgbColor string Hyprland rgb color in "rgb(rrggbb)" form.

---@class Hyprconf.Colors
local M = {}

---@param color string? `#rrggbb`, `rgb(rrggbb)` or `0xaarrggbb`.
---@return integer[]?
local function channels(color)
  local value = tostring(color or "")
  local hex = value:match("^#(%x%x%x%x%x%x)$")
    or value:match("^rgb%((%x%x%x%x%x%x)%)$")
    or value:match("^0x%x%x(%x%x%x%x%x%x)$")
  if hex then
    return {
      tonumber(hex:sub(1, 2), 16),
      tonumber(hex:sub(3, 4), 16),
      tonumber(hex:sub(5, 6), 16),
    }
  end
end

---@param rgb number[]
---@return Hyprconf.HexColor
local function format(rgb)
  local parts = {}
  for index, value in ipairs(rgb) do
    parts[index] = math.max(0, math.min(255, math.floor(value + 0.5)))
  end
  return string.format("#%02x%02x%02x", parts[1], parts[2], parts[3])
end

---@param left Hyprconf.HexColor
---@param right Hyprconf.HexColor
---@param weight number Share of `right`, from 0 to 1.
---@return Hyprconf.HexColor
local function mix(left, right, weight)
  local a, b = assert(channels(left)), assert(channels(right))
  return format({
    a[1] + (b[1] - a[1]) * weight,
    a[2] + (b[2] - a[2]) * weight,
    a[3] + (b[3] - a[3]) * weight,
  })
end

---@param color Hyprconf.HexColor
---@param amount number
---@return Hyprconf.HexColor
local function lighten(color, amount)
  return mix(color, "#ffffff", amount)
end

---@param color Hyprconf.HexColor
---@return Hyprconf.HexColor
local function contrast_text(color)
  local function linear(value)
    value = value / 255
    return value <= 0.03928 and value / 12.92 or ((value + 0.055) / 1.055) ^ 2.4
  end
  local c = assert(channels(color))
  local luminance = 0.2126 * linear(c[1])
    + 0.7152 * linear(c[2])
    + 0.0722 * linear(c[3])
  return luminance > 0.45 and "#000000" or "#ffffff"
end

---@param theme table? Noctalia's `colors` table.
---@return table<string, Hyprconf.HexColor>
local function derive(theme)
  theme = theme or {}
  ---@param name string
  ---@param fallback Hyprconf.HexColor
  ---@return Hyprconf.HexColor
  local function pick(name, fallback)
    local c = channels(theme[name])
    return c and format(c) or fallback
  end

  local surface = pick("surface", "#1a1b26")
  local primary = pick("primary", "#7aa2f7")
  local secondary = pick("secondary", "#bb9af7")
  local error = pick("error", "#f7768e")
  local on_surface = pick("on_surface", contrast_text(surface))
  local outline = mix(lighten(surface, 0.1), on_surface, 0.35)
  local yellow = mix(secondary, error, 0.34)
  local cyan = mix(primary, secondary, 0.5)

  return {
    background = surface,
    foreground = on_surface,
    color0 = mix(surface, "#000000", 0.25),
    color1 = error,
    color2 = secondary,
    color3 = yellow,
    color4 = primary,
    color5 = secondary,
    color6 = cyan,
    color7 = lighten(on_surface, 0.12),
    color8 = outline,
    color9 = lighten(error, 0.18),
    color10 = lighten(secondary, 0.16),
    color11 = lighten(yellow, 0.18),
    color12 = lighten(primary, 0.16),
    color13 = lighten(secondary, 0.16),
    color14 = lighten(cyan, 0.16),
    color15 = lighten(on_surface, 0.25),
  }
end

---@type table<string, Hyprconf.HexColor>?
local palette

---@return table<string, Hyprconf.HexColor>
local function colors()
  if not palette then
    local ok, noctalia = pcall(require, "noctalia")
    palette =
      derive(ok and type(noctalia) == "table" and noctalia.colors or nil)
  end
  return palette
end

---@param name string Palette key: background, foreground or color0 to color15.
---@return Hyprconf.RgbColor
function M.get(name)
  return "rgb(" .. assert(colors()[name], name):sub(2) .. ")"
end

---@param mode Hyprconf.RainbowBorderMode
---@param count integer
---@return string[] Colors in `0xaarrggbb` form; empty when disabled.
function M.border_gradient(mode, count)
  local result = {}
  if mode == "disabled" then
    return result
  end
  local argb = function(name)
    return "0xff" .. colors()[name]:sub(2)
  end
  math.randomseed()

  if mode == "material_random" then
    local pool = { "background", "foreground" }
    for index = 0, 15 do
      pool[#pool + 1] = "color" .. index
    end
    for index = 1, count do
      result[index] = argb(pool[math.random(1, #pool)])
    end
  elseif mode == "gradient_flow" then
    -- Brightest at both ends, fading to color8 in the middle.
    local by_distance = { [0] = "color13", "color12", "color11" }
    for index = 1, count do
      local distance = index - 1
      if distance > count / 2 then
        distance = distance - count
      end
      result[index] = argb(by_distance[math.abs(distance)] or "color8")
    end
  else
    for index = 1, count do
      result[index] = string.format("0xff%06x", math.random(0, 0xffffff))
    end
  end
  return result
end

return M
