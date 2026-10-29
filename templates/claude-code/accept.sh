#!/usr/bin/env bash
# Acceptance test for templates/claude-code/: every check compares against an exact
# expected value. The last line is "== N PASS, M FAIL ==", and M must be 0.
#
#   bash accept.sh                  test the installed statusline and settings in your HOME
#   SCRIPTS_ONLY=1 bash accept.sh   test only statusline.sh next to this file (CI does this)
#
# Expected results: a Linux desktop 45 PASS; a server reached over ssh 44 PASS and SKIP T12c;
# SCRIPTS_ONLY 31 PASS. When T7g-T8 print SKIP (rate limit, expired token, no Fable limit),
# 4 fewer. T9 is gone, and T10, the git prompt, is in templates/workstation/accept.sh.

HERE=$(cd "$(dirname "$0")" && pwd)
if [[ -n "${SCRIPTS_ONLY-}" ]]; then S="$HERE/statusline.sh"; else S=~/.claude/statusline.sh; fi
T=$(mktemp -d); cd "$T" || exit 1
# The statusline shows "rc" when it finds a session file of a parent claude with Remote Control
# on. Point it at an empty directory, so running this test inside such a session changes nothing.
# The OAuth credentials are linked in for T7g-T8, which fetch the real Fable limit.
REAL_CFG=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
export CLAUDE_CONFIG_DIR=$T/cfg; mkdir -p cfg/sessions
[[ -r "$REAL_CFG/.credentials.json" ]] && ln -s "$REAL_CFG/.credentials.json" cfg/.credentials.json
# The Fable limit is cached in $XDG_CACHE_HOME; use an empty one, so other sessions don't interfere.
export XDG_CACHE_HOME=$T/cache; C=$XDG_CACHE_HOME/claude-statusline
export COLORTERM=truecolor                     # use the truecolor branch so the expected values are fixed
O=$'\033[38;2;217;119;87m'; G=$'\033[38;2;126;231;135m'; Y=$'\033[38;2;103;216;232m'; R=$'\033[0m'
pass=0; fail=0
chk(){ if [[ "$2" == "$3" ]]; then echo "PASS $1"; ((pass++)); else echo "FAIL $1"; printf '  expected: %q\n  actual:   %q\n' "$2" "$3"; ((fail++)); fi; }
mk(){ printf '{"model":{"id":"%s","display_name":"%s"},"effort":{"level":"xhigh"},"transcript_path":"%s","cwd":"%s","context_window":{"used_percentage":12.4},"rate_limits":{"five_hour":{"used_percentage":41.2,"resets_at":%s},"seven_day":{"used_percentage":3}}}' "$1" "$2" "$3" "$4" "$RA"; }
RA=$(( $(date +%s) + 8010 ))                   # the 5-hour window resets in 2h13m
U='{"type":"user","message":{"role":"user","content":"<local-command-stdout>'
SL(){ bash "$S"; }

if [[ ! -r "$S" ]]; then
  echo "FAIL T1-T6 no $S"; ((fail++))
else
# T1 basic rendering: outside a repository, one line
chk "T1a basic line" "${O}Opus 5 | effort: xhigh | context: 12% | 5h: 41% (2h13m) | weekly-allmodels: 3%${R}" "$(mk claude-opus-5 "Opus 5" "" /tmp | SL)"
chk "T1b 256 colours without truecolor" $'\033[38;5;173m'"Opus 5 | effort: xhigh | context: 12% | 5h: 41% (2h13m) | weekly-allmodels: 3%${R}" "$(mk claude-opus-5 "Opus 5" "" /tmp | COLORTERM= SL)"

# T1c-d Remote Control: a green "rc" at the end of line 1 while the session file has a bridgeSessionId
printf '{"pid":%s,"bridgeSessionId":"session_01TEST"}' "$$" > "cfg/sessions/$$.json"
chk "T1c rc on" "${O}Opus 5 | effort: xhigh | context: 12% | 5h: 41% (2h13m) | weekly-allmodels: 3% | ${G}rc${R}" "$(mk claude-opus-5 "Opus 5" "" /tmp | SL)"
printf '{"pid":%s,"bridgeSessionId":null}' "$$" > "cfg/sessions/$$.json"
chk "T1d rc off" "${O}Opus 5 | effort: xhigh | context: 12% | 5h: 41% (2h13m) | weekly-allmodels: 3%${R}" "$(mk claude-opus-5 "Opus 5" "" /tmp | SL)"

