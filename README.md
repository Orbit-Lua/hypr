# Hyprland Lua Config

Personal Hyprland 0.55+ configuration using `hyprland.lua` as the Lua entrypoint.

## Layout

- `hyprland.lua` - minimal entrypoint that loads `lua/hyprconf`.
- `lua/hyprconf/` - tracked Hyprland modules.
- `lua/bin/hypr.lua` - runtime commands used by keybinds and menus.
- `lua/config/*.toml` - simple runtime data for autostart, menus, profiles, effects, and polkit candidates.
- `lua/user/` - active local monitor and animation profiles.
- `profiles/` - reusable monitor and animation presets.
- `deps/rofi/` - tracked rofi config files copied into `~/.config/rofi` when missing.
- `effects/` - generated Hyprland color/effect state.

## Dependency Sync

Some runtime commands hard-code rofi config paths such as `~/.config/rofi/config-edit.rasi`.

`lua/hyprconf/deps.lua` keeps those files available:

- Source: `deps/rofi/`
- Target: `${ROFI_CONFIG_DIR:-~/.config/rofi}`
- Behavior: copy missing files only; existing user-edited rofi files are not overwritten.

The sync runs when Hyprland loads this config and before `lua/bin/hypr.lua` runtime commands. To run it manually:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua sync-deps
```

## Dependencies

This is an Arch-oriented config. Validate packages with `pacman -Q <package>` or `yay -Q <package>`.

Required core packages:

```sh
pacman -Q hyprland lua rofi swappy grim slurp wl-clipboard cliphist xdg-utils xdg-user-dirs libnotify kitty thunar yad uwsm xdg-desktop-portal xdg-desktop-portal-hyprland hyprland-qt-support
```

Version expectations:

- `hyprland >= 0.55`
- `swappy >= 1.8`
- `rofi` or `rofi-wayland`
- `lua` available as the `lua` command

Required for the default Noctalia shell bindings:

```sh
pacman -Q noctalia-qs
command -v qs
```

If Noctalia shell is not used, set `noctalia_shell.enabled = false` in `lua/hyprconf/context.lua` and replace the `qs ...` keybinds/autostart commands.

Required for clipboard and screenshots:

```sh
pacman -Q grim slurp wl-clipboard cliphist swappy
command -v grim slurp wl-copy wl-paste cliphist swappy
```

Polkit needs one working agent. This config searches several known paths from `lua/config/polkit.toml`; `hyprpolkitagent`, `polkit-gnome`, or `polkit-kde-agent` are all acceptable.

Optional packages used by configured menus, keybinds, or autostart:

```sh
pacman -Q network-manager-applet blueman fcitx5 nwg-look qt6ct qt5ct pipewire wireplumber pipewire-pulse
yay -Q vesktop-bin mcontrolcenter-bin polychromatic tailscale obsidian
```

Optional personal integrations:

- `ags` - fallback overview command.
- `rog-control-center`, `asusctl` - ASUS laptop keys/autostart.
- `remmina`, `vesktop`, `tailscale` - personal autostart apps.
- `~/.oh-my-zsh/themes` - zsh theme selector.
- `~/.config/kitty/kitty-themes` - kitty theme selector.

## Common Edits

- Defaults, terminal, file manager, touchpad, Noctalia shell: `lua/hyprconf/context.lua`
- Keybinds: `lua/hyprconf/binds.lua`
- Autostart commands: `lua/config/autostart.toml`
- Window/layer rules: `lua/hyprconf/rules.lua`
- Appearance/input/layout: `lua/hyprconf/options.lua`
- Menus/actions: `lua/bin/hypr.lua` and `lua/hyprconf/commands/`
- Active profiles: `lua/user/`
- Profile presets: `profiles/`

## Validation

Run before considering the config ready:

```sh
find lua profiles -type f -name '*.lua' -print0 | xargs -0 luac -p
hyprland --verify-config --config ~/.config/hypr/hyprland.lua
```

`make ready` also runs formatting, linting, and Hyprland verification when `stylua` and `luacheck` are installed.

## Credit

Based in part on [Hyprland-Dots](https://github.com/LinuxBeginnings/Hyprland-Dots/tree/main/config/hypr).
