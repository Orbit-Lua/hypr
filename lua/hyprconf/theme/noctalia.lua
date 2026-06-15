local ctx = require("hyprconf.context")
local color = require("hyprconf.util.color")
local json = require("hyprconf.util.json")

---@class Hyprconf.NoctaliaTheme
---@field apply fun(): boolean
local M = {}

---@class Hyprconf.NoctaliaMaterialColors
---@field mSurface Hyprconf.HexColor
---@field mSurfaceVariant Hyprconf.HexColor
---@field mOnSurface Hyprconf.HexColor
---@field mOnSurfaceVariant Hyprconf.HexColor
---@field mPrimary Hyprconf.HexColor
---@field mSecondary Hyprconf.HexColor
---@field mTertiary Hyprconf.HexColor
---@field mError Hyprconf.HexColor
---@field mOnPrimary Hyprconf.HexColor
---@field mOnSecondary Hyprconf.HexColor
---@field mOnTertiary Hyprconf.HexColor
---@field mOnError Hyprconf.HexColor
---@field mHover Hyprconf.HexColor
---@field mOnHover Hyprconf.HexColor
---@field mOutline Hyprconf.HexColor
---@field mShadow Hyprconf.HexColor

---@class Hyprconf.NoctaliaPaths
---@field colors string Noctalia material colors JSON path.
---@field wallpapers string Noctalia wallpapers JSON path.
---@field qml string Generated Quickshell QML color JSON path.
---@field rofi string Generated rofi color theme path.
---@field effects_colors string Generated Hyprland effects color path.
---@field generated string Generated Lua color module path.
---@field effects_cache string Hypr effects cache directory.

---@type Hyprconf.NoctaliaPaths
local paths = {
  colors = ctx.home .. "/.config/noctalia/colors.json",
  wallpapers = ctx.home .. "/.cache/noctalia/wallpapers.json",
  qml = ctx.home .. "/.config/quickshell/qml_color.json",
  rofi = ctx.home .. "/.config/rofi/noctalia/colors.rasi",
  effects_colors = ctx.config_dir .. "/effects/colors-hyprland.conf",
  generated = ctx.config_dir .. "/lua/hyprconf/generated/noctalia.lua",
  effects_cache = ctx.home .. "/.cache/hypr/effects",
}

---@type string[]
local material_keys = {
  "mSurface",
  "mSurfaceVariant",
  "mOnSurface",
  "mOnSurfaceVariant",
  "mPrimary",
  "mSecondary",
  "mTertiary",
  "mError",
  "mOnPrimary",
  "mOnSecondary",
  "mOnTertiary",
  "mOnError",
  "mHover",
  "mOnHover",
  "mOutline",
  "mShadow",
}

---@type string[]
local qml_order = {
  "windowBackground",
  "primaryText",
  "layerBackground1",
  "layerBackground2",
  "layerBackground3",
  "surfaceText",
  "secondaryText",
  "borderPrimary",
  "shadowColor",
  "accentPrimary",
  "accentSecondary",
  "selectionBackground",
  "accentPrimaryText",
  "selectionText",
  "borderSecondary",
}

---@param value any
---@return string
local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

---@param path string
---@return nil
local function mkdir_parent(path)
  local parent = path:match("(.+)/[^/]+$")
  if parent then
    os.execute("mkdir -p " .. shell_quote(parent))
  end
end

---@param path string
---@param content string
---@return nil
local function write_file(path, content)
  mkdir_parent(path)
  local file = assert(io.open(path, "w"))
  file:write(content)
  file:close()
end

---@param summary string
---@param body? string
---@param urgency? Hyprconf.NotifyUrgency
---@return nil
local function notify(summary, body, urgency)
  local cmd = "notify-send"
  if urgency then
    cmd = cmd .. " -u " .. shell_quote(urgency)
  end
  cmd = cmd .. " " .. shell_quote(summary) .. " " .. shell_quote(body or "")
  os.execute(cmd .. " >/dev/null 2>&1 || true")
end

---@param value string
---@return Hyprconf.RgbColor
local function hex_to_rgb(value)
  return color.rgb(value)
end

---@param path string
---@return Hyprconf.MaterialSourceColors
local function load_material_colors(path)
  local content = json.read(path)
  ---@type Hyprconf.MaterialSourceColors
  local colors = {}

  for _, key in ipairs(material_keys) do
    colors[key] = json.string_field(content, key)
  end

  return colors
end

