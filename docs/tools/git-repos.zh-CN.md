# 仓库和 worktree

[English](git-repos.md) | **简体中文**

开仓库、开 worktree、任务做完后清理的 git 命令。为什么这样放、怎么命名，见[工作区](../rules/workspace.zh-CN.md)。

给 agent：[set-up-project.md](../../prompts/workspace/set-up-project.md) 第一次把项目拉下来，[start-task.md](../../prompts/workspace/start-task.md) 开一个任务，[finish-task.md](../../prompts/workspace/finish-task.md) 任务做完后清理。

## 开一个仓库

| 情况 | 做法 |
|---|---|
| 自己或团队的仓库 | 在项目目录下普通 clone |
| 给别人的开源项目提 PR | fork；`origin` 是你的 fork，`upstream` 是原仓库 |
| 拿别人的代码当自己项目的起点 | clone 后把原仓库改名为只读的 `source`，`origin` 换成你自己新建的仓库 |
| 只是试用别人的项目 | 普通 clone，切到一个 release tag；不用 fork，也不用 worktree |

自己或团队的仓库：

```bash
mkdir -p ~/code/<repo> && cd ~/code/<repo>
git clone git@github.com:<org>/<repo>.git          # -> ~/code/<repo>/<repo>
git -C ~/code/<repo>/<repo> pull --ff-only          # sync main, any time later
```

给别人的项目提 PR：

```bash
gh repo fork <owner>/<repo> --clone=false
mkdir -p ~/code/<repo> && cd ~/code/<repo>
git clone git@github.com:<you>/<repo>.git && cd <repo>
git remote add upstream https://github.com/<owner>/<repo>.git
git fetch upstream
git branch --set-upstream-to=upstream/main main     # local main follows the original
gh repo set-default <owner>/<repo>                  # gh pr create targets the original
```

之后新分支从 `upstream/main` 开，推到 `origin`。动手前先读对方的 CONTRIBUTING 和 LICENSE，大改动先开 issue 和维护者对齐。

拿别人的代码起步：

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

保留原仓库的 LICENSE 和署名，README 里写明代码来源。以后想看自己改了什么：`git diff source-code...main --stat`。

只是试用：

```bash
git clone https://github.com/<vendor>/<sdk>.git
cd <sdk> && git checkout <latest-tag>               # pin a release, don't follow main
```

## 开一个 worktree

在主 clone 里执行：

```bash
cd ~/code/<repo>/<repo>
git fetch origin
git worktree add ../feat-new-task -b feat/new-task origin/main                # a new task
git worktree add ../feat-teleop -b feat/teleop --track origin/feat/teleop     # take over a branch from the remote
```

每个新 worktree 都要各自初始化，被 `.gitignore` 忽略的文件不会跟过来：

```bash
cd ../feat-new-task
git submodule update --init --recursive    # if the repository has submodules
cp ../<repo>/.env .env                      # local secrets and settings, if any
npm ci                                      # or: python -m venv .venv && .venv/bin/pip install -e .
git push -u origin feat/new-task
```

然后开 tmux 和 agent 会话：

```bash
tmux new -s cc-feat-new-task
claude -n feat-new-task
```

## 常驻的 worktree

`review-pr` 的命令见 [Code review](../rules/code-review.zh-CN.md)。`playtest` 只建一次，之后切到想试的版本：

```bash
git worktree add --detach ../playtest origin/main   # once, from the main clone
cd ../playtest && git fetch origin --tags
git switch --detach v0.1.0                          # a release; or origin/main for the latest
```

## 任务做完

PR 合并后，在主 clone 里：

```bash
git pull --ff-only
git worktree remove ../feat-new-task
git branch -D feat/new-task                 # after a squash merge, -d refuses
git push origin --delete feat/new-task      # skip if GitHub already deleted it
git fetch --prune
tmux kill-session -t cc-feat-new-task
```

删之前先按[工作区](../rules/workspace.zh-CN.md)里的三件事检查一遍。

## 来源

- [git-worktree](https://git-scm.com/docs/git-worktree)
- GitHub Docs：[Contributing to a project](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project)、[Syncing a fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork)

<!-- docs-sync: 20b6bfa6f3206300c4f1128448b2bf403480135f54e79cd36b94e07e6e6ba13a -->
