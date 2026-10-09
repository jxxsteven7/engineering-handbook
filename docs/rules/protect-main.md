# Protect main

**English** | [简体中文](protect-main.zh-CN.md)

In a code repository, every change reaches `main` through a reviewed pull request. GitHub, git hooks and CI enforce this, so nobody has to remember it. Set it up once per repository.

For agents: [set-up-repo.md](../../prompts/repository/set-up-repo.md) sets up all of this, step by step.

## Rules

- Nobody commits to `main`, pushes to it, force-pushes it or deletes it. That includes maintainers.
- Every change is made on its own branch, opened as a pull request and squash-merged.
- Someone other than the author approves every pull request. Agents never merge.
- The required checks pass, and the branch is up to date with `main`, before anything merges.
- Commits and pull requests carry no agent attribution.

## Three layers

| Layer | What it catches | Where |
|---|---|---|
| Git hooks | Commits on `main`, pushes to `main`, bad commit messages, agent attribution | `.githooks/` |
| CI | Anything pushed: commit format, version, tests | `.github/workflows/` |
| GitHub rules | Whatever gets past the other two | Repository settings |

Hooks can be skipped and CI only reports, so the GitHub rules are the last line of defense.

## On GitHub

- Merging: allow only squash merging, with the PR title as the commit title, and delete branches after merging.
- A ruleset named `protect-main` on the default branch: no deletion, no force push, a pull request with one approval, all conversations resolved, required checks passing and the branch up to date.
- On GitHub Free, rulesets are not enforced on private repositories. Until the repository is public or on a paid plan, only the hooks protect `main`.
- GitHub doesn't let you approve your own pull request. While you are the only maintainer, set required approvals to 0 but keep requiring a pull request, and review your own changes anyway.

## Key commands

Turn on the hooks once per clone; the setting covers every worktree:

```bash
git config core.hooksPath .githooks
```

If you have already changed files on `main`, move them to a branch:

```bash
git stash
git worktree add ../feat-xxx -b feat/xxx origin/main
cd ../feat-xxx && git stash pop
```

Never skip the hooks with `--no-verify`.

## Use it in your repository

Everything to copy is in [templates/repo/](../../templates/repo/): the hooks, the commit checker, the CI workflow, a PR template, `CODEOWNERS`, and a `.claude/settings.json` that turns off Claude Code's attribution. Give [set-up-repo.md](../../prompts/repository/set-up-repo.md) to an agent and it copies and adapts them, then prints the GitHub settings for you to apply.

## How much of this you need

Code that others use, or that several people and agents work on, needs all of it. A repository of docs with a single maintainer needs less: commit to `main` directly, and keep only the `commit-msg` hook and a CI check on push. This handbook works that way; see [CONTRIBUTING.md](../../CONTRIBUTING.md).
