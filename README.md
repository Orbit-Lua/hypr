# Hyprland Lua Config

Personal Hyprland 0.55+ configuration written in Lua. `hyprland.lua` is the
Hyprland entrypoint, `lua/hyprconf/` contains the loaded modules, and
`lua/bin/hypr.lua` provides runtime actions used by keybinds, rofi menus, and
autostart hooks.

This is a workstation config, not a generic Hyprland distribution. It targets an
Arch-based Wayland setup with Hyprland, `uwsm`, rofi, kitty, Thunar, AGS,
Noctalia shell commands, and several personal desktop utilities.

## Quick Start

Install or clone this repository at the canonical path:

```sh
~/.config/hypr
```

Then start Hyprland with the Lua entrypoint:

```sh
hyprland --config ~/.config/hypr/hyprland.lua
```

The config assumes this path in several runtime commands and in `make test`.
For a checkout elsewhere, use an absolute config path when testing:

```sh
hyprland --verify-config --config /absolute/path/to/hyprland.lua
```

Modules load in this order:

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

Rofi support files are copied from `deps/rofi/` into
`${ROFI_CONFIG_DIR:-~/.config/rofi}` when Hyprland loads and before runtime
commands run. Existing rofi files are not overwritten.

## Requirements

Required for the normal config path:

- Hyprland 0.55+ with Lua config support
- a `lua` executable on `PATH`
- `uwsm`
- `rofi`
- `kitty`
- `thunar`
- `notify-send`
- desktop portals for Hyprland and Wayland

If LuaJIT is used, it still needs to be available as `lua`, because runtime
commands and autostart entries invoke `lua` directly.

Primary shell and keybind workflows use Noctalia and AGS commands:

- `ags`
- `qs -c noctalia-shell`
- `qs -c overview`

Screenshot and clipboard workflows expect:

```sh
grim slurp wl-clipboard cliphist swappy xdg-user-dir xdg-open
```

Autostart currently launches additional machine-specific tools from
`lua/config/autostart.toml`, including:

- `rog-control-center`
- `mcontrolcenter`
- `polychromatic-tray-applet`
- `nm-applet`
- `blueman-applet`
- `fcitx5`
- `vesktop`
- `remmina`
- `tailscale`

One polkit agent must exist at a path listed in `lua/config/polkit.toml`.

Optional menu or keybind integrations include:

- `nwg-look`
- `qt6ct` and `qt5ct`
- `yad`
- PipeWire playback tools such as `pw-play`
- ASUS tools such as `asusctl`
- Oh My Zsh theme files
- kitty theme files under `~/.config/kitty/kitty-themes`

## Runtime Commands

Run runtime actions through the Lua helper:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua <command>
```

Useful commands:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua sync-deps
lua ~/.config/hypr/lua/bin/hypr.lua quick-settings
lua ~/.config/hypr/lua/bin/hypr.lua keybinds
lua ~/.config/hypr/lua/bin/hypr.lua key-hints
lua ~/.config/hypr/lua/bin/hypr.lua profile-selector
lua ~/.config/hypr/lua/bin/hypr.lua profile-selector animation
lua ~/.config/hypr/lua/bin/hypr.lua profile-selector monitor
lua ~/.config/hypr/lua/bin/hypr.lua screenshot --area
lua ~/.config/hypr/lua/bin/hypr.lua clip-manager
lua ~/.config/hypr/lua/bin/hypr.lua rainbow-menu
lua ~/.config/hypr/lua/bin/hypr.lua refresh
```

Running the helper without a valid command prints the complete command list.
The source of truth for supported command names is `lua/bin/hypr.lua`.

## Profiles

Profiles keep active machine-local choices separate from reusable presets.

- Active profile files live in `lua/user/`
- Reusable presets live in `profiles/<category>/`
- Selected preset state is written to `profiles/.selected/<category>`
- Profile targets and rofi themes are configured in `lua/config/profiles.toml`

Current profile categories:

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
`~/.config/rofi/config-edit.rasi`. Dependency sync copies missing files from
`deps/rofi/` into `${ROFI_CONFIG_DIR:-~/.config/rofi}` and leaves existing local
customizations alone.

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

Runtime helpers support these overrides:

- `HYPR_CONFIG_DIR`, defaulting to `~/.config/hypr`
- `ROFI_CONFIG_DIR`, defaulting to `~/.config/rofi`
- `EFFECTS_DIR`, defaulting to `$HYPR_CONFIG_DIR/effects`
- `RAINBOW_BORDER_MODE_FILE`, defaulting to `$EFFECTS_DIR/rainbow-border-mode`
- `NOTIFY_APP_NAME`, defaulting to `Hyprland`
- `NOTIFY_DEFAULT_TIMEOUT`, defaulting to `3000`
- `NOTIFY_FALLBACK_ICON`, defaulting to empty

## Development

Run the standard local readiness command before treating changes as done:

```sh
make ready
```

`make ready` is not a pure check. It formats every Lua file found under the repo,
lints those files, and validates the canonical config path:

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

`make test` verifies that Hyprland can parse the config. It does not exercise
runtime helper flows, TOML-driven autostart commands, profile copying, rofi
menus, or keybind actions. For runtime smoke checks, use targeted helper
commands such as:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua sync-deps
lua ~/.config/hypr/lua/bin/hypr.lua not-a-command
```

## Credit

Based in part on
[Hyprland-Dots](https://github.com/LinuxBeginnings/Hyprland-Dots/tree/main/config/hypr).
