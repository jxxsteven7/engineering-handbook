# Workspace

**English** | [简体中文](workspace.zh-CN.md)

Where each piece of work lives. Three principles:

1. One task = one branch = one worktree = one tmux session = one agent session, all with the same name.
2. The main clone only syncs `main`. Never develop in it.
3. Always start a new branch explicitly from `origin/main`, and run `git fetch` first.

The commands are in [Repositories and worktrees](../tools/git-repos.md). For agents: [start-task.md](../../prompts/workspace/start-task.md) starts a task, and [finish-task.md](../../prompts/workspace/finish-task.md) cleans up after one.

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

## Start a task

Create the worktree from the main clone, then open the tmux and agent sessions inside it, all three with the same name:

```bash
cd ~/code/<repo>/<repo>
git fetch origin
git worktree add ../feat-new-task -b feat/new-task origin/main
cd ../feat-new-task
tmux new -s cc-feat-new-task
claude -n feat-new-task
```

- Set up each new worktree on its own: files ignored by `.gitignore` don't come along, such as `.env`, dependencies and submodules.
- Give each worktree its own dependencies: an editable install in a venv can point to only one worktree.
- Don't copy datasets or checkpoints into every worktree; point to a shared directory with an environment variable or a symlink.

## Standing worktrees

- `review-pr`: for reviewing other people's PRs, and PRs below the top of a stack; see [Code review](code-review.md).
- `playtest`: for trying a version by hand. It is detached and only for testing; when you find a bug, note the version and fix it in a new worktree from `origin/main`.

## When the task is done

After the PR merges, remove its worktree, branch and tmux session. Delete the agent's session and this task's memory notes too, or they will mislead the next session. Turn anything left undone into issues first.

Before you remove anything, check three things: `git status --short` shows no work of yours, `git stash list` is empty, and no process is still running in the directory. [finish-task.md](../../prompts/workspace/finish-task.md) does all of this.

## Sources

- This layout is a community convention; neither git nor GitHub prescribes it.
