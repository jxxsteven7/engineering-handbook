# Git 常用命令

[English](git-commands.md) | **简体中文**

日常最常用的 git 命令，按要做的事分组，用到时查。开仓库和 worktree 见[仓库和 worktree](git-repos.zh-CN.md)，提交错了或 rebase 冲突见 [Git 救急](git-first-aid.zh-CN.md)。

## 看状态和历史

| 想看什么 | 命令 |
|---|---|
| 在哪个分支、改了哪些文件 | `git status` |
| 还没暂存的改动 | `git diff` |
| 已暂存、下次提交会带上的改动 | `git diff --staged` |
| 最近的提交 | `git log --oneline -10` |
| 所有分支画成一张图 | `git log --oneline --graph --all` |
| 某个提交改了什么 | `git show <sha>` |
| 一个文件的每次改动 | `git log -p -- <file>` |
| 每一行最后是哪个提交改的 | `git blame <file>` |
| 哪个提交加入或删掉了某段文字 | `git log -S '<text>'` |

## 和远程同步

`git status` 不联网，它只拿本地分支和本地记下的 `origin/main` 比。`origin/main` 只在 fetch、pull、push 的时候更新，所以 status 说 up to date，只代表和上次同步时一致，GitHub 上后来有没有新提交它不知道。要看真实状态，先 fetch。

```text
git fetch    GitHub -> origin/main            download only; your branch and files don't change
git pull     git fetch + merge origin/main    with --ff-only, only if main has no commits of its own
git status   main vs origin/main              offline
```

| 想做什么 | 命令 |
|---|---|
| 本地比 GitHub 落后或领先几个提交 | `git fetch && git status` |
| 每个本地分支跟着哪个远程分支、差几个提交 | `git fetch && git branch -vv` |
| pull 会拉下来哪些提交 | `git log --oneline main..origin/main` |
| push 会推上去哪些提交 | `git log --oneline origin/main..main` |
| 把 GitHub 上的新提交拿下来 | `git pull --ff-only` |
| 第一次推送一个新分支 | `git push -u origin <branch>` |
| 之后再推送 | `git push` |
| 远程仓库的地址 | `git remote -v` |

fetch 只下载，不动你的分支和文件，随时可以跑，看完再决定要不要 pull。

## 提交

| 想做什么 | 命令 |
|---|---|
| 暂存一个文件 | `git add <file>` |
| 一段一段挑要暂存的改动 | `git add -p` |
| 取消暂存，改动留着 | `git restore --staged <file>` |
| 丢掉一个文件还没暂存的改动 | `git restore <file>` |
| 提交 | `git commit -m "<type>: <summary>"` |

标题怎么写见 [Commit 与 PR](../rules/commits-and-prs.zh-CN.md)。提交之后想改或撤回，见 [Git 救急](git-first-aid.zh-CN.md)。

## 分支

新任务按[工作区](../rules/workspace.zh-CN.md)的做法开在自己的 worktree 里。在一个 checkout 里看和换分支：

| 想做什么 | 命令 |
|---|---|
| 列出本地和远程的分支 | `git branch -a` |
| 换到另一个分支 | `git switch <branch>` |
| 从最新的 `main` 开一个新分支 | `git fetch && git switch -c <branch> origin/main` |
| 当前分支比 `main` 多改了哪些文件 | `git diff --stat origin/main...HEAD` |
| 删掉本地分支 | `git branch -d <branch>`，squash 合并过的要用 `-D` |

## 收起手头的改动

| 想做什么 | 命令 |
|---|---|
| 收起改动，工作区变干净 | `git stash` |
| 连新建的文件一起收 | `git stash -u` |
| 看收起了哪些 | `git stash list` |
| 拿回最近收的那次 | `git stash pop` |

## 版本标签

标签由 CI 打，见[版本与发布](../rules/versioning.zh-CN.md)。

| 想做什么 | 命令 |
|---|---|
| 列出所有标签，新的在前 | `git fetch --tags && git tag --sort=-v:refname` |
| 切到某个版本看看 | `git switch --detach <tag>` |
| 回到 `main` | `git switch main` |

## 来源

- Pro Git：[Remote Branches](https://git-scm.com/book/en/v2/Git-Branching-Remote-Branches)
- [git-fetch](https://git-scm.com/docs/git-fetch)、[git-status](https://git-scm.com/docs/git-status)、[git-stash](https://git-scm.com/docs/git-stash)

<!-- docs-sync: 9c567b66b56099f85280835b64cf755b817036f1ac60dd7dba28fb4e51efdf53 -->
