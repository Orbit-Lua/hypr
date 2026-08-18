# Hyprland Lua Workstation Config

Personal Hyprland 0.55+ configuration written in Lua for one active workstation.
It wires together Hyprland options, monitor and animation profiles, Vicinae
menus, Noctalia v5 themes, screenshots, desktop portals, and a small helper CLI.

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
- Vicinae as the application launcher, window switcher, clipboard history,
  file search, emoji picker, and dmenu frontend for custom Hyprland menus.
- Profile presets for animations and monitors, with active local profiles under
  `lua/user/`.
- Noctalia v5 integration for Hyprland and palette-driven border effects.
- Screenshot helpers for full screen, region, delayed, active window, and
  Swappy annotation flows.
- Structured TOML config for autostart, menu rows, profile metadata, quick
  settings, key hints, and effects.

## Requirements

Core runtime:

- Hyprland 0.55+ with Lua config support.
- `lua` on `PATH`; runtime helpers invoke `lua` directly.
- `uwsm`, `vicinae`, `kitty`, `thunar`, `notify-send`.
- Enabled Vicinae and hyprpolkitagent systemd user services. Their enablement
  is managed by the parent dotfiles repository through Homebase.
- A desktop portal stack.

Feature-specific tools:

- Shell overview: `qs`.
- Screenshots: `grim`, `slurp`, `swappy`, `wl-copy`, `xdg-user-dir`,
  `xdg-open`.
- Sounds: `pw-play` or `paplay` or `aplay`.
- Session applications are managed by systemd and XDG autostart in the parent
  dotfiles repository.

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
lua/config/*.toml            structured runtime data
lua/user/*.lua               active machine-local profiles
profiles/<category>/*.lua    reusable profile presets
profiles/.selected/          selected profile state
effects/                     rainbow state and generated color cache
```

Core modules load in this order:

```text
env -> monitors -> autostart -> options -> gestures -> animations -> binds -> rules
```

## Startup Ownership

Hyprland autostart is intentionally limited to compositor-owned runtime work.
`lua/config/autostart.toml` currently starts only the rainbow border helper,
which also prepares the generated color cache when needed.

Long-running session applications are owned outside this submodule:

| Owner | Startup responsibility |
| --- | --- |
| UWSM | Starts the Hyprland graphical session and its systemd target |
| Package user units | Run `vicinae.service` and `hyprpolkitagent.service` |
| Parent dotfiles units | Run KeePassXC, shells, tray apps, and Vesktop |
| System XDG autostart | Runs NetworkManager, Blueman, and fcitx5 applets |

Homebase reconciles the parent dotfiles repository's declarative user-service
inventory without adding duplicate Hyprland autostart commands:

```sh
hb setup --hook desktop-session --yes
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
HYPR_CONFIG_DIR=/path/to/hypr lua /path/to/hypr/lua/bin/hypr.lua keybinds
```

## Helper CLI

Run commands with:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua <command>
```

Common examples:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua quick-settings
lua ~/.config/hypr/lua/bin/hypr.lua keybinds
lua ~/.config/hypr/lua/bin/hypr.lua profile-selector
lua ~/.config/hypr/lua/bin/hypr.lua screenshot --area
```

Available commands are defined in `lua/bin/hypr.lua`:

```text
change-blur
change-layout
game-mode
key-hints
keybinds
kill-active
kitty-themes
overview
portal-hyprland
profile-selector
quick-settings
rainbow-border
rainbow-menu
refresh
screenshot
sound
touchpad
web-search
zsh-theme
```

## Daily Workflows

### Keybinds

- `SUPER + /`: open the cheat sheet from `lua/config/key-hints.toml`.
- `SUPER + SHIFT + /`: search keybind definitions from
  `lua/hyprconf/binds.lua`.
- `SUPER + SHIFT + E`: open quick settings.
- `SUPER + D`: toggle the Vicinae launcher.
- `SUPER + S`: enter a web search through Vicinae dmenu.
- `SUPER + CTRL + S`: open the Vicinae window switcher.
- `SUPER + ALT + V`: open Vicinae clipboard history.
- `SUPER + F`: open Vicinae file search.
- `SUPER + .`: open the Vicinae emoji picker.
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

- Noctalia v5 generates `noctalia.lua`; the entrypoint applies its Hyprland
  theme without modifying the generated file.
- `lua/hyprconf/colors.lua` reads the four semantic Noctalia colors and derives
  the material and 16-color palettes used by Hyprland.
- Derived colors are cached in ignored `effects/colors-cache.lua`. The cache is
  rewritten only when `noctalia.lua` changes or the cache is invalid.
- `rainbow-menu` chooses the rainbow border mode and writes
  `effects/rainbow-border-mode`.
- `rainbow-border` applies runtime border colors through the shared color
  module.
- `kitty-themes` and `zsh-theme` edit external user config files.

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
| Defaults, apps, paths, search URL, touchpad | `lua/hyprconf/context.lua` |
| Autostart commands | `lua/config/autostart.toml` |
| Keybinds | `lua/hyprconf/binds.lua` |
| Key hint rows | `lua/config/key-hints.toml` |
| Quick settings rows | `lua/config/quick-settings.toml` |
| Window and layer rules | `lua/hyprconf/rules.lua` |
| Options, input, gestures, layout, cursor | `lua/hyprconf/options.lua` |
| Profile targets | `lua/config/profiles.toml` |
| Rainbow and sound settings | `lua/config/effects.toml` |
| Noctalia palette derivation and cache | `lua/hyprconf/colors.lua` |

Useful runtime overrides:

```text
HYPR_CONFIG_DIR              default: ~/.config/hypr
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
make all
```

This runs:

- `make fmt`: formats Lua with `stylua`.
- `make lint`: lints Lua with `luacheck`.
- `make test`: verifies Hyprland can parse
  `~/.config/hypr/hyprland.lua`.

> [!NOTE]
> `make test` validates config parsing only. It does not exercise Vicinae menus,
> profile copying, screenshots, keybind actions, autostart commands, desktop
> portals, systemd user-unit lifecycle, or external app integrations. In a live
> session, validation may still trigger reload hooks such as `refresh`.

Useful non-interactive smoke checks:

```sh
vicinae ping
vicinae cmd ls
lua ~/.config/hypr/lua/bin/hypr.lua not-a-command
```

## Side Effects To Know

- `kitty-themes` edits `~/.config/kitty/kitty.conf` and reloads kitty.
- `zsh-theme` edits `~/.zshrc`.
- `portal-hyprland` restarts desktop portal processes.
- `profile-selector` copies presets into `lua/user/`, writes
  `profiles/.selected/<category>`, and reloads Hyprland.
- `screenshot` writes under the Pictures screenshots directory and uses the
  clipboard.

Treat `effects/` as generated runtime state. Preserve `lua/user/` and
`profiles/.selected/` unless you intentionally want to change the active local
profile.
