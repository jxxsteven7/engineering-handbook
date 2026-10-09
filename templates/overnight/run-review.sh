#!/usr/bin/env bash
# Reviews one PR, then fixes what the review found, from the Agentic Engineering Handbook
# (docs/rules/overnight.md). watch.sh starts it in a tmux session named review-pr<N>, inside
# the PR's own worktree:
#
#   run-review.sh <PR number> <worktree> <review effort> <development prompt file>
#
# 1. A fresh Claude Code session (REVIEW_MODEL, the given effort) reviews the PR and writes
#    pr<N>-review.md, ending in "FINDINGS: <x> required, <y> nits". It changes no files.
# 2. If it found anything, the same session is resumed on FIX_MODEL at FIX_EFFORT. It fixes
#    everything in order, runs the checks, pushes to the PR's branch, waits for CI and writes
#    pr<N>-summary.md, ending in a VERDICT line. It never merges.
# Both run with --dangerously-skip-permissions, because nobody is there to approve; the red
# lines are in review-prompt.md and fix-prompt.md.
set -uo pipefail

number="$1" worktree="$2" effort="$3" plan="$4"
dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
. "$dir/overnight.conf"
state="$dir/state"
review="$dir/pr$number-review.md"
summary="$dir/pr$number-summary.md"
log() { printf '%s %s\n' "$(date '+%F %T')" "$*" | tee -a "$dir/watch.log"; }

mkdir -p "$state"
echo "$number" > "$state/busy"
trap 'rm -f "$state/busy"' EXIT

fill() { # fill <template>: the template with its placeholders filled in
  local text
  text="$(cat "$1")"
  text="${text//\{N\}/$number}"
  text="${text//\{EFFORT\}/$effort}"
  text="${text//\{PLAN\}/$PLANS_DIR/$plan}"
  text="${text//\{REVIEW\}/$review}"
  text="${text//\{SUMMARY\}/$summary}"
  text="${text//\{CHECKS\}/$CHECKS}"
  text="${text//\{LANGUAGE\}/$LANGUAGE}"
  printf '%s' "$text"
}

cd "$worktree" || { log "pr$number: no worktree at $worktree"; exit 1; }
git fetch --quiet origin
branch="$(git branch --show-current)"
if [ -n "$(git status --porcelain)" ] || [ "$(git rev-parse HEAD)" != "$(git rev-parse "origin/$branch")" ]; then
  log "pr$number: $worktree has local changes or is not at origin/$branch; not reviewing"
  exit 1
fi

session="$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen)"
echo "$session" > "$dir/pr$number-session"
log "pr$number: review started ($REVIEW_MODEL, effort $effort), session $session"
claude -p --session-id "$session" --name "review-pr$number" --model "$REVIEW_MODEL" --effort "$effort" \
  --dangerously-skip-permissions "$(fill "$dir/review-prompt.md")" | tee "$dir/pr$number-review.out"

findings="$(grep -E '^`?FINDINGS: [0-9]+ required, [0-9]+ nits' "$review" 2>/dev/null | tail -1 | tr -d '`')"
if [ -z "$findings" ]; then
  log "pr$number: the review wrote no FINDINGS line to $review; stopping"
  exit 1
fi
required="$(sed -E 's/FINDINGS: ([0-9]+) required.*/\1/' <<<"$findings")"
nits="$(sed -E 's/.*, ([0-9]+) nits.*/\1/' <<<"$findings")"

if [ "$required" = 0 ] && [ "$nits" = 0 ]; then
  log "pr$number: the review found nothing; waiting for CI"
  checks="$(gh pr checks "$number" --watch 2>&1 | tail -20)"
  if gh pr checks "$number" >/dev/null 2>&1; then verdict="VERDICT: ready to merge. The review found nothing and CI passed."
  else verdict="VERDICT: not ready. The review found nothing, but CI did not pass."; fi
  printf 'The review found nothing; no changes were made.\n\nCI:\n\n```\n%s\n```\n\n%s\n' "$checks" "$verdict" > "$summary"
  log "pr$number: done. $verdict"
  exit 0
fi

log "pr$number: $required required, $nits nits; fixing on $FIX_MODEL ($FIX_EFFORT)"
claude -p --resume "$session" --model "$FIX_MODEL" --effort "$FIX_EFFORT" \
  --dangerously-skip-permissions "$(fill "$dir/fix-prompt.md")" | tee "$dir/pr$number-fix.out"

verdict="$(grep -E '^`?VERDICT:' "$summary" 2>/dev/null | tail -1 | tr -d '`')"
log "pr$number: done. ${verdict:-no VERDICT line in $summary}"
