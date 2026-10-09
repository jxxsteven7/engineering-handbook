#!/usr/bin/env bash
# Acceptance test for templates/workstation/: every check compares against an exact
# expected value. The last line is "== N PASS, M FAIL ==", and M must be 0.
#
#   bash accept.sh                  test the installed files and settings in your HOME
#   SCRIPTS_ONLY=1 bash accept.sh   test only the two scripts next to this file (CI does this)
#
# Expected results: a Linux desktop 41 PASS; a server reached over ssh 40 PASS and SKIP T12c;
# SCRIPTS_ONLY 34 PASS.

HERE=$(cd "$(dirname "$0")" && pwd)
if [[ -n "${SCRIPTS_ONLY-}" ]]; then
  S="$HERE/statusline.sh"; GP="$HERE/bash_git_prompt.sh"
else
  S=~/.claude/statusline.sh; GP=~/.bash_git_prompt.sh
fi
T=$(mktemp -d); cd "$T" || exit 1
export COLORTERM=truecolor                     # use the truecolor branch so the expected values are fixed
O=$'\033[38;2;217;119;87m'; G=$'\033[38;2;126;231;135m'; Y=$'\033[38;2;103;216;232m'; R=$'\033[0m'
pass=0; fail=0
chk(){ if [[ "$2" == "$3" ]]; then echo "PASS $1"; ((pass++)); else echo "FAIL $1"; printf '  expected: %q\n  actual:   %q\n' "$2" "$3"; ((fail++)); fi; }
mk(){ printf '{"model":{"id":"%s","display_name":"%s"},"effort":{"level":"xhigh"},"transcript_path":"%s","cwd":"%s","context_window":{"used_percentage":12.4},"rate_limits":{"seven_day":{"used_percentage":3}}}' "$1" "$2" "$3" "$4"; }
U='{"type":"user","message":{"role":"user","content":"<local-command-stdout>'
SL(){ bash "$S"; }

if [[ ! -r "$S" ]]; then
  echo "FAIL T1-T6 no $S"; ((fail++))
else
# T1 basic rendering: outside a repository, one line
chk "T1a basic line" "${O}Opus 5 | effort: xhigh | context: 12% | weekly: 3%${R}" "$(mk claude-opus-5 "Opus 5" "" /tmp | SL)"
chk "T1b 256 colours without truecolor" $'\033[38;5;173m'"Opus 5 | effort: xhigh | context: 12% | weekly: 3%${R}" "$(mk claude-opus-5 "Opus 5" "" /tmp | COLORTERM= SL)"

# T2 a real 0% is shown
chk "T2 0% is kept" "${O}Opus 5 | context: 0% | weekly: 0%${R}" \
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
L1="${O}Opus 5 | effort: %s | context: 12%% | weekly: 3%%${R}"
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
chk "T6b plain repository read from .git" "${O}Opus 5 | effort: xhigh | context: 12% | weekly: 3%${R}"$'\n'"${Y}branch: main${R} | ${G}worktree: repo${R}" "$(mk claude-opus-5 "Opus 5" "" "$T/repo" | SL)"
mkdir -p repo/sub/dir
chk "T6c found from a subdirectory" "${Y}branch: main${R} | ${G}worktree: repo${R}" "$(mk claude-opus-5 "Opus 5" "" "$T/repo/sub/dir" | SL | sed -n 2p)"
mkdir -p wt && printf 'gitdir: %s/repo/.git\n' "$T" > wt/.git
chk "T6d linked worktree (.git is a file)" "${Y}branch: main${R} | ${G}worktree: wt${R}" "$(mk claude-opus-5 "Opus 5" "" "$T/wt" | SL | sed -n 2p)"
echo 0123456789abcdef > repo/.git/HEAD
chk "T6e detached HEAD shows 7 characters" "${Y}branch: 0123456${R} | ${G}worktree: repo${R}" "$(mk claude-opus-5 "Opus 5" "" "$T/repo" | SL | sed -n 2p)"
chk "T6f branch only: no separator" "${Y}branch: solo${R}" "$(printf '{"model":{"display_name":"Opus 5"},"worktree":{"branch":"solo"},"cwd":"/tmp"}' | SL | sed -n 2p)"
chk "T6g outside a repository: no line 2" "1" "$(mk claude-opus-5 "Opus 5" "" /tmp | SL | wc -l | tr -d ' ')"
fi

# T10 git prompt (bash_git_prompt.sh). Needs git 2.31 or later.
if ! command -v git >/dev/null; then
  echo "FAIL T10 git is not installed"; ((fail++))
elif [[ ! -r "$GP" ]]; then
  echo "FAIL T10 no $GP"; ((fail++))
