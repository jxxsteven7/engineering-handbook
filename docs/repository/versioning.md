# Versioning and releases

**English** | [简体中文](versioning.zh-CN.md)

Every pull request is squash-merged, so it lands on `main` as one commit, and that commit carries a version. `git log --oneline main` then reads like a changelog, and undoing a version means reverting one commit.

For agents: [set-up-repo.md](../../prompts/repository/set-up-repo.md) installs the CI that does this.

## Format

| Part | Name | Who changes it |
|---|---|---|
| `Z` | patch | CI: each merged pull request adds one |
| `Y` | minor | A maintainer, for a release with new features |
| `X` | major | A maintainer, for a milestone such as the first public release |

A commit on `main` looks like `v0.4.2 fix: return players to their team after reconnecting (#31)`. GitHub adds the ` (#N)` when it merges.

## How it works

1. You title the pull request `<type>: <summary>`, with no version.
2. CI puts the next version in front of the title, and updates it whenever another pull request merges first.
3. A maintainer merges with **Squash and merge**, so the commit title is the PR title, version included.
4. For a minor or major version, a maintainer edits the version in the title. When it merges, CI tags the commit and publishes a GitHub Release. Patch versions get no tag; they live only in the commit titles.

## Rules

- Commits on branches carry no version. Only the PR title does.
- Only maintainers choose minor and major versions. Agents never do, and never create tags.
- Never skip, reuse or lower a number; CI accepts only the next one.

## Key commands

```bash
git fetch origin && node scripts/check-commits.mjs next        # the next patch version
node scripts/check-commits.mjs next --minor                     # or the next minor
git log --oneline main                                          # the history, one version per line
```
