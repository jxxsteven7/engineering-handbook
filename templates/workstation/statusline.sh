#!/usr/bin/env bash
# Claude Code statusline, from the Agentic Engineering Handbook (docs/tools/workstation.md).
# Install it as ~/.claude/statusline.sh; templates/workstation/install.sh does that.
#
# Up to 2 lines:
#   1. model | effort | context % | weekly %   (Claude orange, whole line)
#   2. branch | worktree                       (branch cyan, worktree green)
# Segments are joined with " | "; a segment whose value is missing is dropped, and
# line 2 is omitted entirely outside a git repository. The permission-mode / PR /
# shells line below these is drawn by Claude Code itself, not here.
# Reads the statusline JSON payload on stdin. Always exits 0, so a failure never makes
# the statusline disappear.

set -uo pipefail

input=$(cat)

# ---------- palette ----------
if [[ "${COLORTERM:-}" == "truecolor" || "${COLORTERM:-}" == "24bit" ]]; then
  ORANGE=$'\033[38;2;217;119;87m'   # Claude orange #D97757
  GREEN=$'\033[38;2;126;231;135m'
  CYAN=$'\033[38;2;103;216;232m'
else
  ORANGE=$'\033[38;5;173m'
  GREEN=$'\033[38;5;114m'
  CYAN=$'\033[38;5;80m'
fi
R=$'\033[0m'

# ---------- pull fields out of the payload in one jq pass ----------
# One field per line (NOT @tsv + read: tab is an IFS whitespace char, so empty
# fields would collapse and shift every later value).
# NOTE on `// ""`: jq treats only null/false as falsy, so a genuine 0% survives.
mapfile -t F < <(
  printf '%s' "$input" | jq -r '
    [ (.model.display_name // .model.id // "")
    , (.effort.level // "")
    , (.worktree.name // "")
    , (.worktree.branch // "")
    , (.workspace.current_dir // .cwd // "")
    , (.context_window.used_percentage // "")
    , (.rate_limits.seven_day.used_percentage // "")
    , (.transcript_path // "")
    ] | .[] | tostring' 2>/dev/null
)
model="${F[0]-}"
effort="${F[1]-}"
wt_name="${F[2]-}"
wt_branch="${F[3]-}"
cur_dir="${F[4]-}"
ctx_pct="${F[5]-}"
wk_pct="${F[6]-}"
transcript="${F[7]-}"

# Round a percentage to a whole number; fail (non-zero) when absent/unparseable.
fmt_pct() {
  local v="${1-}"
  [[ -n "$v" && "$v" != "null" ]] || return 1
  [[ "$v" =~ ^-?[0-9]+([.][0-9]+)?$ ]] || return 1
  printf '%.0f' "$v"
}

# ---------- git info without the git binary (read .git directly) ----------
# Every render must be fast, so this reads files instead of running git.
repo_root=""
git_dir=""

find_repo() {
  local d="$1"
  while [[ -n "$d" && "$d" != "/" ]]; do
    if [[ -e "$d/.git" ]]; then repo_root="$d"; return 0; fi
    d="${d%/*}"
  done
  [[ -e "/.git" ]] && { repo_root="/"; return 0; }
  return 1
}

resolve_gitdir() {
  local g="$repo_root/.git" line
  if [[ -f "$g" ]]; then                 # linked worktree: ".git" is a file
    IFS= read -r line < "$g" || return 1
    g="${line#gitdir: }"
    [[ "$g" != /* ]] && g="$repo_root/$g"
  fi
  [[ -d "$g" ]] && git_dir="$g"
}

read_head_branch() {
  local head
  [[ -r "$git_dir/HEAD" ]] || return 1
  IFS= read -r head < "$git_dir/HEAD" || return 1
  case "$head" in
    "ref: refs/heads/"*) printf '%s' "${head#ref: refs/heads/}" ;;
    "ref: "*)            printf '%s' "${head#ref: }" ;;
    "")                  return 1 ;;
    *)                   printf '%s' "${head:0:7}" ;;   # detached HEAD
  esac
}

if [[ -z "$wt_name" || -z "$wt_branch" ]]; then
  if find_repo "${cur_dir:-$PWD}" && resolve_gitdir; then
    [[ -z "$wt_name" ]] && wt_name="${repo_root##*/}"
    [[ -z "$wt_branch" ]] && wt_branch="$(read_head_branch)"
  fi
fi

# ---------- ultracode detection ----------
# The payload only carries effort.level, and with ultracode on that resolves to
# "xhigh"; the ultracode flag never reaches the statusline. The session transcript
# records every transition, so take the LAST of:
#   /effort output    "Set effort level to ultracode" | "... to <level>"
#   /model output     "Set model to ... with ultracode effort" | "... with <level> effort"
#   CLI attachments   ultra_effort_enter / ultra_effort_exit
# The transcript format is internal to Claude Code and may change; when nothing
# matches, the label is simply effort.level. `tac | grep -m1` stops at the first hit
# from the end, so this runs on every render without a cache. Escaped quotes inside
# tool output ( \"content\":... ) never match the unescaped prefix, so quoting these
# strings in a conversation cannot spoof it.
ultra=0
if [[ -n "$transcript" && -r "$transcript" ]]; then
  marker=$(tac -- "$transcript" 2>/dev/null | grep -m1 -oE \
    '"content":"<local-command-stdout>(Set effort level to [a-z]+|Set model to [^"]{0,200} with [a-z]+ effort)|"attachment":\{"type":"ultra_effort_(enter|exit)"' 2>/dev/null) || true
  case "$marker" in
    *"Set effort level to ultracode"*|*" with ultracode effort"*|*ultra_effort_enter*) ultra=1 ;;
  esac
fi

# ---------- render ----------
SEP=" | "

# Line 1 (Claude orange, one colour for the whole line):
#   <model> | effort: <level> | context: N% | weekly: N%
#   model   = model.display_name, else model.id, else "Claude".
#   effort  = effort.level, replaced by "ultracode" when the transcript says so.
#   context = the current model's context window.
#   weekly  = rate_limits.seven_day, the account-wide 7-day limit.
effort_label="$effort"
(( ultra )) && effort_label="ultracode"

parts=("${model:-Claude}")
[[ -n "$effort_label" ]] && parts+=("effort: ${effort_label}")
if v=$(fmt_pct "$ctx_pct"); then parts+=("context: ${v}%"); fi
if v=$(fmt_pct "$wk_pct");  then parts+=("weekly: ${v}%"); fi

line1="${ORANGE}"
for i in "${!parts[@]}"; do
  (( i )) && line1+="$SEP"
  line1+="${parts[$i]}"
done
line1+="${R}"
printf '%s\n' "$line1"

# Line 2: branch (cyan) | worktree (green). Each segment carries its own colour and
# its own reset, so the separator between them stays in the terminal's default colour.
# Only the segments that have a value are printed; no repository, no line 2.
segs=()
[[ -n "$wt_branch" ]] && segs+=("${CYAN}branch: ${wt_branch}${R}")
[[ -n "$wt_name"   ]] && segs+=("${GREEN}worktree: ${wt_name}${R}")
if (( ${#segs[@]} )); then
  line2=""
  for i in "${!segs[@]}"; do
    (( i )) && line2+="$SEP"
    line2+="${segs[$i]}"
  done
  printf '%s\n' "$line2"
fi

exit 0