# T2 a real 0% is shown
chk "T2 0% is kept" "${O}Opus 5 | context: 0% | weekly-allmodels: 0%${R}" \
  "$(printf '{"model":{"display_name":"Opus 5"},"context_window":{"used_percentage":0},"rate_limits":{"seven_day":{"used_percentage":0}}}' | SL)"

# T3 a missing field drops its segment, with no empty separator
chk "T3a no rate_limits" "${O}Opus 5 | context: 12%${R}" "$(printf '{"model":{"display_name":"Opus 5"},"context_window":{"used_percentage":12.4}}' | SL)"
chk "T3b only the model" "${O}Opus 5${R}" "$(printf '{"model":{"display_name":"Opus 5"}}' | SL)"
chk "T3c model id without display_name" "${O}claude-opus-5${R}" "$(printf '{"model":{"id":"claude-opus-5"}}' | SL)"

# T4 garbage input: one line "Claude", exit 0
out=$(echo garbage | SL); ec=$?
chk "T4a garbage prints Claude" "${O}Claude${R}" "$out"
chk "T4b garbage exits 0" "0" "$ec"

# T5 ultracode: the last marker in the transcript wins
L1="${O}Opus 5 | effort: %s | context: 12%% | 5h: 41%% (2h13m) | weekly-allmodels: 3%%${R}"
printf '%s\n' "${U}Set effort level to ultracode (this session only): xhigh + dynamic workflow orchestration</local-command-stdout>\"}}" > a.jsonl
chk "T5a /effort ultracode" "$(printf "$L1" ultracode)" "$(mk claude-opus-5 "Opus 5" "$T/a.jsonl" /tmp | SL)"
{ cat a.jsonl; printf '%s\n' "${U}Set effort level to xhigh (saved as your default for new sessions): x</local-command-stdout>\"}}"; } > b.jsonl
chk "T5b /effort xhigh" "$(printf "$L1" xhigh)" "$(mk claude-opus-5 "Opus 5" "$T/b.jsonl" /tmp | SL)"
{ cat b.jsonl; printf '%s\n' '{"type":"attachment","attachment":{"type":"ultra_effort_enter","reminderType":"full"}}'; } > c.jsonl
chk "T5c ultra_effort_enter" "$(printf "$L1" ultracode)" "$(mk claude-opus-5 "Opus 5" "$T/c.jsonl" /tmp | SL)"
{ cat c.jsonl; printf '%s\n' '{"type":"attachment","attachment":{"type":"ultra_effort_exit"}}'; } > d.jsonl
chk "T5d ultra_effort_exit" "$(printf "$L1" xhigh)" "$(mk claude-opus-5 "Opus 5" "$T/d.jsonl" /tmp | SL)"
{ cat d.jsonl; printf '%s\n' "${U}Set model to \`Fable 5.1\` for this session only with ultracode effort</local-command-stdout>\"}}"; } > e.jsonl
chk "T5e /model ... with ultracode effort" "$(printf "$L1" ultracode)" "$(mk claude-opus-5 "Opus 5" "$T/e.jsonl" /tmp | SL)"
{ cat d.jsonl; printf '%s\n' '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"quoted: \"content\":\"<local-command-stdout>Set effort level to ultracode"}]}}'; } > f.jsonl
chk "T5f quoted in tool output: ignored" "$(printf "$L1" xhigh)" "$(mk claude-opus-5 "Opus 5" "$T/f.jsonl" /tmp | SL)"
chk "T5g no transcript: effort.level" "$(printf "$L1" xhigh)" "$(mk claude-opus-5 "Opus 5" "$T/nope.jsonl" /tmp | SL)"

# T6 line 2: branch cyan | worktree green, separator in the default colour
chk "T6a worktree fields from the payload" "${Y}branch: feat/x${R} | ${G}worktree: foo${R}" \
  "$(printf '{"model":{"display_name":"Opus 5"},"worktree":{"name":"foo","branch":"feat/x"},"cwd":"/tmp"}' | SL | sed -n 2p)"
