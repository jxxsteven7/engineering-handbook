# Repositories and worktrees

**English** | [简体中文](repos-and-worktrees.zh-CN.md)

Three principles:

1. One task = one branch = one worktree = one tmux session = one agent session, all with the same name.
2. The main clone only syncs `main`. Never develop in it.
3. Always start a new branch explicitly from `origin/main`, and run `git fetch` first.

For agents: [set-up-project.md](../../prompts/workspace/set-up-project.md) clones a project for the first time, [start-task.md](../../prompts/workspace/start-task.md) starts a task, and [finish-task.md](../../prompts/workspace/finish-task.md) cleans up after one.

## Layout

```text
~/code/
└── <repo>/                  # project directory, named after the repository
    ├── <repo>/              # main clone: syncs main only, never develop here
    ├── feat-lobby/          # worktree for the branch feat/lobby
    ├── fix-ws-reconnect/    # worktree for the branch fix/ws-reconnect
    ├── review-pr/           # standing detached worktree for reviewing PRs
    ├── playtest/            # standing detached worktree for trying a version
    └── plans/               # plans and prompts for agents, not in git
```

- Keep every worktree next to the main clone inside the project directory, never inside the main clone, or IDE indexing, grep and tests will pick it up.
- A branch can be checked out in only one worktree at a time, so every task and every agent gets its own branch.

## Names

| What | Rule | Example |
|---|---|---|
| Project directory, main clone | The repository's name | `myapp/myapp` |
| Branch | `<type>/<short-description>`, lowercase, words joined by `-` | `feat/lobby` |
| Worktree directory | The branch name with `/` replaced by `-` | `feat-lobby` |
| tmux session | `cc-` plus the worktree name | `cc-feat-lobby` |
| Agent session | The worktree name | `claude -n feat-lobby` |
| Remotes | `origin` is the repository you push to, `upstream` the original you send PRs back to, `source` a read-only origin of code | |

## Open a repository

| Situation | What to do |
|---|---|
| Your own or your team's repository | A plain clone inside the project directory |
| Send PRs to someone else's project | Fork it; `origin` is your fork, `upstream` the original |
| Start your own project from someone else's code | Clone it, rename their repository to the read-only `source`, and make your new repository `origin` |
| Just try someone else's project | A plain clone at a release tag; no fork, no worktrees |

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

## Start a task

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

- Give each worktree its own dependencies: an editable install in a venv can point to only one worktree.
- Don't copy datasets or checkpoints into every worktree; point to a shared directory with an environment variable or a symlink.

Then open tmux and the agent session:

```bash
tmux new -s cc-feat-new-task
claude -n feat-new-task
```

## Standing worktrees

- `review-pr`: for reviewing other people's PRs; see [Code review](../repository/code-review.md).
- `playtest`: for trying a version by hand. It is detached and only for testing; when you find a bug, note the version and fix it in a new worktree from `origin/main`.

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

Before you remove anything, check three things: `git status --short` shows no work of yours, `git stash list` is empty, and no process is still running in the directory. Turn anything left undone into issues first. Delete the agent's session and this task's memory notes too, or they will mislead the next session; [finish-task.md](../../prompts/workspace/finish-task.md) does all of this.

## Sources

- [git-worktree](https://git-scm.com/docs/git-worktree)
- GitHub Docs: [Contributing to a project](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project), [Syncing a fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork)
- This layout is a community convention; neither git nor GitHub prescribes it.
