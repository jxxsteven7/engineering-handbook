# 配置工作站

[English](workstation.md) | **简体中文**

每台机器配一次，之后每个 agent 会话都从同样的工具、同样的界面和同样的规则开始。涉及密钥和账号的步骤你自己做，其余的可以交给 agent。

给 agent：[workstation.md](../../prompts/setup/workstation.md) 会先检查机器，把只有你能做的事交给你，再安装并测试其余部分。

## 配好之后

| 部分 | 效果 |
|---|---|
| Statusline | Claude Code 输入框下方：模型、effort、上下文占用和周额度；在仓库里还有分支和 worktree |
| Git 提示符 | 任何 bash 终端进了仓库，`$` 前面出现 `(branch) [worktree]`，linked worktree 带 `+` |
| Bypass 权限 | 每个新的 Claude Code 会话执行命令、改文件都不再询问 |
| 复制粘贴 | 选中文字即复制；Ctrl+V 粘贴文字和截图 |
| 不署名 | Claude Code 不加 co-author 行、PR 结尾说明和会话链接 |

## 规则

- 密钥、token 和登录都归你。agent 从不生成 SSH key、不读 token、不替你登录。
- agent 从不运行 sudo。它把命令交给你，你在 Claude Code 里加 `!` 前缀执行，输出会回到对话里。
- bypass 模式意味着没人逐条确认命令。要配合本手册的其他规则一起用：每个 agent 在自己的 worktree 里干活，硬性规则写在 `AGENTS.md` 里，`main` 受保护。不要以 root 身份运行 `claude`。

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

### 3. GitHub 的 SSH key

每台机器一把 key，以机器命名，这样作废一台机器的 key 不会影响其他机器。

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "<you>-<machine>-github" -f ~/.ssh/github_ed25519
cat ~/.ssh/github_ed25519.pub        # add it at https://github.com/settings/keys
```

把下面这段加进 `~/.ssh/config`：

```text
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_ed25519
    IdentitiesOnly yes
```

```bash
chmod 600 ~/.ssh/config
ssh -T git@github.com                # "Hi <you>! You've successfully authenticated"
```

### 4. 登录

```bash
gh auth login                                    # GitHub CLI, for pull requests and checks
curl -fsSL https://claude.ai/install.sh | bash   # Claude Code, without sudo; then open a new terminal
claude                                           # log in, then /exit
```

用 Codex 的话，运行 `npm install -g @openai/codex`，再运行 `codex` 登录。

### 5. 安装其余部分

```bash
git clone https://github.com/jxxsteven7/agentic-engineering-handbook.git ~/agentic-engineering-handbook
bash ~/agentic-engineering-handbook/templates/workstation/install.sh
```

安装脚本从不用 sudo，可以反复运行。它最后会跑一遍测试，最后一行必须是 `0 FAIL`。然后重启 `claude`，再开一个新终端。

## 补充说明

- 在 GNOME 上贴截图：按 PrtSc，框选区域，按 Enter，回到 Claude Code 按 Ctrl+V，输入框里会出现 `[Image #1]`。
- ssh 登录的机器上，安装脚本会让颜色和本地终端一致，重新登录一次即可。Ctrl+V 读的是服务器的剪贴板，所以图片要先用 `scp` 传过去，再给出路径。
- 这些脚本是为 Ubuntu 和 bash 写的。macOS 和 zsh 的情况见 prompt 末尾的移植说明。

<!-- docs-sync: c66b9d8787fb4a691def2a5eef64adb81834aa8a35c7e61429955ed48b291eeb -->
