# AGENTS instructions

Personal Hyprland 0.55+ Lua config. Prefer documenting current behavior over
generalizing it into a reusable distribution.

## Structure

- `hyprland.lua`: Hyprland entrypoint
- `lua/hyprconf/`: core modules loaded by `require("hyprconf").setup()`
- `lua/bin/hypr.lua`: runtime CLI and command inventory
- `lua/config/*.toml`: autostart, menu rows, polkit, effects, profiles
- `lua/user/*.lua`: active machine-local profile files
- `profiles/<category>/*.lua`: reusable profile presets
- `profiles/.selected/<category>`: selected preset state
- `deps/rofi/`: rofi defaults copied only when missing
- `effects/`: generated runtime state

## Workflow Notes

- Treat `lua/bin/hypr.lua` as the source of truth for runtime commands
- Check `lua/config/autostart.toml` before changing dependency docs
- Check `lua/hyprconf/context.lua` before changing defaults or path docs
- Runtime helpers invoke `lua` directly, so do not document `luajit` alone
- This repo is expected at `~/.config/hypr` unless docs say otherwise
- Preserve user-local profile data in `lua/user/`

## Validation

- Run `make ready` before treating changes as ready
- `make ready` formats all repo Lua files with `stylua`
- `make ready` lints all repo Lua files with `luacheck`
- `make test` validates `~/.config/hypr/hyprland.lua`
- `make test` does not exercise rofi menus, profiles, autostart, or keybinds
