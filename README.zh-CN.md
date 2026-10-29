# Agentic Engineering Handbook

[English](README.md) | **简体中文**

不得不说，现在agent发展太快了，作为一名Phd in Robotics，我必须学会如何用agent辅助我完成科研和engineering work。但是根据最近半年的一些开发经验来看，我发现虽然现在的agent已经可以自己做好很多事情，但他有时候并不知道什么时候该做，什么时候该停，以及在哪里做，并且很可能会把你的工作空间搞得一团糟。

因此我根据自己的工程经验，总结了一套Agentic Engineering的流程和规则。我认为我们自己在整个开发过程中依然需要要扮演最重要的规划者、决策者的角色。而且这样做能让我们能够快速进步。

至于读者们该如何阅读/使用本repo，我的规划是：其大致分为两部分，第一部分是我来维护的一些rules docs，上面是我总结的如何用agent写代码和做工程的一些经验，和我认为的比较规范的自动化流程，让我们能够对自己/自己的agent在做什么事情有把控，我承诺这部分将由我人为来维护，确保有较好的可读性，也尽可能能让读者读起来有趣一些；第二部分则是根据我的规则生成的自动化prompt md，在有了对规则的理解后，可以将prompt md直接喂给你的agent来完成相关的配置。

具体的，我的这套规则流程包含：

1. 环境配置（准备工作）：
- 在我们的电脑配置好agent，以及一些方便的工具
- 服务器、GitHub及SSH
2. Project协作开发
- main分支保护、GitHub worktree及PR
- code-review和Change List (CL) 参考google
- CI和CD
- 版本管理、Tag及Release
3. 长任务、连续任务提高agentic效率
- 做好plan
- agent监督 / 人应该在哪里决策
4. 开发与维护记录
- 人工维护的Progress Doc，自己清楚自己在干嘛，做了什么
- Project的实验表格
- agent擅长做的可视化实验报告，artifact或website (cloudflare)


## 原则

1. **你来规划，agent 来执行。** agent 动手写代码之前，由你决定做什么、怎么拆成几个 PR，并把具体数值定下来：默认值、上下限、文案。你没定的，agent 会替你定。
2. **清楚你和你的 agent 在做什么。** agent 写的每一行你未必都看，但你始终知道有哪些任务在跑、在哪里跑、进行到哪一步、各自能动哪些东西。如果不能用一句话说清每个任务的状态，就停下来先弄清楚。
3. **每个任务只有一个地址。** 一个任务对应一个分支、一个 worktree、一个终端会话、一个 agent 会话，名字全部一致。主 checkout 只用来同步 `main`，谁都不在里面干活。
4. **一个改动只做一件事。** 一个 PR 只做一件自成一体的事，小到一次就能审完。它以一个带版本号的 squash commit 进入 `main`。
5. **关口由人把守。** agent 交出计划后就停下，等人批准。它从不合并，也从不往 `main` 推送。批准计划和合并 PR 这两件事始终由人来做。
6. **换一双眼睛审查。** 每个改动都由作者以外的人审查，默认是人来审。计划里标明可以交给 agent 的任务，由一个没写过这段代码的新 agent 会话审查和修复，并且 CI 要通过。不管哪种，合并都由人来做，写代码的会话从不给自己的工作下结论。
7. **让机器来执行规则。** 分支保护、git hook 和 CI 会拦住人和 agent 忘掉的事。只写在文档里的规则，迟早有人违反。
8. **做完 = 验证过。** 测试跑过，程序启动过，输出有人看过。"应该没问题"不算做完。
9. **写在下一个会话会去找的地方。** 计划写进文件，决定写进 PR 描述，后续事项开成 issue。agent 的 memory 只留对所有任务都适用的经验。
10. **每个任务做完就清理。** PR 合并后，删掉它的 worktree、分支、会话和笔记。过期的会话和笔记会误导下一个 agent。
11. **你的名字，你的代码。** commit 里不带任何 agent 署名。谁提交，谁就对每一行负责，包括 agent 写的那些。

## 仓库结构

| 文件夹 | 给谁 | 里面是什么 |
|---|---|---|
| `docs/rules/` | 人 | 规则，也就是这套方法本身：做什么、为什么，只留最能说明规则的命令。中英双语，按下面目录的顺序读一遍。 |
| `docs/agents/` | 人 | 和 agent 一起工作：只有用 agent 时才需要的规则，比如并行开发和夜间审查。中英双语，读完规则篇再读。 |
| `docs/tools/` | 人 | 工具用法：工作站、Claude Code、SSH、git 这些具体怎么配、怎么用。中英双语，用到时查。 |
| `prompts/` | agent | 交给 agent 的详细分步说明，让它按同一套规则配置环境或完成任务。只有英文。 |
| `templates/` | 你的电脑和仓库 | 要拷到别处才能运行的真实文件：脚本、hook、CI workflow、空白的计划模板。一般不用你手动拷，prompt 会告诉 agent 拿哪些。 |
| `scripts/`、`.githooks/`、`.github/` | 本仓库 | 本仓库自己的检查。 |

