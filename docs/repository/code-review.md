# Code review

**English** | [简体中文](code-review.zh-CN.md)

Someone other than the author reviews every change before it merges, whether a person or an agent wrote it. The standard follows Google's [code reviewer's guide](https://google.github.io/eng-practices/review/reviewer/).

For agents: [review-pr.md](../../prompts/repository/review-pr.md) has an agent review a pull request and write a report, without changing anything.

## Rules

- Approve once a pull request clearly makes the code better overall, even if it isn't perfect. Hold back anything that makes the code worse.
- Check in this order: correctness, design, the project's rules, readability, scope. Read every line.
- When an agent built the change from a plan, compare the two. Anything asked for but missing is a finding, and so is anything done that wasn't asked for.
- Mark optional comments `nit:`. Comment on the code, not the person, and say why.
- Answer within one working day.
- The author answers for every line an agent wrote, and reads and runs it before asking for review.
- An agent review, in a new session that didn't write the code, is a useful first pass. It replaces a person's review only for tasks the plan marks that way, as in [overnight review](../agents/overnight.md). Agents never approve or merge.

## Key commands

Keep one detached worktree for reviewing, next to your other worktrees. It takes no branch, so you can't commit to someone else's by accident.

```bash
git worktree add --detach ../review-pr origin/main          # once, from the main checkout

cd ../review-pr
git fetch origin pull/123/head && git switch --detach FETCH_HEAD
gh pr view 123 --comments
git diff origin/main...HEAD                                 # the change since the branch point
git fetch origin pull/123/head && git range-diff HEAD...FETCH_HEAD   # after a new push: what changed
gh pr review 123 --approve                                  # or --request-changes -b "..."
git switch --detach origin/main                             # park the worktree when done
```

In Claude Code, `/code-review` runs an agent review of the current branch.

## Sources

- [The standard of code review](https://google.github.io/eng-practices/review/reviewer/standard.html)
- [What to look for in a code review](https://google.github.io/eng-practices/review/reviewer/looking-for.html)
- [How to write code review comments](https://google.github.io/eng-practices/review/reviewer/comments.html)
- [Handling pushback in code reviews](https://google.github.io/eng-practices/review/reviewer/pushback.html)

Google's guides are licensed under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/).
