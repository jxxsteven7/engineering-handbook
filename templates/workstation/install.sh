#!/usr/bin/env bash
# Sets up Claude Code and the terminal on this machine, as docs/tools/workstation.md in the
# Agentic Engineering Handbook describes:
#
#   A. statusline         ~/.claude/statusline.sh: model | effort | context | weekly, and branch | worktree
#   B. git prompt         ~/.bash_git_prompt.sh, hooked into ~/.bashrc: (branch) [worktree] before the $
#   C. permissions        bypass permissions by default in every new Claude Code session
#   D. copy and paste     the fullscreen interface: select to copy, Ctrl+V pastes text and images
#   E. no attribution     Claude Code adds no co-author trailer, PR footer or session link
#
# Usage: bash templates/workstation/install.sh
# It never uses sudo: when a system package is missing, it prints the command and stops.
# It can run again at any time; finished steps are skipped, and a file it would replace is
# renamed to <file>.bak-<time> first. It ends with the acceptance test, accept.sh.

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

say "[1/6] Tools"
pkgs=()
for c in jq:jq git:git tput:ncurses-bin tac:coreutils mktemp:coreutils; do
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
if ! printf '%s\n' 2.31 "$(git --version | awk '{print $3}')" | sort -V -C; then
  say "  ✗ $(git --version) is too old; the git prompt needs 2.31 or later"; exit 1
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

say "[2/6] A · statusline"
mkdir -p ~/.claude
put "$HERE/statusline.sh" ~/.claude/statusline.sh 755

say "[3/6] B · git prompt"
put "$HERE/bash_git_prompt.sh" ~/.bash_git_prompt.sh 644
touch ~/.bashrc
if grep -qF '. ~/.bash_git_prompt.sh' ~/.bashrc; then
  say "  · ~/.bashrc already sources it"
else
  cat >> ~/.bashrc <<'EOF'

# Show the current git branch (yellow) and worktree (pink) in the prompt.
# Appends to PS1; the colours set above are left untouched.
if [ -f ~/.bash_git_prompt.sh ]; then
    . ~/.bash_git_prompt.sh
fi
EOF
  say "  ✓ added the hook at the end of ~/.bashrc"
fi

say "[4/6] C, D, E · ~/.claude/settings.json"
f=~/.claude/settings.json
[[ -s "$f" ]] || echo '{}' > "$f"
if jq --arg cmd "$HOME/.claude/statusline.sh" '.statusLine = {type: "command", command: $cmd}
      | .permissions.defaultMode = "bypassPermissions"
      | .skipDangerousModePermissionPrompt = true
      | .tui = "fullscreen"
      | .attribution = {commit: "", pr: "", sessionUrl: false}' "$f" > "$f.tmp"; then
  if cmp -s "$f" "$f.tmp"; then rm -f "$f.tmp"; say "  · already set"
  else cp "$f" "$f.bak-$STAMP" && mv "$f.tmp" "$f" && say "  ✓ merged the keys; the old file is ${f##*/}.bak-$STAMP"; fi
else
  rm -f "$f.tmp"; say "  ✗ $f is not valid JSON; fix it and run this script again"; exit 1
fi
if [[ -r ~/.claude.json && "$(jq -r 'if has("copyOnSelect") then .copyOnSelect else true end' ~/.claude.json 2>/dev/null)" == "false" ]]; then
  say "  ! copyOnSelect is off in ~/.claude.json, so selecting text won't copy it. Turn on Copy on select in /config if you want it."
fi

say "[5/6] COLORTERM over ssh"
if [[ -n "${SSH_CONNECTION-}" ]]; then
  if grep -q 'ssh does not forward COLORTERM' ~/.bashrc; then
    say "  · already added"
  else
    cat >> ~/.bashrc <<'EOF'

# ssh does not forward COLORTERM (sshd only accepts LANG LC_*), so programs here would
# assume a 256-colour terminal: Claude Code and its statusline fall back to 256-colour
# approximations that look lighter. The terminals used to ssh in are truecolor.
if [ -n "${SSH_CONNECTION-}" ] && [ -z "${COLORTERM-}" ] && [[ "$TERM" == *256color* ]]; then
    export COLORTERM=truecolor
fi
EOF
    say "  ✓ added the COLORTERM fix at the end of ~/.bashrc"
  fi
else
  say "  · not an ssh session; skipped (desktop terminals set COLORTERM themselves)"
fi

say "[6/6] Acceptance test"
bash "$HERE/accept.sh"; rc=$?
say ""
if (( rc == 0 )); then
  say "All passed. Next:"
  say "  1. Quit any running claude and start it again: the fullscreen interface, bypass and the statusline take effect then."
  say "  2. Open a new terminal (or run source ~/.bashrc): inside a git repository the prompt shows (branch) [worktree]."
  if [[ -n "${SSH_CONNECTION-}" ]]; then say "  3. This is an ssh session: log in again so the colours match your local machine."; fi
else
  say "The acceptance test failed. Fix the FAIL lines above, then run this script again."
fi
exit "$rc"
