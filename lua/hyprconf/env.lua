---@class Hyprconf.Env
---@field setup fun()
local M = {}

---@type table<string, string>
local variables = {
  -- Default applications
  EDITOR = "nvim",

  -- Wayland session identity
  XDG_CURRENT_DESKTOP = "Hyprland",
  XDG_SESSION_DESKTOP = "Hyprland",
  XDG_SESSION_TYPE = "wayland",

  -- Toolkit backend selection
  GDK_BACKEND = "wayland,x11,*",
  QT_QPA_PLATFORM = "wayland;xcb",
  CLUTTER_BACKEND = "wayland",

  -- Toolkit scaling and appearance
  QT_AUTO_SCREEN_SCALE_FACTOR = "1",
  QT_WAYLAND_DISABLE_WINDOWDECORATION = "1",
  QT_QPA_PLATFORMTHEME = "gtk3",
  QT_SCALE_FACTOR = "1",
  QT_QUICK_CONTROLS_STYLE = "org.hyprland.style",
  GDK_SCALE = "1",

  -- Cursor theme
  HYPRCURSOR_THEME = "Bibata-Modern-Ice",
  HYPRCURSOR_SIZE = "24",
  XCURSOR_THEME = "Bibata-Modern-Ice",
  XCURSOR_SIZE = "24",

  -- Browser, Electron, and graphics compatibility
  MOZ_ENABLE_WAYLAND = "1",
  ELECTRON_OZONE_PLATFORM_HINT = "auto",
  __GLX_VENDOR_LIBRARY_NAME = "mesa",

  -- Input method
  QT_IM_MODULE = "fcitx",
  XMODIFIERS = "@im=fcitx",
  GLFW_IM_MODULE = "ibus",
  INPUT_METHOD = "fcitx",
  IMSETTINGS_MODULE = "fcitx",
  SDL_IM_MODULE = "fcitx",
}

---@return nil
function M.setup()
  for name, value in pairs(variables) do
    hl.env(name, value)
  end
end

return M
