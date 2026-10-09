# 保护 main

[English](protect-main.md) | **简体中文**

在代码仓库里，每个改动都通过审查过的 PR 进入 `main`。这件事由 GitHub、git hook 和 CI 来保证，不靠谁记着。每个仓库配一次即可。

给 agent：[set-up-repo.md](../../prompts/repository/set-up-repo.md) 会一步步把下面这些全部配好。

## 规则

- 谁都不能往 `main` 提交、推送、强推或删除它，维护者也不例外。
- 每个改动都在自己的分支上完成，开成 PR，用 squash 合并。
- 每个 PR 都要由作者以外的人批准。agent 从不合并。
- 合并前，必需的检查要全部通过，分支也要和 `main` 同步到最新。
- commit 和 PR 里不带任何 agent 署名。

## 三层防护

| 层 | 拦住什么 | 在哪里 |
|---|---|---|
| Git hook | 在 `main` 上提交、推送到 `main`、不合格式的 commit 信息、agent 署名 | `.githooks/` |
| CI | 所有推上去的东西：commit 格式、版本号、测试 | `.github/workflows/` |
| GitHub 规则 | 前两层漏掉的一切 | 仓库设置 |

hook 可以被跳过，CI 只负责报告，所以 GitHub 规则是最后一道防线。

## GitHub 上要设的

- 合并方式：只允许 squash，commit 标题用 PR 标题，合并后自动删除分支。
- 在默认分支上建一个叫 `protect-main` 的 ruleset：禁止删除、禁止强推，必须走 PR 并有一个批准，所有讨论都已解决，必需的检查通过且分支是最新的。
- GitHub Free 不会在私有仓库上执行 ruleset。仓库公开或升级到付费方案之前，保护 `main` 只能靠 hook。
- GitHub 不允许批准自己的 PR。只有你一个维护者时，把需要的批准数设为 0，但保留"必须走 PR"，自己的改动照样自己审。

## 关键命令

每个 clone 打开一次 hook，所有 worktree 都会生效：

```bash
git config core.hooksPath .githooks
```

如果已经在 `main` 上改了文件，把改动挪到一个分支上：

```bash
git stash
git worktree add ../feat-xxx -b feat/xxx origin/main
cd ../feat-xxx && git stash pop
```

不要用 `--no-verify` 跳过 hook。

## 用到你的仓库

要拷的东西都在 [templates/repo/](../../templates/repo/) 里：hook、commit 检查脚本、CI workflow、PR 模板、`CODEOWNERS`，还有一个关掉 Claude Code 署名的 `.claude/settings.json`。把 [set-up-repo.md](../../prompts/repository/set-up-repo.md) 交给 agent，它会拷贝并改好这些文件，再把 GitHub 设置的命令打印出来交给你执行。

## 需要做到哪一步

别人在用的代码，或者有好几个人和 agent 一起改的代码，上面这些都要做。只有文档、只有一个维护者的仓库，做得少一些就够了：直接往 `main` 提交，只保留 `commit-msg` hook 和 push 时跑的 CI。这本手册就是这么做的，见 [CONTRIBUTING.zh-CN.md](../../CONTRIBUTING.zh-CN.md)。

<!-- docs-sync: fd177bd340c71baa67354e150fd472f7a78e8654dbbfcb63f55203341df08951 -->
