# Hyprland Lua Config

Personal Hyprland 0.55+ Lua configuration for one active workstation. It is
organized as small Lua modules plus a helper CLI for rofi menus, profile
selection, screenshots, effects, and session tasks.

This is not a generic Hyprland template. Most paths assume the checkout lives at
`~/.config/hypr`; helper commands can use another location through
`HYPR_CONFIG_DIR`.

## Requirements

Core runtime:

- Hyprland 0.55+ with Lua config support
- `lua` on `PATH`
- `uwsm`
- `rofi`
- `kitty`
- `thunar`
- `notify-send`
- Hyprland and Wayland desktop portals
- A polkit agent matching a path in `lua/config/polkit.toml`

Feature-specific helpers also use local desktop tools:

- Quickshell and AGS: `qs`, `ags`
- Clipboard: `wl-paste`, `wl-copy`, `cliphist`
- Screenshots: `grim`, `slurp`, `swappy`, `xdg-user-dir`, `xdg-open`
- Theme and media helpers: `magick`, `pw-play` or `paplay` or `aplay`
- Autostart integrations: `rog-control-center`, `mcontrolcenter`,
  `polychromatic-tray-applet`, `nm-applet`, `blueman-applet`, `fcitx5`,
  Vesktop, Remmina, and Tailscale

Runtime helpers call `lua` directly. LuaJIT is fine only if it provides the
`lua` command used by the scripts.

## Layout

```text
hyprland.lua                 Hyprland Lua entrypoint
application-style.conf       hyprland-qt-support style settings
lua/bin/hypr.lua             Runtime helper CLI and command inventory
lua/hyprconf/init.lua        Core module load order
lua/hyprconf/                Hyprland config modules and shared helpers
lua/hyprconf/commands/       Runtime helper implementations
lua/hyprconf/theme/          Noctalia theme generation
lua/config/*.toml            Structured autostart, menu, profile, and effect config
lua/user/*.lua               Active machine-local profile files
profiles/<category>/*.lua    Reusable profile presets
profiles/.selected/          Selected profile state
deps/rofi/                   Rofi defaults copied only when missing
effects/                     Generated runtime effect state
```

Core modules load in this order:

```text
env
deps
monitors
autostart
options
gestures
animations
binds
rules
```

## Install

Place the repository at the expected path:

```sh
git clone git@github.com:Orbit-Lua/hypr.git ~/.config/hypr
```

Start Hyprland with the Lua entrypoint:

```sh
hyprland --config ~/.config/hypr/hyprland.lua
```

For another checkout location, pass Hyprland the absolute config path and set
`HYPR_CONFIG_DIR=/path/to/config` for helper commands.

## Helper CLI

Run helper commands with:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua <command>
```

Examples:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua sync-deps
lua ~/.config/hypr/lua/bin/hypr.lua quick-settings
lua ~/.config/hypr/lua/bin/hypr.lua keybinds
lua ~/.config/hypr/lua/bin/hypr.lua profile-selector
lua ~/.config/hypr/lua/bin/hypr.lua screenshot --area
```

Commands defined by `lua/bin/hypr.lua`:

```text
change-blur
change-layout
clip-manager
game-mode
key-hints
keybinds
keybinds-layout-init
kill-active
kitty-themes
noctalia-theme
overview
polkit
portal-hyprland
profile-selector
quick-settings
rainbow-border
rainbow-menu
refresh
rofi-search
rofi-theme
screenshot
sound
sync-deps
touchpad
zsh-theme
```

Most helper commands sync rofi defaults first. `sync-deps` copies files from
`deps/rofi/` into `${ROFI_CONFIG_DIR:-~/.config/rofi}` only when the target file
does not already exist.

## Main Workflows

Profiles:

- `profile-selector` reads categories from `profiles/`.
- Presets live in `profiles/animation/` and `profiles/monitor/`.
- Active files live in `lua/user/animations.lua` and `lua/user/monitors.lua`.
- Selected preset names are stored under `profiles/.selected/`.

Menus:

- `quick-settings` reads `lua/config/quick-settings.toml`.
- `key-hints` reads `lua/config/key-hints.toml` and opens a `yad` cheat sheet.
- `keybinds` scans `lua/hyprconf/binds.lua` and opens a searchable rofi list.
- `clip-manager` wraps `cliphist` with rofi actions for select, delete, and wipe.

