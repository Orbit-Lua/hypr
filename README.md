# Hyprland Lua Config

Personal Hyprland 0.55+ Lua configuration for an Arch-based Wayland
workstation. The config wires together Hyprland, rofi, Noctalia/Quickshell,
AGS, kitty, Thunar, clipboard tools, screenshots, profiles, and a small Lua
runtime command helper.

This repository is a working desktop config, not a reusable Hyprland
distribution. Use it when you want a concrete Lua-based Hyprland setup to run,
study, or adapt for a similar machine.

## What It Provides

- Lua Hyprland entrypoint at `hyprland.lua`
- Ordered core modules under `lua/hyprconf/`
- Runtime helper at `lua/bin/hypr.lua` for menus, screenshots, profiles,
  layout toggles, effects, session actions, and dependency sync
- TOML-backed autostart, profile, polkit, menu, key-hint, and effect settings
- Rofi defaults in `deps/rofi/` copied only when missing
- Profile presets under `profiles/` with active machine-local files in
  `lua/user/`
- Generated runtime effect state under `effects/`

## Requirements

Core environment:

- Hyprland 0.55+ with Lua config support
- `lua` on `PATH`
- `uwsm`
- `rofi`
- `kitty`
- `thunar`
- `notify-send`
- Hyprland and Wayland desktop portals
- A polkit agent at one of the paths in `lua/config/polkit.toml`

Runtime helpers invoke `lua` directly. LuaJIT is fine only if the command is
available as `lua`.

Shell and desktop integrations used by the current config:

- `ags`
- `qs -c noctalia-shell`
- `qs -c overview`
- `wl-paste`, `wl-copy`, and `cliphist`
- `grim`, `slurp`, `swappy`, `xdg-user-dir`, and `xdg-open`

Autostart currently references these machine-specific tools in
`lua/config/autostart.toml`:

- `rog-control-center`
- `mcontrolcenter`
- `polychromatic-tray-applet`
- `nm-applet`
- `blueman-applet`
- `fcitx5`
- `vesktop`
- `remmina`
- `tailscale`

Optional menu integrations include `nwg-look`, `qt6ct`, `qt5ct`, `yad`,
PipeWire playback tools such as `pw-play`, ASUS tools such as `asusctl`, Oh My
Zsh themes, and kitty themes in `~/.config/kitty/kitty-themes`.

## Installation

Clone or place the repository at the expected path:

```sh
git clone <repo-url> ~/.config/hypr
```

If you are using a non-git copy, the important part is the final path:

```sh
~/.config/hypr
```

The config and validation target assume this location unless you explicitly
override paths.

Start Hyprland with the Lua entrypoint:

```sh
hyprland --config ~/.config/hypr/hyprland.lua
```

For a checkout in another directory, validate with an absolute path:

```sh
hyprland --verify-config --config /absolute/path/to/hyprland.lua
```

## Quick Start

Sync missing rofi defaults:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua sync-deps
```

Open the quick settings menu:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua quick-settings
```

Browse keybinds:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua keybinds
```

Select a profile:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua profile-selector
lua ~/.config/hypr/lua/bin/hypr.lua profile-selector animation
lua ~/.config/hypr/lua/bin/hypr.lua profile-selector monitor
```

Take a screenshot:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua screenshot --area
```

Running the helper without a valid command prints the supported command list.
The source of truth for command names is `lua/bin/hypr.lua`.

## Runtime Commands

Use the helper form for runtime actions:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua <command>
```

Current command inventory:

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

Most commands sync missing rofi defaults before running. Some commands have
intentional side effects outside this repository:

- `profile-selector` copies a preset into `lua/user/` and reloads Hyprland
- `rofi-theme` edits `${ROFI_CONFIG_DIR:-~/.config/rofi}/config.rasi`
- `kitty-themes` edits `~/.config/kitty/kitty.conf`
- `zsh-theme` edits `~/.zshrc`
- `screenshot` writes screenshots under the Pictures directory and copies them
  to the clipboard
- `portal-hyprland` restarts desktop portal processes
- `noctalia-theme` reads `~/.config/noctalia/colors.json` and writes generated
  color files for Quickshell, rofi, Hyprland effects, and this repo

## Configuration

Core loading order from `lua/hyprconf/init.lua`:

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

Common edit points:

- Defaults, apps, and touchpad device: `lua/hyprconf/context.lua`
- Keybinds: `lua/hyprconf/binds.lua`
- Autostart commands: `lua/config/autostart.toml`
- Window and layer rules: `lua/hyprconf/rules.lua`
- Appearance, input, gestures, and layout: `lua/hyprconf/options.lua`
- Quick settings rows: `lua/config/quick-settings.toml`
- Key hint rows: `lua/config/key-hints.toml`
- Polkit agent candidates: `lua/config/polkit.toml`
- Profile targets and rofi themes: `lua/config/profiles.toml`
- Rainbow border and sound settings: `lua/config/effects.toml`

## Profiles

Profiles separate active machine-local settings from reusable presets.

- Active files live in `lua/user/`
- Presets live in `profiles/<category>/`
- If an active `lua/user/` file exists, it is loaded before preset defaults
- If an active file is missing, the corresponding `profiles/<category>/default.lua`
  fallback is loaded
