#!/usr/bin/env bash
# Self-test for watch.sh and run-review.sh, with stand-ins for gh, claude and tmux, so it runs
# anywhere git is installed and touches nothing outside a temporary directory. CI runs it.
#
#   bash templates/overnight/selftest.sh
#
# It sets up a bare remote, a main clone and one PR worktree, then lets the watcher find the PR,
# wait for it to settle, start the review, and resume the session for the fix. The last line is
# "== N PASS, M FAIL ==", and M must be 0.
set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
pass=0; fail=0
chk(){ if [[ "$2" == "$3" ]]; then echo "PASS $1"; ((pass++)); else echo "FAIL $1"; printf '  expected: %q\n  actual:   %q\n' "$2" "$3"; ((fail++)); fi; }
has(){ if grep -qF -- "$2" "$3" 2>/dev/null; then echo "PASS $1"; ((pass++)); else echo "FAIL $1: no \"$2\" in ${3##*/}"; ((fail++)); fi; }

export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
G(){ git -c init.defaultBranch=main -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }

# A remote, the main clone, and a worktree for the branch feat/x with one pushed commit.
G init -q --bare "$T/remote.git"
G clone -q "$T/remote.git" "$T/code/r/r" 2>/dev/null
G -C "$T/code/r/r" commit -q --allow-empty -m "chore: start"
G -C "$T/code/r/r" push -q origin main
G -C "$T/code/r/r" worktree add -q "$T/code/r/feat-x" -b feat/x origin/main 2>/dev/null
G -C "$T/code/r/feat-x" commit -q --allow-empty -m "feat: add x"
G -C "$T/code/r/feat-x" push -q -u origin feat/x 2>/dev/null
SHA=$(git -C "$T/code/r/feat-x" rev-parse HEAD)

# The autoreview directory, as the prompt sets it up.
A="$T/code/r/plans/autoreview"
mkdir -p "$A"
cp "$HERE"/{watch.sh,run-review.sh,review-prompt.md,fix-prompt.md} "$A/"
printf 'feat/x  high  01-x.md\n' > "$A/branches.txt"
cat > "$A/overnight.conf" <<EOF
REPO_DIR="$T/code/r/r"
GH_REPO="o/r"
PLANS_DIR="$T/code/r/plans"
REVIEW_MODEL="opus"
FIX_MODEL="fable"
FIX_EFFORT="xhigh"
CHECKS="make check"
LANGUAGE="English"
STABLE_MIN=0
POLL_SEC=1
EOF

# Stand-ins. gh reports one open PR at the branch head and passing checks; claude records its
# arguments, writes a review with one required finding, then a summary on --resume; tmux runs
# the command in the foreground, so the test needs no terminal.
B="$T/bin"; mkdir -p "$B"
cat > "$B/gh" <<EOF
#!/usr/bin/env bash
case "\$1 \$2" in
  "pr list") echo "7 $SHA" ;;
  "pr checks") echo "all checks passed" ;;
esac
EOF
cat > "$B/claude" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$T/claude.args"
if [[ " \$* " == *" --resume "* ]]; then
  printf 'Fixed 1.\n\nVERDICT: ready to merge. Everything was fixed and CI passed.\n' > "$A/pr7-summary.md"
else
  printf '1. src/x.js:1 a bug. Required.\n\nFINDINGS: 1 required, 0 nits\n' > "$A/pr7-review.md"
fi
EOF
cat > "$B/tmux" <<'EOF'
#!/usr/bin/env bash
# new-session -d -s <name> -c <dir> <command>: run <command> in <dir>, without the trailing "exec bash"
if [[ "$1" == new-session ]]; then
  shift; while [[ "$1" == -* ]]; do case "$1" in -c) dir=$2; shift 2 ;; -s) shift 2 ;; *) shift ;; esac; done
  cmd=${1%; exec bash}
  ( cd "$dir" && bash -c "$cmd" ) > /dev/null 2>&1
fi
EOF
chmod +x "$B"/*
export PATH="$B:$PATH"

# Round 1: the PR is new, so the watcher only records its head and waits for it to settle.
ONCE=1 bash "$A/watch.sh" > /dev/null
chk "the first round records the head" "$SHA" "$(cat "$A/state/feat-x.sha")"
has "the first round waits" "waiting 0 min for it to settle" "$A/watch.log"
chk "no review yet" "no" "$( [ -e "$A/pr7-review.md" ] && echo yes || echo no )"

# Round 2: the head hasn't moved, so the review and the fix run.
sleep 1
ONCE=1 bash "$A/watch.sh" > /dev/null
has "the review was started" "feat/x: started review-pr7 (review effort high)" "$A/watch.log"
has "the review ran on the review model and effort" "--model opus --effort high" "$T/claude.args"
has "the review prompt was filled in" "Compare the PR with its development prompt, $T/code/r/plans/01-x.md." "$T/claude.args"
has "the fix resumed the same session" "--resume $(cat "$A/pr7-session" 2>/dev/null)" "$T/claude.args"
has "the fix ran on the fix model and effort" "--model fable --effort xhigh" "$T/claude.args"
has "the fix prompt names the checks" "Before pushing, run the checks: make check" "$T/claude.args"
has "the verdict was logged" "pr7: done. VERDICT: ready to merge." "$A/watch.log"
chk "the branch is marked as reviewed" "yes" "$( [ -e "$A/state/feat-x.started" ] && echo yes || echo no )"
chk "the busy flag is cleared" "no" "$( [ -e "$A/state/busy" ] && echo yes || echo no )"

# Round 3: a branch is reviewed only once.
calls=$(wc -l < "$T/claude.args")
ONCE=1 bash "$A/watch.sh" > /dev/null
chk "a reviewed branch is not reviewed again" "$calls" "$(wc -l < "$T/claude.args")"

echo "== $pass PASS, $fail FAIL =="
(( fail == 0 ))
