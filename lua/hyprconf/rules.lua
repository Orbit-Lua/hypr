---@class Hyprconf.WindowMatch
---@field class? string Window class regex.
---@field title? string Window title regex.
---@field initial_title? string Initial window title regex.
---@field tag? string Hyprland window tag matcher.
---@field fullscreen? boolean

---@class Hyprconf.WindowRule
---@field name string Rule identifier.
---@field match Hyprconf.WindowMatch
---@field tag? string Tag operation such as "+browser".
---@field no_blur? boolean
---@field opacity? string Hyprland opacity expression.
---@field idle_inhibit? "fullscreen"|"focus"|"always"|"none"
---@field center? boolean
---@field float? boolean
---@field size? string Hyprland size expression.
---@field fullscreen? integer|boolean
---@field no_initial_focus? boolean
---@field move? string
---@field pin? boolean
---@field keep_aspect_ratio? boolean
---@field workspace? string

---@class Hyprconf.LayerMatch
---@field namespace? string Layer namespace regex.

---@class Hyprconf.LayerRule
---@field name string Rule identifier.
---@field match Hyprconf.LayerMatch
---@field blur? boolean
---@field ignore_alpha? number
---@field blur_popups? boolean
---@field no_anim? boolean

---@alias Hyprconf.TaggedWindow [string, Hyprconf.WindowMatch]

---@class Hyprconf.Rules
---@field setup fun()
local M = {}

---@param spec Hyprconf.WindowRule
---@return any
local function window_rule(spec)
  return hl.window_rule(spec)
end

---@param spec Hyprconf.LayerRule
---@return any
local function layer_rule(spec)
  return hl.layer_rule(spec)
end

---@param spec HL.WorkspaceRuleSpec
---@return any
local function workspace_rule(spec)
  return hl.workspace_rule(spec)
end

local tag_rule_index = 0
---@param name string
---@param match Hyprconf.WindowMatch
---@return any
local function tag(name, match)
  tag_rule_index = tag_rule_index + 1
  return window_rule({
    name = string.format("tag-%03d-%s", tag_rule_index, name),
    match = match,
    tag = "+" .. name,
  })
end

---@type Hyprconf.TaggedWindow[]
local tagged_windows = {
  { "browser", { class = "^(zen|zen-alpha)$" } },
  { "quick-cheat", { title = "^(Quick Cheat Sheet)$" } },
  { "nwg-settings", { class = "^(nwg-displays|nwg-look)$" } },
  { "terminal", { class = "^(com\\.mitchellh\\.ghostty|kitty)$" } },
  { "im", { class = "^([Vv]esktop)$" } },
  { "games", { class = "^(gamescope)$" } },
  { "games", { class = "^(steam_app_\\d+)$" } },
  { "file-manager", { class = "^([Tt]hunar)$" } },
  { "multimedia-video", { class = "^(mpv|vlc)$" } },
  { "settings", { class = "^(org\\.gnome\\.[Bb]aobab|[Bb]aobab)$" } },
  {
    "settings",
    { class = "^(nm-applet|nm-connection-editor|blueman-manager)$" },
  },
  { "settings", { class = "^(pavucontrol|org\\.pulseaudio\\.pavucontrol)$" } },
  { "settings", { class = "^(qt5ct|qt6ct)$" } },
  { "settings", { class = "(xdg-desktop-portal-gtk)" } },
  { "viewer", { class = "^(org\\.gnome\\.Loupe)$" } },
}

