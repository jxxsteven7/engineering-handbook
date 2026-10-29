# Clean up after a task

Follows: `docs/rules/workspace.md` and `docs/tools/git-repos.md` in the Engineering Handbook.

Fill in before use: the branch or the PR number. Run this from the main clone (`~/code/<repo>/<repo>`), not from the worktree you are removing.

Do it after every PR that was merged or closed, and after every review that is finished. Leftovers cost: an old session gets picked up by `claude -c`, and notes written for one PR are loaded by every later session in the repository, where their stale tips mislead the next task.

Order: follow-ups first, then the worktree, branches and sessions, then memory.

## Stop points

- Before deleting anything, show the user the list of what you will delete and wait for confirmation.
- Don't remove a worktree that has uncommitted work, stashed changes or a running process. Report it instead.
- The standing worktrees `review-pr` and `playtest` are never removed: park `review-pr` on `origin/main`, and only stop what runs in `playtest`.
- Don't delete memory notes that hold lessons for every task, or decisions that still apply.

## 1. Collect the follow-ups

Gather everything this task left for later:

- points marked deferred or known limits in the PR description;
- review comments marked `nit:` or "in a later PR";
- notes about this task in the repository's agent memory and in `plans/notes/`;
- things the session said it would do later.

Check each one against the latest `main` and drop what is already done. For the rest, propose issues to the user, then create the ones they approve:

```bash
gh issue create --title "<type>: <summary>" --body "Deferred in #<N>: <details>"
```

Reminders that matter only to the user can go into memory, with the issue number if there is one.

## 2. Confirm the PR is merged or closed

```bash
gh pr view <N> --json state,mergedAt,headRefName
gh pr list --state merged --head <branch>      # after a squash merge, git branch --merged can't tell
```

## 3. Check the worktree is safe to remove

```bash
git -C ../<worktree> status --short --ignored   # only dependencies and build output may remain
git stash list                                  # all worktrees share one stash; it must hold nothing of this task
for p in /proc/[0-9]*; do readlink "$p/cwd" 2>/dev/null | grep -qE "^$HOME/code/<repo>/<worktree>(/|$)" && echo "${p#/proc/}"; done
```

The last command lists processes whose working directory is in the worktree; there must be none. An idle shell left in tmux after the agent exited counts. Don't use `pgrep -f` for this; it matches its own command line.

## 4. Remove the worktree, branches and tmux session

```bash
git pull --ff-only                              # main now has the merged PR
git worktree remove ../<worktree>
git branch -D <branch>                          # after a squash merge, -d refuses
git push origin --delete <branch>               # skip if GitHub already deleted it
git fetch --prune
tmux kill-session -t cc-<worktree>
```

For a standing `review-pr`, instead: `git -C ../review-pr switch --detach origin/main`, and delete any local branch the review created.

## 5. Remove the agent sessions

Claude Code keeps each session as `<session-id>.jsonl` plus a directory of the same name in `~/.claude/projects/<dir>/`, where `<dir>` is the session's working directory with every character that isn't a letter or digit replaced by `-`. For `~/code/<repo>/<worktree>` that is `~/.claude/projects/-home-<user>-code-<repo>-<worktree>/`.

- For a removed worktree, delete that whole directory.
- For the standing `review-pr`, delete only the sessions in it and keep the directory.
- Sessions of the overnight review (`review-pr<N>`) were started in the PR's worktree, so they go with it.

List what you will delete and get confirmation first.

## 6. Clean up memory

Claude Code's memory belongs to the repository, not the worktree: every worktree and the main clone share `~/.claude/projects/<main clone dir>/memory/`, and `MEMORY.md` there is loaded by every session.

- Keep lessons for every task (how the project works, quirks of this machine, settled decisions) and open follow-ups, by issue number if they have one.
- Delete notes about this task alone: tips, restack steps, "next steps". Move anything still undone into step 1 first.
- Afterwards, check that no line in `MEMORY.md` and no `[[link]]` in other notes points to a deleted note.

## 7. Report

What you removed, the issues you created, and what is left for the user.
