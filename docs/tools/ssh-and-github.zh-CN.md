# SSH 和 GitHub

[English](ssh-and-github.md) | **简体中文**

让这台机器用 SSH 推送到 GitHub、连服务器，再登录 `gh`，用来开 PR、看 CI。密钥和登录你自己做，不交给 agent。

## SSH key

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

## GitHub CLI

```bash
gh auth login                        # GitHub CLI, for pull requests and checks
```

## 服务器

给常用的服务器在 `~/.ssh/config` 里起个别名，以后 `ssh <alias>` 就能登录。最后两行打开 X11 转发：服务器上的 Claude Code 借它直接用你本机的剪贴板，选中即复制、Ctrl+V 贴文字和截图，都和在本机一样。

```text
Host <alias>
    HostName <ip-or-domain>
    User <user>
    ForwardX11 yes
    ForwardX11Trusted yes
```

- 只给自己信任的服务器开，不要写在 `Host *` 下。开着的时候，服务器上有 root 权限的人能截你本机的屏、记录键盘、读剪贴板。
- 服务器上还要装 `xclip`，并在 `~/.bashrc` 里加一个函数。这一步交给 agent：在本机的 Claude Code 里，把 [workstation.md](../../prompts/setup/workstation.md) 和服务器的别名一起给它就行。
- 已经在跑的 `claude` 不会变，要在新的 ssh 登录里重新启动。

<!-- docs-sync: ba68e694b3c47e5601fd8892410fd54141fa68171c0a1da085e19f24a3069634 -->
