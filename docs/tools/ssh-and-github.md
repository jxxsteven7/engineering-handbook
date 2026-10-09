# SSH and GitHub

**English** | [简体中文](ssh-and-github.zh-CN.md)

Let this machine push to GitHub over SSH, then log in to `gh` to open pull requests and check CI. These steps involve keys and accounts, so you do them yourself rather than an agent.

## SSH key

One key per machine, named after it, so you can revoke one machine without touching the others.

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "<you>-<machine>-github" -f ~/.ssh/github_ed25519
cat ~/.ssh/github_ed25519.pub        # add it at https://github.com/settings/keys
```

Add this to `~/.ssh/config`:

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
