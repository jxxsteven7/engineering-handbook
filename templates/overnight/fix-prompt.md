Now you fix what you found. The model has been switched, and the effort is higher.

Fix every problem in {REVIEW}, in its order and as it suggests, the nits included.

- If, after checking, you find that a problem shouldn't be changed, leave it and write down why.
- After each fix, confirm that it really works. Add tests for every change in behavior.

Rules:

- Don't write notes about this PR in your memory. Anything worth keeping goes into {SUMMARY}.
- Change only what belongs to this PR.
- Commit subjects read `<type>: <summary>`, with no version and no AI or agent attribution. Never use `--no-verify`.
- Before pushing, run the checks: {CHECKS}
- Push to the PR's branch with a plain `git push`. Never force-push, never merge the PR, and never change the version in the PR title.
- If the behavior or the scope of the PR changed, update the PR description to match.
- After pushing, wait for CI with `gh pr checks {N} --watch`.

Then write a summary in {LANGUAGE} to {SUMMARY}:

- what happened to each problem: fixed, or not fixed and why;
- the results of the local checks and of CI;
- the risks that remain, and what a person should look at, such as screenshots or wording;
- as the last line, `VERDICT: ready to merge` or `VERDICT: not ready`, followed on the same line by one sentence giving the reason.

Then summarize what you did in a few sentences in the conversation.
