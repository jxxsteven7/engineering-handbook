# Set up Claude Code

Follows: `docs/tools/claude-code.md` in the Engineering Handbook.

You are setting up Claude Code on the machine you run on, so that every session starts with the same statusline, permissions and settings. The user may give you nothing but this file. That is enough: work out the rest from the machine itself, and ask only for what you can't find out.

This file covers Claude Code only. For a whole machine, with system packages, git, SSH, the git prompt and the clipboard on a server, the user gives you `prompts/setup/workstation.md` instead; it includes this file as its part C.

## Start here

Find the handbook. It is the repository that contains this file; its root is two directories above this file. If you were given only the text of this file, use `~/engineering-handbook`, and if it isn't there, clone it with `git clone https://github.com/jxxsteven7/engineering-handbook.git ~/engineering-handbook`. The scripts are in `templates/claude-code/` there. Below, `<handbook>` stands for its root.

If the user named a server because they want copy and paste in `claude` over ssh, that is part D of `prompts/setup/workstation.md`; follow that file instead.

The result has six parts:

| Part | Where | Effect |
|---|---|---|
| A. Statusline | `~/.claude/statusline.sh`, `statusLine` in `~/.claude/settings.json` | Under the input box: `model \| effort: <level> \| context: N% \| 5h: N% (1h30m) \| weekly-fable: N%` in orange (`weekly-allmodels: N%` with any model other than Fable), plus a green `rc` at the end while Remote Control is on; inside a repository also `branch: <branch> \| worktree: <name>` in cyan and green |
| B. Bypass permissions | `permissions.defaultMode` and `skipDangerousModePermissionPrompt` in `~/.claude/settings.json` | Every new session starts with `bypass permissions on` and no confirmation dialog |
| C. Copy and paste | `tui` in `~/.claude/settings.json`, and `xclip` or `wl-clipboard` on a desktop | The fullscreen interface: selecting text copies it; Ctrl+V pastes text and images |
| D. No attribution | `attribution` in `~/.claude/settings.json` | No co-author trailer, PR footer or session link from Claude Code |
| E. Remote Control | `remoteControlAtStartup` and `agentPushNotifEnabled` in `~/.claude/settings.json` | Every new session starts with Remote Control on, so it can be followed and answered from claude.ai/code or the Claude app; Claude may also send a notification to the phone |
| F. Earlier auto-compact | `modelSettings.<model>.autoCompactWindow` in `~/.claude/settings.json`, for `claude-opus-5-5` and `claude-fable-5-1` | The two 1M-context models compact at about 370k tokens instead of near 970k |

They are done when `<handbook>/templates/claude-code/accept.sh` ends with a line `== N PASS, 0 FAIL ==`.

## Hard rules

1. **Never use sudo.** You don't have the password. When a system package is missing, give the user the exact command and tell them to run it in the input box with a `!` prefix, so the output comes back into the conversation, for example `! sudo apt install -y jq xclip`.
2. **Keys, tokens and logins belong to the user.** Never read or print a token (including the contents of `~/.claude/.credentials.json`), and never run a login flow for the user. Give them the commands and wait. You may check whether something exists, for example `test -s ~/.claude/.credentials.json`, without reading it. The statusline and `accept.sh` read the OAuth token themselves, to fetch the Fable limit (see step 3); that is expected, but you still never read or print it.
3. **Install the script as it is.** Don't rewrite, "improve" or reformat `statusline.sh`: no changes to text, colours, labels, separators or order. The only allowed changes are the porting differences listed at the end, and they must not change what the script outputs.
4. **Change only what this task owns.** In `~/.claude/settings.json`, only `statusLine`, `permissions.defaultMode`, `skipDangerousModePermissionPrompt`, `tui`, `attribution`, `remoteControlAtStartup`, `agentPushNotifEnabled`, and `autoCompactWindow` under `modelSettings.claude-opus-5-5` and `modelSettings.claude-fable-5-1`; every other key stays, including `permissions.allow`, `permissions.deny` and other keys under `modelSettings`.
5. **Finish with evidence.** Run the acceptance test and report its last line. If any check fails, fix the cause and run it again until it passes. Never report "it should work".
6. **Don't fight the administrator.** If `/etc/claude-code/managed-settings.json` sets `"disableBypassPermissionsMode": "disable"`, bypass can't be turned on. Report it, and don't edit system files.
7. Never run `claude` as root: Claude Code refuses bypass mode under root or sudo.

