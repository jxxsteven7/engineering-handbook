#!/usr/bin/env bash
# Acceptance test of the clipboard over ssh, from the Agentic Engineering Handbook (part F of
# prompts/setup/workstation.md). Run it on the workstation:  bash accept-clipboard.sh <ssh alias>
# It overwrites the workstation clipboard for a moment and then puts back what was there, an
# image included. The last line reads "== N PASS, M FAIL ==", and M must be 0.
H=${1:?usage: bash accept-clipboard.sh <ssh alias>}
pass=0; fail=0
chk(){ if [[ "$2" == "$3" ]]; then echo "PASS $1"; ((pass++)); else echo "FAIL $1"; printf '  expected: %q\n  actual:   %q\n' "$2" "$3"; ((fail++)); fi; }
R(){ ssh -o BatchMode=yes "$H" "$1" </dev/null 2>/dev/null; }

# Read and write the workstation clipboard, as text or as a PNG image. xclip and wl-copy stay in
# the background to serve what they copied, so they must not hold on to this script's output.
if [ -n "${DISPLAY-}" ] && command -v xclip >/dev/null; then
  lget(){ xclip -o -selection clipboard 2>/dev/null; }; lset(){ xclip -selection clipboard >/dev/null 2>&1; }
  ltypes(){ xclip -o -selection clipboard -t TARGETS 2>/dev/null; }
  lgetimg(){ xclip -o -selection clipboard -t image/png 2>/dev/null; }; lsetimg(){ xclip -selection clipboard -t image/png >/dev/null 2>&1; }
elif [ -n "${WAYLAND_DISPLAY-}" ] && command -v wl-copy >/dev/null; then
  lget(){ wl-paste --no-newline 2>/dev/null; }; lset(){ wl-copy >/dev/null 2>&1; }
  ltypes(){ wl-paste --list-types 2>/dev/null; }
  lgetimg(){ wl-paste --type image/png 2>/dev/null; }; lsetimg(){ wl-copy --type image/png >/dev/null 2>&1; }
else
  echo "FAIL the workstation has no usable xclip or wl-clipboard, so this test can't run (sudo apt install -y xclip)"; exit 1
fi

cfg=$(ssh -G "$H" 2>/dev/null)
chk "T1 ~/.ssh/config: ForwardX11 yes"        "yes" "$(awk '$1=="forwardx11"{print $2}' <<<"$cfg")"
chk "T2 ~/.ssh/config: ForwardX11Trusted yes" "yes" "$(awk '$1=="forwardx11trusted"{print $2}' <<<"$cfg")"
chk "T3 logs in without a password" "ok" "$(R 'echo ok')"
chk "T4 X11 forwarding works (DISPLAY is set on the server)" "1" "$([[ -n "$(R 'echo $DISPLAY')" ]] && echo 1 || echo 0)"
RX=$(R 'command -v xclip || echo ~/.local/bin/xclip')

# Keep what is on the clipboard, an image included, to put it back afterwards
img=$(mktemp); trap 'rm -f "$img"' EXIT
if ltypes | grep -qx 'image/png'; then lgetimg > "$img"; else saved=$(lget; printf x); saved=${saved%x}; fi
m1="clip-ws-to-srv-$$"; printf %s "$m1" | lset; sleep 0.5
chk "T5 copied on the workstation, read by xclip on the server (the way Ctrl+V goes)" "$m1" "$(R "$RX -o -selection clipboard")"
m2="clip-srv-to-ws-$$"
R "printf %s $m2 | timeout 6 $RX -quiet -selection clipboard" & sleep 2
chk "T6 written by xclip on the server, on the workstation clipboard (the way copy on select goes)" "$m2" "$(lget)"
wait
if [ -s "$img" ]; then lsetimg < "$img"; else printf %s "$saved" | lset; fi

chk "T7 claude in an interactive shell on the server is the ~/.bashrc function" "function" "$(R 'bash -ic "type -t claude"' | tail -1)"
v=$(R 'B=$(readlink -f "$(command -v claude || echo ~/.local/bin/claude)"); if [ -f "$B" ]; then LC_ALL=C grep -aqE "\?\.ssh\?\?!![A-Za-z_\$]+\.SSH_CONNECTION" "$B" && echo same || echo changed; else echo none; fi')
case "$v" in
  none) echo "SKIP T8 Claude Code is not installed on the server yet" ;;
  *)    chk "T8 Claude Code on the server still decides ssh from SSH_CONNECTION alone" "same" "$v" ;;
esac
echo "== $pass PASS, $fail FAIL =="
(( fail == 0 ))