else
  BY=$'\001\033[38;5;220m\002'; BP=$'\001\033[38;5;213m\002'; BR=$'\001\033[00m\002'
  gp(){ ( cd "$2" && TERM=$1 bash -c '. "$0"; __git_prompt_info' "$GP" ) 2>/dev/null; }
  gpps1(){ bash -c 'PS1=$1; . "$0"; [[ -n $2 ]] && . "$0"; printf %s "$PS1"' "$GP" "$1" "${2-}"; }
  GIT=(git -c user.name=t -c user.email=t@t -c init.defaultBranch=main -c commit.gpgsign=false -c core.hooksPath=/dev/null)
  mkdir -p "$T/gp/plain"; "${GIT[@]}" init -q "$T/gp/g"; "${GIT[@]}" -C "$T/gp/g" commit -q --allow-empty -m init
  mkdir -p "$T/gp/g/sub/dir"; "${GIT[@]}" -C "$T/gp/g" worktree add -q "$T/gp/g-feat" -b feat 2>/dev/null
  "${GIT[@]}" init -q "$T/gp/fresh"
  chk "T10a outside a repository: nothing added" "" "$(gp xterm-256color "$T/gp/plain")"
  chk "T10b main checkout: (branch) yellow [worktree] pink" " ${BY}(main)${BR} ${BP}[g]${BR}" "$(gp xterm-256color "$T/gp/g")"
  chk "T10c the same in a subdirectory" " ${BY}(main)${BR} ${BP}[g]${BR}" "$(gp xterm-256color "$T/gp/g/sub/dir")"
  chk "T10d linked worktree gets a +" " ${BY}(feat)${BR} ${BP}[+g-feat]${BR}" "$(gp xterm-256color "$T/gp/g-feat")"
  sha=$("${GIT[@]}" -C "$T/gp/g" rev-parse --short HEAD); "${GIT[@]}" -C "$T/gp/g" checkout -q --detach
  chk "T10e detached HEAD: detached:<sha>" " ${BY}(detached:${sha})${BR} ${BP}[g]${BR}" "$(gp xterm-256color "$T/gp/g")"
  chk "T10f new repository without commits: the unborn branch" " ${BY}(main)${BR} ${BP}[fresh]${BR}" "$(gp xterm-256color "$T/gp/fresh")"
  chk "T10g inside .git: nothing" "" "$(gp xterm-256color "$T/gp/g/.git")"
  chk "T10h fewer than 256 colours: bold yellow and magenta" " "$'\001\033[01;33m\002'"(detached:${sha})${BR} "$'\001\033[01;35m\002'"[g]${BR}" "$(gp xterm "$T/gp/g")"
  chk "T10i inserted before a trailing \\\$" '\u@\h:\w$(__git_prompt_info)\$ ' "$(gpps1 '\u@\h:\w\$ ')"
  chk "T10j sourcing twice adds it once" '\u@\h:\w$(__git_prompt_info)\$ ' "$(gpps1 '\u@\h:\w\$ ' twice)"
  chk "T10k PS1 without a trailing \\\$: appended" '> $(__git_prompt_info)' "$(gpps1 '> ')"
  chk "T10l non-interactive shell: no error, no PS1, function defined" "rc=0 ps1=unset fn=function" \
    "$(env -u PS1 bash -c '. "$0"; echo "rc=$? ps1=${PS1-unset} fn=$(type -t __git_prompt_info)"' "$GP")"
  if [[ -z "${SCRIPTS_ONLY-}" ]]; then
    chk "T10m ~/.bashrc sources it (PS1 of an interactive bash)" "yes" \
      "$(cd "$T/gp/plain" && bash -ic 'case $PS1 in *__git_prompt_info*) echo yes;; *) echo no;; esac' 2>/dev/null </dev/null | tail -1)"
  fi
fi

if [[ -z "${SCRIPTS_ONLY-}" ]]; then
  SJ=~/.claude/settings.json
  # T11 permissions and attribution
  chk "T11a permissions.defaultMode is bypassPermissions" "bypassPermissions" "$(jq -r '.permissions.defaultMode // empty' "$SJ" 2>/dev/null)"
  chk "T11b skipDangerousModePermissionPrompt is true" "true" "$(jq -r '.skipDangerousModePermissionPrompt // empty' "$SJ" 2>/dev/null)"
  chk "T11c attribution is off" '{"commit":"","pr":"","sessionUrl":false}' "$(jq -c '.attribution // empty' "$SJ" 2>/dev/null)"
  # T12 copy and paste
  chk "T12a tui is fullscreen" "fullscreen" "$(jq -r '.tui // empty' "$SJ" 2>/dev/null)"
  CJ=~/.claude.json
  chk "T12b copyOnSelect is not turned off" "true" "$( [ -r "$CJ" ] && jq -r 'if has("copyOnSelect") then .copyOnSelect else true end' "$CJ" 2>/dev/null || echo true )"
  case "${XDG_SESSION_TYPE:-}" in
    x11)     chk "T12c X11 desktop has xclip (needed to paste images)" "yes" "$(command -v xclip >/dev/null && echo yes || echo no)" ;;
    wayland) chk "T12c Wayland desktop has wl-paste (needed to paste images)" "yes" "$(command -v wl-paste >/dev/null && echo yes || echo no)" ;;
    *)       echo "SKIP T12c (no desktop session: Ctrl+V reads the remote clipboard; copy images over with scp and give the path)" ;;
  esac
fi

cd /; rm -rf "$T"
echo "== $pass PASS, $fail FAIL =="
(( fail == 0 ))
