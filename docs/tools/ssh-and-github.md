# SSH and GitHub

**English** | [简体中文](ssh-and-github.zh-CN.md)

Let this machine push to GitHub and reach your servers over SSH, then log in to `gh` to open pull requests and check CI. You set up keys and logins yourself, not an agent.

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

## Servers

Give each server you use an alias in `~/.ssh/config`, so that `ssh <alias>` logs you in. The last two lines turn on X11 forwarding: through it, Claude Code on the server uses your machine's clipboard directly, so copy on select and Ctrl+V for text and screenshots work as they do locally.

```text
Host <alias>
    HostName <ip-or-domain>
    User <user>
    ForwardX11 yes
    ForwardX11Trusted yes
```

- Turn it on only for servers you trust, never under `Host *`. While it is on, anyone with root on the server can take screenshots of your machine, log your keystrokes and read your clipboard.
- The server also needs `xclip` and a function in `~/.bashrc`. Leave that to an agent: in Claude Code on your own machine, give it [workstation.md](../../prompts/setup/workstation.md) together with the server's alias.
- A `claude` that is already running doesn't change; start it again in a new ssh login.
