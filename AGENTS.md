# AGENTS.md

Guidance for coding agents working in this Hyprland config repository.

## Scope

- This repo is a personal Hyprland 0.55+ configuration using Lua as the main entrypoint.
- Keep changes practical, local, and consistent with existing Lua modules, Lua runtime helpers, and TOML data.
- Do not revert user changes or generated local state unless explicitly requested.

## Layout

- `hyprland.lua` is the minimal Lua entrypoint.
- `lua/hyprconf/` contains tracked Hyprland modules.
- `lua/user/` contains active user-local Lua profile data.
- `profiles/<category>/*.lua` contains reusable profile presets.
- `profiles/.selected/<category>` remembers the selected preset per category.
- `lua/bin/hypr.lua` contains runtime actions and menu commands.
- `lua/config/*.toml` contains repeated runtime data such as autostart commands, menu rows, profile targets, and polkit candidates.

## Editing Rules

- Prefer extending existing modules over adding new top-level concepts.
- Keep Lua modules returning an `M` table with `M.setup()` when they are loaded by `lua/hyprconf/init.lua`.
- Keep monitor profiles as plain Lua snippets that call `hl.monitor(...)`.
- Keep animation profiles as Lua snippets that call `profile.apply_animation(...)`.
- Prefer Lua helpers in `lua/hyprconf/cli.lua` instead of adding shell scripts.
- Keep repeated runtime lists in TOML when the shape is simple data.
- Preserve generated or machine-written files unless the task is specifically about regeneration.

## Style

- Follow `.editorconfig`.
- Lua: 2-space indent.
- Keep comments useful and short; avoid narrating obvious assignments.
- Prefer ASCII unless the edited file already uses non-ASCII for UI text or symbols.

## Validation

Run the relevant checks before finishing:

```sh
find lua profiles -type f -name '*.lua' -print0 | xargs -0 luac -p
hyprland --verify-config --config ~/.config/hypr/hyprland.lua
```

## Safety

- Avoid destructive commands such as `git reset --hard`, `git checkout --`, or deleting config state.
- If a Lua command launches UI tools such as rofi or sends desktop notifications, prefer syntax/static checks unless runtime behavior is explicitly requested.
- Be careful with commands that affect monitors, themes, wallpaper, audio, or running processes; validate code paths before triggering them.
