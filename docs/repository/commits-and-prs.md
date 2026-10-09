# Commits and pull requests

**English** | [简体中文](commits-and-prs.zh-CN.md)

Small, single-purpose pull requests with clear titles are easy to review and easy to revert. The same rules apply to people and agents. They follow Google's [CL author's guide](https://google.github.io/eng-practices/review/developer/); Google calls a pull request a CL (changelist).

For agents: [open-pr.md](../../prompts/repository/open-pr.md) covers every rule below in detail, from the first commit to opening the pull request.

## Rules

- One branch per change, named `<type>/<short-description>`, for example `feat/room-settings` or `fix/reconnect-after-lock`.
- One pull request does one self-contained thing, with its tests. Keep refactoring and behavior changes apart. About 100 changed lines is comfortable; 1000 is usually too many.
- Commit subjects and PR titles read `<type>: <summary>`: one imperative sentence that makes sense on its own, in lowercase, without a period. The types are `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`, `perf` and `revert`.
- The PR description says what changed, why, how it was tested, and which parts an agent wrote.
- Read your whole diff before asking for review. Code an agent wrote counts as your code.
- No agent attribution in commits or pull requests.

A commit message looks like this:

```text
fix: return players to their team after reconnecting

The reconnect handler looked players up by socket ID, which changes on
every reconnect. Look them up by their player token instead.
```

## During review

- Push new commits instead of amending, so the reviewer can see what changed. The squash merge cleans up the history anyway.
- Answer every comment: make the change, or explain why not. If the reviewer didn't understand some code, make the code clearer rather than only replying.

## Key commands

Catch up with `main` on your own branch:

```bash
git fetch origin
git rebase origin/main
git push --force-with-lease
```

On a branch that others also push to, use `git merge origin/main` instead.

## Stacked pull requests

When a change is too big for one pull request, split it into a chain of branches, each built on the one below, with one pull request per branch. The bottom one targets `main`; each of the others targets the branch below it. Merge from the bottom up.

```bash
git switch -c feat/lobby-api                                       # the next layer starts where this one ends
git rebase --update-refs feat/lobby-model                          # from the top, after changing a lower layer
git rebase --update-refs --onto origin/main feat/lobby-model       # from the top, after the bottom was squash-merged
```

Don't stack parts that don't depend on each other; open separate pull requests against `main` instead.

## Sources

- [Small CLs](https://google.github.io/eng-practices/review/developer/small-cls.html)
- [Writing good CL descriptions](https://google.github.io/eng-practices/review/developer/cl-descriptions.html)
- [How to handle reviewer comments](https://google.github.io/eng-practices/review/developer/handling-comments.html)

Google's guides are licensed under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/).