## Steps

Read `<handbook>/templates/claude-code/install.sh` and `<handbook>/templates/claude-code/accept.sh` before you start.

### 1. Look at the machine

Report what you find in a short table:

- the system: `uname -sr`, `. /etc/os-release && echo "$PRETTY_NAME"`;
- the kind of session: `echo "$XDG_SESSION_TYPE"` (`x11` or `wayland` is a desktop; empty or `tty` is a server) and `echo "${SSH_CONNECTION-}"`;
- tools: `bash --version` (4.2 or later), `jq`, `curl`, and on a desktop `xclip` (X11) or `wl-paste` (Wayland);
- Claude Code: `claude --version`, and on Linux whether it is logged in: `test -s ~/.claude/.credentials.json`.

### 2. Ask the user for what only they can do

For each missing item, give the exact command and wait until the user says it is done:

- system packages: `! sudo apt install -y jq curl` plus `xclip` on X11 or `wl-clipboard` on Wayland;
- Claude Code: `curl -fsSL https://claude.ai/install.sh | bash`, without sudo; then a new terminal, `claude`, log in, `/exit`.

### 3. Install

```bash
bash <handbook>/templates/claude-code/install.sh
```

It checks the tools, installs A, merges the settings for B to F (keeping a backup of the old `settings.json`), and runs the acceptance test. It never uses sudo and can run again safely. If it stops at step 1 because something is missing, go back to step 2 of this prompt.

If the installer can't run (for example on a system without `apt`), do the same by hand:

1. Copy `statusline.sh` to `~/.claude/statusline.sh` with mode 755. If a different file is already there, rename it to `<file>.bak-<date>` first.
2. Merge the settings with `jq`, using the absolute path of the statusline (not `~`):

   ```bash
   f=~/.claude/settings.json; [ -s "$f" ] || echo '{}' > "$f"
   jq --arg cmd "$HOME/.claude/statusline.sh" '.statusLine = {type: "command", command: $cmd}
         | .permissions.defaultMode = "bypassPermissions"
         | .skipDangerousModePermissionPrompt = true
         | .tui = "fullscreen"
         | .attribution = {commit: "", pr: "", sessionUrl: false}
         | .remoteControlAtStartup = true
         | .agentPushNotifEnabled = true
         | .modelSettings["claude-opus-5-5"].autoCompactWindow = 400000
         | .modelSettings["claude-fable-5-1"].autoCompactWindow = 400000' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
   ```

3. Run `bash <handbook>/templates/claude-code/accept.sh`.

Don't write `copyOnSelect`; it is on by default. If `~/.claude.json` has `"copyOnSelect": false`, the user turned it off; tell them, and leave it.

About E and F:

- Remote Control needs Claude Code logged in with a claude.ai account. With an API key it stays off, and that is expected. An organisation's policy can also lock it off; report that, and don't try to work around it. Without the Claude app on the phone, `agentPushNotifEnabled` does nothing.
- `autoCompactWindow` is read per model from `modelSettings`, which is also where `/autocompact` writes it. With 400000, a session compacts at about 367k tokens: the window minus the smaller of the model's output limit and 20k, minus 13k. Without it, the 1M models wait until about 967k. For another 1M-context model, add the same key under its name. Don't use the environment variable `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` instead: it is an internal testing switch and applies only to the process started with it.
- Both apply only to sessions started after the change.

About the weekly limit in the statusline:

