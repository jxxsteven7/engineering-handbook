# ~/.bash_git_prompt.sh, from the Agentic Engineering Handbook (docs/setup/workstation.md).
# templates/workstation/install.sh installs it and hooks it into ~/.bashrc.
#
# Adds two fields to the bash prompt when the current directory is inside a git
# repository:
#
#   (branch)      yellow   — current branch, or a short SHA when HEAD is detached
#   [worktree]    pink     — name of the worktree you are standing in
#
# Sourced from ~/.bashrc, after the distribution's own PS1 setup. Nothing else in
# the prompt is touched: the green user@host and blue path stay as Ubuntu ships them.
#
# Escape handling: this text is produced by command substitution inside PS1, so
# the usual \[ \] markers are NOT available (bash decodes those before the
# substitution runs). Raw \001 / \002 are emitted instead — they are precisely
# what \[ \] compile to, and readline honours them in the final prompt string.
# Without this, long branch names corrupt line wrapping and Ctrl+R redraws.

# --- colours -----------------------------------------------------------------
# 256-colour when the terminal advertises it, otherwise the closest 8-colour
# match, so this stays safe over ssh or on a plain tty.
if [ "$(tput colors 2>/dev/null || echo 0)" -ge 256 ]; then
    __gp_branch_color=$'\001\033[38;5;220m\002'   # yellow
    __gp_wt_color=$'\001\033[38;5;213m\002'       # pink
else
    __gp_branch_color=$'\001\033[01;33m\002'      # bold yellow
    __gp_wt_color=$'\001\033[01;35m\002'          # bold magenta
fi
__gp_reset=$'\001\033[00m\002'

__git_prompt_info() {
    # One rev-parse for the three paths. --path-format=absolute (git 2.31+)
    # makes --git-common-dir absolute too, which is what the linked-worktree
    # comparison below needs.
    local out gitdir commondir toplevel branch wt
    out=$(git rev-parse --path-format=absolute \
                        --git-dir --git-common-dir --show-toplevel 2>/dev/null) || return 0
    [ -n "$out" ] || return 0

    { read -r gitdir; read -r commondir; read -r toplevel; } <<< "$out"

    # Inside .git/ itself, or a bare repo: no worktree to name.
    [ -n "$toplevel" ] || return 0

    # Branch. --show-current is empty on a detached HEAD and, unlike
    # `rev-parse --abbrev-ref HEAD`, does not error out in a fresh repo that has
    # no commits yet.
    branch=$(git branch --show-current 2>/dev/null)
    if [ -z "$branch" ]; then
        branch=$(git rev-parse --short HEAD 2>/dev/null)
        if [ -n "$branch" ]; then
            branch="detached:$branch"
        else
            branch="no-commits"   # freshly initialised repo
        fi
    fi

    # Worktree name = the directory the worktree root lives in. A linked
    # worktree (git worktree add) keeps its own git dir under the main repo's
    # .git/worktrees/, so its --git-dir differs from --git-common-dir; that is
    # the reliable test. Linked worktrees get a '+' prefix.
    wt="${toplevel##*/}"
    [ "$gitdir" != "$commondir" ] && wt="+$wt"

    printf ' %s(%s)%s %s[%s]%s' \
        "$__gp_branch_color" "$branch"  "$__gp_reset" \
        "$__gp_wt_color"     "$wt"      "$__gp_reset"
}

# Append to whatever PS1 already is, just before its trailing '$ '.
# Non-interactive shells have no PS1; the function above is still defined so the
# file can be sourced and tested from a script.
[ -n "${PS1-}" ] || return 0

case "$PS1" in
    *__git_prompt_info*) : ;;                       # already installed
    *'\$ ')  PS1="${PS1%'\$ '}"'$(__git_prompt_info)\$ ' ;;
    *)       PS1="$PS1"'$(__git_prompt_info)' ;;
esac
