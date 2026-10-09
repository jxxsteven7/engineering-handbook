# Set up a workstation for coding agents

Follows: `docs/tools/workstation.md` and `docs/tools/ssh-and-github.md` in the Agentic Engineering Handbook.

You are setting up the machine you run on, for the user, so that every Claude Code session starts with the same tools, view and rules. The handbook is the repository that contains this file; its root is two directories above this file, and the scripts are in `templates/workstation/` there. Read `templates/workstation/install.sh` and `templates/workstation/accept.sh` before you start.

The result has five parts:

| Part | Where | Effect |
|---|---|---|
| A. Statusline | `~/.claude/statusline.sh`, `statusLine` in `~/.claude/settings.json` | Under the input box: `model \| effort: <level> \| context: N% \| weekly: N%` in orange; inside a repository also `branch: <branch> \| worktree: <name>` in cyan and green |
| B. Git prompt | `~/.bash_git_prompt.sh`, a hook at the end of `~/.bashrc` | In any bash terminal inside a repository: yellow `(branch)` and pink `[worktree]` before the `$`; a linked worktree shows `[+name]` |
| C. Bypass permissions | `permissions.defaultMode` and `skipDangerousModePermissionPrompt` in `~/.claude/settings.json` | Every new Claude Code session starts with `bypass permissions on` and no confirmation dialog |
| D. Copy and paste | `tui` in `~/.claude/settings.json`, and `xclip` or `wl-clipboard` on a desktop | The fullscreen interface: selecting text copies it; Ctrl+V pastes text and images |
| E. No attribution | `attribution` in `~/.claude/settings.json` | No co-author trailer, PR footer or session link from Claude Code |

The work is done when `accept.sh` ends with a line `== N PASS, 0 FAIL ==`.

## Hard rules

1. **Never use sudo.** You don't have the password. When a system package is missing, give the user the exact command and tell them to run it in the input box with a `!` prefix, so the output comes back into the conversation, for example `! sudo apt install -y jq xclip`.
2. **Keys, tokens and logins belong to the user.** Never create an SSH key, never read or print a private key or token (including the contents of `~/.claude/.credentials.json`), and never run a login flow for the user. Give them the commands from the docs and wait. You may check whether something exists, for example `test -s ~/.claude/.credentials.json`, without reading it.
3. **Install the scripts as they are.** Don't rewrite, "improve" or reformat `statusline.sh` or `bash_git_prompt.sh`: no changes to text, colours, labels, separators or order. The only allowed changes are the porting differences listed at the end, and they must not change what the scripts output.
4. **Change only what this task owns.** In `~/.claude/settings.json`, only `statusLine`, `permissions.defaultMode`, `skipDangerousModePermissionPrompt`, `tui` and `attribution`; every other key stays, including `permissions.allow` and `permissions.deny`. In `~/.bashrc`, only append the hook (and, over ssh, the `COLORTERM` fix) at the end; never touch the lines the distribution put there, including its `PS1`.
5. **Finish with evidence.** Run the acceptance test and report its last line. If any check fails, fix the cause and run it again until it passes. Never report "it should work".
6. **Don't fight the administrator.** If `/etc/claude-code/managed-settings.json` sets `"disableBypassPermissionsMode": "disable"`, bypass can't be turned on. Report it, and don't edit system files.
7. Never run `claude` as root: Claude Code refuses bypass mode under root or sudo.

## Steps

### 1. Look at the machine

Report what you find in a short table:

- the system: `uname -sr`, `. /etc/os-release && echo "$PRETTY_NAME"`;
- the kind of session: `echo "$XDG_SESSION_TYPE"` (`x11` or `wayland` is a desktop; empty or `tty` is a server) and `echo "${SSH_CONNECTION-}"`;
- tools: `git --version` (2.31 or later), `bash --version` (4.2 or later), `jq`, `tmux`, `curl`, `gh`, and on a desktop `xclip` (X11) or `wl-paste` (Wayland);
- Claude Code: `claude --version`, and on Linux whether it is logged in: `test -s ~/.claude/.credentials.json`;
- GitHub: `gh auth status`, and `ssh -T git@github.com` (exit status 1 with "You've successfully authenticated" means it works);
- git identity: `git config --global user.name` and `git config --global user.email`;
- Codex, if the user uses it: `codex --version`.

### 2. Ask the user for what only they can do

For each missing item, give the exact command and wait until the user says it is done:

- system packages: `! sudo apt install -y git tmux jq curl gh` plus `xclip` on X11 or `wl-clipboard` on Wayland;
- git identity: ask for the name and email, then set them with `git config --global user.name "<name>"` and `git config --global user.email "<email>"`;
- the SSH key: the commands in `docs/tools/ssh-and-github.md`. Once the user has created the key and added it on GitHub, you may add the `Host github.com` block to `~/.ssh/config` if it is missing, then `chmod 600 ~/.ssh/config`, and run `ssh -T git@github.com` to confirm;
- `! gh auth login`;
- Claude Code: `curl -fsSL https://claude.ai/install.sh | bash`, without sudo; then a new terminal, `claude`, log in, `/exit`;
- Codex, if wanted: `npm install -g @openai/codex` (needs Node.js), then `codex` and sign in.

