# 配置工作站

[English](workstation.md) | **简体中文**

每台机器配一次，之后每个 agent 会话都从同样的工具、同样的界面和同样的规则开始。涉及密钥和账号的步骤你自己做，其余的可以交给 agent。Claude Code 本身的设置单独写在[配置 Claude Code](claude-code.zh-CN.md)，这里的安装脚本会一起做完。

给 agent：[workstation.md](../../prompts/setup/workstation.md) 会先检查机器，把只有你能做的事交给你，再安装并测试其余部分。

## 配好之后

| 部分 | 效果 |
|---|---|
| Git 提示符 | 任何 bash 终端进了仓库，`$` 前面出现 `(branch) [worktree]`，linked worktree 带 `+` |
| ssh 上的颜色 | ssh 登录的机器上，Claude Code 的颜色和本地终端一样深 |
| Claude Code | statusline、默认 bypass、复制粘贴、不署名、自动开 Remote Control、提前自动压缩，见[配置 Claude Code](claude-code.zh-CN.md) |

## 规则

- 密钥、token 和登录都归你。agent 从不生成 SSH key、不读 token、不替你登录。
- agent 从不运行 sudo。它把命令交给你，你在 Claude Code 里加 `!` 前缀执行，输出会回到对话里。

## 步骤

### 1. 系统包

```bash
sudo apt update
sudo apt install -y git tmux jq curl gh
sudo apt install -y xclip            # X11 desktop; wl-clipboard on Wayland; nothing on a server
```

用 `echo $XDG_SESSION_TYPE` 看是哪种：`x11`、`wayland`，ssh 登录时为空。

### 2. Git 身份和默认配置

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
git config --global pull.ff only             # pull never creates a merge commit silently
git config --global fetch.prune true         # drop origin/* refs deleted on the remote
git config --global rebase.autoStash true    # stash and restore around a rebase
git config --global rebase.updateRefs true   # stacked branches follow a rebase (git 2.38 or later)
git config --global rerere.enabled true      # remember conflict resolutions
```

### 3. SSH 和 GitHub

按 [SSH 和 GitHub](ssh-and-github.zh-CN.md) 配好 SSH key，并登录 `gh`。

### 4. Claude Code 和 Codex

```bash
curl -fsSL https://claude.ai/install.sh | bash   # Claude Code, without sudo; then open a new terminal
claude                                           # log in, then /exit
```

用 Codex 的话，运行 `npm install -g @openai/codex`，再运行 `codex` 登录。

### 5. 安装其余部分

```bash
git clone https://github.com/jxxsteven7/engineering-handbook.git ~/engineering-handbook
bash ~/engineering-handbook/templates/workstation/install.sh
```

它先配终端，再接着跑 Claude Code 的安装脚本。两个脚本都从不用 sudo，可以反复运行，各自最后跑一遍测试，最后一行必须是 `0 FAIL`。然后重启 `claude`，再开一个新终端。

## 补充说明

- ssh 登录的机器上，颜色要重新登录一次才生效。想在服务器上的 Claude Code 里也选中即复制、Ctrl+V 贴文字和截图，见 [SSH 和 GitHub](ssh-and-github.zh-CN.md) 的服务器一节。
- 这些脚本是为 Ubuntu 和 bash 写的。macOS 和 zsh 的情况见 prompt 末尾的移植说明。

<!-- docs-sync: 0e8db68bf119465a8fcb44ace07e7062b53f46a9d74a3471b29ebcca7b3ee35e -->
