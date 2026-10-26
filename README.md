# Hyprland Lua configuration

Hyprland configuration with Vicinae menus, Noctalia colors, selectable profiles and checked desktop helpers.

[![Validate Hyprland](https://github.com/Orbit-Lua/hypr/actions/workflows/check.yml/badge.svg?branch=main)](https://github.com/Orbit-Lua/hypr/actions/workflows/check.yml) [![Hyprland](https://img.shields.io/badge/Hyprland-0.55%2B-58E1FF?logo=hyprland&logoColor=white)](https://hypr.land/)

## Install

Use Hyprland 0.55+ on Arch Linux. Install these helper dependencies separately:

- Lua.
- Vicinae, Noctalia and Quickshell.
- YAD, Ghostty and Thunar.
- grim, slurp, swappy and wl-clipboard.
- libnotify and xdg-user-dirs.
- pw-play or paplay.

[Nacre](https://github.com/abnertu/nacre) deploys its pinned `hypr-config` input to `~/.config/hypr`.

1. Update `hypr-config` in Nacre.
2. Publish that change.
3. Update `nacre` in the machine flake.
4. Deploy the machine configuration.

Nacre owns session applications. This configuration starts compositor-owned work only.

## Usage

Hyprland loads `hyprland.lua`. Use these bindings to open the main tools:

| Binding | Action |
| --- | --- |
| `SUPER + /` | Open the cheat sheet |
| `SUPER + SHIFT + /` | Search bindings |
| `SUPER + SHIFT + E` | Open quick settings |

Run a helper from a shell:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua key-hints
```

Run the helper without arguments to list its commands. `screenshot` saves a PNG under the XDG Pictures directory's `Screenshots` subdirectory. It also copies the image to the clipboard. Clipboard failure keeps the saved image. `portal-hyprland` restarts the backend and broker through systemd user units.

Helpers report native failures with a nonzero status. Interactive menus, notification choices and image editing can wait for user input. Other native commands have a finite timeout. Mutating helpers share a nonblocking lock. Retry a busy operation after its writer finishes.

## Configuration

| Change | Source |
| --- | --- |
| Applications, paths, search URL and touchpad device | `lua/hyprconf/context.lua` |
| Bindings and window rules | `lua/hyprconf/binds.lua`, `lua/hyprconf/rules.lua` |
| Input, layout and appearance | `lua/hyprconf/options.lua` |
| Menus, effects and defaults | `lua/config/*.toml` |
| Animation and monitor presets | `profiles/<category>/*.lua` |

Quick settings edits need a writable checkout. Noctalia generates `noctalia.lua` through its theme templates.

For live development:

1. Clone this repo outside `~/.config/hypr`.
2. Set `users.users.<name>.development.hyprlandPath` to the clone's absolute path in the machine flake.
3. Deploy that link once.
4. Run `hyprctl reload` after each complete update.

Automatic reload can read an intermediate multi-file checkout. See [Nacre's desktop guide](https://github.com/abnertu/nacre/blob/main/docs/desktop-session.md#live-development).

## State and recovery

Runtime choices live in `$XDG_STATE_HOME/hypr`, or `~/.local/state/hypr` by default:

- `profiles/selected/<category>` records a profile name.
- `effects/rainbow-border-mode` records the border mode.

Remove a selection to restore its TOML default. `HYPR_CONFIG_DIR` and `HYPR_STATE_DIR` override the configuration and state roots.

A profile change verifies its reload before acceptance. Failure restores the previous selection and reloads it. Recovery failures report both errors.

Touchpad state lasts for the session in `$XDG_RUNTIME_DIR/touchpad.status`. Changes save state after acknowledgement. Versions without native device-state reporting use the last acknowledged receipt.

Game mode captures compositor values under `$XDG_RUNTIME_DIR/hypr/`. Disabling it restores those values, including originally disabled animations.
