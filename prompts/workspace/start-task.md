# Start a task in its own worktree

Follows: `docs/workspace/repos-and-worktrees.md` in the Agentic Engineering Handbook.

Fill in before use: the task in one sentence, and, if known, the branch name and the base (default `origin/main`). For a branch that already exists on the remote, give its name.

The project uses the layout `~/code/<repo>/<repo>` for the main clone, with worktrees next to it. Find the main clone with `git rev-parse --path-format=absolute --git-common-dir` (its parent directory) if you are in a worktree.

## Stop points

- Never develop, commit or install anything in the main clone. It only syncs `main` and creates worktrees.
- Never reuse a branch or worktree that belongs to another task. A branch can be checked out in only one worktree; if git refuses, stop and report rather than forcing it.
- Ask before copying secrets (`.env` and similar) into the new worktree.

## 1. Name it

- Branch: `<type>/<short-description>`, lowercase, words joined by `-`. The type is one of the repository's commit types, usually `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`, `perf`. Propose a name if the user didn't give one.
- Worktree directory: the branch name with `/` replaced by `-`, next to the main clone: `~/code/<repo>/<type>-<short-description>`.
- tmux session: `cc-<worktree directory name>`. Agent session: the worktree directory name.

Check that none of these exists yet: `git worktree list`, `git branch --list <branch>`, `git ls-remote --heads origin <branch>`, `tmux has-session -t cc-<name>`.

## 2. Create the worktree

From the main clone:

```bash
git -C ~/code/<repo>/<repo> pull --ff-only
git -C ~/code/<repo>/<repo> fetch origin
```

Then one of:

```bash
# a new task, always from an explicit base
git -C ~/code/<repo>/<repo> worktree add ../<type>-<desc> -b <type>/<desc> origin/main

# a branch that exists on the remote
git -C ~/code/<repo>/<repo> worktree add ../<type>-<desc> -b <type>/<desc> --track origin/<type>/<desc>

# a branch that exists only locally
git -C ~/code/<repo>/<repo> worktree add ../<type>-<desc> <type>/<desc>
```

In a fork (an `upstream` remote exists), fetch `upstream` and start from `upstream/main` instead.

## 3. Set up the worktree

Files ignored by git don't come along, so set the worktree up on its own. Look at what the repository uses and do only what applies:

| If the repository has | Do |
|---|---|
| `.gitmodules` | `git submodule update --init --recursive` |
| `.env.example`, or a `.env` in the main clone | Ask, then copy the main clone's `.env` |
| `package-lock.json` | `npm ci` |
| `pnpm-lock.yaml` / `yarn.lock` | `pnpm install --frozen-lockfile` / `yarn install --frozen-lockfile` |
| `pyproject.toml` or `setup.py` | `python -m venv .venv && .venv/bin/pip install -e .` (plus the dev extras the README names); never reuse another worktree's venv |
| `uv.lock` | `uv sync` |
| `.githooks/` | nothing: `core.hooksPath` set in the main clone covers every worktree |
| Large data or checkpoints | Don't copy them; point to the shared directory with the environment variable or symlink the README describes |

Follow the README or CONTRIBUTING where they say more.

## 4. Publish the branch

For a new branch: `git push -u origin <type>/<desc>`. The first push sets the tracking branch.

## 5. Start the session

```bash
tmux new -d -s cc-<type>-<desc> -c ~/code/<repo>/<type>-<desc>
```

If the user wants an agent to start working now, start it inside that tmux session with the name and the task prompt:

```bash
tmux send-keys -t cc-<type>-<desc> 'claude -n <type>-<desc> "$(cat <prompt file>)"' Enter
```

## 6. Report

The worktree path, the branch and its base, what was installed, the tmux session, and how to attach: `tmux attach -t cc-<type>-<desc>`.
