# Hyprland Lua configuration

Personal Hyprland 0.55+ configuration for an Arch Linux workstation, with Vicinae menus, Noctalia colors and selectable monitor and animation profiles.

[![check](https://github.com/Orbit-Lua/hypr/actions/workflows/check.yml/badge.svg?branch=main)](https://github.com/Orbit-Lua/hypr/actions/workflows/check.yml)
[![Hyprland](https://img.shields.io/badge/Hyprland-0.55%2B-58E1FF?logo=hyprland&logoColor=white)](https://hypr.land/)

## Install

[Nacre](https://github.com/abnertu/nacre) deploys its pinned `hypr-config` input to `~/.config/hypr`. To adopt a revision:

1. Update `hypr-config` in Nacre and publish that change.
2. Update `nacre` in the machine flake.
3. Deploy.

For local development:

1. Clone this repo outside `~/.config/hypr`.
2. In the machine flake, set `users.users.<name>.development.hyprlandPath` to the absolute path of the clone.
3. Deploy the link once. After that, edits apply when the compositor reloads.

After a multi-file Git update, run `hyprctl reload`. Automatic reload can read an intermediate checkout.

See [Nacre's desktop guide](https://github.com/abnertu/nacre/blob/main/docs/desktop-session.md#live-development).

The helpers need coreutils, util-linux, Lua, Vicinae, Noctalia, Quickshell, YAD, Ghostty, Thunar, grim, slurp, swappy, wl-copy, notify-send, xdg-user-dir and pw-play or paplay. Nacre owns long-running session applications. This configuration autostarts only compositor-owned work.

## Usage

Hyprland loads `hyprland.lua`. These bindings open the main tools:

| Binding | Opens |
| --- | --- |
| `SUPER + /` | Cheat sheet |
| `SUPER + SHIFT + /` | Binding search |
| `SUPER + SHIFT + E` | Quick settings |

Run the helper from a shell:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua key-hints
```

Run the helper without arguments to list its commands. `screenshot` saves a PNG under the XDG Pictures directory's `Screenshots` subdirectory and copies it to the clipboard. `portal-hyprland` restarts desktop portals.

## Configuration

| Change | Source |
| --- | --- |
| Applications, search URL, paths, touchpad device | `lua/hyprconf/context.lua` |
| Bindings and window rules | `lua/hyprconf/binds.lua`, `lua/hyprconf/rules.lua` |
| Input, layout and appearance | `lua/hyprconf/options.lua` |
| Menus, cheat sheet, effects and defaults | `lua/config/*.toml` |
| Animation and monitor presets | `profiles/<category>/*.lua` |

Quick settings can save edits only in a writable checkout. Noctalia generates `noctalia.lua`. Change its theme through Noctalia.

Runtime choices live in `$XDG_STATE_HOME/hypr` (default `~/.local/state/hypr`):

- `profiles/selected/<category>` records a profile name.
- `effects/rainbow-border-mode` records the border mode.

Remove a selection to restore its TOML default. Touchpad state lasts for the session in `$XDG_RUNTIME_DIR/touchpad.status`. `HYPR_CONFIG_DIR` and `HYPR_STATE_DIR` override the configuration and state roots.


Helpers report native failures and return a nonzero status. Native commands have a finite timeout, except interactive menus and image editing. Mutating helpers share a nonblocking lock. Retry a busy operation after its current writer finishes.

Profile changes verify reload success before acceptance. A failed reload restores the previous selection and reloads it. Recovery failures report both errors. Touchpad changes save state only after acknowledgement. Hyprland versions without device-state reporting use the last acknowledged session receipt.

Game mode stores captured compositor values under `$XDG_RUNTIME_DIR/hypr/`. Disabling it restores those values, including originally disabled animations. Screenshot failures retain any image already published. Clipboard failure does not delete that image.

Portal recovery restarts the Hyprland backend and portal broker through systemd user units. It does not start unmanaged portal processes.
