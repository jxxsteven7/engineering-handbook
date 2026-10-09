# Set up a repository: protected main, checked commits, versions

Follows: `docs/repository/protect-main.md` and `docs/repository/versioning.md` in the Agentic Engineering Handbook.

You are setting up the git repository in the current working directory so that:

- every change reaches `main` through a reviewed, squash-merged pull request;
- every merged pull request gets the next version in its title, and CI tags and releases minor and major versions;
- no commit, PR title or PR description carries AI or agent attribution.

The handbook is the repository that contains this file; its root is two directories above this file. Everything you copy is in `templates/repo/` there. Read the two docs above and `templates/repo/scripts/check-commits.mjs` (its header explains every mode) before you start.

## Stop points

- After step 1, report what you found and what you plan to change, then wait for the user to confirm.
- Never change GitHub settings yourself. In step 6, print the exact commands and wait until the user runs them or tells you to.
- Never commit to `main`, push to `main`, merge a pull request or create a tag.
- Never add agent attribution to a commit, PR title or PR description.
- If something in the repository conflicts with these steps (an existing hook manager, another version scheme, merge commits on `main`), stop and ask instead of choosing.

## Steps

1. **Look around** and report:
   - the remote, the default branch, and whether the repository is public or private: `gh repo view --json nameWithOwner,visibility,defaultBranchRef`;
   - the current merge settings: `gh api repos/OWNER/REPO --jq '{allow_squash_merge, allow_merge_commit, allow_rebase_merge, squash_merge_commit_title, squash_merge_commit_message, delete_branch_on_merge}'`;
   - existing rulesets and branch protection: `gh api repos/OWNER/REPO/rulesets` and `gh api repos/OWNER/REPO/branches/main/protection` (a 404 means none);
   - existing hooks (`git config core.hooksPath`, `.githooks/`, `.husky/`, `.pre-commit-config.yaml`), CI workflows, PR template, `CODEOWNERS`, `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `.claude/settings.json`;
   - whether `node --version` is 22 or later, and `gh auth status`;
   - the last 20 commit subjects on `main` (`git log --oneline -20 origin/main`), existing tags (`git tag --list 'v*'`) and a root `package.json` version, if any.

   Ask the user:
   - which commit types to allow, starting from `feat fix docs refactor test chore ci perf revert`;
   - the GitHub usernames of the maintainers, and whether there is more than one;
   - the names of the project's own CI jobs that must pass before merging.
2. **Branch.** `git fetch origin`, then create `chore/protect-main` from `origin/main`, in its own worktree if the project uses worktrees (`git worktree add ../chore-protect-main -b chore/protect-main origin/main`).
3. **Copy and adapt** from `templates/repo/`, keeping the same paths:
   - `scripts/check-commits.mjs` and `scripts/check-commits.test.mjs`. Set `TYPES` to the agreed types and `RULES` to the file that states the rules (usually `CONTRIBUTING.md`). If you removed a type that the tests use, change those tests to another type.
   - `.githooks/commit-msg`, `.githooks/pre-commit`, `.githooks/pre-merge-commit`, `.githooks/pre-push`, executable (`chmod +x`). If the project already has hooks, merge them into these files rather than dropping either, and tell the user.
   - `.github/workflows/conventions.yml`. Keep the job names `Commits and version`, `Script tests` and `Landed commits and release`; the ruleset refers to the first two. Leave the project's other workflows alone.
   - `.github/pull_request_template.md`. Keep the What, Why, How tested and AI assistance sections; adapt the checklist to the project.
   - `.github/CODEOWNERS`, with the maintainers' usernames.
   - `.claude/settings.json`: add the `attribution` and `includeCoAuthoredBy` keys, keeping any keys already there.
4. **Write the rules down.**
   - Put the block at the end of this file at the top of `AGENTS.md`, creating the file if needed. Fill in the project's check commands.
   - Make sure `CLAUDE.md` exists and contains the line `@AGENTS.md`, so Claude Code reads the same rules.
   - In `CONTRIBUTING.md` (create it if needed), state the rules in plain words for people: `main` is protected; one branch and one pull request per change; squash merge; PR titles `<type>: <summary>` with the version added by CI; maintainers choose minor and major versions; no agent attribution; run `git config core.hooksPath .githooks` once after cloning.
5. **Verify, then open the pull request.**
   - `git config core.hooksPath .githooks`
   - `node --test scripts/*.test.mjs` passes.
   - `node scripts/check-commits.mjs next` prints the version the first pull request will get; show it to the user. If the history has no versions yet, it prints `v0.0.1`.
   - Commit with a subject such as `chore: protect main and check commits`. The `commit-msg` hook must accept it; never use `--no-verify`.
   - `node scripts/check-commits.mjs range origin/main..HEAD` passes.
   - Push the branch, open a pull request with the same title, and fill in the template. Wait for the checks and report their results. Don't merge.
6. **GitHub settings.** Fill in OWNER and REPO, print these commands, explain each one, and wait.
   - Merging: squash only, the PR title as the commit title and an empty body, branches deleted after merging.

     ```bash
     gh api -X PATCH repos/OWNER/REPO \
       -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
       -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=BLANK \
       -F delete_branch_on_merge=true
     ```

   - The `protect-main` ruleset. List as required checks `Commits and version`, `Script tests` and the project's own job names (the `name:` of each job). They must have run at least once, on the pull request from step 5, before GitHub can enforce them. With a single maintainer, change `required_approving_review_count` to 0 and `require_code_owner_review` and `require_last_push_approval` to false, because GitHub doesn't let anyone approve their own pull request; tell the user to switch them back when a second maintainer joins.

     ```bash
     gh api -X POST repos/OWNER/REPO/rulesets --input - <<'EOF'
     {
       "name": "protect-main",
       "target": "branch",
       "enforcement": "active",
       "bypass_actors": [],
       "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
       "rules": [
         { "type": "deletion" },
         { "type": "non_fast_forward" },
         {
           "type": "pull_request",
           "parameters": {
             "required_approving_review_count": 1,
             "dismiss_stale_reviews_on_push": true,
             "require_code_owner_review": true,
             "require_last_push_approval": true,
             "required_review_thread_resolution": true,
             "allowed_merge_methods": ["squash"]
           }
         },
         {
           "type": "required_status_checks",
           "parameters": {
             "strict_required_status_checks_policy": true,
             "required_status_checks": [
               { "context": "Commits and version" },
               { "context": "Script tests" }
             ]
           }
         }
       ]
     }
     EOF
     ```

   - Optional, for public repositories: require approval for workflows from outside contributors (**Settings → Actions → General**) and turn on private vulnerability reporting (**Settings → Code security**). These have no single `gh` command; tell the user where to click.
   - If the repository is private on GitHub Free, tell the user that the ruleset is saved but not enforced until the repository is public or on a paid plan.
7. **Check the result** after the user has applied the settings: read them back with the commands from step 1 and confirm each value. Then tell the user that merging the pull request from step 5 with **Squash and merge** gives `main` its first version.
8. **Report**: what you changed, the pull request link, the settings still to apply, and anything you were unsure about.

## Block for AGENTS.md

```markdown
## Always

- **Never work on `main`.** Before changing any file, make sure you are on a branch of your own, in its own worktree if the project uses worktrees. Never commit to `main`, push to `main`, force-push other people's branches or bypass hooks with `--no-verify`.
- **Never add AI or agent attribution.** Commit messages, PR titles and PR descriptions contain no `Co-Authored-By` trailers for AI tools, no "Generated with" lines and no session links. If your tool adds them by default, remove them.
- **Leave versions to CI and maintainers.** Write commit subjects and PR titles as `<type>: <summary>`, with no version; CI adds it to the PR title. Never choose a minor or major version, and never create tags or releases.
- **Run the checks** before you push: <the project's lint, test and build commands>.
- **Get your work reviewed, and never merge it yourself.** Review your own changes first, push the branch, open a pull request and stop. Do not merge, and do not count your own review as the required review.
```
