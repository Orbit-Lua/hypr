# Hyprland Lua Config

Hyprland 0.55+ configuration written in Lua. `hyprland.lua` is the
entrypoint, `lua/hyprconf/` contains the configuration modules, and
`lua/bin/hypr.lua` provides runtime commands used by keybinds, rofi menus, and
autostart hooks.

This is a workstation config rather than a generic distribution. It targets an
Arch-based Wayland setup with Hyprland, `uwsm`, rofi, kitty, Thunar, Noctalia
shell support, and a set of personal desktop utilities.

## Quick Start

Clone or place this repository at `~/.config/hypr`, then point Hyprland at the
Lua entrypoint:

```sh
hyprland --config ~/.config/hypr/hyprland.lua
```

The config loads modules in this order:

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

Rofi support files are synced automatically when Hyprland loads this config and
before runtime commands run. Existing files in `~/.config/rofi` are left alone.

## Requirements

Core tools expected by the config:

- Hyprland 0.55+ with Lua config support
- Lua or LuaJIT
- `uwsm`
- `rofi`
- `kitty`
- `thunar`
- desktop portals for Hyprland/Wayland
- Noctalia shell commands used by autostart

Screenshot and clipboard workflows expect:

```sh
grim slurp wl-clipboard cliphist swappy
```

Polkit needs one working agent. Candidate paths are configured in
`lua/config/polkit.toml`, including `hyprpolkitagent`, `polkit-gnome`, and
`polkit-kde-agent` variants.

Optional integrations appear in menus, keybinds, or autostart data. Missing
optional commands should only affect the related action:

- `network-manager-applet`
- `blueman`
- `fcitx5`
- `nwg-look`
- `qt6ct` and `qt5ct`
- PipeWire tools
- Vesktop
- Remmina
- Tailscale
- ASUS and device-specific tools
- personal theme selectors

## Usage

Run runtime actions through the Lua helper:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua <command>
```

Useful commands:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua sync-deps
lua ~/.config/hypr/lua/bin/hypr.lua quick-settings
lua ~/.config/hypr/lua/bin/hypr.lua keybinds
lua ~/.config/hypr/lua/bin/hypr.lua profile-selector
lua ~/.config/hypr/lua/bin/hypr.lua profile-selector animation
lua ~/.config/hypr/lua/bin/hypr.lua profile-selector monitor
lua ~/.config/hypr/lua/bin/hypr.lua screenshot
lua ~/.config/hypr/lua/bin/hypr.lua clip-manager
lua ~/.config/hypr/lua/bin/hypr.lua rainbow-menu
lua ~/.config/hypr/lua/bin/hypr.lua refresh
```

Running the helper without a valid command prints the full command list.

## Profiles

Profiles keep machine-local choices separate from reusable presets.

- Active profile files live in `lua/user/`
- Reusable presets live in `profiles/<category>/`
- Selected preset state is written to `profiles/.selected/<category>`
- Profile targets and rofi themes are configured in `lua/config/profiles.toml`

The current profile categories are:

- `animation`, targeting `lua/user/animations.lua`
- `monitor`, targeting `lua/user/monitors.lua`

Use the profile selector to copy a preset into the active user file and reload
Hyprland:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua profile-selector animation
lua ~/.config/hypr/lua/bin/hypr.lua profile-selector monitor
```

## Rofi Sync

Some commands use fixed rofi config paths such as
`~/.config/rofi/config-edit.rasi`. The dependency sync copies missing files from
`deps/rofi/` into `${ROFI_CONFIG_DIR:-~/.config/rofi}` without overwriting local
customizations.

Run the sync manually with:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua sync-deps
```

## Configuration Map

- Entry point: `hyprland.lua`
- Main modules: `lua/hyprconf/`
- Runtime CLI: `lua/bin/hypr.lua`
- Runtime command implementations: `lua/hyprconf/commands/`
- Runtime data: `lua/config/*.toml`
- Active local profiles: `lua/user/`
- Reusable profile presets: `profiles/`
- Synced rofi defaults: `deps/rofi/`
- Generated effect state: `effects/`

Common edits:

- Defaults, apps, search engine, and touchpad device: `lua/hyprconf/context.lua`
- Keybinds: `lua/hyprconf/binds.lua`
- Autostart commands: `lua/config/autostart.toml`
- Window and layer rules: `lua/hyprconf/rules.lua`
- Appearance, input, gestures, and layout: `lua/hyprconf/options.lua`
- Menu rows: `lua/config/quick-settings.toml` and `lua/config/key-hints.toml`
- Polkit agent candidates: `lua/config/polkit.toml`
- Profile targets: `lua/config/profiles.toml`

## Environment Overrides

Several paths and notification defaults can be overridden for testing or alternate
layouts:

- `HYPR_CONFIG_DIR`, defaulting to `~/.config/hypr`
- `ROFI_CONFIG_DIR`, defaulting to `~/.config/rofi`
- `EFFECTS_DIR`, defaulting to `$HYPR_CONFIG_DIR/effects`
- `RAINBOW_BORDER_MODE_FILE`, defaulting to `$EFFECTS_DIR/rainbow-border-mode`
- `NOTIFY_APP_NAME`, defaulting to `Hyprland`
- `NOTIFY_DEFAULT_TIMEOUT`, defaulting to `3000`
- `NOTIFY_FALLBACK_ICON`, defaulting to empty

## Development

Run the full local check before treating changes as ready:

```sh
make ready
```

Individual targets are also available:

```sh
make fmt
make lint
make test
```

`make ready` formats Lua with `stylua`, lints with `luacheck`, and verifies the
Hyprland config with:

```sh
hyprland --verify-config --config ~/.config/hypr/hyprland.lua
```

## Credit

Based in part on
[Hyprland-Dots](https://github.com/LinuxBeginnings/Hyprland-Dots/tree/main/config/hypr).
