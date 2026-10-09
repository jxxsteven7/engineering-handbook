# <project>: plan for <round or date>

Settled with <who> on <date>. Development prompts: `01-*.md`, `02-*.md` in this directory.

## Pull requests

| PR | Branch / worktree | What it does | Depends on | Start | Review by |
|---|---|---|---|---|---|
| ① <topic> | `feat/<topic>` | <one line> | — | now | agent |
| ② <topic> | `feat/<topic>` | <one line> | ① merged | after ① | person |

- Files that two PRs both change, and which one rebases: <for example: ① and ② both change `src/app.ts`; whichever merges second rebases>.
- Shared interfaces, written exactly as both prompts state them: <field names, formats, who writes and who reads>.
- "Review by agent" means the overnight review and fix may stand in for a person's line-by-line review; a person still merges.

## Decisions

Everything the agents must not decide for themselves, with exact values: defaults, limits, wording, names.

- <decision>
- <decision>

## For people to do

Commands that need sudo, accounts or money, with when to do them.

| When | What |
|---|---|
| <date or "before ② merges"> | <what> |
