# Review a pull request

Follows: `docs/rules/code-review.md` in the Engineering Handbook.

Fill in before use: the pull request number `<N>`, and optionally the plan or prompt the pull request was built from and the file to write the report to. Without a report file, write `review-pr<N>.md` in the parent directory of the repository, so the report stays out of the repository.

You are reviewing pull request #<N>. You are a new session and you did not write this code.

## Stop points

- Don't change any file in the repository, commit, push, or comment on GitHub.
- Don't read or write memory notes about this pull request. The review must be independent. Decisions made during development count only if the pull request description states them; otherwise review against the plan.
- When the report is written, stop. Fixing is a separate step.

## 1. Get the change

If you were opened in the pull request's own worktree, review it there and don't switch. That is the case when all three hold:

- `git branch --show-current` prints the same name as `gh pr view <N> --json headRefName -q .headRefName`;
- `git status --short` prints nothing;
- `git rev-parse HEAD` prints the same sha as `gh pr view <N> --json headRefOid -q .headRefOid`.

If the branch matches but the tree isn't clean or HEAD differs, stop and ask: the author may not have pushed yet. Otherwise use a detached checkout, so that no branch is taken: the project's review worktree if it has one (often `../review-pr`), otherwise the current directory if `git status --short` is empty. If neither is possible, stop and ask.

```bash
git fetch origin pull/<N>/head
git switch --detach FETCH_HEAD                  # not in the pull request's own worktree
gh pr view <N> --comments
gh pr checks <N>
git log --oneline origin/main..HEAD
git diff --stat origin/main...HEAD
git diff origin/main...HEAD
```

If the pull request is part of a stack (its base isn't `main`), compare with its base branch instead of `origin/main`.

## 2. Read the rules

Read `AGENTS.md`, `CONTRIBUTING.md` and the docs they point to. Note the project's hard constraints and the checks it requires.

## 3. Review

Go in this order, and read every changed line:

1. **Correctness.** Is the logic right? Look at edge cases: empty and very large input, errors and failure paths, concurrency, retries, repeated actions, time zones and encodings where relevant. Are they covered by tests? Run the tests, and the program if that settles a question.
2. **Design.** Does the change belong where it is? Does it fit the rest of the system? Is any part more complex or more general than the task needs?
3. **The project's rules.** Go through its hard constraints one by one.
4. **Readability.** Clear names; comments that explain why, not what; code consistent with its surroundings.
5. **Scope.** The pull request does what its description says and nothing unrelated.
6. **Docs and title.** Docs match the new behavior. The title is `<type>: <summary>` and nothing carries agent attribution.

## 4. Compare with the plan

If you were given a plan or prompt, check it item by item. Anything asked for but missing is a finding, and so is anything done that wasn't asked for.

## 5. Verify every finding

Read the code around it, and run a test or a small experiment where that settles it. Report only what you have confirmed. If you suspect something but couldn't confirm it, list it separately as a question.

## 6. Write the report

Write it to the report file, in the user's language:

- Findings numbered and sorted from most to least severe.
- For each: location (`file:line`), the problem, why it is a problem, a suggested fix, and whether it is **required** or a **nit**.
- Required means a bug, a broken rule, a missing part of the plan, or anything that makes the code worse. Everything else is a nit.
- Then the questions you couldn't settle, if any, and anything done well that is worth keeping.
- The last line exactly: `FINDINGS: <required count> required, <nit count> nits`

Then summarize the review in a few sentences in the conversation.
