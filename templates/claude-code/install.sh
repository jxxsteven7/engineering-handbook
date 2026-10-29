#!/usr/bin/env bash
# Sets up Claude Code on this machine, as docs/tools/claude-code.md in the Engineering Handbook
# describes:
#
#   A. statusline         ~/.claude/statusline.sh: model | effort | context | 5h | weekly-fable or weekly-allmodels | rc,
#                         and branch | worktree
#   B. permissions        bypass permissions by default in every new Claude Code session
#   C. copy and paste     the fullscreen interface: select to copy, Ctrl+V pastes text and images
#   D. no attribution     Claude Code adds no co-author trailer, PR footer or session link
#   E. Remote Control     every new session starts with Remote Control on, and Claude may notify your phone
#   F. auto-compact       Opus 5.5 and Fable 5.1 compact at about 370k tokens instead of near 1M
#
# Usage: bash templates/claude-code/install.sh
# It never uses sudo: when a system package is missing, it prints the command and stops.
# It can run again at any time; finished steps are skipped, and a file it would replace is
# renamed to <file>.bak-<time> first. It ends with the acceptance test, accept.sh.
# templates/workstation/install.sh runs it too, after the terminal setup.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
STAMP=$(date +%Y%m%d-%H%M%S)
say() { printf '%s\n' "$*"; }

# Copy a file into place, keeping a backup of an older, different version.
put() {
  local src=$1 dst=$2 mode=$3
  if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then say "  · $dst is up to date"; return; fi
  if [[ -f "$dst" ]]; then mv "$dst" "$dst.bak-$STAMP" && say "  · renamed the old $dst to ${dst##*/}.bak-$STAMP"; fi
  install -m "$mode" "$src" "$dst" && say "  ✓ wrote $dst"
}

say "[1/4] Tools"
pkgs=()
for c in jq:jq curl:curl tac:coreutils stat:coreutils mktemp:coreutils setsid:util-linux flock:util-linux; do
  command -v "${c%%:*}" >/dev/null || pkgs+=("${c#*:}")
done
case "${XDG_SESSION_TYPE:-}" in
  x11)     command -v xclip    >/dev/null || pkgs+=(xclip) ;;
  wayland) command -v wl-paste >/dev/null || pkgs+=(wl-clipboard) ;;
esac
if (( ${#pkgs[@]} )); then
  say "  ✗ Missing system packages. Install them first (this needs sudo):"
  say "    sudo apt install -y $(printf '%s\n' "${pkgs[@]}" | sort -u | paste -sd' ')"
  exit 1
fi
if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 2) )); then
  say "  ✗ bash $BASH_VERSION is too old; 4.2 or later is needed"; exit 1
fi
CLAUDE=$(command -v claude || { [[ -x ~/.local/bin/claude ]] && echo ~/.local/bin/claude; })
if [[ -z "$CLAUDE" ]]; then
  say "  ✗ Claude Code is not installed. Install it without sudo:"
  say "    curl -fsSL https://claude.ai/install.sh | bash"
  say "    Then open a new terminal, run claude, log in, /exit, and run this script again."; exit 1
fi
if [[ "$(uname)" == Linux && ! -s ~/.claude/.credentials.json ]]; then
  say "  ✗ Claude Code is not logged in: run claude, log in, /exit, and run this script again."; exit 1
fi
say "  ✓ all tools present; Claude Code $("$CLAUDE" --version 2>/dev/null | awk '{print $1}')"

say "[2/4] A · statusline"
mkdir -p ~/.claude
put "$HERE/statusline.sh" ~/.claude/statusline.sh 755

say "[3/4] B to F · ~/.claude/settings.json"
f=~/.claude/settings.json
[[ -s "$f" ]] || echo '{}' > "$f"
if jq --arg cmd "$HOME/.claude/statusline.sh" '.statusLine = {type: "command", command: $cmd}
      | .permissions.defaultMode = "bypassPermissions"
      | .skipDangerousModePermissionPrompt = true
      | .tui = "fullscreen"
      | .attribution = {commit: "", pr: "", sessionUrl: false}
      | .remoteControlAtStartup = true
      | .agentPushNotifEnabled = true
      | .modelSettings["claude-opus-5-5"].autoCompactWindow = 400000
      | .modelSettings["claude-fable-5-1"].autoCompactWindow = 400000' "$f" > "$f.tmp"; then
  if cmp -s "$f" "$f.tmp"; then rm -f "$f.tmp"; say "  · already set"
  else cp "$f" "$f.bak-$STAMP" && mv "$f.tmp" "$f" && say "  ✓ merged the keys; the old file is ${f##*/}.bak-$STAMP"; fi
else
  rm -f "$f.tmp"; say "  ✗ $f is not valid JSON; fix it and run this script again"; exit 1
fi
if [[ -r ~/.claude.json && "$(jq -r 'if has("copyOnSelect") then .copyOnSelect else true end' ~/.claude.json 2>/dev/null)" == "false" ]]; then
  say "  ! copyOnSelect is off in ~/.claude.json, so selecting text won't copy it. Turn on Copy on select in /config if you want it."
fi

say "[4/4] Acceptance test"
bash "$HERE/accept.sh"; rc=$?
say ""
if (( rc == 0 )); then
  say "All passed. Quit any running claude and start it again: the statusline, bypass, the fullscreen interface, Remote Control and auto-compact take effect then."
  if [[ -n "${SSH_CONNECTION-}" ]] && ! grep -q 'ssh does not forward COLORTERM' ~/.bashrc 2>/dev/null; then
    say "This is an ssh session: for the same colours as your local terminal, and for copy and paste with your own computer, see prompts/setup/workstation.md."
  fi
else
  say "The acceptance test failed. Fix the FAIL lines above, then run this script again."
fi
exit "$rc"
