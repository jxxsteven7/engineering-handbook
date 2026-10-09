# Git 救急

[English](git-first-aid.md) | **简体中文**

出了意外先别慌：只要提交过，`git reflog` 几乎都能找回来。下面是最常见的情况。

## Rebase

```bash
git rebase origin/main                          # replant the current branch on the latest main
git rebase --onto origin/main <old-base>        # move only the commits after <old-base>
git rebase -i origin/main                       # reorder, squash or reword your own commits
git commit --fixup <sha> && git rebase -i --autosquash origin/main   # fold a fix into an earlier commit
```

冲突时：

```bash
git status                                      # which files conflict
git add <files> && git rebase --continue        # after resolving them
git rebase --abort                              # give up and go back to where you started
git reset --hard ORIG_HEAD                      # the rebase finished, but you regret it
```

- rebase 之后用 `--force-with-lease` 推送，不要用 `--force`。
- 不要 rebase 别人也在用的分支。
- 别人强推了你本地也有的分支：确认本地没有自己的提交后，`git fetch && git reset --hard origin/<branch>`。

## 各种意外

| 情况 | 处理 |
|---|---|
| 在 `main` 上直接提交了，还没推送 | `git switch -c feat/xxx` 把提交带到新分支，再 `git branch -f main origin/main` 把 `main` 拨回去 |
| 改了一半发现站错了分支，还没提交 | `git switch -c <new-branch>` 直接带走改动；要去已有的分支，就 `git stash`，切过去，再 `git stash pop` |
| 最后一次提交写错了，还没推送 | 改信息或补文件用 `git commit --amend`；整个撤回但保留改动用 `git reset --soft HEAD~1` |
| 某个文件想恢复成 `main` 上的样子 | `git restore --source origin/main -- <file>` |
| 只想要另一个分支上的某一个提交 | `git cherry-pick <sha>` |
| 已经合进 `main` 的 PR 有问题 | 不要改写 `main`。开一个新分支，`git revert <sha>`（squash 之后的那个提交），走正常的 PR |
| reset 或 rebase 之后提交"丢了" | 用 `git reflog` 找到之前的 sha，再 `git branch rescue <sha>` |
| 不知道哪个提交引入了 bug | `git bisect start`、`git bisect bad`、`git bisect good <tag>`，然后 `git bisect run <test command>` |
| squash 合并后，分支到底合了没有 | `gh pr list --state merged --head <branch>`。`git branch --merged` 按哈希判断，squash 之后会说没合并 |
| worktree 目录被直接 `rm -rf` 了 | `git worktree prune` 清掉残留的记录 |
| 密钥被提交并推送了 | 先去平台上作废密钥、重新生成，再处理 git 历史。只删提交不换密钥没有用 |
| 线上版本要紧急修复 | 从 `origin/main` 或对应的 release tag 开一个 `fix/<what>` 的 worktree，修完照常走 PR |

## 来源

- [git-rebase](https://git-scm.com/docs/git-rebase)、[git-reflog](https://git-scm.com/docs/git-reflog)、[git-bisect](https://git-scm.com/docs/git-bisect)

<!-- docs-sync: 06a04d69fdff2f18e8def8563934a590ece5f5f1435936c83236f8f41ca78d52 -->
