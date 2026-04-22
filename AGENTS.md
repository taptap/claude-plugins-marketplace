# AGENTS.md

> Loaded as both `AGENTS.md` (Codex) and `CLAUDE.md` (Claude Code, via symlink). Single source of truth — keep them in sync by editing this file only.

This repository is the **TapTap Plugins** marketplace for Claude Code and Codex CLI. It hosts four plugins (`git`, `sync`, `spec`, `test`), the marketplace manifests both editors consume, and the validation that keeps everything in sync.

## Repository layout

- `plugins/<name>/` — one directory per plugin. Each contains `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, and any of `commands/`, `skills/`, `agents/`, `hooks/`.
- `.claude-plugin/marketplace.json` — Claude Code marketplace registry (consumed by `claude-plugin install …`).
- `.agents/plugins/marketplace.json` — Codex marketplace registry (consumed by `codex marketplace add taptap/agents-plugins`).
- `.claude/` — repo-level Claude Code config: `skills/`, `rules/`, `hooks/`, `agents/`.
- `.codex/` — present per project; this repo doesn't ship one. `/sync:basic` writes one for downstream repos.
- `tests/validate.sh` — single source of truth for repo validation (versions, manifests, shellcheck, schemas).
- `CHANGELOG.md` — release notes per `metadata.version` bump.

## Commands

```bash
bash tests/validate.sh        # MUST pass before any PR. Runs shellcheck on every shell script
                              # and validates plugin/marketplace version consistency, Codex manifest
                              # interface fields, .agents/plugins/marketplace.json integrity, schemas.
```

There is no build step (markdown + JSON + shell only). No package manager, no compiler.

Slash commands you'll often see in workflow:

- `/sync:basic` — bootstrap a downstream repo (Claude/Codex hooks, MR template, status line, MCP, LSP).
- `/prepare-release` — reset versions to `production+1`, update CHANGELOG and READMEs.
- `/git:commit-push-pr` — confirm-each-step branch → commit → review → push → MR flow.
- `/clear-cache` — clear local Claude Code plugin cache when iterating on a plugin's source.

## Conventions

- **English only** for commit messages, MR/PR titles, and MR/PR descriptions. Comments inside code can be Chinese (existing style).
- **No ticket IDs.** This repo isn't wired to a ticketing system; do not insert `TAP-XXXX` into commit subjects.
- **Confirm each git step** when running `/git:commit-push-pr` (branch creation, commit, review, push, MR creation). Never auto-commit or auto-push without explicit user request.
- **Version bumping is mandatory.** Any change to `plugins/<name>/**` bumps that plugin's patch version in BOTH `.claude-plugin/plugin.json` AND `.codex-plugin/plugin.json` AND its entry in `.claude-plugin/marketplace.json`. Touching `.claude-plugin/marketplace.json` itself bumps `metadata.version` once. New untracked files under `plugins/<name>/` count as a plugin change. Full rules in [.claude/rules/versioning.md](.claude/rules/versioning.md).
- **Release** = `/prepare-release` (resets to `production+1`, writes CHANGELOG + README) → review → PR.

## Plugin contract

Every plugin must keep these in sync (enforced by `tests/validate.sh`):

| File | Required for | Notes |
|---|---|---|
| `plugins/<name>/.claude-plugin/plugin.json` | Claude Code | `name`, `version`, `description`, `author` |
| `plugins/<name>/.codex-plugin/plugin.json` | Codex | Same fields **plus** an `interface` block with `displayName`, `category` (`Productivity`/`Coding`), `capabilities` (`["Read", "Write"]`). Without `interface`, Codex 0.121+ silently rejects the plugin and it never shows up in the picker |
| `plugins/<name>/skills/**/SKILL.md` | both | YAML frontmatter `name` MUST match the directory name (Codex skill loader is strict) |
| `.claude-plugin/marketplace.json` entry | Claude Code | Plugin must be listed here to be installable via `claude-plugin install` |
| `.agents/plugins/marketplace.json` entry | Codex | Required so `codex marketplace add taptap/agents-plugins` discovers the plugin. Use `policy.installation = "INSTALLED_BY_DEFAULT"` for core plugins so adding the marketplace auto-installs them |

The two marketplace formats are **different schemas**; they are not interchangeable.

## Safety

- Never run `glab mr approve` / `glab mr merge` / `gh pr merge`.
- Never force-push to `main`; never amend commits already pushed.
- Never write under `~/.codex/`, `~/.claude/`, or `~/.agents/` from CI or scripted plugin install — those are user state. The only exception is `plugins/sync/scripts/ensure-codex-plugins.sh`, which intentionally edits `~/.codex/config.toml` to mirror project plugin enablement.
- `tests/validate.sh` does not require network access. Keep it that way.
