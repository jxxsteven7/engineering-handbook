#!/usr/bin/env bash
# Self-test of server-clipboard.sh: runs it in a throwaway HOME, with stand-ins for xclip and
# claude, and checks what it changes. Nothing outside a temporary directory is touched.
# The last line reads "== N PASS, M FAIL ==", and M must be 0.
set -u
here=$(cd "$(dirname "$0")" && pwd)
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
export HOME="$t/home"
export PATH="$t/bin:$HOME/.local/bin:/usr/bin:/bin"
mkdir -p "$HOME/.local/bin" "$t/bin"
pass=0; fail=0
chk(){ if [[ "$2" == "$3" ]]; then echo "PASS $1"; ((pass++)); else echo "FAIL $1"; printf '  expected: %q\n  actual:   %q\n' "$2" "$3"; ((fail++)); fi; }

# A working xclip, and a claude that prints whether it sees SSH_CONNECTION. The comment holds
# the line Claude Code uses to decide that a session is remote.
printf '#!/bin/sh\nexit 0\n' > "$t/bin/xclip"
cat > "$HOME/.local/bin/claude" <<'EOF'
#!/bin/sh
# function g(){return hu()?.ssh??!!a.SSH_CONNECTION}
[ "${1-}" = --version ] && { echo "9.9.9 (Claude Code)"; exit 0; }
echo "SSH_CONNECTION=${SSH_CONNECTION-unset} args=$*"
EOF
chmod +x "$t/bin/xclip" "$HOME/.local/bin/claude"
echo '# the distribution'"'"'s ~/.bashrc' > "$HOME/.bashrc"
echo 'PATH="$HOME/.local/bin:$PATH"' > "$HOME/.profile"
fn_count(){ grep -c 'env -u SSH_CONNECTION claude' "$HOME/.bashrc"; }
backups(){ ls "$HOME"/.bashrc.bak-clip-* 2>/dev/null | wc -l; }

out=$(bash "$here/server-clipboard.sh" </dev/null)
chk "S1 finds xclip" "OK   xclip: $t/bin/xclip" "$(grep '^OK   xclip' <<<"$out")"
chk "S2 appends the claude() function once" "1" "$(fn_count)"
chk "S3 backs up ~/.bashrc first" "1" "$(backups)"
chk "S4 keeps the distribution's lines" "# the distribution's ~/.bashrc" "$(head -1 "$HOME/.bashrc")"
chk "S5 the Claude Code check passes" "OK   9.9.9 (Claude Code) still decides ssh from SSH_CONNECTION alone" "$(grep 'still decides' <<<"$out")"

out=$(bash "$here/server-clipboard.sh" </dev/null)
chk "S6 a second run reports the function" "OK   ~/.bashrc already has the claude() function" "$(grep 'claude() function' <<<"$out")"
chk "S7 a second run adds nothing" "1 1" "$(fn_count) $(backups)"

# The function hides SSH_CONNECTION only when DISPLAY and xclip are there.
run(){ env -i HOME="$HOME" PATH="$PATH" "$@" "$BASH" -c '. "$HOME/.bashrc"; claude -r "two words"'; }
chk "S8 ssh with DISPLAY and xclip: claude sees no SSH_CONNECTION" "SSH_CONNECTION=unset args=-r two words" "$(run SSH_CONNECTION='10.0.0.1 22 10.0.0.2 22' DISPLAY=localhost:10.0)"
chk "S9 ssh without DISPLAY: claude starts unchanged" "SSH_CONNECTION=10.0.0.1 22 10.0.0.2 22 args=-r two words" "$(run SSH_CONNECTION='10.0.0.1 22 10.0.0.2 22')"
# Without /usr/bin in PATH, so that an xclip installed on this machine doesn't count.
chk "S10 ssh with DISPLAY but no xclip: claude starts unchanged" "SSH_CONNECTION=10.0.0.1 22 10.0.0.2 22 args=-r two words" "$(run PATH="$HOME/.local/bin" SSH_CONNECTION='10.0.0.1 22 10.0.0.2 22' DISPLAY=localhost:10.0)"

# A Claude Code that decides ssh some other way gets a warning; a missing one is skipped.
sed -i '/SSH_CONNECTION}$/d' "$HOME/.local/bin/claude"
out=$(bash "$here/server-clipboard.sh" </dev/null)
chk "S11 warns when Claude Code decides ssh differently" "1" "$(grep -c '^WARN this version of Claude Code decides ssh differently' <<<"$out")"
rm "$HOME/.local/bin/claude"
out=$(bash "$here/server-clipboard.sh" </dev/null)
chk "S12 skips the check when Claude Code is missing" "1" "$(grep -c '^SKIP Claude Code is not installed' <<<"$out")"

echo "== $pass PASS, $fail FAIL =="
(( fail == 0 ))
