# Set up a workstation for coding agents

Follows: `docs/tools/workstation.md` and `docs/tools/ssh-and-github.md` in the Engineering Handbook.

You are setting up the user's machines so that every Claude Code session starts with the same tools, view and rules. The user may give you nothing but this file and a few words, such as the name of a server. That is enough: work out what to do from the table below and from the machine itself, and ask only for what you can't find out.

## Start here

Find the handbook. It is the repository that contains this file; its root is two directories above this file. If you were given only the text of this file, use `~/engineering-handbook`, and if it isn't there, clone it with `git clone https://github.com/jxxsteven7/engineering-handbook.git ~/engineering-handbook`. The scripts are in `templates/workstation/` there. Below, `<handbook>` stands for its root.

Then take the row that fits, without asking the user to choose:

| Situation | What to do |
|---|---|
| The user named a server: an alias from `~/.ssh/config`, a host name, or `user@host` | Part F for that server, from this machine; skip steps 1 to 6. If this machine is itself reached over ssh (`SSH_CONNECTION` is set), do nothing: tell the user to give this file and the server's name to Claude Code on the computer they sit at |
| No server named, on a desktop (`XDG_SESSION_TYPE` is `x11` or `wayland`) | Steps 1 to 6 here. At the end, list the `Host` aliases in `~/.ssh/config` and offer to do part F for any of them |
| No server named, on a machine reached over ssh | Steps 1 to 6 here. At the end, tell the user that for copy and paste in `claude` here, they give this file and this server's name to Claude Code on the computer they sit at |

The result has six parts. Steps 1 to 6 set up A to E on the machine you run on. F connects `claude` on a server to the clipboard of the computer the user sits at, called the workstation below, and you set it up from there.

| Part | Where | Effect |
|---|---|---|
| A. Statusline | `~/.claude/statusline.sh`, `statusLine` in `~/.claude/settings.json` | Under the input box: `model \| effort: <level> \| context: N% \| 5h: N% (1h30m) \| weekly: N%` in orange, plus a green `rc` at the end while Remote Control is on; inside a repository also `branch: <branch> \| worktree: <name>` in cyan and green |
| B. Git prompt | `~/.bash_git_prompt.sh`, a hook at the end of `~/.bashrc` | In any bash terminal inside a repository: yellow `(branch)` and pink `[worktree]` before the `$`; a linked worktree shows `[+name]` |
| C. Bypass permissions | `permissions.defaultMode` and `skipDangerousModePermissionPrompt` in `~/.claude/settings.json` | Every new Claude Code session starts with `bypass permissions on` and no confirmation dialog |
| D. Copy and paste | `tui` in `~/.claude/settings.json`, and `xclip` or `wl-clipboard` on a desktop | The fullscreen interface: selecting text copies it; Ctrl+V pastes text and images |
| E. No attribution | `attribution` in `~/.claude/settings.json` | No co-author trailer, PR footer or session link from Claude Code |
| F. Clipboard on a server | On the workstation, the server's block in `~/.ssh/config`; on the server, `xclip`, a `claude()` function at the end of `~/.bashrc`, and `tui` and `attribution` in `~/.claude/settings.json` if they are missing | In `claude` on that server over ssh: selecting text copies it to the workstation's clipboard, and Ctrl+V pastes the workstation's text and screenshots |

A to E are done when `accept.sh` ends with a line `== N PASS, 0 FAIL ==`, and F when `accept-clipboard.sh` does.

## Hard rules

1. **Never use sudo.** You don't have the password. When a system package is missing, give the user the exact command and tell them to run it in the input box with a `!` prefix, so the output comes back into the conversation, for example `! sudo apt install -y jq xclip`.
2. **Keys, tokens and logins belong to the user.** Never create an SSH key, never read or print a private key or token (including the contents of `~/.claude/.credentials.json`), and never run a login flow for the user. Give them the commands from the docs and wait. You may check whether something exists, for example `test -s ~/.claude/.credentials.json`, without reading it.
3. **Install the scripts as they are.** Don't rewrite, "improve" or reformat `statusline.sh` or `bash_git_prompt.sh`: no changes to text, colours, labels, separators or order. The only allowed changes are the porting differences listed at the end, and they must not change what the scripts output.
4. **Change only what this task owns.** In `~/.claude/settings.json`, only `statusLine`, `permissions.defaultMode`, `skipDangerousModePermissionPrompt`, `tui` and `attribution`; every other key stays, including `permissions.allow` and `permissions.deny`. In `~/.bashrc`, only append the hook (and, over ssh, the `COLORTERM` fix) at the end; never touch the lines the distribution put there, including its `PS1`. Part F lists the only three things it may change.
5. **Finish with evidence.** Run the acceptance test and report its last line. If any check fails, fix the cause and run it again until it passes. Never report "it should work".
6. **Don't fight the administrator.** If `/etc/claude-code/managed-settings.json` sets `"disableBypassPermissionsMode": "disable"`, bypass can't be turned on. Report it, and don't edit system files.
7. Never run `claude` as root: Claude Code refuses bypass mode under root or sudo.

