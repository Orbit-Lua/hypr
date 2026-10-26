# AGENTS Instructions

Preserve bindings and their actions. Keep deployed configuration read-only and runtime state outside its source tree.

## Git

- Write commits in [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) format.
- For a non-trivial change, write a commit body that explains why.
- Mark a breaking change with `!` and a `BREAKING CHANGE:` footer.
- Author commits as the user alone, without `Co-Authored-By` or other co-author trailers.
- Commit as the plan progresses.
- Before you push, squash related commits into one commit to keep the history clean.
- Push only after the user approves that push.
- Version releases with [Semantic Versioning 2.0.0](https://semver.org/).
- Keep plans, diagnostic logs and throwaway test output outside the repo.
- Resolve the complete deployment symlink chain before updating a checkout.
- A Nix store link can point back to a live checkout.
- Complete refactors in an isolated worktree before updating that live tree.
- Suspend automatic reload during a multi-file live update.
- Reload the complete tree after the update.

## Runtime contracts

- Give each application one startup owner. Session managers or user services own session applications.
- Keep autostart declarations for compositor-owned work. Remove duplicate startup declarations when ownership moves.
- Keep shared shell and terminal settings in the user environment configuration.
- Keep Noctalia theme changes in its templates.
- Write runtime files under `ctx.state_dir`, never under `ctx.config_dir`.
- Keep helper declarations in TOML and validate them through `hyprconf.config`.
- The TOML reader supports single-line strings, numbers and booleans. It also reads arrays, tables and array tables.
- Keep declarations within that subset.
- Preserve JSON null positions and reject malformed native replies.
- Keep command execution outside compositor configuration loading.
- Use the checked process adapter for synchronous native helper operations.
- Quote arguments with `shell.quote` when a trusted command needs a shell.
- Keep each mutating operation under the shared lock.
- Preserve saved state when runtime application fails.
- Report failed recovery separately from the original failure.
- Treat notifications and screenshot sounds as optional feedback.
- Keep successful screenshot publication when clipboard copying fails.
- Store profile names rather than copied profile files.
- Keep the first-line profile label for menus.
- Keep the ignored `monitors.conf` and `workspaces.conf` files outside configuration loading.

## Lua contracts

- Keep compositor and helper contexts separate. Helpers reach Hyprland through `runtime.hyprctl`.
- Import each owner directly. Add an abstraction only to remove real duplication.
- Use the installed Hyprland stubs for annotations.
- Use `HL.*` types for values passed into Hyprland.
- Annotate parsed TOML and JSON structures at their consumers.
- Keep `mouse = true` bind fields despite their absence from `HL.BindOptions`.
- Change those fields only with an intentional binding change.

## Tests

- Add a test to the repo only when it guards behavior that no existing test covers.
- The test must fail when that behavior breaks. Weigh this before you add each test.
- Run throwaway tests freely to check your work.
- Keep throwaway tests out of the repo unless they meet the bar above.
- Keep keymap compatibility in the frozen snapshot and callback probes.
- Use the synthetic Noctalia fixture instead of personal theme state.
- Test helpers through their CLI with temporary roots and fake native commands.
- Parse shipped profiles with native Hyprland in isolated roots.
- Reject process execution while loading the real configuration entry point.
- Test behavior rather than copied option inventories or source text.
- Run `just all` before you finish.
- CI runs `just check`, which preserves source formatting.
- Use `LUA` and `LUALS` to select validation executables.
- Verify real menus, portals and hardware only in an authorized desktop session.
- Report unavailable checks and uncovered contracts.

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
- Run native Hyprland validation as an unprivileged user.

## Docs

- Keep each doc concise and plain. Each sentence must carry information.
- Write English docs in US English, to the [ASD-STE100](https://www.asd-ste100.org/) writing rules:
  - Give one instruction in each sentence.
  - Write instructions in the imperative and in the active voice.
  - Use one word for one meaning, and one meaning for one word.
  - An instruction has 20 words or fewer. A description has 25 words or fewer.
- Review each sentence over these limits. Split it if it holds more than one instruction or fact.
- A list of items can stay in one sentence. Make a bullet list from more than five items.
- Write a non-English doc in two passes:
  1. Write an English draft to these rules.
  2. Translate the draft. Keep its sentence boundaries and one term for each concept.
     Keep commands, paths and code unchanged. Use the natural word order of the target language.
- Read [README.md](README.md) before you change deployment, configuration or state recovery.
- Keep operator procedures in the README and contributor constraints here.
