# Hyprland Lua Config

Personal Hyprland 0.55+ configuration written in Lua. `hyprland.lua` is the
entrypoint and loads the modules under `lua/hyprconf`.

## Layout

- `hyprland.lua`: Hyprland Lua entrypoint.
- `lua/hyprconf/`: tracked configuration modules.
- `lua/bin/hypr.lua`: runtime commands used by keybinds and menus.
- `lua/config/*.toml`: runtime data for autostart, menus, profiles, effects,
  and polkit candidates.
- `lua/user/`: active local monitor and animation choices.
- `profiles/`: reusable monitor and animation presets.
- `profiles/.selected/`: selected preset state by profile category.
- `deps/rofi/`: rofi files synced into `~/.config/rofi` when missing.
- `effects/`: generated Hyprland color and effect state.

## Dependencies

This config targets Arch-based systems. Core tools include Hyprland, Lua, rofi,
kitty, Thunar, `uwsm`, desktop portals, Noctalia shell support, and common
Wayland utilities.

Clipboard and screenshot commands expect:

```sh
grim slurp wl-clipboard cliphist swappy
```

Polkit needs one working agent. Candidates are configured in
`lua/config/polkit.toml`; `hyprpolkitagent`, `polkit-gnome`, and
`polkit-kde-agent` are supported.

Several optional commands are wired into menus, keybinds, or autostart, such as
`network-manager-applet`, `blueman`, `fcitx5`, `nwg-look`, `qt6ct`, `qt5ct`,
PipeWire tools, Vesktop, Tailscale, Obsidian, ASUS tools, and personal theme
selectors.

## Rofi Sync

Some runtime commands use fixed rofi paths, such as
`~/.config/rofi/config-edit.rasi`. The dependency sync copies missing files from
`deps/rofi/` into `${ROFI_CONFIG_DIR:-~/.config/rofi}` without overwriting
existing files.

The sync runs when Hyprland loads this config and before runtime commands. To
run it manually:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua sync-deps
```

## Common Edits

- Defaults, apps, touchpad, and Noctalia shell: `lua/hyprconf/context.lua`
- Keybinds: `lua/hyprconf/binds.lua`
- Autostart commands: `lua/config/autostart.toml`
- Window and layer rules: `lua/hyprconf/rules.lua`
- Appearance, input, and layout: `lua/hyprconf/options.lua`
- Menus and actions: `lua/bin/hypr.lua` and `lua/hyprconf/commands/`
- Active profiles: `lua/user/`
- Profile presets: `profiles/`

## Validation

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
Hyprland config.

## Credit

Based in part on
[Hyprland-Dots](https://github.com/LinuxBeginnings/Hyprland-Dots/tree/main/config/hypr).