- With a Fable model, line 1 shows `weekly-fable: N%`, the same number as the Fable limit in `/usage`. Claude Code doesn't pass it to the statusline, so the script gets it from `GET https://api.anthropic.com/api/oauth/usage`, the endpoint `/usage` calls. It is an account endpoint, not a model call, and costs no tokens. It is not documented, so it may change; then the Fable number disappears and line 1 shows `weekly-allmodels` instead.
- The fetch runs detached, at most once a minute, and only while a Fable session draws the statusline. All sessions share one cache, `~/.cache/claude-statusline/usage.json` (mode 600). A render never waits for the network, and nothing keeps running once Claude Code is closed.
- The script reads the access token from `~/.claude/.credentials.json` and passes it to `curl` on stdin, so it never shows up in `ps` (T8 checks this). It never refreshes the token: Claude Code does that when it starts. While the token is expired, line 1 falls back to `weekly-allmodels`.
- With any other model, or when the account has no Fable limit, line 1 shows `weekly-allmodels`, the account-wide 7-day limit from the payload.

### 4. Verify

- The last line of the acceptance test must be `== N PASS, 0 FAIL ==`: 45 on a Linux desktop, 44 on a server reached over ssh (where `SKIP T12c` is expected).
- T7g to T8 fetch the real Fable limit. They print `SKIP T7g-T8` with 4 fewer passes when the endpoint is rate-limited (HTTP 429, after several fetches within minutes; wait 10 minutes and run `accept.sh` again), when the token has expired (HTTP 401; start `claude` once, then run it again), or when the account has no Fable limit. None of these is a fault in the scripts; don't change them.
- For each `FAIL`, the test prints the expected and the actual value. Fix the cause (a missing file, setting or package), not the script, and run `accept.sh` again.

### 5. Hand over

Tell the user:

1. Quit any running `claude` and start it again; the statusline, bypass mode, the fullscreen interface, Remote Control and the earlier auto-compact take effect then.
2. To paste a screenshot on a GNOME desktop: press PrtSc, select, press Enter, then Ctrl+V in Claude Code; `[Image #1]` appears.
3. On a machine reached over ssh: for the same colours as the local terminal, and for copy and paste with the clipboard of the computer they sit at, they use `prompts/setup/workstation.md` (parts B and D).

Then list these checks for the user to try once in a real session:

- `/effort ultracode` changes line 1 to `effort: ultracode`, and `/effort xhigh` changes it back.
- Inside a repository, line 2 reads `branch: <branch> | worktree: <name>`; outside one there is no line 2.
- A new `claude` shows `⏵⏵ bypass permissions on` with no dialog.
- Dragging over output shows `copied … to clipboard`.
- Line 1 ends with a green `rc`, and the session shows up at claude.ai/code and in the Claude app.
- With `/model` set to Fable, line 1 shows `weekly-fable: N%`, the same as the Fable limit in `/usage`; with Opus it shows `weekly-allmodels: N%`. The Fable number can take up to a minute to appear.

## Porting notes

The script is written for GNU/Linux with bash. Elsewhere, only these changes are allowed:

| Where | Change |
|---|---|
| macOS: `tac` is missing | In `statusline.sh`, replace `tac -- "$transcript"` with `tail -r "$transcript"` |
| macOS: the system bash is 3.2 | `brew install bash`, and make sure that bash comes first in `PATH`, because the scripts use bash 4.2 features |
| macOS: credentials live in the Keychain | `install.sh` checks `~/.claude/.credentials.json` only on Linux; on macOS, ask the user whether `claude` is logged in. For the Fable limit, the fetcher in `statusline.sh` reads the same JSON from `security find-generic-password -s "Claude Code-credentials" -w`; if that service name doesn't exist, find it with `security dump-keychain 2>/dev/null \| grep -i claude`. Untested |
| macOS: `stat -c`, `setsid` and `flock` are missing | In `statusline.sh`, `stat -c '%n %Y' f1 f2` becomes `stat -f '%N %m' f1 f2`; `setsid -f bash "$0" --fetch-usage … </dev/null >/dev/null 2>&1` becomes `( nohup bash "$0" --fetch-usage … </dev/null >/dev/null 2>&1 & )`; `flock -n 9` becomes an atomic `mkdir "$SL_CACHE/usage.lock.d"`, removed with `rmdir` on exit, and a lock directory older than 60 seconds is deleted. Untested |
| macOS: pasting | Ctrl+V (not Cmd+V) pastes images through `osascript` and `pbpaste`; nothing to install. T12c is skipped |
| Other Linux distributions, WSL | GNU tools are present; install the packages with the system's own package manager instead of `apt` |
