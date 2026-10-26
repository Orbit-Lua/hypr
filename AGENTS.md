# AGENTS Instructions

Personal Hyprland configuration for one workstation. Preserve bindings and runtime behaviour unless the task changes them. Read [README.md](README.md) for deployment, configuration and state locations.

## Runtime contracts

- Nacre (`~/codebase/nacre`) deploys this repo as its `hypr-config` input into a read-only Nix store path.
- Write runtime files under `ctx.state_dir` (`$XDG_STATE_HOME/hypr`), never under `ctx.config_dir`.
- Nacre owns long-running session applications. `lua/config/autostart.toml` holds only compositor-owned work.
- Home Manager owns shell and terminal configuration, such as `~/.zshrc`. Helpers that rewrite those files fail. Change their themes through Home Manager or Noctalia.
- `monitors.conf` and `workspaces.conf` are the user's local profile, and Git ignores them. The configuration does not load them.
- Keep structured data (autostart, menu rows, cheat sheet, effects) in `lua/config/*.toml`.
- Noctalia generates `noctalia.lua`. Change colors through the Noctalia templates, not in the file.
- Tests read `tests/fixtures/noctalia.lua`, so theme updates do not change the snapshots.
- Loading the config must not read command output through `io.popen`. `tests/config.lua` errors on it and records each `os.execute` in the snapshot.
- Code under `lua/hyprconf/*.lua` runs inside Hyprland with `hl`.
- `commands/` and `runtime/` run in the helper CLI. They reach the compositor through `runtime/hyprctl`.
- `util/shell`, `util/fs`, `util/toml` and `util/json` work in both contexts.
- Build shell commands with `shell.quote`.
- Add an abstraction only to remove real duplication.
- Annotations follow Hyprland's stubs (`/usr/share/hypr/stubs`, through `.luarc.json`). Use `HL.*` types for values that reach `hl`.
- Put `---@type` on parsed TOML and JSON. The parsers return them untyped.
- Keep the existing `mouse = true` bind fields, although `HL.BindOptions` does not declare them. Change them only in an intentional keymap change.
- Keep the small-module layout and the `---@class`/`---@field`/`---@param`/`---@return` annotations on typed structures.
- A profile is a whole Lua file under `profiles/<category>/`. Its first line `-- profile: <label>` sets its label. State stores only the selected name.
- Run interactive or session-mutating helper commands only when the task needs them.

## Tests

- Add a test to the repo only when it guards behaviour that no existing test covers.
- The test must fail when that behaviour breaks. Weigh this before you add each test.
- Run throwaway tests freely to check your work.
- Keep throwaway tests out of the repo unless they meet the bar above.
- Run `make all` before you finish. CI runs `make check`, which validates without formatting.
- Both targets run Luacheck, LuaLS, behaviour snapshots and Hyprland parsing with a throwaway home. `LUALS` overrides the lua-language-server binary.
- `make keymap` compares each bind with `tests/keymap.snapshot`.
- `make config` compares all other values sent to Hyprland with `tests/config.snapshot`: options, rules, animations, monitors, environment and event handlers.
- If a requested change alters a snapshot, regenerate it and show the diff:
  - `lua tests/keymap.lua > tests/keymap.snapshot`
  - `lua tests/config.lua "$(mktemp -d)" > tests/config.snapshot`
- `make all` tests helpers with fake native programs. Verify real menus, portals and hardware only in an authorized desktop session.

## Git

- Write commits in [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) format.
- For a non-trivial change, write a commit body that explains why.
- Mark a breaking change with `!` and a `BREAKING CHANGE:` footer.
- Author commits as the user alone, without `Co-Authored-By` or other co-author trailers.
- Commit as the plan progresses.
- Before you push, squash related commits into one commit to keep the history clean.
- Push only after the user approves that push.
- Version releases with [Semantic Versioning 2.0.0](https://semver.org/).

## CI

- Keep a CI check only when it catches a concrete failure that no existing check covers.
- Identify that failure before you add or keep the check.
- Apply the test rules to CI checks too.
- Run the repo's entry points against real inputs or isolated fixtures.
- Reject duplicate checks, source-text assertions, copied inventories and checks that only prove that a command or file exists.
- Name each workflow, job and step by its target and its action.
- Propagate command failures.
- Count a missing prerequisite or skipped required coverage as a failure.
- After you change these rules, audit the repo against them.
- Validate changes locally. Then verify the required CI on the pushed commit.
- Report each uncovered contract and each unavailable check.

## Docs

- Keep each doc concise and plain. Each sentence must carry information.
- Write English docs to the [ASD-STE100](https://www.asd-ste100.org/) writing rules:
  - An instruction has 20 words or fewer. A description has 25 words or fewer.
  - Give one instruction in each sentence.
  - Write instructions in the imperative and in the active voice.
  - Use one word for one meaning, and one meaning for one word.


## Helper declarations

`hyprconf.config` validates helper declarations and profile identifiers. The TOML reader supports single-line strings, numbers, booleans, arrays, tables and array tables. It rejects multiline strings, inline tables and dates. Keep declarations within this subset. Runtime JSON parsing preserves null positions and rejects malformed input.