Effects and themes:

- `rainbow-menu` writes `effects/rainbow-border-mode`.
- `rainbow-border` applies runtime border colors from generated effect colors
  when available.
- `noctalia-theme` reads Noctalia color and wallpaper state, then writes
  generated Quickshell, rofi, Hyprland, and cache files.

Screenshots:

- `screenshot --now` captures the full screen.
- `screenshot --area` uses `slurp` to select a region.
- `screenshot --swappy` captures a region and opens Swappy.
- `screenshot --in5` and `screenshot --in10` delay capture.
- `screenshot --active` captures the active window geometry.

## Side Effects

Several commands intentionally touch files or processes outside this repository:

- `rofi-theme` edits `${ROFI_CONFIG_DIR:-~/.config/rofi}/config.rasi`.
- `kitty-themes` edits `~/.config/kitty/kitty.conf` and signals running kitty
  processes to reload.
- `zsh-theme` edits `~/.zshrc`.
- `portal-hyprland` restarts desktop portal processes.
- `profile-selector` copies presets into `lua/user/`, writes
  `profiles/.selected/<category>`, and reloads Hyprland.
- `screenshot` writes PNG files under the Pictures screenshots directory and
  copies captures to the clipboard.
- `noctalia-theme` writes generated files under `~/.config/quickshell`,
  `~/.config/rofi`, `~/.cache/hypr/effects`, `effects/`, and
  `lua/hyprconf/generated/`.

## Configuration

Common edit points:

- Defaults, applications, paths, search URL, and touchpad device:
  `lua/hyprconf/context.lua`
- Autostart commands: `lua/config/autostart.toml`
- Keybinds: `lua/hyprconf/binds.lua`
- Window and layer rules: `lua/hyprconf/rules.lua`
- Appearance, input, gestures, layout, cursor, and render options:
  `lua/hyprconf/options.lua`
- Quick settings rows: `lua/config/quick-settings.toml`
- Key hint rows: `lua/config/key-hints.toml`
- Profile targets and rofi themes: `lua/config/profiles.toml`
- Polkit candidates: `lua/config/polkit.toml`
- Rainbow border and sound settings: `lua/config/effects.toml`

Runtime helper environment overrides:

```text
HYPR_CONFIG_DIR              default: ~/.config/hypr
ROFI_CONFIG_DIR              default: ~/.config/rofi
EFFECTS_DIR                  default: $HYPR_CONFIG_DIR/effects
RAINBOW_BORDER_MODE_FILE     default: $EFFECTS_DIR/rainbow-border-mode
NOTIFY_APP_NAME              default: Hyprland
NOTIFY_DEFAULT_TIMEOUT       default: 3000
NOTIFY_FALLBACK_ICON         default: empty
TOUCHPAD_DEVICE              default: lua/hyprconf/context.lua value
TERMINAL                     default for quick edit actions: kitty
EDITOR                       default for quick edit actions: nvim
```

## Development

Install the tools used by the Makefile:

- `stylua`
- `luacheck`
- `hyprland`

Run the standard readiness check from the repository root:

```sh
make ready
```

This runs:

- `make fmt`: formats Lua files with `stylua`
- `make lint`: lints Lua files with `luacheck`
- `make test`: verifies Hyprland can parse `~/.config/hypr/hyprland.lua`

`make test` runs:

```sh
hyprland --verify-config --config ~/.config/hypr/hyprland.lua
```

This validates config parsing only. It does not exercise rofi menus, profile
copying, screenshots, keybind actions, autostart commands, desktop portals, or
external app integrations. In a live session, validation may still trigger
reload hooks such as `refresh`.

Useful non-interactive smoke checks:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua sync-deps
lua ~/.config/hypr/lua/bin/hypr.lua not-a-command
```

Treat `effects/` as generated runtime state. Preserve `lua/user/` and
`profiles/.selected/` unless you are intentionally changing active profile
state.

## Credit

Based in part on
[Hyprland-Dots](https://github.com/LinuxBeginnings/Hyprland-Dots/tree/main/config/hypr).
