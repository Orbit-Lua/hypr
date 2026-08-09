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

---@alias Hyprconf.TaggedWindow [string, Hyprconf.WindowMatch]

---@class Hyprconf.Rules
---@field setup fun()
local M = {}

---@param spec Hyprconf.WindowRule
---@return any
local function wr(spec)
  return hl.window_rule(spec)
end

---@param spec Hyprconf.LayerRule
---@return any
local function lr(spec)
  return hl.layer_rule(spec)
end

local tag_rule_index = 0
---@param name string
---@param match Hyprconf.WindowMatch
---@return any
local function tag(name, match)
  tag_rule_index = tag_rule_index + 1
  return wr({
    name = string.format("tag-%03d-%s", tag_rule_index, name),
    match = match,
    tag = "+" .. name,
  })
end

---@type Hyprconf.TaggedWindow[]
local tagged_windows = {
  {
    "browser",
    {
      class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$",
    },
  },
  { "browser", { class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$" } },
  { "browser", { class = "^(chrome-.+-Default)$" } },
  { "browser", { class = "^([Cc]hromium)$" } },
  {
    "browser",
    { class = "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$" },
  },
  { "browser", { class = "^(Brave-browser(-beta|-dev|-unstable)?)$" } },
  { "browser", { class = "^([Tt]horium-browser|[Cc]achy-browser)$" } },
  { "browser", { class = "^(zen-alpha|zen)$" } },
  { "quick-cheat", { title = "^(Quick Cheat Sheet)$" } },
  { "quick-settings", { title = "^(Quick Settings)$" } },
  { "nwg-settings", { class = "^(nwg-displays|nwg-look)$" } },
  { "terminal", { class = "^(Alacritty|kitty|kitty-dropterm)$" } },
  { "email", { class = "^([Tt]hunderbird|org.mozilla.Thunderbird)$" } },
  { "email", { class = "^(eu.betterbird.Betterbird)$" } },
  { "email", { class = "^(org.gnome.Evolution)$" } },
  { "projects", { class = "^(codium|codium-url-handler|VSCodium)$" } },
  { "projects", { class = "^(VSCode|code|code-url-handler)$" } },
  { "projects", { class = "^(jetbrains-.+)$" } },
  { "projects", { class = "^(dev.zed.Zed|antigravity)$" } },
  { "screenshare", { class = "^(com.obsproject.Studio)$" } },
  { "im", { class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$" } },
  { "im", { class = "^([Ff]erdium)$" } },
  { "im", { class = "^([Ww]hatsapp-for-linux)$" } },
  {
    "im",
    { class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$" },
  },
  { "im", { class = "^(teams-for-linux)$" } },
  { "im", { class = "^(im.riot.Riot|Element)$" } },
  { "games", { class = "^(gamescope)$" } },
  { "games", { class = "^(steam_app_\\d+)$" } },
  { "gamestore", { class = "^([Ss]team)$" } },
  { "gamestore", { title = "^([Ll]utris)$" } },
  { "gamestore", { class = "^(com.heroicgameslauncher.hgl)$" } },
  {
    "file-manager",
    { class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmmanfm-qt)$" },
  },
  { "file-manager", { class = "^(app.drey.Warp)$" } },
  { "multimedia", { class = "^([Aa]udacious)$" } },
  { "multimedia_video", { class = "^([Mm]pv|vlc)$" } },
  { "settings", { title = "^(ROG Control)$" } },
  { "settings", { class = "^(wihotspot(-gui)?)$" } },
  { "settings", { class = "^([Bb]aobab|org.gnome.[Bb]aobab)$" } },
  { "settings", { class = "^(gnome-disks|wihotspot(-gui)?)$" } },
  { "settings", { title = "(Kvantum Manager)" } },
  { "settings", { class = "^(file-roller|org.gnome.FileRoller)$" } },
  {
    "settings",
    { class = "^(nm-applet|nm-connection-editor|blueman-manager)$" },
  },
  {
    "settings",
    {
      class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$",
    },
  },
  { "settings", { class = "^(qt5ct|qt6ct)$" } },
  { "settings", { class = "(xdg-desktop-portal-gtk)" } },
  { "settings", { class = "^(org.kde.polkit-kde-authentication-agent-1)$" } },
  { "settings", { class = "^([Rr]ofi)$" } },
  { "settings", { class = "^(btrfs-assistant)$" } },
  { "settings", { class = "^(timeshift-gtk)$" } },
  {
    "viewer",
    {
      class = "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$",
    },
  },
  { "viewer", { class = "^(evince)$" } },
  { "viewer", { class = "^(eog|org.gnome.Loupe)$" } },
}

---@type Hyprconf.WindowRule[]
local window_rules = {
  {
    name = "multimedia-video-no-blur",
    match = { tag = "multimedia_video" },
    no_blur = true,
    opacity = "1.0",
  },
  {
    name = "multimedia-no-blur",
    match = { tag = "multimedia" },
    no_blur = true,
    opacity = "1.0",
  },
  {
    name = "idle-inhibit-fullscreen",
    match = { fullscreen = true },
    idle_inhibit = "fullscreen",
  },
  {
    name = "quick-cheat-center",
    match = { tag = "quick-cheat" },
    center = true,
  },
  {
    name = "nwg-settings-center",
    match = { tag = "nwg-settings" },
    center = true,
  },
  {
    name = "rog-control-center",
    match = { title = "^(ROG Control)$" },
    center = true,
  },
  {
    name = "keybindings-center",
    match = { title = "^(Keybindings)$" },
    center = true,
  },
  {
    name = "audio-settings-center",
    match = {
      class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$",
    },
    center = true,
  },
  {
    name = "ferdium-center",
    match = { class = "^([Ff]erdium)$" },
    center = true,
    float = true,
    size = "(monitor_w*0.6) (monitor_h*0.7)",
  },
  {
    name = "quick-cheat-float",
    match = { tag = "quick-cheat" },
    float = true,
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
    name = "zoom-onedriver-float",
    match = { class = "([Zz]oom|onedriver|onedriver-launcher)" },
    float = true,
  },
  {
    name = "calculator-float",
    match = { class = "(org.gnome.Calculator|qalculate-gtk)" },
    float = true,
  },
  {
    name = "mpv-float",
    match = { class = "^(mpv|com.github.rafostar.Clapper)$" },
    float = true,
  },
  {
    name = "auth-float",
    match = { title = "^(Authentication Required)$" },
    float = true,
    center = true,
  },
  {
    name = "codium-dialog-float",
    match = {
      class = "(codium|codium-url-handler|VSCodium)",
      title = "negative:(.*codium.*|.*VSCodium.*)",
    },
    float = true,
  },
  {
    name = "heroic-dialog-float",
    match = {
      class = "^(com.heroicgameslauncher.hgl)$",
      title = "negative:(Heroic Games Launcher)",
    },
    float = true,
  },
  {
    name = "steam-dialog-float",
    match = { class = "^([Ss]team)$", title = "negative:^([Ss]team)$" },
    float = true,
  },
  {
    name = "add-folder-dialog",
    match = { title = "^(Add Folder to Workspace)$" },
    float = true,
    size = "(monitor_w*0.7) (monitor_h*0.6)",
    center = true,
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
    name = "sddm-background-dialog",
    match = { title = "^(SDDM Background)$" },
    float = true,
    center = true,
    size = "(monitor_w*0.16) (monitor_h*0.12)",
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
  {
    name = "projects-opacity",
    match = { tag = "projects" },
    opacity = "0.9 0.8",
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
    name = "editor-opacity",
    match = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" },
    opacity = "0.8 0.7",
  },
  {
    name = "deluge-opacity",
    match = { class = "^(deluge)$" },
    opacity = "0.9 0.8",
  },
  {
    name = "seahorse-opacity",
    match = { class = "^(seahorse)$" },
    opacity = "0.9 0.8",
  },
  {
    name = "pip-opacity",
    match = { title = "^(Picture-in-Picture)$" },
    opacity = "0.95 0.75",
  },
  {
    name = "games-no-blur",
    match = { tag = "games" },
    no_blur = true,
    fullscreen = 0,
  },
  {
    name = "jetbrains-no-initial-focus",
    match = { class = "^(jetbrains-*)" },
    no_initial_focus = true,
  },
  {
    name = "wind-no-initial-focus",
    match = { title = "^(wind.*)$" },
    no_initial_focus = true,
  },
  {
    name = "Whatsapp-zapzap",
    match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" },
    size = "(monitor_w*0.6) (monitor_h*0.7)",
    center = true,
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
    name = "notion-workspace",
    match = { class = "^([Nn]otion)$" },
    workspace = "10",
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
    name = "steam-app",
    match = { class = "^(steam_app.*)$" },
    workspace = "10",
    no_initial_focus = true,
  },
  {
    name = "stalker",
    match = { title = "^(STALKER.*)$" },
    workspace = "10",
    no_initial_focus = true,
  },
}

---@type Hyprconf.LayerRule[]
local layer_rules = {
  { name = "rofi", match = { namespace = "rofi" }, blur = true },
  {
    name = "notifications",
    match = { namespace = "notifications" },
    blur = true,
  },
  {
    name = "noctalia-bar",
    match = { namespace = "noctalia-bar-.*$" },

    -- other namespace:
    -- noctalia-panel
    -- noctalia-attached-panel
    -- noctalia-dock
    -- noctalia-notification
    -- noctalia-osd
    -- noctalia-launcher-overlay
    -- noctalia-desktop-widget-<type>-<id>

    -- regex example:
    -- ^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$

    ignore_alpha = 0,
  },
  {
    name = "noctalia-panel",
    match = { namespace = "noctalia-attached-panel" },
    ignore_alpha = 0,
  },
}

---@return nil
function M.setup()
  for _, item in ipairs(tagged_windows) do
    tag(item[1], item[2])
  end

  for _, rule in ipairs(window_rules) do
    wr(rule)
  end

  for _, rule in ipairs(layer_rules) do
    lr(rule)
  end
end

return M
