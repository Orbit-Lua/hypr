# Hyprland Lua Workstation Config

Personal Hyprland 0.55+ configuration written in Lua for one active workstation.
It wires together Hyprland options, monitor and animation profiles, rofi menus,
Noctalia material colors, screenshots, clipboard tools, desktop portals, and a
small helper CLI.

This repository is intentionally specific to this machine. It assumes the normal
checkout path is `~/.config/hypr`, default apps are `kitty` and `thunar`, the
main modifier is `SUPER`, and several workflows depend on local Wayland desktop
tools.

> [!IMPORTANT]
> This is not a generic Hyprland starter template. Paths, autostart entries,
> device names, and profile state are tuned for the current workstation.

## Features

- Lua entrypoint for Hyprland with a fixed module load order.
- Runtime helper CLI at `lua/bin/hypr.lua`.
- Rofi menus for quick settings, keybind search, clipboard history, web search,
  theme selection, and profile selection.
- Profile presets for animations and monitors, with active local profiles under
  `lua/user/`.
- Noctalia material color generation for Quickshell, rofi, Hyprland effects,
  and cached wallpaper effects.
- Screenshot helpers for full screen, region, delayed, active window, and
  Swappy annotation flows.
- Structured TOML config for autostart, menu rows, profile metadata, polkit
  candidates, quick settings, key hints, and effects.

## Requirements

Core runtime:

- Hyprland 0.55+ with Lua config support.
- `lua` on `PATH`; runtime helpers invoke `lua` directly.
- `uwsm`, `rofi`, `kitty`, `thunar`, `notify-send`.
- A desktop portal stack and a polkit agent matching
  `lua/config/polkit.toml`.

Feature-specific tools:

- Shells and panels: `qs`, `ags`.
- Clipboard: `wl-paste`, `wl-copy`, `cliphist`.
- Screenshots: `grim`, `slurp`, `swappy`, `xdg-user-dir`, `xdg-open`.
- Sounds and theme effects: `pw-play` or `paplay` or `aplay`, plus `magick`.
- Autostart integrations: `rog-control-center`, `mcontrolcenter`,
  `polychromatic-tray-applet`, `nm-applet`, `blueman-applet`, `fcitx5`,
  Vesktop, Remmina, and Tailscale.

Development tools:

- `stylua`
- `luacheck`
- `hyprland`

## Repository Layout

```text
hyprland.lua                 Hyprland Lua entrypoint
application-style.conf       hyprland-qt-support style settings
lua/bin/hypr.lua             helper CLI and command inventory
lua/hyprconf/init.lua        core module load order
lua/hyprconf/                Hyprland config modules and shared helpers
lua/hyprconf/commands/       runtime command implementations
lua/hyprconf/theme/          Noctalia theme generation
lua/config/*.toml            structured runtime data
lua/user/*.lua               active machine-local profiles
profiles/<category>/*.lua    reusable profile presets
profiles/.selected/          selected profile state
deps/rofi/                   rofi defaults copied only when missing
effects/                     generated runtime effect state
```

Core modules load in this order:

```text
env -> deps -> monitors -> autostart -> options -> gestures -> animations -> binds -> rules
```

## Quick Start

Place the repository at the expected path:

```sh
git clone <repo-url> ~/.config/hypr
```

Start Hyprland with the Lua entrypoint:

```sh
hyprland --config ~/.config/hypr/hyprland.lua
```

If you use a different checkout path, start Hyprland with the absolute path and
set `HYPR_CONFIG_DIR` for helper commands:

```sh
HYPR_CONFIG_DIR=/path/to/hypr lua /path/to/hypr/lua/bin/hypr.lua sync-deps
```

## Helper CLI

Run commands with:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua <command>
```

Common examples:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua sync-deps
lua ~/.config/hypr/lua/bin/hypr.lua quick-settings
lua ~/.config/hypr/lua/bin/hypr.lua keybinds
lua ~/.config/hypr/lua/bin/hypr.lua profile-selector
lua ~/.config/hypr/lua/bin/hypr.lua screenshot --area
lua ~/.config/hypr/lua/bin/hypr.lua noctalia-theme
```

Available commands are defined in `lua/bin/hypr.lua`:

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

Most helper commands sync rofi defaults before running. `sync-deps` copies files
from `deps/rofi/` to `${ROFI_CONFIG_DIR:-~/.config/rofi}` only when the target
file does not already exist.

## Daily Workflows

### Keybinds

- `SUPER + H`: open the cheat sheet from `lua/config/key-hints.toml`.
- `SUPER + SHIFT + K`: search keybind definitions from
  `lua/hyprconf/binds.lua`.
