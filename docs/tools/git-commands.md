# Common Git commands

**English** | [简体中文](git-commands.zh-CN.md)

The git commands used most from day to day, grouped by what you want to do. Look them up when you need them. To open a repository or a worktree, see [Repositories and worktrees](git-repos.md); for a wrong commit or a rebase conflict, see [Git first aid](git-first-aid.md).

## Status and history

| What you want to see | Command |
|---|---|
| Which branch you are on and which files changed | `git status` |
| Changes not staged yet | `git diff` |
| Staged changes, which the next commit will include | `git diff --staged` |
| The latest commits | `git log --oneline -10` |
| All branches drawn as a graph | `git log --oneline --graph --all` |
| What a commit changed | `git show <sha>` |
| Every change to one file | `git log -p -- <file>` |
| Which commit last changed each line | `git blame <file>` |
| Which commit added or removed some text | `git log -S '<text>'` |

## Syncing with the remote

`git status` works offline: it compares your local branch with `origin/main`, the copy of GitHub's main that git keeps locally. `origin/main` only updates on fetch, pull and push, so when status says up to date, it means up to date with the last sync. It doesn't know about anything pushed to GitHub since. To see the real state, fetch first.

```text
git fetch    GitHub -> origin/main            download only; your branch and files don't change
git pull     git fetch + merge origin/main    with --ff-only, only if main has no commits of its own
git status   main vs origin/main              offline
```

| What you want to do | Command |
|---|---|
| How many commits you are behind or ahead of GitHub | `git fetch && git status` |
| Which remote branch each local branch follows, and how far apart they are | `git fetch && git branch -vv` |
| The commits a pull would bring in | `git log --oneline main..origin/main` |
| The commits a push would send | `git log --oneline origin/main..main` |
| Bring in the new commits from GitHub | `git pull --ff-only` |
| Push a new branch for the first time | `git push -u origin <branch>` |
| Push after that | `git push` |
| The remote repository's address | `git remote -v` |

Fetch only downloads and never touches your branch or files, so run it any time, look, and then decide whether to pull.

## Committing

| What you want to do | Command |
|---|---|
| Stage a file | `git add <file>` |
| Pick the changes to stage, one hunk at a time | `git add -p` |
| Unstage a file and keep its changes | `git restore --staged <file>` |
| Throw away a file's unstaged changes | `git restore <file>` |
| Commit | `git commit -m "<type>: <summary>"` |

How to write the subject: see [Commits and pull requests](../rules/commits-and-prs.md). To change or undo a commit afterwards, see [Git first aid](git-first-aid.md).

## Branches

Following [Workspace](../rules/workspace.md), a new task gets its own worktree. To see and switch branches within one checkout:

| What you want to do | Command |
|---|---|
| List local and remote branches | `git branch -a` |
| Switch to another branch | `git switch <branch>` |
| Start a new branch from the latest `main` | `git fetch && git switch -c <branch> origin/main` |
| The files the current branch changed compared with `main` | `git diff --stat origin/main...HEAD` |
| Delete a local branch | `git branch -d <branch>`; after a squash merge it takes `-D` |

## Putting changes aside

| What you want to do | Command |
|---|---|
| Put your changes aside and leave a clean working tree | `git stash` |
| Include new files as well | `git stash -u` |
| See what you have put aside | `git stash list` |
| Bring back the latest one | `git stash pop` |

## Version tags

CI creates the tags; see [Versioning and releases](../rules/versioning.md).

| What you want to do | Command |
|---|---|
| List all tags, newest first | `git fetch --tags && git tag --sort=-v:refname` |
| Check out a version to try it | `git switch --detach <tag>` |
| Go back to `main` | `git switch main` |

## Sources

- Pro Git: [Remote Branches](https://git-scm.com/book/en/v2/Git-Branching-Remote-Branches)
- [git-fetch](https://git-scm.com/docs/git-fetch), [git-status](https://git-scm.com/docs/git-status), [git-stash](https://git-scm.com/docs/git-stash)
