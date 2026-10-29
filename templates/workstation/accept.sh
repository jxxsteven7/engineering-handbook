#!/usr/bin/env bash
# Acceptance test for templates/workstation/: every check compares against an exact
# expected value. The last line is "== N PASS, M FAIL ==", and M must be 0.
#
#   bash accept.sh                  test the installed git prompt in your HOME
#   SCRIPTS_ONLY=1 bash accept.sh   test only bash_git_prompt.sh next to this file (CI does this)
#
# Expected results: 13 PASS; SCRIPTS_ONLY 12 PASS. The statusline and the Claude Code
# settings are tested by templates/claude-code/accept.sh.

HERE=$(cd "$(dirname "$0")" && pwd)
if [[ -n "${SCRIPTS_ONLY-}" ]]; then GP="$HERE/bash_git_prompt.sh"; else GP=~/.bash_git_prompt.sh; fi
T=$(mktemp -d); cd "$T" || exit 1
pass=0; fail=0
chk(){ if [[ "$2" == "$3" ]]; then echo "PASS $1"; ((pass++)); else echo "FAIL $1"; printf '  expected: %q\n  actual:   %q\n' "$2" "$3"; ((fail++)); fi; }

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

cd /; rm -rf "$T"
echo "== $pass PASS, $fail FAIL =="
(( fail == 0 ))
