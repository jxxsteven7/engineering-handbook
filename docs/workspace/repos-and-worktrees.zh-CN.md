# 仓库和 worktree

[English](repos-and-worktrees.md) | **简体中文**

三条原则：

1. 一个任务 = 一个分支 = 一个 worktree = 一个 tmux 会话 = 一个 agent 会话，名字全部对应。
2. 主 clone 只用来同步 `main`，永远不在里面开发。
3. 新分支永远显式从 `origin/main` 开，开之前先 `git fetch`。

给 agent：[set-up-project.md](../../prompts/workspace/set-up-project.md) 第一次把项目拉下来，[start-task.md](../../prompts/workspace/start-task.md) 开一个任务，[finish-task.md](../../prompts/workspace/finish-task.md) 任务做完后清理。

## 目录布局

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

- 所有 worktree 都和主 clone 并列放在项目目录下，不要放进主 clone 里面，否则 IDE 索引、grep、测试都会扫进去。
- 一个分支同一时刻只能被一个 worktree 检出，所以每个任务、每个 agent 都用各自的分支。

## 命名

| 对象 | 规则 | 例子 |
|---|---|---|
| 项目目录、主 clone | 和仓库同名 | `myapp/myapp` |
| 分支 | `<type>/<short-description>`，小写，单词用 `-` 连接 | `feat/lobby` |
| worktree 目录 | 分支名里的 `/` 换成 `-` | `feat-lobby` |
| tmux 会话 | `cc-` 加 worktree 名 | `cc-feat-lobby` |
| agent 会话 | 和 worktree 同名 | `claude -n feat-lobby` |
| remote | `origin` 是你能 push 的仓库，`upstream` 是要提 PR 回去的原仓库，`source` 是只读的代码来源 | |

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

## 开一个任务

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

- 每个 worktree 配各自的依赖：一个 venv 的 editable install 只能指向一个 worktree。
- 数据集、checkpoint 不要每个 worktree 拷一份，用环境变量或软链指向共享目录。

然后开 tmux 和 agent 会话：

```bash
tmux new -s cc-feat-new-task
claude -n feat-new-task
```

## 常驻的 worktree

- `review-pr`：审别人的 PR，用法见 [Code review](../repository/code-review.zh-CN.md)。
- `playtest`：手动试玩某个版本。它是 detached 的，只测不改；发现 bug 先记下版本，再从 `origin/main` 开一个 fix 的 worktree 去修。

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

删之前确认三件事：`git status --short` 里没有自己的改动，`git stash list` 为空，没有进程还在这个目录里跑。没做完的事先开成 issue。agent 的会话记录和这个任务的 memory 笔记也要删，不然会误导下一个会话，[finish-task.md](../../prompts/workspace/finish-task.md) 会把这些一并做完。

## 来源

- [git-worktree](https://git-scm.com/docs/git-worktree)
- GitHub Docs：[Contributing to a project](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project)、[Syncing a fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork)
- 这种目录布局是社区惯例，git 和 GitHub 官方没有规定。

<!-- docs-sync: 917342184b3c699184878762836f05050aae9aa7a1348e789b5f11e152ed88a6 -->
