# Repositories and worktrees

**English** | [简体中文](git-repos.zh-CN.md)

The git commands to open a repository, create a worktree, and clean up after a task. For why things go where they do and how they are named, see [Workspace](../rules/workspace.md).

For agents: [set-up-project.md](../../prompts/workspace/set-up-project.md) clones a project for the first time, [start-task.md](../../prompts/workspace/start-task.md) starts a task, and [finish-task.md](../../prompts/workspace/finish-task.md) cleans up after one.

## Open a repository

| Situation | What to do |
|---|---|
| Your own or your team's repository | A plain clone inside the project directory |
| Send PRs to someone else's project | Fork it; `origin` is your fork, `upstream` the original |
| Start your own project from someone else's code | Clone it, rename their repository to the read-only `source`, and make your new repository `origin` |
| Just try someone else's project | A plain clone at a release tag; no fork, no worktrees |
| Open-source a project in stages | Publish snapshots of tags, or keep a public and a private repository; see [Open-sourcing in stages](../rules/staged-open-source.md) |

Your own or your team's repository:

```bash
mkdir -p ~/code/<repo> && cd ~/code/<repo>
git clone git@github.com:<org>/<repo>.git          # -> ~/code/<repo>/<repo>
git -C ~/code/<repo>/<repo> pull --ff-only          # sync main, any time later
```

Send PRs to someone else's project:

```bash
gh repo fork <owner>/<repo> --clone=false
mkdir -p ~/code/<repo> && cd ~/code/<repo>
git clone git@github.com:<you>/<repo>.git && cd <repo>
git remote add upstream https://github.com/<owner>/<repo>.git
git fetch upstream
git branch --set-upstream-to=upstream/main main     # local main follows the original
gh repo set-default <owner>/<repo>                  # gh pr create targets the original
```

New branches then start from `upstream/main` and are pushed to `origin`. Before you start, read the project's CONTRIBUTING and LICENSE, and for a large change open an issue to agree with the maintainers first.

Start from someone else's code:

```bash
gh repo create <you>/<myproj> --private
mkdir -p ~/code/<myproj> && cd ~/code/<myproj>
git clone https://github.com/<owner>/<their-repo>.git <myproj> && cd <myproj>
git remote rename origin source
git remote set-url --push source DISABLED           # pushing to source fails on purpose
git remote add origin git@github.com:<you>/<myproj>.git
git push -u origin main
git branch source-code source/main && git push origin source-code   # freeze the original code
```

Keep their LICENSE and credit, and say in the README where the code comes from. To see what you have changed since: `git diff source-code...main --stat`.

Just try it:

```bash
git clone https://github.com/<vendor>/<sdk>.git
cd <sdk> && git checkout <latest-tag>               # pin a release, don't follow main
```

## Create a worktree

From the main clone:

```bash
cd ~/code/<repo>/<repo>
git fetch origin
git worktree add ../feat-new-task -b feat/new-task origin/main                # a new task
git worktree add ../feat-teleop -b feat/teleop --track origin/feat/teleop     # take over a branch from the remote
```

Set up each new worktree on its own, because files ignored by `.gitignore` don't come along:

```bash
cd ../feat-new-task
git submodule update --init --recursive    # if the repository has submodules
cp ../<repo>/.env .env                      # local secrets and settings, if any
npm ci                                      # or: python -m venv .venv && .venv/bin/pip install -e .
git push -u origin feat/new-task
```

Then open tmux and the agent session:

```bash
tmux new -s cc-feat-new-task
claude -n feat-new-task
```

## Standing worktrees

The commands for `review-pr` are in [Code review](../rules/code-review.md). Create `playtest` once, then switch it to the version you want to try:

```bash
git worktree add --detach ../playtest origin/main   # once, from the main clone
cd ../playtest && git fetch origin --tags
git switch --detach v0.1.0                          # a release; or origin/main for the latest
```

## When the task is done

After the PR merges, from the main clone:

```bash
git pull --ff-only
git worktree remove ../feat-new-task
git branch -D feat/new-task                 # after a squash merge, -d refuses
git push origin --delete feat/new-task      # skip if GitHub already deleted it
git fetch --prune
tmux kill-session -t cc-feat-new-task
```

Before you remove anything, run the three checks in [Workspace](../rules/workspace.md).

## Sources

- [git-worktree](https://git-scm.com/docs/git-worktree)
- GitHub Docs: [Contributing to a project](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project), [Syncing a fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork)