- Selected state is written to `profiles/.selected/<category>`
- Profile targets are configured in `lua/config/profiles.toml`

Current categories:

- `animation`, targeting `lua/user/animations.lua`
- `monitor`, targeting `lua/user/monitors.lua`

Load a preset with:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua profile-selector animation
lua ~/.config/hypr/lua/bin/hypr.lua profile-selector monitor
```

## Environment Overrides

Runtime helpers support these environment variables:

- `HYPR_CONFIG_DIR`, defaulting to `~/.config/hypr`
- `ROFI_CONFIG_DIR`, defaulting to `~/.config/rofi`
- `EFFECTS_DIR`, defaulting to `$HYPR_CONFIG_DIR/effects`
- `RAINBOW_BORDER_MODE_FILE`, defaulting to
  `$EFFECTS_DIR/rainbow-border-mode`
- `NOTIFY_APP_NAME`, defaulting to `Hyprland`
- `NOTIFY_DEFAULT_TIMEOUT`, defaulting to `3000`
- `NOTIFY_FALLBACK_ICON`, defaulting to empty
- `TOUCHPAD_DEVICE`, defaulting to the device in `lua/hyprconf/context.lua`
- `TERMINAL`, used by quick settings edit actions and defaulting to `kitty`
- `EDITOR`, used by quick settings edit actions and defaulting to `nvim`

## Project Structure

```text
hyprland.lua                 Hyprland Lua entrypoint
lua/hyprconf/                Core modules loaded by setup()
lua/hyprconf/commands/       Runtime command implementations
lua/bin/hypr.lua             Runtime CLI and command inventory
lua/config/*.toml            Runtime data files
lua/user/*.lua               Active machine-local profile files
profiles/<category>/*.lua    Reusable profile presets
profiles/.selected/          Selected preset state
deps/rofi/                   Rofi defaults copied only when missing
effects/                     Generated runtime state
```

## Development

Install the local development tools used by the Makefile:

- `stylua`
- `luacheck`
- `hyprland`

Run the standard readiness target before treating changes as complete:

```sh
make ready
```

`make ready` formats every Lua file, lints every Lua file, and validates the
canonical config path:

```sh
stylua $(find . -path './.git' -prune -o -type f -name '*.lua' -print | sort)
luacheck $(find . -path './.git' -prune -o -type f -name '*.lua' -print | sort)
hyprland --verify-config --config ~/.config/hypr/hyprland.lua
```

Individual targets:

```sh
make fmt
make lint
make test
```

`make test` only checks whether Hyprland can parse the config. It does not
exercise rofi menus, profile copying, autostart commands, screenshots,
keybinds, or portal/session helpers. In a live session, Hyprland config
verification may still trigger reload hooks such as the `refresh` helper; it is
not a full runtime test.

## Contributing

This is a personal config, so contributions should preserve current behavior
unless a behavior change is intentional and documented.

Before opening a change:

1. Keep edits scoped to the relevant module or config file
2. Preserve `lua/user/` machine-local profile data
3. Check `lua/bin/hypr.lua` before documenting command names
4. Check `lua/config/autostart.toml` before documenting dependencies
5. Check `lua/hyprconf/context.lua` before documenting defaults or paths
6. Run `make ready`

Bug reports should include:

- Hyprland version
- The command or keybind used
- Any relevant terminal output or notification text
- Whether the issue happens after `hyprland --verify-config`
- Local overrides such as `HYPR_CONFIG_DIR`, `ROFI_CONFIG_DIR`, or selected
  profiles

Pull Requests should include:

- What changed and why
- Which files or commands are affected
- Validation output from `make ready`
- Manual smoke checks for any rofi menu, profile, screenshot, autostart, or
  keybind behavior touched by the change

## FAQ

### Can I install this somewhere other than `~/.config/hypr`?

Yes, but the default workflow assumes `~/.config/hypr`. Use
`HYPR_CONFIG_DIR=/path/to/config` for runtime helpers and pass an absolute path
to `hyprland --verify-config` when testing another checkout.

### Why are rofi files copied into `~/.config/rofi`?

Runtime menus use fixed rofi config names. `sync-deps` copies missing defaults
from `deps/rofi/` into `${ROFI_CONFIG_DIR:-~/.config/rofi}` and leaves existing
files untouched.

### Why do some commands fail outside a Hyprland session?

Several helpers call `hyprctl`, rofi, desktop portals, notification actions, or
Wayland clipboard tools. They are intended for the live workstation session, not
for a headless test environment.

### Why does `make test` pass when a menu still fails?

`make test` validates Hyprland config parsing only. Rofi menus, profile
selection, screenshots, keybind actions, autostart commands, and external app
integrations need separate manual smoke checks. In a live session, verification
can also trigger reload-time helpers, so treat it as parser validation rather
than a side-effect-free runtime audit.

### Which file should I edit for dependencies?

Start with `lua/config/autostart.toml` for launched services and
`lua/bin/hypr.lua` plus `lua/hyprconf/commands/` for runtime helper
dependencies.

## Credit

Based in part on
[Hyprland-Dots](https://github.com/LinuxBeginnings/Hyprland-Dots/tree/main/config/hypr).
