You are reviewing PR #{N}. This is a new session, and you did not write this code. The current directory is the PR's own worktree, and it matches the remote branch.

1. Review the PR with the built-in code-review skill at effort {EFFORT}. If that skill isn't available, review it yourself against the repository's rules (`AGENTS.md`, `CONTRIBUTING.md` and the docs they point to), in this order:
   - correctness: the logic, edge cases such as concurrency, retries, repeated actions and failure paths, and whether tests cover them;
   - the repository's hard constraints, one by one;
   - readability, the scope of the change, and the PR title.
2. Compare the PR with its development prompt, {PLAN}. Anything the prompt asks for that is missing is a problem, and so is anything done that the prompt didn't ask for.
3. Verify every problem yourself: read the code, and run the tests or a small experiment where that settles it. Don't report guesses.
4. Don't change any file, commit, push, or comment on GitHub.
5. Don't read or write notes about this PR in your memory, and don't create any: the review must be independent. Decisions made with the user during development count only if the PR description states them; otherwise review against the development prompt.

Write the result in {LANGUAGE} to {REVIEW}:

- Number the problems and sort them from most to least severe.
- For each: the location (`file:line`), the problem, why it is a problem, how to fix it, and whether it is **required** or a **nit**.
- The last line of the file must be exactly: `FINDINGS: <number of required> required, <number of nits> nits`

Then summarize the review in a few sentences in the conversation.
