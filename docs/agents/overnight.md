# Parallel development and overnight review

**English** | [简体中文](overnight.zh-CN.md)

> [!NOTE]
> A trial: it has run one round on a real project, where four PRs were reviewed and fixed in one night.

Several PRs are developed at once, each in its own worktree with its own development session. A shell script watches GitHub. As soon as a PR is up, it starts a new session to review it, has a stronger model fix what the review found, waits for CI, and writes down whether the PR is ready to merge. People do two things: confirm the plans before bed, and merge in the morning.

For agents: [overnight.md](../../prompts/agents/overnight.md) sets up `plans/` and the watcher, and starts it. The files to copy are in [templates/overnight/](../../templates/overnight/).

## When to use it

- The requirements are settled and split into PRs that don't get in each other's way.
- The repository has clear rules (`AGENTS.md`) and automated tests.
- For some PRs you are willing to let the agent's review stand in for your line-by-line reading, and merge on its verdict. The plan says so for each PR; any PR it doesn't mark is reviewed by a person as usual.

It doesn't suit work whose requirements are still being explored as you go.

## How it runs

```text
plan (you + one session)  ->  one development prompt per PR
  -> per PR: worktree + tmux + dev session -> plan -> [you confirm] -> code -> open PR -> stop
  -> watcher: PR settled -> fresh session reviews -> stronger model fixes -> push, wait for CI -> verdict
  -> [you] in the morning: read the verdicts, merge in dependency order -> clean up
```

- There are only two human gates: confirming plans and merging. Confirm every development session's plan before bed, or there will be no PRs in the morning.
- A shell script watches GitHub, not an agent session that stays open: waiting costs no tokens, and a script doesn't forget.
- One review runs at a time and the others queue, because end-to-end tests use a lot of memory. Each branch is reviewed automatically once.
- The review runs in a new session, never the one that wrote the code. The fix resumes that same session on a stronger model. Both run as `claude -p` and exit when done; the session is kept, so in the morning you can continue it with `claude --resume <ID>`.

## Planning

- Open a session in the main clone and go through the requirements until every point is decided, down to the values: defaults, limits, wording. Whatever you leave open, the agent decides.
- Splitting into PRs: changes to the same files go in one PR; dependent PRs go in order; unrelated ones run in parallel; an interface two PRs share is written as an agreement, word for word the same in both prompts.
- The plan lives in `plans/`, outside the repository and out of git: `00-plan.md` is a table of the PRs, plus one development prompt per PR. The table says whether a person or an agent reviews each PR.
- Development sessions write their notes to `plans/notes/` and the decisions settled with you into the PR description, never into memory. Memory is shared by every session in the repository, and a review session that reads it is no longer independent. The first round ran into exactly this.

## Key commands

```bash
# one development session per PR, from the main clone
git worktree add ../feat-xxx -b feat/xxx origin/main
tmux new -s cc-feat-xxx -c ~/code/<repo>/feat-xxx
claude -n feat-xxx "$(cat ~/code/<repo>/plans/01-xxx.md)"

# the watcher, in its own tmux session
tmux new -d -s cc-watch ~/code/<repo>/plans/autoreview/watch.sh

# in the morning
cat ~/code/<repo>/plans/autoreview/watch.log
cat ~/code/<repo>/plans/autoreview/pr<N>-summary.md      # the last line is the VERDICT
tmux attach -t review-pr<N>                              # what the review session printed

# when needed
rm ~/code/<repo>/plans/autoreview/state/feat-xxx.started           # review that branch again
tmux kill-session -t review-pr<N> && rm -f ~/code/<repo>/plans/autoreview/state/busy   # a stuck review
```

## Merging in the morning

- Merge in dependency order. After each merge, rebase the remaining PRs that conflict.
- PRs the plan marks for a person: the VERDICT is only a hint. Read the diff, look at the screenshots, run it yourself, then approve.
- PRs the plan marks for an agent: read the summary and CI, and merge if they're fine. A person always clicks merge.
- After merging, clean up as in [Repositories and worktrees](../workspace/repos-and-worktrees.md). The PR's files in `plans/` can stay as a record.

## Risks

| Risk | What to do |
|---|---|
| Usage: a few high-effort development sessions, plus reviews and fixes, use up a week's limit fast | Check the weekly figure in the statusline before you start; lower the effort or run fewer sessions when it's high |
| Full permissions: unattended runs need `--dangerously-skip-permissions` | Run only in the PR's own worktree, with the red lines fixed in the prompts: no merging, no force-pushing, no version changes, nothing outside the PR's scope |
| Memory: several end-to-end test runs at once bring the machine down | Reviews run one at a time; limit the memory of heavy jobs when needed |
| A development session gets stuck, or stops when the usage limit runs out | Check `watch.log` and tmux. For now, a person has to notice |
| The fix session judges its own work | Merge on the verdict alone only for PRs the plan marks for an agent; a person reviews the rest |
| PRs conflict with each other | Name the files that will conflict in the prompts when planning; a person sets the merge order, and the later PR rebases |

## Not done yet

- When an upstream PR merges, start the worktree and development session of the next PR automatically and stop at its plan gate, so that an agent gives the next instruction.
- Notice a stuck development session: no commits for a few hours.
- After the fix, have a new session check it again, so the fixer doesn't judge its own work.
- After a merge, rebase the other PRs and run their checks again automatically.
- Send a notification to the phone when a round is done.
