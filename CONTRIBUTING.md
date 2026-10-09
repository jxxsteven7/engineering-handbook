# Contributing

**English** | [简体中文](CONTRIBUTING.zh-CN.md)

How this repository is written and maintained. The rules apply to everyone, including AI agents.

## How changes get in

- This is a docs repository with one maintainer, so the maintainer commits to `main` directly. There are no branches, pull requests or versions; the [full process](docs/rules/protect-main.md) is meant for code that others depend on.
- Outside contributors fork the repository and open a pull request.
- Two checks still apply. The `commit-msg` hook checks every commit message: `<type>: <summary>`, English, and no AI or agent attribution. On every push, CI checks that each doc matches its translation, that the scripts pass their tests, and that no commit carries attribution. The `pre-commit` hook only reminds you when docs need syncing.
- Milestones, such as the first public release, get a tag by hand.

## Setup

You need git and Node.js 22 or later.

```bash
git clone git@github.com:jxxsteven7/agentic-engineering-handbook.git
cd agentic-engineering-handbook
git config core.hooksPath .githooks
```

## The three kinds of files

- `docs/` is for people, in English and Chinese, in two folders. `docs/rules/` holds the method itself: what to do and why, with only the one or two commands that best show each rule. `docs/tools/` holds how to use the tools, such as git and SSH, to look up when you need them. Keep each doc short.
- `prompts/` is for agents, in English only. A prompt spells out every step, the exact commands, where to stop and wait for a person, and how to check the result. Each prompt starts with the doc it follows, and the doc links back to it.
- `templates/` holds files that people install on their machines or copy into their repositories. Every script there has tests, and CI runs them.

`prompts/` is grouped by topic: `setup/`, `workspace/`, `repository/` and `agents/`. A new rule goes in `docs/rules/`. A new set of commands for a tool goes in `docs/tools/`, and the rule that needs it links there. Link every new doc and prompt from the contents table in the README.

## Writing a doc

1. Write or edit the doc in one language, usually Chinese (`X.zh-CN.md`). Keep it short and plain: what to do, then why, and only the commands people actually type. Run every command you include.
2. In Claude Code, run `/sync-docs`. It updates the other language only where you changed something, polishes the new text with the humanizer skills, records the sync stamp and runs the checks. With Codex, ask it to follow `.claude/skills/sync-docs/SKILL.md`.
3. Read the result, then commit both languages together.

The two files must stay parallel, and the sync check enforces it:

- the same headings, paragraphs, list items, quotes and tables, in the same order;
- code blocks identical, so comments inside code are in English;
- the same inline code;
- links to the same-language version of other docs, and the language switcher at the top.

The check can't tell whether the translation says the same thing, so read the diff before you commit. If you commit one language alone, the pre-commit hook reminds you, and CI fails on the push until both match. To see what needs syncing, or to run the checks by hand:

```bash
node scripts/check-docs-sync.mjs --status
node scripts/check-docs-sync.mjs
node --test scripts/*.test.mjs templates/repo/scripts/*.test.mjs
SCRIPTS_ONLY=1 bash templates/workstation/accept.sh
bash templates/overnight/selftest.sh
```

## Working with agents

- Codex reads [AGENTS.md](AGENTS.md). Claude Code reads [CLAUDE.md](CLAUDE.md), which imports `AGENTS.md`, so both follow the same rules.
- To bring a file into a conversation, reference it with `@`, for example `@docs/rules/code-review.md check that this doc matches its prompt`.
