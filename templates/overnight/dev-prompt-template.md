# Task: <topic> (one PR)

Branch `<type>/<topic>`, in the worktree `../<type>-<topic>`. <One sentence: what this PR achieves.> Before you start, read <the files and docs that matter>.

## Scope

<Each item with the values settled in the plan: defaults, limits, wording. Put rules in a table.>

## Agreements with other PRs

- <Shared interfaces, written exactly as in the other PR's prompt, and who writes and who reads them.>
- <Files the other PR also changes, and which PR rebases.>

## Out of scope

- <What this PR doesn't do, and which PR does it instead.>

## Docs and tests

- <Which docs to update.>
- <Which cases the tests must cover.>

## Rules

- <The repository rules that are easiest to forget: language, required checks, and so on.>
- Commits and the PR carry no AI or agent attribution. Subjects read `<type>: <summary>`, without a version.
- Run before pushing: <the project's checks>.
- Notes about this PR go to `../plans/notes/<topic>.md`, and decisions you settle with me go into the PR description, never into memory: memory is shared by every session in this repository, including the one that will review this PR.
- Review your own work, push the branch, open a PR with the template filled in, then stop. Don't merge.

## Pace

First give me an implementation plan: the files you will change and how. Write code only after I confirm it. You may make several commits, but open only one PR.
