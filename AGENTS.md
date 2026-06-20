# AGENTS instuctions

This repo is a personal hyprland 0.55+ config in lua.

## Structure

- hyprland.lua: hyprland entrypoint
- lua/hyprconf/: main modules
- lua/user/: active user-local lua profile data
- `profiles/<category>/*.lua`: reusable profile presets
- `profiles/.selected/<category>` remembers the selected preset per category
- lua/bin/hypr.lua: runtime actions and menu commands
- lua/config/*.toml: runtime data such as autostart commands, menu rows, etc.

## Validation

run `make ready`
