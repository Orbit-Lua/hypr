# Hyprland Lua configuration

Personal Hyprland 0.55+ configuration for an Arch Linux workstation, with Vicinae menus, Noctalia colors and selectable monitor and animation profiles.

[![check](https://github.com/Orbit-Lua/hypr/actions/workflows/check.yml/badge.svg?branch=main)](https://github.com/Orbit-Lua/hypr/actions/workflows/check.yml)
[![Hyprland](https://img.shields.io/badge/Hyprland-0.55%2B-58E1FF?logo=hyprland&logoColor=black)](https://hypr.land/)

## Install

[Nacre](https://github.com/abnertu/nacre) deploys its pinned `hypr-config` input to `~/.config/hypr`. To adopt a revision, update `hypr-config` in Nacre, publish that change, then update `nacre` in the machine flake and deploy.

For local development, clone this repository outside `~/.config/hypr` and set `users.users.<name>.development.hyprlandPath` to its absolute path in the machine flake. Deploy the link once; subsequent edits apply on compositor reload. See [Nacre's desktop guide](https://github.com/abnertu/nacre/blob/main/docs/desktop-session.md#live-development).

The helpers expect Lua, Vicinae, Noctalia, Quickshell, YAD, Ghostty, Thunar, grim, slurp, swappy, wl-copy, notify-send, xdg-user-dir and either pw-play or paplay. Nacre owns long-running session applications; this configuration autostarts only compositor-owned work.

## Usage

Hyprland loads `hyprland.lua`. Press `SUPER + /` for the cheat sheet, `SUPER + SHIFT + /` to search bindings, or `SUPER + SHIFT + E` for quick settings.

```sh
lua ~/.config/hypr/lua/bin/hypr.lua key-hints
```

Invoke the helper without arguments to list commands. `screenshot` saves a PNG under the XDG Pictures directory's `Screenshots` subdirectory and copies it to the clipboard. `portal-hyprland` restarts desktop portals.

## Configuration

| Change | Source |
| --- | --- |
| Applications, search URL, paths, touchpad device | `lua/hyprconf/context.lua` |
| Bindings and window rules | `lua/hyprconf/binds.lua`, `lua/hyprconf/rules.lua` |
| Input, layout and appearance | `lua/hyprconf/options.lua` |
| Menus, cheat sheet, effects and defaults | `lua/config/*.toml` |
| Animation and monitor presets | `profiles/<category>/*.lua` |

Quick-settings edits require a writable checkout. Noctalia generates `noctalia.lua`; change its theme through Noctalia.

Runtime choices live in `$XDG_STATE_HOME/hypr` (default `~/.local/state/hypr`): `profiles/selected/<category>` records a profile name, and `effects/rainbow-border-mode` records the border mode. Removing a selection restores the corresponding TOML default. Touchpad state lasts for the session in `$XDG_RUNTIME_DIR/touchpad.status`. `HYPR_CONFIG_DIR` and `HYPR_STATE_DIR` override the configuration and state roots.
