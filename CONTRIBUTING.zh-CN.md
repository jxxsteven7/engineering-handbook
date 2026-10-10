# 参与贡献

[English](CONTRIBUTING.md) | **简体中文**

这个仓库怎么写、怎么维护。规则对所有人都适用，包括 AI agent。

## 改动怎么进来

- 这是一个文档仓库，只有一个维护者，所以维护者直接往 `main` 提交。不开分支、不走 PR、没有版本号；[完整流程](docs/rules/protect-main.zh-CN.md)是给有人依赖的代码准备的。
- 外部贡献者 fork 仓库后提 PR。
- 有两道检查仍然保留。`commit-msg` hook 检查每条 commit 信息：`<type>: <summary>`、英文、没有 AI 或 agent 署名。每次 push，CI 检查每篇文档和译文是否一致、脚本测试是否通过、commit 里有没有署名。`pre-commit` hook 只在文档需要同步时提醒一下。
- 里程碑（比如第一次公开）手动打 tag。

## 准备

需要 git 和 Node.js 22 或更新版本。

```bash
git clone git@github.com:jxxsteven7/agentic-engineering-handbook.git
cd agentic-engineering-handbook
git config core.hooksPath .githooks
```

## 三类文件

- `docs/` 给人看，中英双语，分两个文件夹。`docs/rules/` 是规则，也就是这套方法本身：做什么、为什么，每条规则只留一两条最能说明它的命令。`docs/tools/` 是工具用法，比如 git、SSH 具体怎么用，用到时再查。每篇都要短。
- `prompts/` 给 agent 用，只有英文。prompt 要把每一步、确切的命令、在哪里停下来等人、怎么检查结果都写清楚。每个 prompt 开头写明它遵循哪篇文档，文档里也链接回它。
- `templates/` 放给别人装到自己电脑上、或者拷到自己仓库里的文件。里面每个脚本都有测试，CI 会跑。

`prompts/` 按主题分文件夹：`setup/`、`workspace/`、`repository/`、`agents/`。新的规则放进 `docs/rules/`。某个工具的一组新命令放进 `docs/tools/`，用到它的规则篇再链接过去。新加的文档和 prompt 都要在 README 的目录表里链接。

## 写一篇文档

文档的原则只有三个词：简单、简洁、可读。一篇几分钟读完，每句话都有用，没用过这些工具的人也能照着做。拿不准要不要写的，就不写。

1. 用一种语言写或改文档，一般是中文（`X.zh-CN.md`）。要短、要直白：先说做什么，再说为什么，只放大家真正会敲的命令。放进去的每条命令都要亲自跑过。
2. 在 Claude Code 里运行 `/sync-docs`。它只在你改过的地方更新另一种语言，用 humanizer skill 打磨新写的文字，记录同步戳，再跑检查。用 Codex 的话，让它按 `.claude/skills/sync-docs/SKILL.md` 去做。
3. 看一遍结果，然后把两种语言一起提交。

两个文件必须保持对应，同步检查会强制这一点：

- 标题、段落、列表项、引用和表格都一样多，顺序相同；
- 代码块完全相同，所以代码里的注释用英文；
- 行内代码完全相同；
- 链接指向其他文档的同语言版本，开头放语言切换。

检查判断不了译文意思是否一致，所以提交前要看一遍 diff。如果只提交了一种语言，pre-commit hook 会提醒你，push 之后 CI 也会报错，直到两边一致。想看哪些需要同步，或者手动跑检查：

```bash
node scripts/check-docs-sync.mjs --status
node scripts/check-docs-sync.mjs
node --test scripts/*.test.mjs templates/repo/scripts/*.test.mjs
SCRIPTS_ONLY=1 bash templates/workstation/accept.sh
bash templates/workstation/selftest-clipboard.sh
bash templates/overnight/selftest.sh
```

## 和 agent 一起工作

- Codex 读 [AGENTS.md](AGENTS.md)。Claude Code 读 [CLAUDE.md](CLAUDE.md)，它引入了 `AGENTS.md`，所以两者遵守同一套规则。
- 想把某个文件带进对话，用 `@` 引用它，例如 `@docs/rules/code-review.md check that this doc matches its prompt`。

<!-- docs-sync: 1d1181b0ee071490832b105f252d4a5267e141e7be5a98fc4fd103fed9c81d73 -->