### 3. Git defaults

Read each value with `git config --global --get <key>`. Set the ones that are unset. If one is set to something else, show the user both values and ask before changing it.

| Key | Value | Why |
|---|---|---|
| `init.defaultBranch` | `main` | New repositories start on `main` |
| `pull.ff` | `only` | `git pull` never creates a merge commit silently |
| `fetch.prune` | `true` | Remote branches deleted on GitHub disappear locally |
| `rebase.autoStash` | `true` | A rebase stashes and restores uncommitted changes |
| `rebase.updateRefs` | `true` | Stacked branches move along with a rebase (git 2.38 or later) |
| `rerere.enabled` | `true` | Git remembers how you resolved a conflict |

### 4. Install

```bash
bash <handbook>/templates/workstation/install.sh
```

It checks the tools, installs A and B, merges the settings for C, D and E (keeping a backup of the old `settings.json`), adds the `COLORTERM` fix over ssh, and runs the acceptance test. It never uses sudo and can run again safely. If it stops at step 1 because something is missing, go back to step 2 of this prompt.

If the installer can't run (for example on a system without `apt`), do the same by hand:

1. Copy `statusline.sh` to `~/.claude/statusline.sh` with mode 755, and `bash_git_prompt.sh` to `~/.bash_git_prompt.sh` with mode 644. If a different file is already there, rename it to `<file>.bak-<date>` first.
2. Append the hook block from `install.sh` to `~/.bashrc`, unless the line `. ~/.bash_git_prompt.sh` is already there. It must come after the distribution's `PS1` setup, which the end of the file always is.
3. Merge the settings with `jq`, using the absolute path of the statusline (not `~`):

   ```bash
   f=~/.claude/settings.json; [ -s "$f" ] || echo '{}' > "$f"
   jq --arg cmd "$HOME/.claude/statusline.sh" '.statusLine = {type: "command", command: $cmd}
         | .permissions.defaultMode = "bypassPermissions"
         | .skipDangerousModePermissionPrompt = true
         | .tui = "fullscreen"
         | .attribution = {commit: "", pr: "", sessionUrl: false}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
   ```

4. Over ssh only, append the `COLORTERM` block from `install.sh` to `~/.bashrc`.
5. Run `bash <handbook>/templates/workstation/accept.sh`.

Don't write `copyOnSelect`; it is on by default. If `~/.claude.json` has `"copyOnSelect": false`, the user turned it off; tell them, and leave it.

### 5. Verify

- The last line of the acceptance test must be `== N PASS, 0 FAIL ==`: 41 on a Linux desktop, 40 on a server reached over ssh (where `SKIP T12c` is expected).
- For each `FAIL`, the test prints the expected and the actual value. Fix the cause (a missing file, hook, setting or package), not the scripts, and run `accept.sh` again.

### 6. Hand over

Tell the user:

1. Quit any running `claude` and start it again; the fullscreen interface, bypass mode and the statusline take effect then.
2. Open a new terminal or run `source ~/.bashrc`; inside a repository the prompt shows `(branch) [worktree]`.
3. Over ssh, log in again so the colours match the local machine. To paste an image there, copy it over with `scp` and give its path, because Ctrl+V reads the server's clipboard.
4. To paste a screenshot on a GNOME desktop: press PrtSc, select, press Enter, then Ctrl+V in Claude Code; `[Image #1]` appears.

Then list these checks for the user to try once in a real session:

- `/effort ultracode` changes line 1 to `effort: ultracode`, and `/effort xhigh` changes it back.
- Inside a repository, line 2 reads `branch: <branch> | worktree: <name>`; outside one there is no line 2.
- A new `claude` shows `⏵⏵ bypass permissions on` with no dialog.
- Dragging over output shows `copied … to clipboard`.

## Porting notes

The scripts are written for GNU/Linux with bash. Elsewhere, only these changes are allowed:

| Where | Change |
|---|---|
| macOS: `tac` is missing | In `statusline.sh`, replace `tac -- "$transcript"` with `tail -r "$transcript"` |
| macOS: the system bash is 3.2 | `brew install bash`, and make sure that bash comes first in `PATH`, because the scripts use bash 4.2 features |
| macOS: `sort -V` may be missing | If `install.sh` calls git too old although `git --version` says 2.31 or later, check the versions by hand and install the parts by hand as in step 4 |
| macOS: credentials live in the Keychain | `install.sh` checks `~/.claude/.credentials.json` only on Linux; on macOS, ask the user whether `claude` is logged in |
| zsh as the login shell | `bash_git_prompt.sh` is for bash only. Don't source it from `~/.zshrc`; report part B as not applicable. T10m then fails, which is expected |
| macOS: pasting | Ctrl+V (not Cmd+V) pastes images through `osascript` and `pbpaste`; nothing to install. T12c is skipped |
| Other Linux distributions, WSL | GNU tools are present; install the packages with the system's own package manager instead of `apt` |