文档简短地告诉人做什么、为什么。prompt 让 agent 去做，每个细节都写清楚，保证每次结果一样。每篇文档都链接到对应的 prompt，每个 prompt 都写明它遵循哪篇文档。把 prompt 交给 agent 之前先读对应的文档，这样你知道 agent 接下来要做什么。

## 目录

### 规则：按顺序读

| 文档 | 给 agent 的 prompt |
|---|---|
| [工作区](docs/rules/workspace.zh-CN.md)：一个任务一个 worktree、目录布局、命名、任务的开始和收尾 | [start-task.md](prompts/workspace/start-task.md)、[finish-task.md](prompts/workspace/finish-task.md) |
| [保护 main](docs/rules/protect-main.zh-CN.md)：分支保护、hook 和 CI | [set-up-repo.md](prompts/repository/set-up-repo.md) |
| [版本与发布](docs/rules/versioning.zh-CN.md)：每个合并的 PR 一个版本号 | [set-up-repo.md](prompts/repository/set-up-repo.md) |
| [Commit 与 PR](docs/rules/commits-and-prs.zh-CN.md)：小改动、清楚的标题、stack | [open-pr.md](prompts/repository/open-pr.md) |
| [Code review](docs/rules/code-review.zh-CN.md)：什么时候批准、看什么 | [review-pr.md](prompts/repository/review-pr.md) |
| [分阶段开源](docs/rules/staged-open-source.zh-CN.md)：把 tag 做成快照发布，或者公开、私有两个仓库，内部历史都不公开 | |

给你仓库用的文件：[templates/repo/](templates/repo/)。

### Agent：读完规则再读

| 文档 | 给 agent 的 prompt |
|---|---|
| [并行开发和夜间自动审查](docs/agents/overnight.zh-CN.md)（试行）：脚本盯 PR，新会话审查，更强的模型修复，人来合并 | [overnight.md](prompts/agents/overnight.md) |

夜间流程用的文件：[templates/overnight/](templates/overnight/)。

### 工具：用到时查

| 文档 | 给 agent 的 prompt |
|---|---|
| [配置工作站](docs/tools/workstation.zh-CN.md)：系统包、git 配置、Claude Code 和 Codex、git 提示符，以及下一行的全部内容 | [workstation.md](prompts/setup/workstation.md) |
| [配置 Claude Code](docs/tools/claude-code.zh-CN.md)：statusline、bypass 权限、复制粘贴、不署名、Remote Control、提前自动压缩 | [claude-code.md](prompts/setup/claude-code.md) |
| [SSH 和 GitHub](docs/tools/ssh-and-github.zh-CN.md)：SSH key、`~/.ssh/config`、`gh` 登录、服务器上的剪贴板 | 密钥和登录你自己做；服务器上的剪贴板：把 [workstation.md](prompts/setup/workstation.md) 和服务器别名交给 agent |
| [Git 常用命令](docs/tools/git-commands.zh-CN.md)：看状态和历史、和远程同步、提交、分支、stash、标签 | |
| [仓库和 worktree](docs/tools/git-repos.zh-CN.md)：开仓库的几种情况、开 worktree、任务做完后清理 | [set-up-project.md](prompts/workspace/set-up-project.md)、[start-task.md](prompts/workspace/start-task.md)、[finish-task.md](prompts/workspace/finish-task.md) |
| [Git 救急](docs/tools/git-first-aid.zh-CN.md)：rebase 冲突和常见意外 | |

给你电脑用的文件：[templates/workstation/](templates/workstation/)、[templates/claude-code/](templates/claude-code/)。

### 接下来要写

- Agent：和 agent 一起做规划；运行单个开发会话；给 agent 的指令（`AGENTS.md`、`CLAUDE.md`、memory 怎么分工）。
- 工具：服务器的 SSH 配置、tmux、Claude Code 和 Codex 的会话管理。

## 快速上手

**给人看。** 先读上面的原则，再按顺序读规则篇和 agent 篇。工具篇用到时再查。

**给 agent 用。** 把这个仓库 clone 下来，然后让 agent 读对应的 prompt：

```bash
git clone https://github.com/jxxsteven7/engineering-handbook.git ~/engineering-handbook
```

```text
Read ~/engineering-handbook/prompts/repository/set-up-repo.md and follow it for this repository.
```

在 Claude Code 里也可以输入 `@` 再接文件路径。每个 prompt 都写明了它会在哪里停下来等你。

## 参与本仓库

- Claude Code 和 Codex 遵循同一套规则：Codex 读 [AGENTS.md](AGENTS.md)，Claude Code 通过 [CLAUDE.md](CLAUDE.md) 引入它。
- 文档怎么写、怎么翻译：见 [CONTRIBUTING.zh-CN.md](CONTRIBUTING.zh-CN.md)。这是一个只有一个维护者的文档仓库，所以改动直接提交到 `main`，没有版本号。

## 来源与协议

- commit、PR 和 code review 几篇改编自 Google 的 [Engineering Practices](https://google.github.io/eng-practices/)，协议为 [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/)。
- 本仓库公开前会补上协议文件。

<!-- docs-sync: ef93bdc1575c254b25e039fb792816fc687f01111dd55081fe7f73c1e28bc6e8 -->
