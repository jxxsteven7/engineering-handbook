# Set up a workstation

**English** | [简体中文](workstation.zh-CN.md)

Set up each machine once, so that every agent session starts with the same tools, the same view and the same rules. You do the steps that involve keys and accounts; an agent can do the rest. The settings of Claude Code itself are on a page of their own, [Set up Claude Code](claude-code.md); the installer here does them too.

For agents: [workstation.md](../../prompts/setup/workstation.md) checks the machine, asks you for what only you can do, then installs and tests the rest.

## What you get

| Part | What it does |
|---|---|
| Git prompt | In any bash terminal inside a repository: `(branch) [worktree]` before the `$`, with a `+` for a linked worktree |
| Colours over ssh | On a machine you reach over ssh, Claude Code's colours are as deep as in your local terminal |
| Claude Code | The statusline, bypass by default, copy and paste, no attribution, Remote Control at startup and the earlier auto-compact; see [Set up Claude Code](claude-code.md) |

## Rules

- Keys, tokens and logins are yours. An agent never creates an SSH key, reads a token or logs in for you.
- An agent never runs sudo. It gives you the command, and you run it in Claude Code with a `!` prefix, so the output comes back into the conversation.

## Steps

### 1. System packages

```bash
sudo apt update
sudo apt install -y git tmux jq curl gh
sudo apt install -y xclip            # X11 desktop; wl-clipboard on Wayland; nothing on a server
```

`echo $XDG_SESSION_TYPE` tells you which: `x11`, `wayland`, or empty over ssh.

### 2. Git identity and defaults

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

### 3. SSH and GitHub

Set up an SSH key and log in to `gh` as in [SSH and GitHub](ssh-and-github.md).

### 4. Claude Code and Codex

```bash
curl -fsSL https://claude.ai/install.sh | bash   # Claude Code, without sudo; then open a new terminal
claude                                           # log in, then /exit
```

For Codex, run `npm install -g @openai/codex`, then `codex` and sign in.

### 5. Install the rest

```bash
git clone https://github.com/jxxsteven7/engineering-handbook.git ~/engineering-handbook
bash ~/engineering-handbook/templates/workstation/install.sh
```

It sets up the terminal, then runs the Claude Code installer. Neither uses sudo, and both can run again safely. Each ends with a test whose last line must read `0 FAIL`. Then restart `claude` and open a new terminal.

## Good to know

- Over ssh, the colours take effect once you log in again. To copy on select, and paste text and screenshots with Ctrl+V, in Claude Code on a server too, see the section on servers in [SSH and GitHub](ssh-and-github.md).
- The scripts are written for Ubuntu and bash. For macOS and zsh, see the porting notes at the end of the prompt.
