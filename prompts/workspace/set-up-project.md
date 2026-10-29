# Set up a project directory

Follows: `docs/tools/git-repos.md` in the Engineering Handbook.

Fill in before use: the repository (an `owner/name` or URL), and which situation applies. If the user didn't say, ask.

| Situation | Remotes |
|---|---|
| A. Your own or your team's repository | `origin` = the repository |
| B. Send PRs to someone else's project | `origin` = the user's fork, `upstream` = the original |
| C. Start your own project from someone else's code | `origin` = a new repository of the user's, `source` = the original, read-only |
| D. Just try someone else's project | `origin` = the original; a release tag checked out |

## Stop points

- Before creating a repository or a fork on GitHub (`gh repo create`, `gh repo fork`), show the command and wait for the user to confirm. For C, ask whether the new repository is private or public.
- Never push to `source` or `upstream`, and never force-push anything here.
- Never delete or overwrite an existing directory. If `~/code/<repo>` already exists, report what is in it and ask.

## Layout

```text
~/code/<repo>/            # project directory, named after the repository
├── <repo>/               # main clone: syncs main only, never develop here
└── plans/                # created later, when there is a plan; not in git
```

For C, `<repo>` is the name of the user's new repository. D doesn't need the layout: clone wherever the user wants, by default `~/code/<repo>`.

## Steps

### A. Your own or your team's repository

```bash
mkdir -p ~/code/<repo> && cd ~/code/<repo>
git clone git@github.com:<owner>/<repo>.git
cd <repo>
git submodule update --init --recursive    # only if .gitmodules exists
```

### B. Send PRs to someone else's project

1. Read the project's `CONTRIBUTING*`, `LICENSE` and PR template on GitHub, and tell the user anything that affects them (a CLA, an issue-first rule, branch naming).
2. Fork and clone:

   ```bash
   gh repo fork <owner>/<repo> --clone=false
   mkdir -p ~/code/<repo> && cd ~/code/<repo>
   git clone git@github.com:<you>/<repo>.git
   cd <repo>
   git remote add upstream https://github.com/<owner>/<repo>.git
   git fetch upstream
   git branch --set-upstream-to=upstream/main main
   gh repo set-default <owner>/<repo>
   ```

   If the original's default branch isn't `main`, use its name everywhere above.
3. Tell the user: new branches start from `upstream/main`, are pushed to `origin`, and PRs go to `<owner>/<repo>`. Keep their own code out of this repository; if they need the fork inside their own project, reference it as a submodule pinned to a commit.

### C. Start your own project from someone else's code

1. Check the original's license allows it, and tell the user what it requires (keeping the license file, attribution).
2. Create the new repository and clone the original into the layout:

   ```bash
   gh repo create <you>/<myproj> --private          # after the user confirmed private or public
   mkdir -p ~/code/<myproj> && cd ~/code/<myproj>
   git clone https://github.com/<owner>/<their-repo>.git <myproj>
   cd <myproj>
   git remote rename origin source
   git remote set-url --push source DISABLED
   git remote add origin git@github.com:<you>/<myproj>.git
   git push -u origin main
   git branch source-code source/main
   git push origin source-code
   ```

3. Check: `git remote -v` shows `source` with push URL `DISABLED`, and `git push source main` fails.
4. Keep the original's `LICENSE`, and add a line to the README saying where the code comes from. Do that on a branch in a worktree, as in `start-task.md`, not in the main clone.
5. Tell the user how to see their changes (`git diff source-code...main --stat`) and how to take in later updates: on a new branch `chore/sync-source` from `origin/main`, `git fetch source && git merge source/main`, then a normal PR.

### D. Just try someone else's project

```bash
git clone https://github.com/<vendor>/<sdk>.git ~/code/<sdk>
cd ~/code/<sdk>
git tag -l --sort=-v:refname | head -5      # pick the latest release
git checkout <tag>
```

If the user later wants to contribute, rename `origin` to `upstream`, add their fork as `origin`, and continue as in B.

## After any of A to C

1. Turn on the repository's hooks if it ships them: if `.githooks/` exists, `git config core.hooksPath .githooks`; if the README or CONTRIBUTING says how (for example `npm install`, `pre-commit install`), do that.
2. Install the dependencies in the main clone only if the user wants to run the baseline there. Development happens in worktrees, each with its own dependencies.
3. Optionally, if the user reviews PRs or tests releases often, create the standing worktrees, both detached so they hold no branch:

   ```bash
   git worktree add --detach ../review-pr origin/main
   git worktree add --detach ../playtest origin/main
   ```

4. Report: the directory, `git remote -v`, the default branch, the hooks, and the next step (`start-task.md` for the first task).