## Steps

Steps 1 to 6 set up parts A to E on this machine. Read `<handbook>/templates/workstation/install.sh` and `<handbook>/templates/workstation/accept.sh` before you start.

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
3. Over ssh, log in again so the colours match the local machine. For copy and paste with the clipboard of the computer they sit at, screenshots included, they give this file and this server's name to Claude Code on that computer.
4. To paste a screenshot on a GNOME desktop: press PrtSc, select, press Enter, then Ctrl+V in Claude Code; `[Image #1]` appears.

Then list these checks for the user to try once in a real session:

- `/effort ultracode` changes line 1 to `effort: ultracode`, and `/effort xhigh` changes it back.
- Inside a repository, line 2 reads `branch: <branch> | worktree: <name>`; outside one there is no line 2.
- A new `claude` shows `⏵⏵ bypass permissions on` with no dialog.
- Dragging over output shows `copied … to clipboard`.

## Part F: a server's clipboard, from the workstation

Do this on the workstation, for the server the user named. If they named several, do one after the other. The workstation must be a Linux desktop (X11, or Wayland with XWayland). Read `<handbook>/templates/workstation/server-clipboard.sh` and `<handbook>/templates/workstation/accept-clipboard.sh` before you start. The rest of parts A to E on the server is not needed for this.

### Why it doesn't work by default

- The clipboard is on the workstation. A program on the server can reach it in two ways: the OSC 52 escape sequence, where the local terminal writes the clipboard (write only), or X11 forwarding, where `xclip` on the server talks to the workstation's display (read and write, text and images).
- Claude Code treats a session as remote whenever `SSH_CONNECTION` is set. This is not documented; it was read from the code of Claude Code 2.1.295. In a remote session, copying only sends OSC 52, and reading the clipboard returns nothing. GNOME Terminal ignores OSC 52 (tested), so text selected in `claude` on a server is lost, and Ctrl+V finds no text.
- Ctrl+V (`chat:imagePaste`) on Linux runs `xclip -selection clipboard -t TARGETS -o`, then reads `image/png` if there is an image and `text/plain` otherwise (`wl-paste` on Wayland). A server session usually has neither a `DISPLAY` nor `xclip`.
- Copy on select exists only in the fullscreen interface (part D).

### The fix

```text
workstation clipboard <-> workstation X display <-> ssh -Y tunnel (DISPLAY=localhost:10.0) <-> xclip on the server <-> claude on the server
```

- Trusted X11 forwarding (`ForwardX11 yes` and `ForwardX11Trusted yes`, the same as `ssh -Y`) gives the server a `DISPLAY` that leads back to the workstation, so `xclip` there reads and writes the workstation's clipboard. It must be trusted: with untrusted forwarding, `xclip` may not read other programs' clipboard, and the forwarding stops after 20 minutes. On Wayland, GNOME keeps the clipboard, images included, in sync between XWayland and Wayland.
- `xclip` on the server: installed with apt when there is passwordless sudo; otherwise the script downloads the Ubuntu package and unpacks only the binary into `~/.local/bin`.
- A `claude()` function in the server's `~/.bashrc` starts `claude` without `SSH_CONNECTION`, but only in an ssh session that has a `DISPLAY` and `xclip`. Claude Code then treats the session as local and copies and pastes through `xclip`. In every other case `claude` starts unchanged.

### Stop points

- **Change only these four things, and back each one up first:** the server's block in the workstation's `~/.ssh/config`; `~/.local/bin/xclip` on the server, only if the server has no `xclip` and no passwordless sudo; the `claude()` function at the end of the server's `~/.bashrc`, exactly as the script writes it; and in the server's `~/.claude/settings.json`, the keys `tui` and `attribution`, only if they are missing.
- **Turn on trusted X11 forwarding only for the server the user named, never under `Host *`.** While it is on, anyone with root on that server can reach the workstation's display: take screenshots, log keystrokes, read the clipboard.
- **Never change system files on the server, and never type a sudo password over ssh.** If the server has no `xauth`, or sshd has `X11Forwarding no`, tell the user that an administrator has to fix it.
- **Done means `accept-clipboard.sh` ends with `0 FAIL`,** and you have given the user the checks in F4. Never report "it should work".

### F1. The workstation's `~/.ssh/config`

If the server is already a `Host` alias there and its block has both `ForwardX11` lines, change nothing. Otherwise back the file up with `cp ~/.ssh/config ~/.ssh/config.bak-$(date +%Y%m%d%H%M%S)`, then add the two lines to the server's block, or add a block. For a new block, take `HostName` and `User` from what the user gave, such as `user@host`, and use the first part of the host name as the alias unless they named one. Ask only for what is missing.

```text
Host <alias>
    HostName <ip-or-domain>
    User <user>
    ForwardX11 yes
    ForwardX11Trusted yes
```

