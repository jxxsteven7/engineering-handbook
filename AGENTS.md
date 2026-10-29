# AGENTS.md

Rules for AI agents, such as Codex and Claude Code, working on this repository. Codex reads this file automatically; Claude Code loads it through `CLAUDE.md`.

This repository is a handbook. `docs/` is written for people, in Chinese and English, and stays short and plain: `docs/rules/` holds the rules, `docs/agents/` the rules that only matter when agents do the work, and `docs/tools/` how to use the tools. `prompts/` is written for agents, in English, and spells out every step. `templates/` holds files to copy into other repositories. `scripts/`, `.githooks/` and `.github/` are this repository's own checks. `CONTRIBUTING.md` explains how each kind of file is written; read it before you change anything. Claude Code expands the reference below; other agents should open the file.

@CONTRIBUTING.md

## Always

- **Commit to `main` directly.** This repository uses no branches, pull requests or versions. Commit only when the user asks, and push only when the user asks.
- **Never add AI or agent attribution.** Commit messages contain no `Co-Authored-By` trailers for AI tools, no "Generated with" lines and no session links. The commit author is the user. Subjects read `<type>: <summary>`; the `commit-msg` hook checks this, and you never bypass it with `--no-verify`.
- **Keep both languages in sync.** The maintainer often edits only the Chinese `X.zh-CN.md`. To bring the other language in line, follow `.claude/skills/sync-docs/SKILL.md` (in Claude Code, `/sync-docs`). Record the stamp with `node scripts/check-docs-sync.mjs --update <file>` only once the two files really say the same thing.
- **Keep docs and prompts together.** When a doc's rules change, update the prompt that follows it, and the other way round.
- **Run the checks** before you commit: `node scripts/check-docs-sync.mjs`, `node --test scripts/*.test.mjs templates/repo/scripts/*.test.mjs`, `SCRIPTS_ONLY=1 bash templates/claude-code/accept.sh`, `SCRIPTS_ONLY=1 bash templates/workstation/accept.sh`, `bash templates/workstation/selftest-clipboard.sh` and `bash templates/overnight/selftest.sh`.

## Writing

- Simple, concise, readable. Say what to do, then why. No marketing language, no filler.
- Every command in a doc or prompt must have been run, or checked against the tool's documentation. Mark anything untested or on trial as such.
- Keep personal details out: no home directory paths with real user names, private repository names, hostnames or email addresses. Use placeholders such as `<repo>` and `~/code/<repo>`.
- Code blocks are identical in both languages, so comments inside them are in English.
