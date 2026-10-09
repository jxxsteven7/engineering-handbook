# Contributing

**English** | [简体中文](CONTRIBUTING.zh-CN.md)

How this repository is written and maintained. The rules apply to everyone, including AI agents.

## How changes get in

- This is a docs repository with one maintainer, so the maintainer commits to `main` directly. There are no branches, pull requests or versions; the [full process](docs/repository/protect-main.md) is meant for code that others depend on.
- Outside contributors fork the repository and open a pull request.
- Two checks still apply. The `commit-msg` hook checks every commit message: `<type>: <summary>`, English, and no AI or agent attribution. On every push, CI checks that each doc matches its translation, that the scripts pass their tests, and that no commit carries attribution.
- Milestones, such as the first public release, get a tag by hand.

## Setup

You need git and Node.js 22 or later.

```bash
git clone git@github.com:jxxsteven7/agentic-engineering-handbook.git
cd agentic-engineering-handbook
git config core.hooksPath .githooks
```

## The three kinds of files

- `docs/` is for people: the principles and the most important commands, in English and Chinese. Keep each doc short.
- `prompts/` is for agents, in English only. A prompt spells out every step, the exact commands, where to stop and wait for a person, and how to check the result. Each prompt starts with the doc it follows, and the doc links back to it.
- `templates/` holds files that people install on their machines or copy into their repositories. Every script there has tests, and CI runs them.

`docs/` and `prompts/` share the topic folders `setup/`, `workspace/`, `repository/` and `agents/`. Link every new doc and prompt from the contents table in the README.

## Writing a doc

1. Write the English version first, as `X.md`. Say what to do, then why, and include only the commands people actually type. Run every command you include.
2. Edit it for natural English. With Claude Code, run the [humanizer](https://github.com/blader/humanizer) skill on the file.
3. Translate it into `X.zh-CN.md`, block by block:
   - the same headings, paragraphs, list items, quotes and tables, in the same order;
   - code blocks copied unchanged, so comments inside code are in English;
   - the same inline code;
   - links to the Chinese version of other docs, and the language switcher at the top.
4. Edit the translation for natural Chinese. With Claude Code, run the [humanizer-zh](https://github.com/op7418/humanizer-zh) skill on the file.
5. Record the sync stamp and run the checks:

   ```bash
   node scripts/check-docs-sync.mjs --update docs/topic/X.md
   node scripts/check-docs-sync.mjs
   node --test scripts/*.test.mjs templates/repo/scripts/*.test.mjs
   SCRIPTS_ONLY=1 bash templates/workstation/accept.sh
   ```

The sync check compares structure, code and links. It can't tell whether the translation says the same thing, so read both before you record the stamp. When you change a doc later, change both languages in the same commit.

## Working with agents

- Codex reads [AGENTS.md](AGENTS.md). Claude Code reads [CLAUDE.md](CLAUDE.md), which imports `AGENTS.md`, so both follow the same rules.
- To bring a file into a conversation, reference it with `@`, for example `@docs/repository/code-review.md check that this doc matches its prompt`.
