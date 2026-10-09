# 参与贡献

[English](CONTRIBUTING.md) | **简体中文**

这个仓库怎么写、怎么维护。规则对所有人都适用，包括 AI agent。

## 改动怎么进来

- 这是一个文档仓库，只有一个维护者，所以维护者直接往 `main` 提交。不开分支、不走 PR、没有版本号；[完整流程](docs/repository/protect-main.zh-CN.md)是给有人依赖的代码准备的。
- 外部贡献者 fork 仓库后提 PR。
- 有两道检查仍然保留。`commit-msg` hook 检查每条 commit 信息：`<type>: <summary>`、英文、没有 AI 或 agent 署名。每次 push，CI 检查每篇文档和译文是否一致、脚本测试是否通过、commit 里有没有署名。
- 里程碑（比如第一次公开）手动打 tag。

## 准备

需要 git 和 Node.js 22 或更新版本。

```bash
git clone git@github.com:jxxsteven7/agentic-engineering-handbook.git
cd agentic-engineering-handbook
git config core.hooksPath .githooks
```

## 三类文件

- `docs/` 给人看：原则和最重要的命令，中英双语。每篇都要短。
- `prompts/` 给 agent 用，只有英文。prompt 要把每一步、确切的命令、在哪里停下来等人、怎么检查结果都写清楚。每个 prompt 开头写明它遵循哪篇文档，文档里也链接回它。
- `templates/` 放给别人拷到自己仓库里的文件。里面每个脚本都有测试，CI 会跑。

`docs/` 和 `prompts/` 共用 `setup/`、`workspace/`、`repository/`、`agents/` 这几个主题文件夹。新加的文档和 prompt 都要在 README 的目录表里链接。

## 写一篇文档

1. 先写英文版 `X.md`。先说做什么，再说为什么，只放大家真正会敲的命令。放进去的每条命令都要亲自跑过。
2. 把英文改得自然。用 Claude Code 的话，对这个文件运行 [humanizer](https://github.com/blader/humanizer) skill。
3. 逐块翻译成 `X.zh-CN.md`：
   - 标题、段落、列表项、引用和表格都一样多，顺序相同；
   - 代码块原样照抄，所以代码里的注释用英文；
   - 行内代码完全相同；
   - 链接指向其他文档的中文版，开头放语言切换。
4. 把中文改得自然。用 Claude Code 的话，对这个文件运行 [humanizer-zh](https://github.com/op7418/humanizer-zh) skill。
5. 记录同步戳，跑检查：

   ```bash
   node scripts/check-docs-sync.mjs --update docs/topic/X.md
   node scripts/check-docs-sync.mjs
   node --test scripts/*.test.mjs templates/repo/scripts/*.test.mjs
   ```

同步检查比较的是结构、代码和链接，判断不了译文意思是否一致，所以记录同步戳之前，两个版本都要读一遍。以后改一篇文档时，两种语言在同一个 commit 里一起改。

## 和 agent 一起工作

- Codex 读 [AGENTS.md](AGENTS.md)。Claude Code 读 [CLAUDE.md](CLAUDE.md)，它引入了 `AGENTS.md`，所以两者遵守同一套规则。
- 想把某个文件带进对话，用 `@` 引用它，例如 `@docs/repository/code-review.md check that this doc matches its prompt`。

<!-- docs-sync: 1ae911f7f014507fcc20ca06ecc66c10b3ab2ecc84069723a96d0e476b220c30 -->
