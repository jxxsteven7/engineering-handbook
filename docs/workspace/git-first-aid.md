# Git first aid

**English** | [简体中文](git-first-aid.zh-CN.md)

Don't panic: anything that was ever committed can almost always be found again with `git reflog`. These are the most common accidents.

## Rebase

```bash
git rebase origin/main                          # replant the current branch on the latest main
git rebase --onto origin/main <old-base>        # move only the commits after <old-base>
git rebase -i origin/main                       # reorder, squash or reword your own commits
git commit --fixup <sha> && git rebase -i --autosquash origin/main   # fold a fix into an earlier commit
```

When there are conflicts:

```bash
git status                                      # which files conflict
git add <files> && git rebase --continue        # after resolving them
git rebase --abort                              # give up and go back to where you started
git reset --hard ORIG_HEAD                      # the rebase finished, but you regret it
```

- After a rebase, push with `--force-with-lease`, never `--force`.
- Never rebase a branch that other people also use.
- Someone force-pushed a branch you also have locally: make sure you have no commits of your own on it, then `git fetch && git reset --hard origin/<branch>`.

## Accidents

| What happened | What to do |
|---|---|
| You committed on `main` and haven't pushed | `git switch -c feat/xxx` takes the commits to a new branch, then `git branch -f main origin/main` moves `main` back |
| Halfway through, you're on the wrong branch and haven't committed | `git switch -c <new-branch>` takes the changes with you; for an existing branch, `git stash`, switch, then `git stash pop` |
| The last commit is wrong and hasn't been pushed | To fix the message or add a file, `git commit --amend`; to undo it but keep the changes, `git reset --soft HEAD~1` |
| You want a file back the way it is on `main` | `git restore --source origin/main -- <file>` |
| You want one commit from another branch | `git cherry-pick <sha>` |
| A PR already merged into `main` is broken | Don't rewrite `main`. On a new branch, `git revert <sha>` (the squash commit), and open a normal PR |
| Commits "disappeared" after a reset or rebase | Find the old sha with `git reflog`, then `git branch rescue <sha>` |
| You don't know which commit introduced a bug | `git bisect start`, `git bisect bad`, `git bisect good <tag>`, then `git bisect run <test command>` |
| After a squash merge, you can't tell whether a branch was merged | `gh pr list --state merged --head <branch>`. `git branch --merged` compares hashes, so after a squash it says no |
| A worktree directory was deleted with `rm -rf` | `git worktree prune` clears what is left of it |
| A secret was committed and pushed | First revoke it and create a new one on the platform, then clean up the history. Deleting the commit without replacing the secret does nothing |
| A released version needs an urgent fix | Start a `fix/<what>` worktree from `origin/main` or the release tag, fix it, and open a normal PR |

## Sources

- [git-rebase](https://git-scm.com/docs/git-rebase), [git-reflog](https://git-scm.com/docs/git-reflog), [git-bisect](https://git-scm.com/docs/git-bisect)
