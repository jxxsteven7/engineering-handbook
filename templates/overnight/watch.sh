#!/usr/bin/env bash
# Watches the branches in branches.txt and starts one review at a time, from the Agentic
# Engineering Handbook (docs/rules/overnight.md). Settings are in overnight.conf next to it.
# Run it in its own tmux session:
#
#   tmux new -d -s cc-watch ~/code/<repo>/plans/autoreview/watch.sh
#
# A branch is reviewed once, when it has an open PR whose head hasn't moved for STABLE_MIN
# minutes (so the development session has finished pushing) and its worktree is clean. The
# review runs in a tmux session named review-pr<N>; see run-review.sh. To review a branch again,
# delete state/<branch with / replaced by ->.started. Everything it does goes to watch.log.
# It is a shell script, not an agent session, so waiting costs nothing. It never merges.
# With ONCE=1 it looks once and exits (for tests).
set -uo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"
[ -r "$dir/overnight.conf" ] || { echo "No $dir/overnight.conf; copy overnight.conf.example and fill it in." >&2; exit 1; }
# shellcheck source=/dev/null
. "$dir/overnight.conf"
state="$dir/state"
mkdir -p "$state"
STABLE_MIN="${STABLE_MIN:-15}"
POLL_SEC="${POLL_SEC:-300}"
GH_REPO="${GH_REPO:-$(cd "$REPO_DIR" && gh repo view --json nameWithOwner -q .nameWithOwner)}"

log() { printf '%s %s\n' "$(date '+%F %T')" "$*" | tee -a "$dir/watch.log"; }
note() { # note <slug> <message>: logs the message unless it is the last one logged for the slug
  [ "$(cat "$state/$1.note" 2>/dev/null)" = "$2" ] && return
  printf '%s' "$2" > "$state/$1.note"
  log "$2"
}

log "watching $(grep -cvE '^\s*(#|$)' "$dir/branches.txt") branches of $GH_REPO every ${POLL_SEC}s"
while true; do
  while read -r branch effort plan <&3; do
    case "$branch" in ''|'#'*) continue ;; esac
    slug="${branch//\//-}"
    [ -e "$state/$slug.started" ] && continue

    pr="$(gh pr list --repo "$GH_REPO" --head "$branch" --state open \
      --json number,headRefOid -q '.[] | "\(.number) \(.headRefOid)"' 2>/dev/null | head -1)"
    if [ -z "$pr" ]; then note "$slug" "$branch: no open PR yet"; continue; fi
    read -r number sha <<<"$pr"

    now="$(date +%s)"
    if [ "$(cat "$state/$slug.sha" 2>/dev/null)" != "$sha" ]; then
      echo "$sha" > "$state/$slug.sha"
      echo "$now" > "$state/$slug.since"
      note "$slug" "$branch: PR #$number at ${sha:0:7}; waiting ${STABLE_MIN} min for it to settle"
      continue
    fi
    (( now - $(cat "$state/$slug.since") >= STABLE_MIN * 60 )) || continue

    worktree="$(git -C "$REPO_DIR" worktree list --porcelain |
      awk -v b="branch refs/heads/$branch" '/^worktree /{w=substr($0, 10)} $0 == b {print w}')"
    if [ -z "$worktree" ]; then note "$slug" "$branch: no local worktree; not reviewing"; continue; fi
    if [ -n "$(git -C "$worktree" status --porcelain)" ]; then
      note "$slug" "$branch: PR #$number, but $worktree has uncommitted changes; waiting"
      continue
    fi
    if [ -e "$state/busy" ]; then
      note "$slug" "$branch: PR #$number ready; waiting for review-pr$(cat "$state/busy") to finish"
      continue
    fi

    touch "$state/$slug.started"
    echo "$number" > "$state/busy" # run-review.sh takes it over and removes it when it ends
    if tmux new-session -d -s "review-pr$number" -c "$worktree" \
      "bash '$dir/run-review.sh' '$number' '$worktree' '$effort' '$plan'; exec bash"; then
      log "$branch: started review-pr$number (review effort $effort)"
    else
      rm -f "$state/busy" "$state/$slug.started"
      log "$branch: could not start the tmux session review-pr$number; will try again"
    fi
  done 3< "$dir/branches.txt"
  [ -n "${ONCE-}" ] && exit 0
  sleep "$POLL_SEC"
done
