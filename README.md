# Hyprland Lua Config

Personal Hyprland 0.55+ configuration written in Lua. This is the active
desktop config for one workstation, with small runtime helpers for menus,
profiles, screenshots, effects, and session tasks.

The repository is useful as a concrete Hyprland Lua setup, but it is not meant
to be a distro-neutral template. Paths and integrations assume the config lives
at `~/.config/hypr` unless noted otherwise.

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
- A polkit agent matching one of the paths in `lua/config/polkit.toml`

Autostart and helper commands also reference workstation-specific tools:

- AGS and Quickshell: `ags`, `qs -c noctalia-shell`, `qs -c overview`
- Clipboard tools: `wl-paste`, `wl-copy`, `cliphist`
- Screenshots: `grim`, `slurp`, `swappy`, `xdg-user-dir`, `xdg-open`
- Tray or app integrations from `lua/config/autostart.toml`: `rog-control-center`,
  `mcontrolcenter`, `polychromatic-tray-applet`, `nm-applet`,
  `blueman-applet`, `fcitx5`, `vesktop`, `remmina`, and `tailscale`

Runtime helpers invoke `lua` directly. LuaJIT is fine only when it is available
as the `lua` command.

## Layout

```text
hyprland.lua                 Hyprland Lua entrypoint
lua/bin/hypr.lua             Runtime CLI and command inventory
lua/hyprconf/                Core config modules and helper support
lua/hyprconf/commands/       Runtime command implementations
lua/config/*.toml            Autostart, menus, polkit, effects, profiles
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

Validate the config parser with:

```sh
hyprland --verify-config --config ~/.config/hypr/hyprland.lua
```

For another checkout location, pass an absolute config path to Hyprland and use
`HYPR_CONFIG_DIR=/path/to/config` for runtime helpers.

## Runtime Helper

Run helper commands with:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua <command>
```

Useful examples:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua sync-deps
lua ~/.config/hypr/lua/bin/hypr.lua quick-settings
lua ~/.config/hypr/lua/bin/hypr.lua keybinds
lua ~/.config/hypr/lua/bin/hypr.lua profile-selector
lua ~/.config/hypr/lua/bin/hypr.lua screenshot --area
```

Current command inventory from `lua/bin/hypr.lua`:

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

Most commands sync missing rofi defaults before running. `sync-deps` copies
files from `deps/rofi/` into `${ROFI_CONFIG_DIR:-~/.config/rofi}` only when the
target file is missing.

## Side Effects

Several helper commands intentionally touch files or processes outside this
repository:

- `profile-selector` copies presets into `lua/user/`, writes
  `profiles/.selected/<category>`, and reloads Hyprland
- `rofi-theme` edits `${ROFI_CONFIG_DIR:-~/.config/rofi}/config.rasi`
- `kitty-themes` edits `~/.config/kitty/kitty.conf`
- `zsh-theme` edits `~/.zshrc`
- `screenshot` writes to the Pictures screenshots directory and copies captures
  to the clipboard
- `portal-hyprland` restarts desktop portal processes
- `noctalia-theme` reads Noctalia state under `~/.config/noctalia` and
  `~/.cache/noctalia`, then writes generated Quickshell, rofi, Hyprland, and
  effect state files

## Configuration

Common edit points:

- Defaults, apps, search URL, and touchpad device:
  `lua/hyprconf/context.lua`
- Keybinds: `lua/hyprconf/binds.lua`
- Autostart commands: `lua/config/autostart.toml`
- Window and layer rules: `lua/hyprconf/rules.lua`
- Appearance, input, gestures, and layout: `lua/hyprconf/options.lua`
- Quick settings rows: `lua/config/quick-settings.toml`
- Key hint rows: `lua/config/key-hints.toml`
- Polkit agent candidates: `lua/config/polkit.toml`
- Profile targets and rofi themes: `lua/config/profiles.toml`
- Rainbow border and sound settings: `lua/config/effects.toml`

Profiles keep reusable presets separate from active machine-local files:

- Active profile files live in `lua/user/`
- Presets live in `profiles/<category>/`
- Selected state is stored in `profiles/.selected/<category>`
- Profile targets are defined in `lua/config/profiles.toml`

Current profile categories:

- `animation`, targeting `lua/user/animations.lua`
- `monitor`, targeting `lua/user/monitors.lua`

## Environment

Runtime helpers read these environment variables:

- `HYPR_CONFIG_DIR`, default `~/.config/hypr`
- `ROFI_CONFIG_DIR`, default `~/.config/rofi`
- `EFFECTS_DIR`, default `$HYPR_CONFIG_DIR/effects`
- `RAINBOW_BORDER_MODE_FILE`, default `$EFFECTS_DIR/rainbow-border-mode`
- `NOTIFY_APP_NAME`, default `Hyprland`
- `NOTIFY_DEFAULT_TIMEOUT`, default `3000`
- `NOTIFY_FALLBACK_ICON`, default empty
- `TOUCHPAD_DEVICE`, default from `lua/hyprconf/context.lua`
- `TERMINAL`, default `kitty` for quick settings edit actions
- `EDITOR`, default `nvim` for quick settings edit actions

## Development

Install the local development tools used by the Makefile:

- `stylua`
- `luacheck`
- `hyprland`

Run the standard readiness target from the repo root:

```sh
make ready
```

This formats Lua files, lints Lua files, and runs:

```sh
hyprland --verify-config --config ~/.config/hypr/hyprland.lua
```

Individual targets:

```sh
make fmt
make lint
make test
```

`make test` only verifies that Hyprland can parse the config. It does not
exercise rofi menus, profile copying, screenshots, keybind actions, autostart
commands, desktop portals, or external app integrations. In a live session,
verification may still trigger reload hooks such as `refresh`.

For targeted smoke checks:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua sync-deps
lua ~/.config/hypr/lua/bin/hypr.lua not-a-command
```

Run interactive or session-mutating helpers only when you intend to test that
behavior.

## Notes

- Preserve `lua/user/` and `profiles/.selected/` unless you are intentionally
  changing active profile state.
- Treat `effects/` as generated runtime state.
- Check source files before changing documentation for commands, paths,
  defaults, dependencies, or profile targets.
- Credit: based in part on
  [Hyprland-Dots](https://github.com/LinuxBeginnings/Hyprland-Dots/tree/main/config/hypr).
