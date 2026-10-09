# Set up a workstation

**English** | [简体中文](workstation.zh-CN.md)

Set up each machine once, so that every agent session starts with the same tools, the same view and the same rules. You do the steps that involve keys and accounts; an agent can do the rest.

For agents: [workstation.md](../../prompts/setup/workstation.md) checks the machine, asks you for what only you can do, then installs and tests the rest.

## What you get

| Part | What it does |
|---|---|
| Statusline | Under Claude Code's input box: model, effort, context used and the weekly limit; inside a repository also the branch and worktree |
| Git prompt | In any bash terminal inside a repository: `(branch) [worktree]` before the `$`, with a `+` for a linked worktree |
| Bypass permissions | Every new Claude Code session runs commands and edits files without asking |
| Copy and paste | Selecting text copies it; Ctrl+V pastes text and screenshots |
| No attribution | Claude Code adds no co-author line, PR footer or session link |

## Rules

- Keys, tokens and logins are yours. An agent never creates an SSH key, reads a token or logs in for you.
- An agent never runs sudo. It gives you the command, and you run it in Claude Code with a `!` prefix, so the output comes back into the conversation.
- Bypass mode means no one confirms each command. Pair it with the rest of this handbook: each agent works in its own worktree, the hard rules are in `AGENTS.md`, and `main` is protected. Never run `claude` as root.

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

### 3. SSH key for GitHub

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

### 4. Log in

```bash
gh auth login                                    # GitHub CLI, for pull requests and checks
curl -fsSL https://claude.ai/install.sh | bash   # Claude Code, without sudo; then open a new terminal
claude                                           # log in, then /exit
```

For Codex, run `npm install -g @openai/codex`, then `codex` and sign in.

### 5. Install the rest

```bash
git clone https://github.com/jxxsteven7/agentic-engineering-handbook.git ~/agentic-engineering-handbook
bash ~/agentic-engineering-handbook/templates/workstation/install.sh
```

The installer never uses sudo and can run again safely. It ends with a test whose last line must read `0 FAIL`. Then restart `claude` and open a new terminal.

## Good to know

- To paste a screenshot on GNOME, press PrtSc, select an area, press Enter, then Ctrl+V in Claude Code. `[Image #1]` appears in the input box.
- Over ssh, the installer makes the colors match your local terminal; log in again once. Ctrl+V reads the server's clipboard, so copy images there with `scp` and give the path instead.
- The scripts are written for Ubuntu and bash. For macOS and zsh, see the porting notes at the end of the prompt.
