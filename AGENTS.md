# AGENTS Instructions

Preserve bindings and their actions. Keep deployed configuration read-only and runtime state outside its source tree.

## Git

- Write commits in [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) format.
- Start the type, scope and description in lowercase. Keep the case of code identifiers and proper nouns.
- For a non-trivial change, write a commit body that explains why.
- Mark a breaking change with `!` and a `BREAKING CHANGE:` footer.
- Author commits as the user alone. Add no agent trailers or links, such as `Co-Authored-By` or a session URL.
- Commit as the plan progresses.
- Before you push, squash related commits into one commit to keep the history clean.
- Push only after the user approves that push.
- Keep plans, diagnostic logs and throwaway test output outside the repo.
- Resolve the complete deployment symlink chain before updating a checkout.
- A Nix store link can point back to a live checkout.
- Complete refactors in an isolated worktree before updating that live tree.
- Suspend automatic reload during a multi-file live update.
- Reload the complete tree after the update.

## Releases

- Version releases with [Semantic Versioning 2.0.0](https://semver.org/).
- Use bare version tags unless the repository already has a prefix.
- Keep the format of an existing changelog.
- Use [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) for a new changelog.
- Release in this order:
  1. Commit the version files and changelog together, such as `chore(release): prepare 1.2.3`.
  2. Push that commit to the default branch.
  3. Wait for that commit's branch checks to pass.
  4. Create an annotated tag: `git tag -a 1.2.3 -m "Release 1.2.3" <commit>`.
  5. Push the tag alone: `git push origin 1.2.3`.
- Use `1.2.3-rc.1` for a release candidate.
- Let the tag workflow publish the package and create the release.
- Push the commit and tag separately. Do not use `git push --follow-tags`.
- Separate pushes prevent overlapping branch and tag workflows from queuing on one runner.

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
- Use `LUA`, `LUALS` and `RUFF` to select validation executables.
- Verify real menus, portals and hardware only in an authorized desktop session.
- Report unavailable checks and uncovered contracts.

## CI

- Keep a CI check only when it catches a concrete failure that no existing check covers.
- Identify that failure before you add or keep the check.
- Apply the test rules to CI checks too.
- Run the repo's entry points against real inputs or isolated fixtures.
- Reject duplicate checks, source-text assertions, copied inventories and checks that only prove that a command or file exists.
- Name CI files in kebab-case by purpose, such as `deploy-production.yml`.
- Keep reserved host filenames, including `.gitlab-ci.yml`.
- Name workflows in Title Case, such as `Deploy Production`.
- Keep the repository name out of workflow names.
- Name job IDs in snake_case, such as `build_image`.
- Start each GitHub step name with a verb, such as `Install Dependencies` or `Run Tests`.
- Preserve proper nouns and code identifiers when applying case.
- Prefer a specific purpose, such as `deploy-production.yml`, over a vague name, such as `production.yml`.
- Omit redundant host or artifact words, as in `github-action-build.yml` and `build-workflow.yml`.
- Name each workflow, job and step by its target and action.
- Keep job display names unique within the repository.
- Update dispatch references, dependencies, release gates, required check contexts and badges together when renaming CI artifacts.
- Propagate command failures.
- Count a missing prerequisite or skipped required coverage as a failure.
- Run checks in branch workflows. Keep package builds, smoke tests, publication and release creation in tag workflows.
- Start each release job by checking that its commit belongs to the default branch.
- Match release jobs to the repository's version tag format, including release candidates.
- Protect release tags. Allow only protected references to read release credentials.
- Merge CI changes to the default branch before tagging. A tag workflow uses the tagged commit's configuration.
- Run checks on `pull_request` and `push` to branches.
- Run releases in a separate workflow on version-tag pushes, such as `[0-9]+.[0-9]+.[0-9]+` and `[0-9]+.[0-9]+.[0-9]+-*`.
- Check out release jobs with `fetch-depth: 0` for the default-branch ancestry check.
- Keep release secrets in an environment limited to release tags. Protect those tags with a tag ruleset.
- After you change these rules, audit the repo against them.
- Validate changes locally. Then verify the required CI on the pushed commit.
- Report each uncovered contract and each unavailable check.
- Run native Hyprland validation as an unprivileged user.

## Docs

- Keep each doc concise and plain. Each sentence must carry information.
- Keep only standing rules in `AGENTS.md`. Each rule must apply to later, unrelated work.
- Record facts about one place or failure in a code comment, test, commit body, ADR or issue.
- Write English docs in US English, to the [ASD-STE100](https://www.asd-ste100.org/) writing rules:
  - Give one instruction in each sentence.
  - Write instructions in the imperative and in the active voice.
  - Use one word for one meaning, and one meaning for one word.
  - An instruction has 20 words or fewer. A description has 25 words or fewer.
- Review each sentence over these limits.
- Split a sentence if it holds more than one instruction or fact.
- Use a numbered list for three or more instructions in a fixed order, also across sentences.
- Write full-sentence items or sets with more than five items as bullet lists.
- Other sets can stay in one sentence, even above the word limits.
- Write a non-English doc in two passes:
  1. Write an English draft to these rules.
  2. Translate the draft:
     1. Keep its sentence boundaries and one term for each concept.
     2. Keep commands, paths and code unchanged.
     3. Use the target language's natural word order.
- Read [README.md](README.md) before you change deployment, configuration or state recovery.
- Keep operator procedures in the README and contributor constraints here.
