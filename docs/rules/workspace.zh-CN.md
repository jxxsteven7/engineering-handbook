# 工作区

[English](workspace.md) | **简体中文**

每项工作放在哪里。三条原则：

1. 一个任务 = 一个分支 = 一个 worktree = 一个 tmux 会话 = 一个 agent 会话，名字全部对应。
2. 主 clone 只用来同步 `main`，永远不在里面开发。
3. 新分支永远显式从 `origin/main` 开，开之前先 `git fetch`。

具体命令见[仓库和 worktree](../tools/git-repos.zh-CN.md)。给 agent：[start-task.md](../../prompts/workspace/start-task.md) 开一个任务，[finish-task.md](../../prompts/workspace/finish-task.md) 任务做完后清理。

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

## 开一个任务

在主 clone 里开 worktree，再在里面开 tmux 和 agent 会话，三者同名：

```bash
cd ~/code/<repo>/<repo>
git fetch origin
git worktree add ../feat-new-task -b feat/new-task origin/main
cd ../feat-new-task
tmux new -s cc-feat-new-task
claude -n feat-new-task
```

- 每个新 worktree 都要各自初始化：被 `.gitignore` 忽略的文件不会跟过来，比如 `.env`、依赖和子模块。
- 每个 worktree 配各自的依赖：一个 venv 的 editable install 只能指向一个 worktree。
- 数据集、checkpoint 不要每个 worktree 拷一份，用环境变量或软链指向共享目录。

## 常驻的 worktree

- `review-pr`：审别人的 PR，以及 stack 里不在顶层的 PR，用法见 [Code review](code-review.zh-CN.md)。
- `playtest`：手动试玩某个版本。它是 detached 的，只测不改；发现 bug 先记下版本，再从 `origin/main` 开一个 fix 的 worktree 去修。

## 任务做完

PR 合并后，删掉它的 worktree、分支和 tmux 会话。agent 的会话记录和这个任务的 memory 笔记也要删，不然会误导下一个会话。没做完的事先开成 issue。

删之前确认三件事：`git status --short` 里没有自己的改动，`git stash list` 为空，没有进程还在这个目录里跑。[finish-task.md](../../prompts/workspace/finish-task.md) 会把这些一并做完。

## 来源

- 这种目录布局是社区惯例，git 和 GitHub 官方没有规定。

<!-- docs-sync: d3d8384972958363da3e1a98234c45e866f74a94bb009693a704d88b9d4898d8 -->
