# Set up Claude Code

**English** | [简体中文](claude-code.zh-CN.md)

Set up each machine with Claude Code once, so that every session starts with the same view and the same settings. If you only want Claude Code set up, without touching the system or the terminal, this page is all you need. To set up a whole machine from scratch, see [Set up a workstation](workstation.md); it does this page as part of it.

For agents: [claude-code.md](../../prompts/setup/claude-code.md) checks the machine, asks you for what only you can do, then installs and tests the rest.

## What you get

| Part | What it does |
|---|---|
| Statusline | Under the input box: model, effort, context used, the 5-hour limit with the time until it resets, the weekly limit (Fable's own limit while you use Fable, the limit across all models otherwise), and a green `rc` while Remote Control is on; inside a repository also the branch and worktree |
| Bypass permissions | Every new session runs commands and edits files without asking |
| Copy and paste | Selecting text copies it; Ctrl+V pastes text and screenshots |
| No attribution | No co-author line, PR footer or session link |
| Remote Control | Every new session starts with Remote Control on, so you can follow and answer it at claude.ai/code and in the phone app; Claude can also notify your phone |
| Earlier auto-compact | Opus 5.5 and Fable 5.1 compact at about 370k tokens of context instead of waiting until the 1M window is nearly full |

## Rules

- An agent never runs sudo. It gives you the command, and you run it in Claude Code with a `!` prefix, so the output comes back into the conversation.
- Bypass mode means no one confirms each command. Pair it with the rest of this handbook: each agent works in its own worktree, the hard rules are in `AGENTS.md`, and `main` is protected. Never run `claude` as root.
- With Fable, the statusline reads this machine's login token to look up Fable's weekly limit. It asks the same endpoint that `/usage` uses, which costs no tokens; the token goes only to `curl` and never shows up on a command line.

## Steps

### 1. Install Claude Code and log in

```bash
curl -fsSL https://claude.ai/install.sh | bash   # Claude Code, without sudo; then open a new terminal
claude                                           # log in, then /exit
```

### 2. Install the settings

```bash
git clone https://github.com/jxxsteven7/engineering-handbook.git ~/engineering-handbook
bash ~/engineering-handbook/templates/claude-code/install.sh
```

When a system package is missing, it tells you what to install, such as `xclip` for pasting screenshots on a desktop. The installer never uses sudo and can run again safely. It ends with a test whose last line must read `0 FAIL`. Then restart `claude`.

## Good to know

- To paste a screenshot on GNOME, press PrtSc, select an area, press Enter, then Ctrl+V in Claude Code. `[Image #1]` appears in the input box.
- Remote Control needs Claude Code logged in with a claude.ai account; with an API key it stays off.
- The earlier auto-compact is set for Opus 5.5 and Fable 5.1 only. For another 1M-context model, add a line for it as the prompt shows.
- The script is written for Ubuntu and bash. For macOS, see the porting notes at the end of the prompt.
