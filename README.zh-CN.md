# Agentic Engineering Handbook

[English](README.md) | **简体中文**

当 Claude Code、Codex 这类编程 agent 写了大部分代码，项目该怎么管：每项工作放在哪里，agent 做什么、什么时候停下，哪些事还得你自己来。

好的 agent 知道什么时候该做，什么时候该停，以及在哪里做。这三点都是从你这里学来的：从你给它的计划里，从你组织项目的方式里。这本手册讲的就是怎么做计划、怎么组织项目。

> [!NOTE]
> 仍在编写中。内容都来自真实项目的日常使用。标为试行的部分还在验证。

## 原则

1. **你来规划，agent 来执行。** agent 动手写代码之前，由你决定做什么、怎么拆成几个 PR，并把具体数值定下来：默认值、上下限、文案。你没定的，agent 会替你定。
2. **清楚你和你的 agent 在做什么。** agent 写的每一行你未必都看，但你始终知道有哪些任务在跑、在哪里跑、进行到哪一步、各自能动哪些东西。如果不能用一句话说清每个任务的状态，就停下来先弄清楚。
3. **每个任务只有一个地址。** 一个任务对应一个分支、一个 worktree、一个终端会话、一个 agent 会话，名字全部一致。主 checkout 只用来同步 `main`，谁都不在里面干活。
4. **一个改动只做一件事。** 一个 PR 只做一件自成一体的事，小到一次就能审完。它以一个带版本号的 squash commit 进入 `main`。
5. **关口由人把守。** agent 交出计划后就停下，等人批准。它从不合并，也从不往 `main` 推送。批准计划和合并 PR 这两件事始终由人来做。
6. **换一双眼睛审查。** 每个改动都由作者以外的人审查。没写过这段代码的新 agent 会话可以先过一遍。agent 对自己工作的结论不算审查。
7. **让机器来执行规则。** 分支保护、git hook 和 CI 会拦住人和 agent 忘掉的事。只写在文档里的规则，迟早有人违反。
8. **做完 = 验证过。** 测试跑过，程序启动过，输出有人看过。"应该没问题"不算做完。
9. **写在下一个会话会去找的地方。** 计划写进文件，决定写进 PR 描述，后续事项开成 issue。agent 的 memory 只留对所有任务都适用的经验。
10. **每个任务做完就清理。** PR 合并后，删掉它的 worktree、分支、会话和笔记。过期的会话和笔记会误导下一个 agent。
11. **你的名字，你的代码。** commit 里不带任何 agent 署名。谁提交，谁就对每一行负责，包括 agent 写的那些。

## 仓库结构

| 文件夹 | 给谁 | 里面是什么 |
|---|---|---|
| `docs/` | 人 | 原则和最重要的命令，中英双语。从这里开始读。 |
| `prompts/` | agent | 交给 agent 的详细分步说明，让它按同一套规则配置环境或完成任务。只有英文。 |
| `templates/` | 你的电脑和仓库 | 要安装或拷贝的文件：工作站脚本，以及给仓库用的 hook、检查脚本和 CI workflow。 |
| `scripts/`、`.githooks/`、`.github/` | 本仓库 | 本仓库自己的检查。 |

doc 简短地告诉人做什么、为什么。prompt 让 agent 去做，每个细节都写清楚，保证每次结果一样。`docs/` 和 `prompts/` 按同样的主题分文件夹，每篇 doc 都链接到对应的 prompt，每个 prompt 都写明它遵循哪篇 doc。把 prompt 交给 agent 之前先读对应的 doc，这样你知道 agent 接下来要做什么。

| 主题 | 回答的问题 |
|---|---|
| `setup/` | 我的电脑和 agent 怎么配置？ |
| `workspace/` | 每项工作放在哪里？ |
| `repository/` | 一个改动怎么进入 `main`？ |
| `agents/` | 怎么给 agent 规划工作、运行它们、让它们通宵干活？ |

## 目录

### 配置：电脑和 agent

| 文档 | 给 agent 的 prompt |
|---|---|
| [配置工作站](docs/setup/workstation.zh-CN.md)：系统包、git、SSH、登录、statusline、git 提示符、权限 | [workstation.md](prompts/setup/workstation.md) |

给你电脑用的文件：[templates/workstation/](templates/workstation/)。

### 仓库：改动怎么进入 main

| 文档 | 给 agent 的 prompt |
|---|---|
| [保护 main](docs/repository/protect-main.zh-CN.md)：分支保护、hook 和 CI | [set-up-repo.md](prompts/repository/set-up-repo.md) |
| [版本与发布](docs/repository/versioning.zh-CN.md)：每个合并的 PR 一个版本号 | [set-up-repo.md](prompts/repository/set-up-repo.md) |
| [Commit 与 PR](docs/repository/commits-and-prs.zh-CN.md)：小改动、清楚的标题、stack | [open-pr.md](prompts/repository/open-pr.md) |
| [Code review](docs/repository/code-review.zh-CN.md)：什么时候批准、看什么 | [review-pr.md](prompts/repository/review-pr.md) |

给你仓库用的文件：[templates/repo/](templates/repo/)。

### 接下来要写

- `setup/`：给 agent 的指令（`AGENTS.md`、`CLAUDE.md`、memory）。
- `workspace/`：目录布局和命名、worktree、任务完成后的清理、git 救急。
- `agents/`：规划、运行一个 agent 会话、并行开发和夜间审查。

## 快速上手

**给人看。** 先读上面的原则，再读你手头这个主题的文档。

**给 agent 用。** 把这个仓库 clone 下来，然后让 agent 读对应的 prompt：

```bash
git clone https://github.com/jxxsteven7/agentic-engineering-handbook.git ~/agentic-engineering-handbook
```

```text
Read ~/agentic-engineering-handbook/prompts/repository/set-up-repo.md and follow it for this repository.
```

在 Claude Code 里也可以输入 `@` 再接文件路径。每个 prompt 都写明了它会在哪里停下来等你。

## 参与本仓库

- Claude Code 和 Codex 遵循同一套规则：Codex 读 [AGENTS.md](AGENTS.md)，Claude Code 通过 [CLAUDE.md](CLAUDE.md) 引入它。
- 文档怎么写、怎么翻译：见 [CONTRIBUTING.zh-CN.md](CONTRIBUTING.zh-CN.md)。这是一个只有一个维护者的文档仓库，所以改动直接提交到 `main`，没有版本号。

## 来源与协议

- commit、PR 和 code review 几篇改编自 Google 的 [Engineering Practices](https://google.github.io/eng-practices/)，协议为 [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/)。
- 本仓库公开前会补上协议文件。

<!-- docs-sync: 1c32644f82a050695b8490e16cc82318e21aa2d94668789ec87da46970e7b157 -->