mkdir -p repo/.git/refs/heads && echo 'ref: refs/heads/main' > repo/.git/HEAD
chk "T6b plain repository read from .git" "${O}Opus 5 | effort: xhigh | context: 12% | 5h: 41% (2h13m) | weekly-allmodels: 3%${R}"$'\n'"${Y}branch: main${R} | ${G}worktree: repo${R}" "$(mk claude-opus-5 "Opus 5" "" "$T/repo" | SL)"
mkdir -p repo/sub/dir
chk "T6c found from a subdirectory" "${Y}branch: main${R} | ${G}worktree: repo${R}" "$(mk claude-opus-5 "Opus 5" "" "$T/repo/sub/dir" | SL | sed -n 2p)"
mkdir -p wt && printf 'gitdir: %s/repo/.git\n' "$T" > wt/.git
chk "T6d linked worktree (.git is a file)" "${Y}branch: main${R} | ${G}worktree: wt${R}" "$(mk claude-opus-5 "Opus 5" "" "$T/wt" | SL | sed -n 2p)"
echo 0123456789abcdef > repo/.git/HEAD
chk "T6e detached HEAD shows 7 characters" "${Y}branch: 0123456${R} | ${G}worktree: repo${R}" "$(mk claude-opus-5 "Opus 5" "" "$T/repo" | SL | sed -n 2p)"
chk "T6f branch only: no separator" "${Y}branch: solo${R}" "$(printf '{"model":{"display_name":"Opus 5"},"worktree":{"branch":"solo"},"cwd":"/tmp"}' | SL | sed -n 2p)"
chk "T6g outside a repository: no line 2" "1" "$(mk claude-opus-5 "Opus 5" "" /tmp | SL | wc -l | tr -d ' ')"

# T7 weekly-fable: a Fable session shows this week's Fable limit from the shared cache that a
# detached fetcher fills from /api/oauth/usage. T7a-T7f use a cache made up here.
mtime(){ stat -c %Y "$1" 2>/dev/null || stat -f %m "$1"; }
stale(){ touch -d '-700 sec' "$@" 2>/dev/null || touch -t "$(date -v-12M +%Y%m%d%H%M.%S)" "$@"; }
LF="${O}Fable 5.1 | effort: xhigh | context: 12%% | 5h: 41%% (2h13m) | weekly-%s${R}"
mkdir -p "$C"; : > "$C/usage.attempt"
printf '{"limits":[{"kind":"weekly_all","percent":17},{"kind":"weekly_scoped","scope":{"model":{"display_name":"Fable"}},"percent":33.4}]}' > "$C/usage.json"
chk "T7a Fable session, fresh cache: weekly-fable" "$(printf "$LF" "fable: 33%")" "$(mk claude-fable-5-1 "Fable 5.1" "" /tmp | SL)"
chk "T7b other models: weekly-allmodels from the payload" "${O}Opus 5 | effort: xhigh | context: 12% | 5h: 41% (2h13m) | weekly-allmodels: 3%${R}" "$(mk claude-opus-5 "Opus 5" "" /tmp | SL)"
stale "$C/usage.json" "$C/usage.attempt"; a0=$(mtime "$C/usage.attempt")
mk claude-opus-5 "Opus 5" "" /tmp | SL >/dev/null; sleep 1; a1=$(mtime "$C/usage.attempt")
chk "T7c other models never start a fetch" "$a0" "$a1"
t0=${EPOCHREALTIME:-0}; out=$(mk claude-fable-5-1 "Fable 5.1" "" /tmp | SL); t1=${EPOCHREALTIME:-0}
chk "T7d stale cache: weekly-allmodels at once" "$(printf "$LF" "allmodels: 3%")" "$out"
if [[ $t0 != 0 ]]; then ms=$(( (${t1/./} - ${t0/./}) / 1000 )); chk "T7e that render takes under 300 ms (${ms} ms)" "1" "$(( ms < 300 ))"; fi
sleep 1; a2=$(mtime "$C/usage.attempt")
chk "T7f a Fable session with a stale cache starts a fetch" "1" "$(( a2 > a1 ))"

