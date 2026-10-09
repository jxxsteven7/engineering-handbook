#!/usr/bin/env bash
# The server side of the clipboard over ssh, from the Agentic Engineering Handbook (part F of
# prompts/setup/workstation.md): installs xclip and appends a claude() function to ~/.bashrc.
# Run it as a normal user, from the workstation:  ssh <alias> 'bash -s' < server-clipboard.sh
# It never needs root and can run again safely. Every command that might read stdin gets
# </dev/null, so it can't swallow the rest of this script.
set -u
echo "== $(id -un)@$(hostname)"
ok=1

# 1) X11 forwarding needs xauth on the server and X11Forwarding in sshd. Both need an
#    administrator, so this only reports them.
if command -v xauth >/dev/null; then echo "OK   xauth: $(command -v xauth)"
else echo "WARN no xauth, so X11 forwarding won't work: an administrator must run sudo apt install -y xauth"; ok=0; fi
xf=$(cat /etc/ssh/sshd_config.d/*.conf /etc/ssh/sshd_config 2>/dev/null | grep -iE '^[[:space:]]*X11Forwarding[[:space:]]' | head -1 | awk '{print tolower($2)}')
if [ "$xf" = yes ]; then echo "OK   sshd X11Forwarding yes"
else echo "WARN sshd X11Forwarding is ${xf:-not set (OpenSSH defaults to no)}: an administrator must set it to yes and restart sshd"; ok=0; fi

# 2) xclip: use the one that is there; with passwordless sudo, install it with apt; otherwise
#    download the package and unpack only the binary into ~/.local/bin.
X=$(command -v xclip 2>/dev/null || { [ -x ~/.local/bin/xclip ] && echo ~/.local/bin/xclip; })
if [ -z "$X" ]; then
  if sudo -n true </dev/null 2>/dev/null; then
    sudo -n apt-get install -y -q xclip </dev/null >/dev/null 2>&1 && X=$(command -v xclip)
  elif command -v apt-get >/dev/null; then
    d=$(mktemp -d)
    if (cd "$d" && apt-get download xclip </dev/null >/dev/null 2>&1 && dpkg-deb -x xclip_*.deb x </dev/null); then
      mkdir -p ~/.local/bin && install -m 755 "$d/x/usr/bin/xclip" ~/.local/bin/xclip && X=~/.local/bin/xclip
    fi
    rm -rf "$d"
  fi
fi
if [ -n "$X" ] && [ -x "$X" ] && ! ldd "$X" 2>/dev/null | grep -q 'not found'; then echo "OK   xclip: $X"
else echo "FAIL xclip is not usable${X:+ (missing libraries: $(ldd "$X" 2>/dev/null | grep 'not found' | awk '{print $1}' | tr '\n' ' '))}; on a system other than Debian or Ubuntu, or when libraries are missing, ask an administrator to install xclip"; ok=0; fi
# ~/.local/bin must be in the login shell's PATH (Ubuntu's default ~/.profile adds it if the
# directory exists at login).
case "$X" in "$HOME/.local/bin/"*)
  if grep -qs '\.local/bin' ~/.profile ~/.bash_profile ~/.bashrc; then echo "OK   ~/.local/bin is in a PATH setting (takes effect at the next login)"
  else echo "WARN ~/.local/bin is in no PATH setting, so the claude() function won't find xclip"; ok=0; fi ;;
esac

# 3) The claude() function at the end of ~/.bashrc, unless it is there already.
if grep -qs 'env -u SSH_CONNECTION claude' ~/.bashrc; then echo "OK   ~/.bashrc already has the claude() function"
else
  [ -f ~/.bashrc ] && cp ~/.bashrc ~/.bashrc.bak-clip-$(date +%Y%m%d%H%M%S)
  cat >> ~/.bashrc <<'EOF'

# Claude Code treats any session with SSH_CONNECTION as remote: it copies only via
# OSC 52 (which the local terminal ignores) and never reads the clipboard. With X11
# forwarding (ssh -Y) + xclip the workstation clipboard is reachable directly, so hide
# SSH_CONNECTION from claude and it copies/pastes through xclip like a local session.
claude() {
    if [ -n "${SSH_CONNECTION-}" ] && [ -n "${DISPLAY-}" ] && command -v xclip >/dev/null 2>&1; then
        env -u SSH_CONNECTION claude "$@"
    else
        command claude "$@"
    fi
}
EOF
  echo "OK   appended the claude() function to ~/.bashrc (the old file is backed up)"
fi

# 4) The function relies on Claude Code deciding "ssh" from SSH_CONNECTION alone. Check this
#    again after Claude Code updates.
B=$(readlink -f "$(command -v claude 2>/dev/null || echo ~/.local/bin/claude)" 2>/dev/null)
if [ -f "$B" ]; then
  if LC_ALL=C grep -aqE '\?\.ssh\?\?!![A-Za-z_$]+\.SSH_CONNECTION' "$B"; then
    echo "OK   $("$B" --version </dev/null 2>/dev/null | head -1) still decides ssh from SSH_CONNECTION alone"
  else echo "WARN this version of Claude Code decides ssh differently (see Troubleshooting in part F of the prompt); the claude() function may no longer work"; ok=0; fi
else echo "SKIP Claude Code is not installed on the server yet; run this script again after installing it"; fi

[ "$ok" = 1 ] && echo "== SERVER OK" || echo "== SERVER has problems; see the WARN and FAIL lines above"
