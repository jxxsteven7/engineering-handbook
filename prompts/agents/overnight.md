# Set up parallel development and the overnight review

Follows: `docs/agents/overnight.md` in the Engineering Handbook (a trial).

You are setting up an overnight round for one repository: a development session per PR, and a watcher that reviews and fixes each PR once it is up, and leaves the merge to a person. The handbook is the repository that contains this file; its root is two directories above this file, and the files to copy are in `templates/overnight/` there. Read `watch.sh`, `run-review.sh`, `review-prompt.md` and `fix-prompt.md` there before you start.

The project uses the layout of `docs/rules/workspace.md`: the main clone at `~/code/<repo>/<repo>`, worktrees next to it, and `~/code/<repo>/plans/` outside git.

## Stop points

- **The plan is the user's.** Don't start any development session before the user has confirmed `00-plan.md` and every development prompt.
- **Each development session stops at its own plan gate.** It proposes an implementation plan and waits; the user confirms it in its tmux session. Tell the user this must happen before they leave.
- **Never merge, approve, force-push or change versions,** and never start a second watcher. Check `tmux has-session -t cc-watch` first.
- Before starting the watcher, show the user `overnight.conf` and `branches.txt` and wait for a yes.

## 1. Check the plan

`~/code/<repo>/plans/` must hold:

- `00-plan.md`, following `templates/overnight/plan-template.md`: the PR table with branch, scope, dependencies, when to start, and **who reviews** each PR (a person or an agent); the decisions with exact values; what the people have to do.
- One development prompt per PR, following `templates/overnight/dev-prompt-template.md`, with all its sections: task, scope, agreements with other PRs, out of scope, docs and tests, rules, pace.

If something is missing, help the user write it, one PR at a time, and ask about every value the agents would otherwise have to decide. Check that:

- PRs that change the same files are merged into one, or their prompts say which one rebases;
- every interface two PRs share is written identically in both prompts;
- every prompt tells the development session to keep its notes in `plans/notes/` and its decisions in the PR description, never in memory, and to stop after opening the PR;
- every prompt asks for an implementation plan before any code.

## 2. Install the watcher

```bash
mkdir -p ~/code/<repo>/plans/autoreview ~/code/<repo>/plans/notes
cp <handbook>/templates/overnight/{watch.sh,run-review.sh,review-prompt.md,fix-prompt.md} ~/code/<repo>/plans/autoreview/
cp <handbook>/templates/overnight/overnight.conf.example ~/code/<repo>/plans/autoreview/overnight.conf
chmod +x ~/code/<repo>/plans/autoreview/*.sh
```

Fill in `overnight.conf`:

- `REPO_DIR`: the main clone. `GH_REPO`: leave empty unless `gh repo view` in the main clone gives the wrong repository. `PLANS_DIR`: `~/code/<repo>/plans`, as an absolute path or with `$HOME`.
- `REVIEW_MODEL`, `FIX_MODEL`, `FIX_EFFORT`: ask the user; by default `opus`, `fable` and `xhigh`.
- `CHECKS`: the checks the repository requires before a push, from `AGENTS.md` or `CONTRIBUTING.md`, as one command line.
- `LANGUAGE`: the language the user wants the reports in.

Write `branches.txt` with one line per PR: the branch, the review effort (`xhigh` for logic and data, `high` for interface and wording, unless the user says otherwise), and the development prompt's file name.

If the repository's review rules or hard constraints live somewhere other than `AGENTS.md` and `CONTRIBUTING.md`, add the path to step 1 of `review-prompt.md`. Change nothing else in the prompts unless the user asks.

## 3. Check before anything runs

- `bash -n` on both scripts.
- `gh auth status` and `claude --version` work.
- The memory directory of the repository holds no notes about these PRs: `~/.claude/projects/<main clone dir>/memory/`. If it does, show them to the user and propose moving them to `plans/notes/`; a review session that reads them is no longer independent.
- The usage left this week, if the statusline shows it. Several high-effort sessions use a lot; tell the user if it looks tight.

## 4. Start the development sessions

Only after the user confirmed the plan. For each PR that can start now (its dependencies are merged), follow `prompts/workspace/start-task.md` to create the worktree and install the dependencies, then:

```bash
tmux new -d -s cc-<worktree> -c ~/code/<repo>/<worktree>
tmux send-keys -t cc-<worktree> 'claude -n <worktree> "$(cat ~/code/<repo>/plans/<NN>-<topic>.md)"' Enter
```

Leave PRs that wait for another PR out of `branches.txt` for now and list them for the user; add each one when it starts.

Tell the user to attach to each session (`tmux attach -t cc-<worktree>`, detach with Ctrl-b d) and confirm or correct its plan. Development continues only after that.

## 5. Start the watcher

After the user said yes to the configuration:

```bash
tmux new -d -s cc-watch ~/code/<repo>/plans/autoreview/watch.sh
sleep 5 && tail -5 ~/code/<repo>/plans/autoreview/watch.log
```

The log must start with `watching <n> branches of <owner>/<repo>`, then one line per branch, such as `no open PR yet`.

## 6. Hand over

Tell the user:

- what is running: each development session and the watcher, with their tmux names;
- what they still have to do tonight: confirm every development session's plan;
- what to read in the morning: `watch.log`, and for each PR `pr<N>-summary.md`, whose last line is the VERDICT, and `pr<N>-review.md`;
- how to merge: in dependency order; PRs marked for a person need their own review first; after each merge, rebase the PRs that conflict; then clean up with `prompts/workspace/finish-task.md`;
- how to stop the watcher (`tmux kill-session -t cc-watch`), re-review a branch (delete `state/<branch with / as ->.started`), and clear a stuck review (`tmux kill-session -t review-pr<N>` and delete `state/busy`).