# T7g-T8 fetch the real limit with this machine's login. A full run only, not in CI.
if [[ -z "${SCRIPTS_ONLY-}" && -r "$T/cfg/.credentials.json" ]]; then
  # The HTTP status of the endpoint, for a failed fetch; the token goes to curl on stdin, never in argv.
  usage_code(){ jq -r '.claudeAiOauth.accessToken // empty' "$T/cfg/.credentials.json" 2>/dev/null \
    | { IFS= read -r tok; [[ -n "$tok" ]] && printf 'url = "https://api.anthropic.com/api/oauth/usage"\nheader = "Authorization: Bearer %s"\nheader = "anthropic-beta: oauth-2025-04-20"\nheader = "User-Agent: claude-cli/test (external, cli)"\n' "$tok"; } \
    | curl -sS -K - -m 8 -o /dev/null -w '%{http_code}' 2>/dev/null; }
  sleep 2; rm -rf "$C"; bash "$S" --fetch-usage test
  pct=$(jq -r '[.limits[]? | select(.kind=="weekly_scoped" and ((.scope.model.display_name//"")|ascii_downcase|startswith("fable")))] | first | .percent // empty' "$C/usage.json" 2>/dev/null)
  if [[ -n "$pct" ]]; then
    echo "PASS T7g fetched this week's Fable limit: $(printf '%.0f' "$pct")%"; ((pass++))
    chk "T7h a Fable session shows it" "$(printf "$LF" "fable: $(printf '%.0f' "$pct")%")" "$(mk claude-fable-5-1 "Fable 5.1" "" /tmp | SL)"
    chk "T7i the cache file has mode 600" "600" "$(stat -c %a "$C/usage.json" 2>/dev/null || stat -f %Lp "$C/usage.json")"
    pref=$(jq -r '.claudeAiOauth.accessToken // empty' "$T/cfg/.credentials.json" 2>/dev/null | cut -c1-16)
    bash "$S" --fetch-usage test &
    seen=$(for i in $(seq 1 30); do ps -eo args | grep -v grep | grep -cF -- "$pref"; sleep 0.02; done | sort -u | tr '\n' ' ')
    wait
    chk "T8 the token never shows up in ps" "0 " "$seen"
  elif [[ -s "$C/usage.json" ]]; then
    echo "SKIP T7g-T8 (this account has no weekly Fable limit, so line 1 always shows weekly-allmodels)"
  else
    case "$(usage_code)" in
      429) echo "SKIP T7g-T8 (/api/oauth/usage is rate-limited, HTTP 429: wait 10 minutes and run this test again)" ;;
      401) echo "SKIP T7g-T8 (the OAuth token has expired, HTTP 401: start claude once to refresh it, then run this test again)" ;;
      *)   echo "FAIL T7g could not fetch /api/oauth/usage (check that claude is logged in and api.anthropic.com is reachable)"; ((fail++)) ;;
    esac
  fi
fi
for i in 1 2 3 4 5 6 7 8 9 10; do left=$(pgrep -af -- "$S --fetch-usage" | grep -v "pgrep\|bash -c"); [[ -z "$left" ]] && break; sleep 1; done
chk "T7j no fetcher is left running" "" "$left"
fi

if [[ -z "${SCRIPTS_ONLY-}" ]]; then
  SJ=~/.claude/settings.json
  # T11 permissions (B) and attribution (D)
  chk "T11a permissions.defaultMode is bypassPermissions" "bypassPermissions" "$(jq -r '.permissions.defaultMode // empty' "$SJ" 2>/dev/null)"
  chk "T11b skipDangerousModePermissionPrompt is true" "true" "$(jq -r '.skipDangerousModePermissionPrompt // empty' "$SJ" 2>/dev/null)"
  chk "T11c attribution is off" '{"commit":"","pr":"","sessionUrl":false}' "$(jq -c '.attribution // empty' "$SJ" 2>/dev/null)"
  # T12 copy and paste (C)
  chk "T12a tui is fullscreen" "fullscreen" "$(jq -r '.tui // empty' "$SJ" 2>/dev/null)"
  CJ=~/.claude.json
  chk "T12b copyOnSelect is not turned off" "true" "$( [ -r "$CJ" ] && jq -r 'if has("copyOnSelect") then .copyOnSelect else true end' "$CJ" 2>/dev/null || echo true )"
  case "${XDG_SESSION_TYPE:-}" in
    x11)     chk "T12c X11 desktop has xclip (needed to paste images)" "yes" "$(command -v xclip >/dev/null && echo yes || echo no)" ;;
    wayland) chk "T12c Wayland desktop has wl-paste (needed to paste images)" "yes" "$(command -v wl-paste >/dev/null && echo yes || echo no)" ;;
    *)       echo "SKIP T12c (no desktop session: for the clipboard over ssh, give prompts/setup/workstation.md and this server's name to Claude Code on your own computer)" ;;
  esac
  # T13 Remote Control (E)
  chk "T13a remoteControlAtStartup is true" "true" "$(jq -r '.remoteControlAtStartup // empty' "$SJ" 2>/dev/null)"
  chk "T13b agentPushNotifEnabled is true" "true" "$(jq -r '.agentPushNotifEnabled // empty' "$SJ" 2>/dev/null)"
  # T14 auto-compact window of the 1M-context models (F)
  chk "T14a claude-opus-5-5 autoCompactWindow is 400000" "400000" "$(jq -r '.modelSettings["claude-opus-5-5"].autoCompactWindow // empty' "$SJ" 2>/dev/null)"
  chk "T14b claude-fable-5-1 autoCompactWindow is 400000" "400000" "$(jq -r '.modelSettings["claude-fable-5-1"].autoCompactWindow // empty' "$SJ" 2>/dev/null)"
fi

cd /; rm -rf "$T"
echo "== $pass PASS, $fail FAIL =="
(( fail == 0 ))
