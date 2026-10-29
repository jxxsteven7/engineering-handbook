#!/usr/bin/env bash
# Sets up the terminal on this machine, then Claude Code, as docs/tools/workstation.md in the
# Engineering Handbook describes:
#
#   A. git prompt         ~/.bash_git_prompt.sh, hooked into ~/.bashrc: (branch) [worktree] before the $
#   B. colours over ssh   COLORTERM=truecolor at the end of ~/.bashrc, in an ssh session only
#   C. Claude Code        templates/claude-code/install.sh: the statusline, permissions, copy and
#                         paste, no attribution, Remote Control and auto-compact
#
# Usage: bash templates/workstation/install.sh
# It never uses sudo: when a system package is missing, it prints the command and stops.
# It can run again at any time; finished steps are skipped, and a file it would replace is
# renamed to <file>.bak-<time> first. Each part ends with its acceptance test.

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
for c in git:git tput:ncurses-bin; do
  command -v "${c%%:*}" >/dev/null || pkgs+=("${c#*:}")
done
if (( ${#pkgs[@]} )); then
  say "  ✗ Missing system packages. Install them first (this needs sudo):"
  say "    sudo apt install -y ${pkgs[*]}"
  exit 1
fi
if ! printf '%s\n' 2.31 "$(git --version | awk '{print $3}')" | sort -V -C; then
  say "  ✗ $(git --version) is too old; the git prompt needs 2.31 or later"; exit 1
fi
if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 2) )); then
  say "  ✗ bash $BASH_VERSION is too old; 4.2 or later is needed"; exit 1
fi
say "  ✓ all tools present"

say "[2/4] A · git prompt"
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

say "[3/4] B · COLORTERM over ssh"
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

say "[4/4] Acceptance test of the git prompt"
bash "$HERE/accept.sh"; rc=$?

say ""
say "== C · Claude Code (templates/claude-code/install.sh)"
bash "$HERE/../claude-code/install.sh"; rc2=$?
say ""
if (( rc == 0 && rc2 == 0 )); then
  say "Terminal: open a new terminal (or run source ~/.bashrc); inside a git repository the prompt shows (branch) [worktree]."
  if [[ -n "${SSH_CONNECTION-}" ]]; then say "This is an ssh session: log in again so the colours match your local machine."; fi
else
  say "Something failed. Fix the FAIL lines above, then run this script again."
fi
(( rc == 0 && rc2 == 0 ))
