# 配置 Claude Code

[English](claude-code.md) | **简体中文**

每台装了 Claude Code 的机器配一次，之后每个会话都从同样的界面和同样的设置开始。只想配 Claude Code、不动系统和终端，看这一篇就够了；整台机器从头配，看[配置工作站](workstation.zh-CN.md)，它会顺带把这一篇做完。

给 agent：[claude-code.md](../../prompts/setup/claude-code.md) 会先检查机器，把只有你能做的事交给你，再安装并测试其余部分。

## 配好之后

| 部分 | 效果 |
|---|---|
| Statusline | 输入框下方：模型、effort、上下文占用、5 小时额度和它多久重置、每周额度（用 Fable 时显示 Fable 的周额度，其他模型显示所有模型合计的周额度），开着 Remote Control 时还有一个绿色的 `rc`；在仓库里还有分支和 worktree |
| Bypass 权限 | 每个新会话执行命令、改文件都不再询问 |
| 复制粘贴 | 选中文字即复制；Ctrl+V 粘贴文字和截图 |
| 不署名 | 不加 co-author 行、PR 结尾说明和会话链接 |
| Remote Control | 每个新会话自动开 Remote Control，在 claude.ai/code 和手机 App 上能接着看、接着回；Claude 也能往手机推通知 |
| 提前自动压缩 | Opus 5.5 和 Fable 5.1 的上下文到约 37 万 token 就自动压缩，不再等到 1M 窗口快满 |

## 规则

- agent 从不运行 sudo。它把命令交给你，你在 Claude Code 里加 `!` 前缀执行，输出会回到对话里。
- bypass 模式意味着没人逐条确认命令。要配合本手册的其他规则一起用：每个 agent 在自己的 worktree 里干活，硬性规则写在 `AGENTS.md` 里，`main` 受保护。不要以 root 身份运行 `claude`。
- 用 Fable 时，statusline 会读本机的登录 token，去查 Fable 的周额度。查的是 `/usage` 用的同一个接口，不消耗 token；token 只交给 `curl`，不会出现在命令行里。

## 步骤

### 1. 安装 Claude Code 并登录

```bash
curl -fsSL https://claude.ai/install.sh | bash   # Claude Code, without sudo; then open a new terminal
claude                                           # log in, then /exit
```

### 2. 安装设置

```bash
git clone https://github.com/jxxsteven7/engineering-handbook.git ~/engineering-handbook
bash ~/engineering-handbook/templates/claude-code/install.sh
```

缺系统包时它会告诉你装什么，比如桌面上贴截图要用的 `xclip`。安装脚本从不用 sudo，可以反复运行。它最后会跑一遍测试，最后一行必须是 `0 FAIL`。然后重启 `claude`。

## 补充说明

- 在 GNOME 上贴截图：按 PrtSc，框选区域，按 Enter，回到 Claude Code 按 Ctrl+V，输入框里会出现 `[Image #1]`。
- Remote Control 要用 claude.ai 账号登录 Claude Code，用 API key 时它不会开。
- 提前自动压缩只给 Opus 5.5 和 Fable 5.1 设了。用别的 1M 上下文模型，照 prompt 里的写法给它加一行。
- 脚本是为 Ubuntu 和 bash 写的。macOS 的情况见 prompt 末尾的移植说明。

<!-- docs-sync: 6446c60627ffe6f1e95c48008bafd98477887e3ccee3b337537eb38d4ff531d7 -->
