# Agentic Engineering Handbook

**English** | [简体中文](README.zh-CN.md)

How to run software projects when coding agents such as Claude Code and Codex write most of the code: where each piece of work lives, what an agent works on, when it stops, and what stays your job.

A good agent knows when to act, when to stop, and where to work. It learns all three from you: from the plan you give it and from how your projects are organized. This handbook is about the plan and the organization.

> [!NOTE]
> Work in progress. Everything here comes from daily use on real projects. Parts marked as a trial are still being tested.

## Principles

1. **You plan, agents execute.** Before an agent writes code, you decide what gets built, how it splits into pull requests, and the exact values: defaults, limits, wording. Anything you leave open, the agent decides for you.
2. **Know what you and your agents are doing.** You may not read every line an agent writes, but you always know which tasks are running, where they run, how far along they are and what each one may touch. If you can't say that in one sentence per task, stop and find out.
3. **Every task has one address.** One task is one branch, one worktree, one terminal session and one agent session, all with the same name. The main checkout only syncs `main`, and nobody works in it.
4. **One change, one purpose.** A pull request does one self-contained thing and is small enough to review in one sitting. It lands on `main` as a single squash commit with a version number.
5. **People hold the gates.** An agent stops after proposing a plan and waits for approval. It never merges and never pushes to `main`. Approving the plan and merging stay with people.
6. **Review with fresh eyes.** Someone other than the author reviews every change. By default that is a person. For a task the plan marks as safe to leave to agents, a new agent session that didn't write the code reviews and fixes it, and CI must pass. Either way a person merges, and the session that wrote the code never judges its own work.
7. **Let machines enforce the rules.** Branch protection, git hooks and CI catch what people and agents forget. A rule that exists only in a document will get broken.
8. **Done means verified.** The tests ran, the program started, someone looked at the output. "It should work" doesn't count.
9. **Write things down where the next session will look.** Plans go in files, decisions in the PR description, follow-ups in issues. Agent memory keeps only lessons that apply to every task.
10. **Clean up after every task.** When a PR merges, remove its worktree, branch, sessions and notes. Stale sessions and notes mislead the next agent.
11. **Your name, your code.** Commits carry no agent attribution. Whoever commits is responsible for every line, including the lines an agent wrote.

## How the repository is organized

| Folder | For | What's in it |
|---|---|---|
| `docs/` | People | The principles and the commands that matter most, in English and Chinese. Start here. |
| `prompts/` | Agents | Detailed step-by-step instructions you give an agent so it sets something up or does a task by the same rules. In English only. |
| `templates/` | Your machines and repositories | Real files to copy elsewhere and run: scripts, hooks, CI workflows, blank plans. You rarely copy them by hand; the prompts tell the agent which ones to take. |
| `scripts/`, `.githooks/`, `.github/` | This repository | Its own checks. |

A doc tells a person what to do and why, briefly. A prompt has an agent do it, with every detail spelled out so the result is the same each time. `docs/` and `prompts/` use the same topic folders, every doc links to its prompts, and every prompt names the doc it follows. Read the doc before you give its prompt to an agent, so you know what the agent is about to do.

| Topic | The question it answers |
|---|---|
| `setup/` | How do I set up my machine and my agents? |
| `workspace/` | Where does each piece of work live? |
| `repository/` | How does a change reach `main`? |
| `agents/` | How do I plan work for agents, run them and let them work overnight? |

## Contents

### Setup: the machine and the agents

| Doc | Prompts for agents |
|---|---|
| [Set up a workstation](docs/setup/workstation.md): packages, git, SSH, logins, statusline, git prompt, permissions | [workstation.md](prompts/setup/workstation.md) |

Files for your machine: [templates/workstation/](templates/workstation/).

### Workspace: where each piece of work lives

| Doc | Prompts for agents |
|---|---|
| [Repositories and worktrees](docs/workspace/repos-and-worktrees.md): layout, names, opening a repository, starting and finishing a task | [set-up-project.md](prompts/workspace/set-up-project.md), [start-task.md](prompts/workspace/start-task.md), [finish-task.md](prompts/workspace/finish-task.md) |
| [Git first aid](docs/workspace/git-first-aid.md): rebase conflicts and common accidents | |

### Repository: how a change reaches main

| Doc | Prompts for agents |
|---|---|
| [Protect main](docs/repository/protect-main.md): branch protection, hooks and CI | [set-up-repo.md](prompts/repository/set-up-repo.md) |
| [Versioning and releases](docs/repository/versioning.md): one version per merged pull request | [set-up-repo.md](prompts/repository/set-up-repo.md) |
| [Commits and pull requests](docs/repository/commits-and-prs.md): small changes, clear titles, stacks | [open-pr.md](prompts/repository/open-pr.md) |
| [Code review](docs/repository/code-review.md): when to approve, what to check | [review-pr.md](prompts/repository/review-pr.md) |

Files for your repository: [templates/repo/](templates/repo/).

### Agents: planning, running and supervising them

| Doc | Prompts for agents |
|---|---|
| [Parallel development and overnight review](docs/agents/overnight.md) (trial): a script watches the PRs, a new session reviews, a stronger model fixes, a person merges | [overnight.md](prompts/agents/overnight.md) |

Files for the overnight round: [templates/overnight/](templates/overnight/).

### Coming next

- `setup/`: instructions for agents (`AGENTS.md`, `CLAUDE.md`, memory).
- `agents/`: planning with an agent, and running a single development session.

## Quick start

**For people.** Read the principles above, then the docs for the topic you're working on.

**For agents.** Clone this repository, then point your agent at a prompt:

```bash
git clone https://github.com/jxxsteven7/agentic-engineering-handbook.git ~/agentic-engineering-handbook
```

```text
Read ~/agentic-engineering-handbook/prompts/repository/set-up-repo.md and follow it for this repository.
```

In Claude Code you can also type `@` followed by the file's path. Each prompt says where it stops to wait for you.

## Working on this repository

- Claude Code and Codex follow the same rules: Codex reads [AGENTS.md](AGENTS.md), and [CLAUDE.md](CLAUDE.md) imports it for Claude Code.
- How to write and translate docs: [CONTRIBUTING.md](CONTRIBUTING.md). This is a docs repository with one maintainer, so changes are committed to `main` directly, without versions.

## Sources and license

- The docs on commits, pull requests and code review adapt Google's [Engineering Practices](https://google.github.io/eng-practices/), licensed under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/).
- A license for this repository will be added before it is made public.
