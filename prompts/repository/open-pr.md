# Commit your work and open a pull request

Follows: `docs/repository/commits-and-prs.md` in the Agentic Engineering Handbook.

Use this while you make a change in a repository whose `main` is protected: one branch per change, commit subjects and PR titles `<type>: <summary>`, squash merge, versions added by CI. Where the repository's own `AGENTS.md` or `CONTRIBUTING.md` says something more specific, follow the repository.

## Stop points

- Never commit to `main`, push to `main`, merge a pull request, approve one, or push to a branch that isn't yours.
- If the change turns out to need more than one purpose, or grows past about 400 changed lines, stop and propose how to split it before you go on.
- After opening the pull request and waiting for its checks, stop and report. A person reviews and merges.

## 1. Branch

- Check where you are: `git branch --show-current` must not print `main`.
- If you are on `main` with changes, move them:

  ```bash
  git stash
  git fetch origin
  git worktree add ../feat-xxx -b feat/xxx origin/main
  cd ../feat-xxx && git stash pop
  ```

- Name the branch `<type>/<short-description>`: lowercase English, words joined by `-`, with the same type the PR title will have. The worktree directory has the branch name with `/` replaced by `-`.
- Start from the latest `origin/main`, never from whatever happens to be checked out.

## 2. Commits

Commit in small steps. Every message follows these rules, which the `commit-msg` hook checks:

- The subject is `<type>: <summary>`. Allowed types are in `TYPES` at the top of `scripts/check-commits.mjs`; the usual set is `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`, `perf`, `revert`.
- The summary is one imperative sentence that makes sense without the diff: `fix: return players to their team after reconnecting`, not `fix: bug`, `update code` or `changes`.
- It starts with a lowercase letter or a digit and has no period at the end.
- The subject is printable ASCII, at most 72 characters.
- No version in branch commits. CI adds the version to the PR title.
- A blank line separates the subject from the body. The body, in English, says what changed, why, and any known shortcomings. Wrap it at about 72 characters.
- A revert is titled `revert: <summary>` and keeps the `This reverts commit <sha>.` line that `git revert` writes.
- No attribution in any form: no `Co-Authored-By` or `Signed-off-by` trailer naming an AI tool, no "Generated with" line, no link to an agent session, no agent as author or committer. Commit as the user who asked you for the work.
- `fixup!` commits are fine on the branch; the squash merge folds them in.
- If the hook rejects a message, fix the message. Never use `--no-verify`.

## 3. Before opening the pull request

1. Catch up with `main` and resolve any conflicts:

   ```bash
   git fetch origin
   git rebase origin/main
   ```

   Only rebase your own branch. On a branch that others push to, use `git merge origin/main`.
2. Run every check that `AGENTS.md` or `CONTRIBUTING.md` lists, and make them pass. If one fails and you can't fix it within the scope of this change, stop and report it.
3. Read the whole change as a reviewer would: `git diff origin/main...HEAD`. Look for:
   - changes unrelated to the task, which go in another pull request;
   - leftover debug output, commented-out code, temporary files;
   - secrets, tokens, personal paths;
   - behavior changes without tests;
   - docs that the change made wrong;
   - `TODO`s without an issue to point to.
4. Check the size: `git diff --stat origin/main...HEAD`. Apply the stop point above if needed.

## 4. Open the pull request

1. Push: `git push -u origin <branch>`. After a rebase of a branch you pushed before, use `git push --force-with-lease`, never `--force`.
2. Title: `<type>: <summary>` under the same rules as a commit subject, without a version, at most about 64 characters so that the version CI adds still fits in 72.
3. Description: fill in `.github/pull_request_template.md` if it exists. Otherwise use these sections:
   - **What**: one or two sentences.
   - **Why**: the problem, with `Closes #N` for the issue.
   - **How tested**: the commands you ran and what you checked by hand; screenshots for UI changes.
   - **AI assistance**: which parts an AI agent wrote. Leave any box that says the person has read and checked the code unticked; that is for the person to tick.
4. Create it, as a draft if the work isn't finished:

   ```bash
   gh pr create --base main --title "<type>: <summary>" --body-file <file>
   gh pr checks --watch
   ```

5. Report the link and the check results, then stop.

## 5. During review

- Address each comment with a new commit. Don't amend or force-push while a review is in progress, so the reviewer sees what changed.
- If a rebase is unavoidable, push it on its own, then push the fixes, and say so in the pull request.
- Reply to every comment: what you changed, or why you didn't. Make unclear code clearer instead of only explaining it in a reply.
- If the scope changed, update the title and description so they match the final change.

## 6. Stacked pull requests

Use a stack only when the parts depend on each other. Keep all its branches in one worktree.

```bash
git switch -c feat/lobby-api                               # the next layer starts at the top of the current one
gh pr create --base feat/lobby-model --title "feat: ..."    # each layer targets the branch below it
```

- Start each description with `Stack <k>/<n>, depends on #<below>, next #<above>`.
- Always rebase from the top branch, with `--update-refs` (git 2.38 or later), so the branches in between move too:
  - after changing a lower layer: `git rebase --update-refs <changed branch>`;
  - when `main` moves: `git fetch origin && git rebase --update-refs origin/main`;
  - after the bottom layer was squash-merged: `git fetch origin && git rebase --update-refs --onto origin/main <merged branch>`.
- Then push every branch that moved: `git push --force-with-lease origin <branch> <branch> ...`.
- If GitHub didn't retarget the next pull request after the bottom merged, run `gh pr edit <N> --base main`.
- Layers merge from the bottom up, one at a time.