---@param colors Hyprconf.MaterialSourceColors
---@return Hyprconf.NoctaliaMaterialColors
local function material_hex(colors)
  local palette = color.material(colors)

  return {
    mError = palette.error,
    mHover = palette.hover,
    mOnError = palette.on_error,
    mOnHover = palette.on_hover,
    mOnPrimary = palette.on_primary,
    mOnSecondary = palette.on_secondary,
    mOnSurface = palette.on_surface,
    mOnSurfaceVariant = palette.on_surface_variant,
    mOnTertiary = palette.on_tertiary,
    mOutline = palette.outline,
    mPrimary = palette.primary,
    mSecondary = palette.secondary,
    mShadow = palette.shadow,
    mSurface = palette.surface,
    mSurfaceVariant = palette.surface_variant,
    mTertiary = palette.tertiary,
  }
end

---@param colors Hyprconf.NoctaliaMaterialColors
---@return string
local function generate_qml(colors)
  return json.encode_object({
    windowBackground = colors.mSurface,
    primaryText = colors.mOnSurface,
    layerBackground1 = colors.mPrimary,
    layerBackground2 = colors.mSurfaceVariant,
    layerBackground3 = colors.mShadow,
    surfaceText = colors.mOnSurface,
    secondaryText = colors.mOnSurfaceVariant,
    borderPrimary = colors.mPrimary,
    shadowColor = colors.mShadow,
    accentPrimary = colors.mPrimary,
    accentSecondary = colors.mSecondary,
    selectionBackground = colors.mPrimary,
    accentPrimaryText = colors.mOnPrimary,
    selectionText = colors.mOnPrimary,
    borderSecondary = colors.mOutline,
  }, qml_order)
end

---@param colors Hyprconf.NoctaliaMaterialColors
---@return string
local function generate_rofi(colors)
  return string.format(
    [[/* noctalia Material Design theme - generated by Lua */

* {
active-background: %s;
active-foreground: %s;
normal-background: %s;
normal-foreground: %s;
urgent-background: %s;
urgent-foreground: %s;

alternate-active-background: %s;
alternate-active-foreground: %s;
alternate-normal-background: %s;
alternate-normal-foreground: %s;
alternate-urgent-background: %s;
alternate-urgent-foreground: %s;

selected-active-background: %s;
selected-active-foreground: %s;
selected-normal-background: %s;
selected-normal-foreground: %s;
selected-urgent-background: %s;
selected-urgent-foreground: %s;

background-color: %s;
background: rgba(0,0,0,0.85);
foreground: %s;
border-color: %s;

color0: %s;
color1: %s;
color2: %s;
color3: %s;
color4: %s;
color5: %s;
color6: %s;
color7: %s;
color8: %s;
color9: %s;
color10: %s;
color11: %s;
color12: %s;
color13: %s;
color14: %s;
color15: %s;
}
]],
    colors.mPrimary,
    colors.mOnPrimary,
    colors.mSurface,
    colors.mOnSurface,
    colors.mError,
    colors.mOnPrimary,
    colors.mSurfaceVariant,
    colors.mOnSurface,
    colors.mSurface,
    colors.mOnSurface,
    colors.mSurface,
    colors.mOnSurface,
    colors.mPrimary,
    colors.mOnPrimary,
    colors.mPrimary,
    colors.mOnPrimary,
    colors.mSurfaceVariant,
    colors.mOnPrimary,
    colors.mSurface,
    colors.mOnSurface,
    colors.mPrimary,
    colors.mSurface,
    colors.mShadow,
    colors.mSurfaceVariant,
    colors.mOutline,
    colors.mSurfaceVariant,
    colors.mOutline,
    colors.mSurfaceVariant,
    colors.mPrimary,
    colors.mSurfaceVariant,
    colors.mShadow,
    colors.mOutline,
    colors.mSecondary,
    colors.mPrimary,
    colors.mError,
    colors.mTertiary,
    colors.mOnSurface
  )
end

