# AGENTS Instructions

Personal Hyprland 0.55+ Lua config. Treat this as an active workstation
configuration, not a reusable distribution template. Prefer documenting and
preserving current behavior over broad generalization.

## Project Map

- `hyprland.lua`: Hyprland Lua entrypoint
- `lua/hyprconf/init.lua`: core module load order
- `lua/hyprconf/`: Hyprland config modules and runtime helper support
- `lua/hyprconf/commands/`: runtime command implementations
- `lua/bin/hypr.lua`: runtime CLI and command inventory
- `lua/config/*.toml`: autostart, menu rows, polkit, effects, and profiles
- `lua/user/*.lua`: active machine-local profile files
- `profiles/<category>/*.lua`: reusable profile presets
- `profiles/.selected/<category>`: selected preset state
- `deps/rofi/`: rofi defaults copied only when missing
- `effects/`: generated runtime effect state

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

## Source Of Truth

- Runtime commands: `lua/bin/hypr.lua`
- Runtime command behavior: `lua/hyprconf/commands/`
- Defaults and paths: `lua/hyprconf/context.lua`
- Autostart dependencies: `lua/config/autostart.toml`
- Profile targets: `lua/config/profiles.toml`
- Polkit agent candidates: `lua/config/polkit.toml`
- Effect settings: `lua/config/effects.toml`

Do not document command names, dependency lists, defaults, or paths without
checking the relevant source file.

## Development Workflow

Use `rg` or `rg --files` for codebase searches. Keep changes scoped and follow
the existing Lua style.

Run before treating changes as ready:

```sh
make ready
```

What it does:

- `make fmt` formats all repository Lua files with `stylua`
- `make lint` lints all repository Lua files with `luacheck`
- `make test` validates `~/.config/hypr/hyprland.lua` with Hyprland

`make test` only verifies that Hyprland can parse the config. It does not
exercise rofi menus, profile copying, screenshots, keybind actions, autostart
commands, desktop portals, or external app integrations. In a live session,
verification may still trigger reload hooks such as the `refresh` helper.

For targeted runtime smoke checks, prefer commands such as:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua sync-deps
lua ~/.config/hypr/lua/bin/hypr.lua not-a-command
```

Only run interactive or session-mutating commands when the task requires them.

## Behavioral Boundaries

- Preserve user-local profile data in `lua/user/`
- Do not delete or overwrite `profiles/.selected/` state unless explicitly
  requested
- Do not treat `effects/` as hand-authored source; it is generated runtime
  state
- Do not replace existing rofi files in `${ROFI_CONFIG_DIR:-~/.config/rofi}`
  when changing dependency sync behavior
- Do not run destructive git commands or revert unrelated user changes
- Do not generalize this into distro-neutral documentation unless requested
- Do not document LuaJIT alone; runtime helpers invoke `lua` directly
- Keep this repo expected at `~/.config/hypr` unless a section explicitly
  documents an override

Be careful with helper commands that intentionally edit files outside the repo:

- `rofi-theme` edits `${ROFI_CONFIG_DIR:-~/.config/rofi}/config.rasi`
- `kitty-themes` edits `~/.config/kitty/kitty.conf`
- `zsh-theme` edits `~/.zshrc`
- `portal-hyprland` restarts desktop portal processes
- `profile-selector` copies presets into `lua/user/` and reloads Hyprland
- `noctalia-theme` reads Noctalia state under `~/.config/noctalia` and
  `~/.cache/noctalia`, writes Quickshell and rofi color files under
  `~/.config`, writes `effects/colors-hyprland.conf`, writes
  `lua/hyprconf/generated/noctalia.lua`, and may update
  `~/.cache/hypr/effects`

## Style Rules

- Keep Lua files formatted by `stylua`
- Keep lint-clean Lua according to `luacheck`
- Prefer existing helpers in `lua/hyprconf/util/`, `lua/hyprconf/cli.lua`, and
  `lua/hyprconf/commands/common.lua`
- Use structured TOML config files for menu rows, autostart entries, polkit
  paths, profile metadata, and effect settings
- Keep docs factual and specific to this workstation config
- Avoid adding abstractions unless they remove real duplication or match an
  existing local pattern

## Documentation Rules

- README.md is user-facing project documentation
- AGENTS.md is AI-facing automation guidance
- Keep the AGENTS.md title exactly `AGENTS Instructions`
- Check `lua/bin/hypr.lua` before changing command lists
- Check `lua/config/autostart.toml` before changing dependency docs
- Check `lua/hyprconf/context.lua` before changing default path, app, or
  device docs
- Mention limitations of `make test` when documenting validation

## Contribution Guidance

For code changes, include:

- The behavior changed
- Files or commands affected
- `make ready` result
- Any manual smoke checks for rofi, profiles, screenshots, autostart, keybinds,
  or session commands

For bug reports, capture:

- Hyprland version
- Exact command, keybind, or startup path used
- Relevant terminal output or notification text
- Selected profiles and important environment overrides