`ssh -G <alias> | grep -i forwardx11` must show `yes` for both. If `ssh -o BatchMode=yes <alias> true` fails, you can't run the remote steps: ask the user to set up key login, for example with `ssh-copy-id <alias>`, or to run the commands themselves with a `!` prefix.

### F2. The server

```bash
ssh <alias> 'bash -s' < <handbook>/templates/workstation/server-clipboard.sh
```

The script reports whether the server has `xauth` and whether sshd allows X11 forwarding, installs `xclip` if it is missing, appends the `claude()` function, and checks that the installed Claude Code still decides "remote" from `SSH_CONNECTION` alone. It never needs root and can run again safely. The last line must be `== SERVER OK`. For each `WARN` or `FAIL`, do what it says, and tell the user about anything that needs an administrator.

Then make sure Claude Code on the server uses the fullscreen interface, without which selecting text doesn't copy, and adds no attribution to commits. This sets `tui` and `attribution` only where they are missing, and leaves every other key and any value the user chose:

```bash
ssh <alias> 'f=~/.claude/settings.json; cp "$f" "$f.bak-$(date +%Y%m%d%H%M%S)" && jq ".tui //= \"fullscreen\" | .attribution //= {commit: \"\", pr: \"\", sessionUrl: false}" "$f" > "$f.tmp" && mv "$f.tmp" "$f"'
```

If the server has no `~/.claude/settings.json` yet, or no `jq`, skip this and tell the user to give this file to Claude Code on the server once it is installed there.

### F3. Acceptance test

```bash
bash <handbook>/templates/workstation/accept-clipboard.sh <alias>
```

The test overwrites the workstation's clipboard for a few seconds and then puts back what was there, an image included.

It checks the two ssh settings, key login, the forwarded `DISPLAY`, a copy in each direction between the workstation's clipboard and `xclip` on the server, the `claude()` function, and the check Claude Code uses. The last line must be `== 8 PASS, 0 FAIL ==`, or `== 7 PASS, 0 FAIL ==` with `SKIP T8` while Claude Code isn't installed on the server.

### F4. Checks for the user

Give the user these steps, to do once:

1. Open a new terminal on the workstation, run `ssh <alias>`, and start `claude` (or `claude -r` to resume a session). A `claude` that was already running keeps the old behaviour; start it again in the new login.
2. `/tui` shows fullscreen. If it doesn't, run `/tui fullscreen` once; it is saved.
3. Select some text in `claude`, then paste it into another program on the workstation.
4. Copy some text on the workstation, then press Ctrl+V in `claude`.
5. Put a screenshot on the workstation's clipboard, then press Ctrl+V in `claude`: `[Image #1]` appears.
6. To use the terminal's own selection in the fullscreen interface, hold Shift while you drag.

If the server doesn't have the rest of parts A to E (no statusline under the input box), add that they get it by giving this file to Claude Code on the server.

### Notes

- Side effects: `claude` no longer knows it runs over ssh. When it opens a web page, for example to log in, it may start a browser on the server that shows up on the workstation through X11, instead of printing the link. Commands that its Bash tool runs don't see `SSH_CONNECTION` either; `SSH_CLIENT` and `SSH_TTY` are still there.
- It works only with a forwarded `DISPLAY`. With plain `ssh`, or in tmux after you reconnect (the old `DISPLAY` is gone), the function starts `claude` unchanged, and the clipboard doesn't work. In tmux, start `claude` again from the new ssh session.
- The workstation's terminal must not keep Ctrl+V for itself. GNOME Terminal doesn't. Terminals that paste on Ctrl+V, such as Windows Terminal or the VS Code terminal, only ever paste text, so unbind Ctrl+V there.
- Untested: a macOS workstation needs XQuartz with clipboard sync turned on in its settings; a Windows workstation needs an X server such as VcXsrv or X410.
- To undo it, remove the two `ForwardX11` lines from the server's block in `~/.ssh/config`, and the `claude()` function from the server's `~/.bashrc`.

### Troubleshooting

| Symptom | Cause and fix |
|---|---|
| T4 fails: `DISPLAY` is empty on the server | Run `ssh -v <alias> true 2>&1 \| grep -i x11`. Usually the server has no `xauth`, sshd has `X11Forwarding no`, or the workstation itself has no `DISPLAY`, for example in a text console |
| T5 or T6 fails while T4 passes | Usually the forwarding isn't trusted: check T2. Or a clipboard manager on the workstation takes over the clipboard |
| T8 fails, or the server script warns that Claude Code decides ssh differently | An update changed how Claude Code detects ssh. Find the new check with `LC_ALL=C grep -aoE '.{0,200}SSH_CONNECTION.{0,200}' "$(readlink -f "$(command -v claude)")"`. If it now also looks at `SSH_CLIENT` or `SSH_TTY`, change `env -u SSH_CONNECTION` in the function to `env -u SSH_CONNECTION -u SSH_CLIENT -u SSH_TTY`, then do F3 and F4 again |

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