---@param colors Hyprconf.NoctaliaMaterialColors
---@return string
local function generate_hypr_effect_colors(colors)
  local palette = color.material_terminal_palette(colors)
  local lines = {
    "# Generated Noctalia material colors for Hyprland",
    "# Generated from Noctalia Material colors by lua/hyprconf/theme/noctalia.lua",
    "",
  }

  ---@type string[]
  local order = {
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

  for _, name in ipairs(order) do
    lines[#lines + 1] =
      string.format("$%s = %s", name, color.rgb(palette[name]))
  end

  return table.concat(lines, "\n") .. "\n"
end

---@param colors Hyprconf.NoctaliaMaterialColors
---@return string
local function generate_hypr_colors(colors)
  return string.format(
    [[-- Generated by lua/hyprconf/theme/noctalia.lua
return {
  primary = %q,
  surface = %q,
  secondary = %q,
  error = %q,
  tertiary = %q,
  surface_lowest = %q,
}
]],
    hex_to_rgb(colors.mPrimary),
    hex_to_rgb(colors.mSurface),
    hex_to_rgb(colors.mSecondary),
    hex_to_rgb(colors.mError),
    hex_to_rgb(colors.mTertiary),
    hex_to_rgb(colors.mShadow)
  )
end

---@class Hyprconf.HyprMonitor
---@field name? string
---@field focused? boolean

---@return string?
local function focused_monitor()
  local handle = io.popen("hyprctl monitors -j 2>/dev/null")
  if not handle then
    return nil
  end

  local content = handle:read("*a")
  handle:close()

  local ok, monitors = pcall(json.decode, content)
  if not ok or type(monitors) ~= "table" then
    return nil
  end

  ---@cast monitors Hyprconf.HyprMonitor[]
  for _, monitor in ipairs(monitors) do
    if monitor.focused and monitor.name then
      return monitor.name
    end
  end

  return nil
end

---@class Hyprconf.NoctaliaWallpaperEntry
---@field dark? string
---@field light? string
---@field path? string
---@field [1]? string

---@alias Hyprconf.NoctaliaWallpaperValue string|Hyprconf.NoctaliaWallpaperEntry

---@class Hyprconf.NoctaliaWallpapers
---@field wallpapers? table<string, Hyprconf.NoctaliaWallpaperValue>
---@field defaultWallpaper? Hyprconf.NoctaliaWallpaperValue

---@param value Hyprconf.NoctaliaWallpaperValue|Hyprconf.JsonValue
---@return string?
local function wallpaper_path(value)
  if type(value) == "string" then
    return value
  end

  if type(value) ~= "table" then
    return nil
  end

  return value.dark or value.light or value.path or value[1]
end

---@param wallpapers table<string, Hyprconf.NoctaliaWallpaperValue>
---@return string?
local function first_wallpaper(wallpapers)
  for _, value in pairs(wallpapers) do
    local path = wallpaper_path(value)
    if path then
      return path
    end
  end

  return nil
end

---@return string?
local function current_wallpaper()
  local ok, data = pcall(function()
    return json.decode(json.read(paths.wallpapers))
  end)

  if not ok or type(data) ~= "table" then
    return nil
  end

  ---@cast data Hyprconf.NoctaliaWallpapers
  local wallpapers = data.wallpapers
  if type(wallpapers) ~= "table" then
    return wallpaper_path(data.defaultWallpaper)
  end

  local monitor = focused_monitor()
  return (monitor and wallpaper_path(wallpapers[monitor]))
    or wallpaper_path(wallpapers[""])
    or first_wallpaper(wallpapers)
    or wallpaper_path(data.defaultWallpaper)
end

---@param colors Hyprconf.NoctaliaMaterialColors
---@return nil
local function sync_wallpaper_cache(colors)
  local wallpaper = current_wallpaper()
  if not wallpaper then
    return
  end

  local probe = io.open(wallpaper, "r")
  if not probe then
    return
  end
  probe:close()

  os.execute("mkdir -p " .. shell_quote(paths.effects_cache))
  os.execute(
    "ln -sf "
      .. shell_quote(wallpaper)
      .. " "
      .. shell_quote(paths.effects_cache .. "/wallpaper-source")
  )
  os.execute(
    "ln -sf "
      .. shell_quote(wallpaper)
      .. " "
      .. shell_quote(paths.effects_cache .. "/wallpaper-current")
  )

  local cmd = table.concat({
    "magick",
    shell_quote(wallpaper),
    "-blur 0x18",
    "-fill " .. shell_quote(colors.mSurface),
    "-colorize 30",
    "-quality 90",
    shell_quote(paths.effects_cache .. "/wallpaper-modified"),
  }, " ")
  os.execute(cmd .. " >/dev/null 2>&1 || true")
end

---@return boolean
function M.apply()
  local ok, colors = pcall(load_material_colors, paths.colors)
  if not ok then
    notify(
      "Noctalia Theme",
      paths.colors .. " not found or unreadable",
      "critical"
    )
    return false
  end
  colors = material_hex(colors)

  write_file(paths.qml, generate_qml(colors))
  write_file(paths.rofi, generate_rofi(colors))
  write_file(paths.effects_colors, generate_hypr_effect_colors(colors))
  write_file(paths.generated, generate_hypr_colors(colors))
  sync_wallpaper_cache(colors)

  os.execute("hyprctl reload config-only >/dev/null 2>&1 || true")
  notify(
    "Noctalia Theme",
    "Applied Material Design colors to rofi, quickshell, and Hyprland."
  )
  return true
end

return M
