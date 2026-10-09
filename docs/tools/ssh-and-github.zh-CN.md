# SSH 和 GitHub

[English](ssh-and-github.md) | **简体中文**

让这台机器用 SSH 推送到 GitHub，再登录 `gh`，用来开 PR、看 CI。这些步骤涉及密钥和账号，你自己做，不交给 agent。

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

<!-- docs-sync: ed3e47ffa3ba14511e2f12422e6c06434674b935a66e54dc8630f4b1739f7fa2 -->
