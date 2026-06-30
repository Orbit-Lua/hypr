# AGENTS Instructions

Personal Hyprland 0.55+ Lua config for an active workstation. Preserve current
behavior unless the user explicitly asks for a behavior change. Keep docs and
code specific to this setup instead of turning it into a generic distribution
template.

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
- Defaults, apps, paths, and device names: `lua/hyprconf/context.lua`
- Autostart entries: `lua/config/autostart.toml`
- Profile targets: `lua/config/profiles.toml`
- Polkit agent candidates: `lua/config/polkit.toml`
- Effect settings: `lua/config/effects.toml`

Do not change command lists, dependency docs, defaults, paths, or profile
details without checking the relevant source file first.

## Workflow

Use `rg` or `rg --files` for searches. Keep Lua style consistent with nearby
code and prefer existing helpers in `lua/hyprconf/util/`,
`lua/hyprconf/cli.lua`, and `lua/hyprconf/commands/common.lua`.

Before treating code changes as ready, run:

```sh
make ready
```

The target runs:

- `make fmt`: formats repository Lua files with `stylua`
- `make lint`: lints repository Lua files with `luacheck`
- `make test`: validates `~/.config/hypr/hyprland.lua` with Hyprland

`make test` only verifies Hyprland config parsing. It does not exercise rofi
menus, profile copying, screenshots, keybind actions, autostart commands,
desktop portals, or external app integrations. In a live session, validation
may still trigger reload hooks such as `refresh`.

Useful non-interactive smoke checks:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua sync-deps
lua ~/.config/hypr/lua/bin/hypr.lua not-a-command
```

Only run interactive or session-mutating commands when the task requires them.

## Behavioral Boundaries

- Preserve user-local profile data in `lua/user/`
- Do not delete or overwrite `profiles/.selected/` state unless requested
- Treat `effects/` as generated runtime state
- Do not replace existing rofi files in `${ROFI_CONFIG_DIR:-~/.config/rofi}`
  when changing dependency sync behavior
- Do not run destructive git commands or revert unrelated user changes
- Keep the expected repo location as `~/.config/hypr` unless documenting an
  explicit override
- Do not document LuaJIT alone; runtime helpers invoke `lua` directly

Commands with intentional external side effects:

- `rofi-theme` edits `${ROFI_CONFIG_DIR:-~/.config/rofi}/config.rasi`
- `kitty-themes` edits `~/.config/kitty/kitty.conf`
- `zsh-theme` edits `~/.zshrc`
- `portal-hyprland` restarts desktop portal processes
- `profile-selector` copies presets into `lua/user/`, writes
  `profiles/.selected/<category>`, and reloads Hyprland
- `noctalia-theme` reads Noctalia state under `~/.config/noctalia` and
  `~/.cache/noctalia`, writes generated Quickshell and rofi color files under
  `~/.config`, writes `effects/colors-hyprland.conf`, writes
  `lua/hyprconf/generated/noctalia.lua`, and may update
  `~/.cache/hypr/effects`

## Style Rules

- Keep Lua formatted by `stylua`
- Keep Lua lint-clean according to `luacheck`
- Use structured TOML for menu rows, autostart entries, polkit paths, profile
  metadata, and effect settings
- Keep documentation factual and specific to this workstation config
- Avoid new abstractions unless they remove real duplication or match an
  existing local pattern

## Documentation Rules

- `README.md` is user-facing project documentation
- `AGENTS.md` is AI-facing automation guidance
- Keep this file title exactly `AGENTS Instructions`
- Mention the limits of `make test` when documenting validation
- Re-check `lua/bin/hypr.lua`, `lua/config/autostart.toml`, and
  `lua/hyprconf/context.lua` before updating command, dependency, default path,
  app, or device documentation

## Change Notes

For code changes, report:

- Behavior changed
- Files or commands affected
- `make ready` result
- Manual smoke checks for any rofi, profile, screenshot, autostart, keybind, or
  session behavior touched by the change

For bug reports, capture:

- Hyprland version
- Exact command, keybind, or startup path used
- Relevant terminal output or notification text
- Selected profiles and important environment overrides
