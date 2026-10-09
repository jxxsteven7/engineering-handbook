# Open-sourcing in stages

**English** | [简体中文](staged-open-source.zh-CN.md)

A large project will produce several papers. When the first one is published, part of the code goes public, while the code for the later papers is still in development and can't be released yet. Whichever way you do it, the public repository carries none of the internal commit history, because that history may contain deleted secrets, other papers' experiments and internal paths.

## Pick one way

| Way | Suits |
|---|---|
| Publish snapshots: develop in the internal repository as usual, and on each publication turn a tag into one commit in the public repository | Code released mainly so the paper can be reproduced, with few outside PRs |
| Two repositories: the public one holds the core package, and unpublished papers live in a private one | A tool or platform maintained for the long term that takes outside PRs |

Some teams use a single repository with two remotes instead, keeping unpublished papers on long-lived branches and merging them back into `main` on publication. Branches only separate unpublished work in time; when several papers change the same files, they are hard to pull apart at release. The two `main` branches also have to stay identical, which doesn't fit branch protection or squash merges.

## Publish snapshots

Open a temporary worktree at the tag, delete the directories that can't go public yet, and turn what is left into a new commit on the public repository's `main`. The internal repository's branches and history don't change.

```bash
git remote add public git@github.com:<org>/<project>.git          # once
git fetch public
git worktree add --detach ../release-v1.1.0 v1.1.0
cd ../release-v1.1.0
git rm -r -q paper2 paper3                                         # everything not yet published
gitleaks dir .                                                     # secrets in the files about to go public
c=$(git commit-tree "$(git write-tree)" -p public/main -m "chore: release v1.1.0")   # first release: no -p public/main
git push public $c:refs/heads/main
gh release create v1.1.0 --repo <org>/<project> --target main --notes "<paper, weights, data>"
cd - && git worktree remove --force ../release-v1.1.0
```

- Never push an internal tag or branch directly. Pushing a tag makes all the history before it public too. Don't use `git push public --tags` either; it pushes every internal tag.
- Besides scanning for secrets with gitleaks, read the files yourself: internal paths, server addresses, experiments from other papers. LFS files and submodules must not point to private addresses either.
- Once an outside PR is merged in the public repository, bring it back into the internal one by hand: `git fetch public && git cherry-pick <sha>`.

## Two repositories

| Repository | What it holds | Who can see it |
|---|---|---|
| `<project>` | The core package (environments, interfaces, the base pipeline), plus the papers already published | Everyone |
| `<project>-internal` | The papers not yet published, one directory each, such as `paper2/` | The team |

- Both follow this handbook's process: `main` is protected, every change is a PR, and PRs are squash-merged. Outside contributors open their PRs on the public repository.
- The private repository brings in the public one as a submodule, pinned to a version. The public repository never depends on the private one.
- A paper's code plugs into the core package through a registry or plugin interface and doesn't change core files. Releasing it then means moving one directory.
- A core change that gives away nothing new goes straight to the public repository as a PR. One that would give away an idea is first built in the private repository as a subclass or through the registry, and folded into the core on release.
- On the first release, make the public repository's first commit with the snapshot steps above. Rename the original repository to `<project>-internal`, delete the parts now public, and bring them back in as a submodule.

Bring the public repository into the private one:

```bash
git submodule add git@github.com:<org>/<project>.git <project>
git -C <project> switch --detach v0.3.0
git add <project> && git commit -m "chore: pin <project> to v0.3.0"
```

New clones need `git clone --recurse-submodules`. To use a newer public version, switch the submodule to the new tag and commit again.

Release a paper: once it is published, start a task in the public repository as described in [Workspace](workspace.md), copy the paper's directory in, and open one PR.

```bash
mkdir -p extensions
cp -r ~/code/<project>-internal/<project>-internal/paper2 extensions/paper2
gitleaks dir extensions/paper2                     # secrets in the files about to go public
git add extensions && git commit -m "feat: release the paper2 code"
```

Only the current files are copied. When merging, the maintainer raises the version to a minor one; see [Versioning and releases](versioning.md). After the merge, the private repository deletes `paper2/` and switches the submodule to the new version.

When the team grows and you want directories synced automatically by path rules, look at Google's [Copybara](https://github.com/google/copybara). Doing it by hand is enough at first.

## Sources

- [git-commit-tree](https://git-scm.com/docs/git-commit-tree), [git-submodule](https://git-scm.com/docs/git-submodule)
- [gitleaks](https://github.com/gitleaks/gitleaks)
