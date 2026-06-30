# AGENTS Instructions

Personal Hyprland 0.55+ Lua config for an active workstation. Preserve current
behavior unless the user asks for a behavior change. Keep changes specific to
this setup instead of turning it into a generic Hyprland template.

## Project Map

- `hyprland.lua`: Hyprland Lua entrypoint.
- `application-style.conf`: hyprland-qt-support style settings.
- `lua/hyprconf/init.lua`: core module load order.
- `lua/hyprconf/`: Hyprland config modules and shared helper code.
- `lua/hyprconf/commands/`: runtime command implementations.
- `lua/hyprconf/theme/`: Noctalia theme generation.
- `lua/bin/hypr.lua`: helper CLI and command inventory.
- `lua/config/*.toml`: structured config for autostart, menus, polkit,
  effects, and profile targets.
- `lua/user/*.lua`: active machine-local profile files.
- `profiles/<category>/*.lua`: reusable profile presets.
- `profiles/.selected/<category>`: selected preset state.
- `deps/rofi/`: rofi defaults copied only when missing.
- `effects/`: generated runtime effect state.

Core module order:

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

Check these before changing related behavior or documentation:

- Commands and command names: `lua/bin/hypr.lua`
- Command behavior: `lua/hyprconf/commands/`
- Defaults, apps, paths, search URL, and device names:
  `lua/hyprconf/context.lua`
- Autostart entries: `lua/config/autostart.toml`
- Profile targets and menu themes: `lua/config/profiles.toml`
- Polkit candidates: `lua/config/polkit.toml`
- Effect and sound settings: `lua/config/effects.toml`
- Noctalia generated outputs: `lua/hyprconf/theme/noctalia.lua`

## Workflow

- Use `rg` or `rg --files` for searches.
- Keep Lua style consistent with nearby code.
- Prefer existing helpers in `lua/hyprconf/util/`, `lua/hyprconf/cli.lua`,
  and `lua/hyprconf/commands/common.lua`.
- Use structured TOML for menu rows, autostart entries, polkit paths, profile
  metadata, and effect settings.
- Keep edits scoped to this workstation config.
- Do not add abstractions unless they remove real duplication or match an
  existing local pattern.

Before treating code changes as ready, run:

```sh
make ready
```

This runs:

- `make fmt`: formats Lua with `stylua`.
- `make lint`: lints Lua with `luacheck`.
- `make test`: verifies `~/.config/hypr/hyprland.lua` with Hyprland.

`make test` only checks config parsing. It does not exercise rofi menus,
profile copying, screenshots, keybind actions, autostart commands, desktop
portals, or external app integrations. In a live session, validation may still
trigger reload hooks such as `refresh`.

Useful non-interactive smoke checks:

```sh
lua ~/.config/hypr/lua/bin/hypr.lua sync-deps
lua ~/.config/hypr/lua/bin/hypr.lua not-a-command
```

Only run interactive or session-mutating helpers when the task requires them.

## Boundaries

- Preserve `lua/user/` profile files unless the user asks to change active
  profile data.
- Do not delete or overwrite `profiles/.selected/` state unless requested.
- Treat `effects/` as generated runtime state.
- Do not replace existing files in `${ROFI_CONFIG_DIR:-~/.config/rofi}` when
  changing dependency sync behavior.
- Keep the expected repo location as `~/.config/hypr` unless documenting an
  explicit override.
- Do not document LuaJIT alone; runtime helpers invoke `lua` directly.
- Do not run destructive git commands or revert unrelated user changes.

Commands with intentional external side effects:

- `rofi-theme` edits `${ROFI_CONFIG_DIR:-~/.config/rofi}/config.rasi`.
- `kitty-themes` edits `~/.config/kitty/kitty.conf` and reloads kitty.
- `zsh-theme` edits `~/.zshrc`.
- `portal-hyprland` restarts desktop portal processes.
- `profile-selector` copies presets into `lua/user/`, writes
  `profiles/.selected/<category>`, and reloads Hyprland.
- `screenshot` writes under the Pictures screenshots directory and uses the
  clipboard.
- `noctalia-theme` reads Noctalia state under `~/.config/noctalia` and
  `~/.cache/noctalia`, writes generated Quickshell and rofi color files under
  `~/.config`, writes `effects/colors-hyprland.conf`, writes
  `lua/hyprconf/generated/noctalia.lua`, and may update
  `~/.cache/hypr/effects`.

## Documentation

- `README.md` is user-facing project documentation.
- `AGENTS.md` is AI-facing automation guidance.
- Keep this file title exactly `AGENTS Instructions`.
- Keep docs factual and specific to this workstation config.
- Avoid promotional wording and unsupported claims.
- Mention the limits of `make test` when documenting validation.
- Re-check `lua/bin/hypr.lua`, `lua/config/autostart.toml`, and
  `lua/hyprconf/context.lua` before updating command, dependency, default path,
  app, or device documentation.

## Reporting

For code changes, report:

- Behavior changed.
- Files or commands affected.
- `make ready` result.
- Manual smoke checks for any rofi, profile, screenshot, autostart, keybind, or
  session behavior touched by the change.

For bug reports, capture:

- Hyprland version.
- Exact command, keybind, or startup path used.
- Relevant terminal output or notification text.
- Selected profiles and important environment overrides.