---@type Hyprconf.WindowRule[]
local window_rules = {
  {
    name = "multimedia-video-no-blur",
    match = { tag = "multimedia-video" },
    no_blur = true,
    opacity = "1.0",
  },
  {
    name = "idle-inhibit-fullscreen",
    match = { fullscreen = true },
    idle_inhibit = "fullscreen",
  },
  {
    name = "quick-cheat-float",
    match = { tag = "quick-cheat" },
    float = true,
    center = true,
    size = "(monitor_w*0.65) (monitor_h*0.9)",
  },
  {
    name = "settings-float",
    match = { tag = "settings" },
    float = true,
    center = true,
    size = "(monitor_w*0.7) (monitor_h*0.7)",
  },
  {
    name = "viewer-float",
    match = { tag = "viewer" },
    float = true,
    center = true,
  },
  {
    name = "nwg-settings-float",
    match = { tag = "nwg-settings" },
    float = true,
    center = true,
  },
  {
    name = "calculator-float",
    match = { class = "^(qalculate-gtk)$" },
    float = true,
  },
  {
    name = "mpv-float",
    match = { class = "^(mpv)$" },
    float = true,
  },
  {
    name = "auth-float",
    match = { title = "^(Authentication Required)$" },
    float = true,
    center = true,
  },
  {
    name = "steam-dialog-float",
    match = { class = "^([Ss]team)$", title = "negative:^([Ss]team)$" },
    float = true,
  },
  {
    name = "save-as-dialog",
    match = { title = "^(Save As)$" },
    float = true,
    size = "(monitor_w*0.7) (monitor_h*0.6)",
    center = true,
  },
  {
    name = "open-files-dialog",
    match = { initial_title = "(Open Files)" },
    float = true,
    size = "(monitor_w*0.7) (monitor_h*0.6)",
  },
  {
    name = "yad-dialog",
    match = { class = "^(yad)$" },
    float = true,
    center = true,
    size = "(monitor_w*0.2) (monitor_h*0.2)",
  },
  {
    name = "donate-dialog",
    match = { class = "^(hyprland-donate-screen)$" },
    float = true,
    center = true,
  },
  {
    name = "browser-opacity",
    match = { tag = "browser" },
    opacity = "0.99 0.8",
  },
  { name = "im-opacity", match = { tag = "im" }, opacity = "0.94 0.86" },
  {
    name = "file-manager-opacity",
    match = { tag = "file-manager" },
    opacity = "0.9 0.8",
  },
  {
    name = "terminal-opacity",
    match = { tag = "terminal" },
    opacity = "0.9 0.7",
  },
  {
    name = "settings-opacity",
    match = { tag = "settings" },
    opacity = "0.8 0.7",
  },
  {
    name = "seahorse-opacity",
    match = { class = "^(seahorse)$" },
    opacity = "0.9 0.8",
  },
  {
    name = "games-no-blur",
    match = { tag = "games" },
    no_blur = true,
    fullscreen = 0,
  },
  {
    name = "Picture-in-Picture",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    move = "72% 7%",
    opacity = "0.95 0.75",
    pin = true,
    keep_aspect_ratio = true,
    size = "(monitor_w*0.3) (monitor_h*0.3)",
  },
  {
    name = "Thunar-Progress-bar",
    match = { class = "^(thunar)$", title = "^(File Operation Progress)$" },
    float = true,
    center = true,
    size = "(monitor_w*0.26) (monitor_h*0.18)",
  },
  {
    name = "line-main-tag",
    match = { class = "^(line.exe)$", title = "^(LINE)$" },
    tag = "+line_main_window",
  },
  {
    name = "line-sub-tag",
    match = { class = "^(line.exe)$", title = "^$" },
    tag = "+line_sub_window",
  },
  {
    name = "line-explorer-tag",
    match = { class = "^(explorer.exe)$" },
    tag = "+line_explorer",
  },
  {
    name = "line-main-workspace",
    match = { tag = "line_main_window*" },
    workspace = "9",
    float = true,
  },
  {
    name = "line-sub-workspace",
    match = { tag = "line_sub_window*" },
    workspace = "9",
    float = true,
  },
  {
    name = "line-explorer-workspace",
    match = { tag = "line_explorer*" },
    workspace = "9",
    float = true,
  },
  {
    name = "steam",
    match = { class = "steam" },
    workspace = "9",
    no_initial_focus = true,
  },
  {
    name = "gamescope",
    match = { class = "^(gamescope)$" },
    workspace = "10",
    no_initial_focus = true,
  },
}

---@type Hyprconf.LayerRule[]
local layer_rules = {
  {
    name = "vicinae",
    match = { namespace = "vicinae" },
    blur = true,
    ignore_alpha = 0,
    no_anim = true,
  },
  {
    name = "notifications",
    match = { namespace = "notifications" },
    blur = true,
  },
  {
    name = "noctalia-surfaces",
    match = {
      namespace = "^noctalia-(bar-.+|panel|attached-panel|notification|osd)$",
    },
    blur = true,
    blur_popups = true,
    no_anim = true,
    ignore_alpha = 0,
  },
}

---@type HL.WorkspaceRuleSpec[]
local persistent_workspaces = {
  { workspace = "1", persistent = true },
  { workspace = "2", persistent = true },
  { workspace = "3", persistent = true },
  { workspace = "4", persistent = true },
  { workspace = "5", persistent = true },
}

---@return nil
function M.setup()
  for _, item in ipairs(tagged_windows) do
    tag(item[1], item[2])
  end

  for _, rule in ipairs(window_rules) do
    window_rule(rule)
  end

  for _, rule in ipairs(layer_rules) do
    layer_rule(rule)
  end

  for _, rule in ipairs(persistent_workspaces) do
    workspace_rule(rule)
  end
end

return M