- `SUPER + SHIFT + E`: open quick settings.
- `SUPER + D`: toggle the Noctalia launcher.
- `SUPER + A`: toggle overview through Quickshell, falling back to AGS.
- `SUPER + ALT + L`: cycle layouts: Dwindle, Master, Scrolling.
- `SUPER + SHIFT + A`: open the profile selector.
- `SUPER + Print`: screenshot now.
- `SUPER + SHIFT + Print`: screenshot area.
- `SUPER + SHIFT + S`: screenshot area with Swappy.

### Profiles

Profiles are selected through:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua profile-selector
```

Animation presets live in `profiles/animation/` and write to
`lua/user/animations.lua`. Monitor presets live in `profiles/monitor/` and
write to `lua/user/monitors.lua`. Selected preset names are stored under
`profiles/.selected/`.

### Themes And Effects

- `noctalia-theme` reads Noctalia state from `~/.config/noctalia` and
  `~/.cache/noctalia`, then generates rofi, Quickshell, Hyprland color, and
  cache files.
- `rainbow-menu` chooses the rainbow border mode and writes
  `effects/rainbow-border-mode`.
- `rainbow-border` applies runtime border colors using generated material
  colors when available.
- `rofi-theme`, `kitty-themes`, and `zsh-theme` edit external user config files.

### Screenshots

```sh
lua ~/.config/hypr/lua/bin/hypr.lua screenshot --now
lua ~/.config/hypr/lua/bin/hypr.lua screenshot --area
lua ~/.config/hypr/lua/bin/hypr.lua screenshot --swappy
lua ~/.config/hypr/lua/bin/hypr.lua screenshot --in5
lua ~/.config/hypr/lua/bin/hypr.lua screenshot --in10
lua ~/.config/hypr/lua/bin/hypr.lua screenshot --active
```

Screenshots are saved under the Pictures screenshots directory and copied to the
clipboard where applicable.

## Configuration Map

| What to change | Source file |
| --- | --- |
| Defaults, apps, paths, search URL, touchpad device | `lua/hyprconf/context.lua` |
| Autostart commands | `lua/config/autostart.toml` |
| Keybinds | `lua/hyprconf/binds.lua` |
| Key hint rows | `lua/config/key-hints.toml` |
| Quick settings rows | `lua/config/quick-settings.toml` |
| Window and layer rules | `lua/hyprconf/rules.lua` |
| Hyprland options, input, gestures, layout, cursor | `lua/hyprconf/options.lua` |
| Profile targets and menu themes | `lua/config/profiles.toml` |
| Polkit candidates | `lua/config/polkit.toml` |
| Rainbow and sound settings | `lua/config/effects.toml` |
| Noctalia generated outputs | `lua/hyprconf/theme/noctalia.lua` |

Useful runtime overrides:

```text
HYPR_CONFIG_DIR              default: ~/.config/hypr
ROFI_CONFIG_DIR              default: ~/.config/rofi
EFFECTS_DIR                  default: $HYPR_CONFIG_DIR/effects
RAINBOW_BORDER_MODE_FILE     default: $EFFECTS_DIR/rainbow-border-mode
NOTIFY_APP_NAME              default: Hyprland
NOTIFY_DEFAULT_TIMEOUT       default: 3000
NOTIFY_FALLBACK_ICON         default: empty
TOUCHPAD_DEVICE              default: context.lua touchpad_device
TERMINAL                     default for quick edit actions: kitty
EDITOR                       default for quick edit actions: nvim
```

## Validation

Run the standard readiness check from the repository root:

```sh
make ready
```

This runs:

- `make fmt`: formats Lua with `stylua`.
- `make lint`: lints Lua with `luacheck`.
- `make test`: verifies Hyprland can parse
  `~/.config/hypr/hyprland.lua`.

> [!NOTE]
> `make test` validates config parsing only. It does not exercise rofi menus,
> profile copying, screenshots, keybind actions, autostart commands, desktop
> portals, or external app integrations. In a live session, validation may still
> trigger reload hooks such as `refresh`.

Useful non-interactive smoke checks:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua sync-deps
lua ~/.config/hypr/lua/bin/hypr.lua not-a-command
```

## Side Effects To Know

- `rofi-theme` edits `${ROFI_CONFIG_DIR:-~/.config/rofi}/config.rasi`.
- `kitty-themes` edits `~/.config/kitty/kitty.conf` and reloads kitty.
- `zsh-theme` edits `~/.zshrc`.
- `portal-hyprland` restarts desktop portal processes.
- `profile-selector` copies presets into `lua/user/`, writes
  `profiles/.selected/<category>`, and reloads Hyprland.
- `screenshot` writes under the Pictures screenshots directory and uses the
  clipboard.
- `noctalia-theme` writes generated files under this repo, `~/.config`, and
  `~/.cache/hypr/effects`.

Treat `effects/` as generated runtime state. Preserve `lua/user/` and
`profiles/.selected/` unless you intentionally want to change the active local
profile.
