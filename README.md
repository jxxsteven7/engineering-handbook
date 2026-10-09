# Agentic Engineering Handbook

**English** | [简体中文](README.zh-CN.md)

I have to say, agents are moving fast. As a robotics PhD, I need to learn how to use agents in my research and engineering work. Over the last six months of development, though, I've found that while today's agents can already do a lot on their own, they sometimes don't know when to act, when to stop, or where to work, and they can easily make a mess of your workspace.

So I drew on my own engineering experience to put together a set of processes and rules for agentic engineering. I believe we still need to play the most important roles throughout development: the planner and the decision-maker. Working this way also helps us improve quickly.

As for how to read and use this repository, I've planned it in roughly two parts. The first is the rule docs that I maintain: what I've learned about writing code and doing engineering with agents, and the automated workflows I consider good practice, so that we stay in control of what we and our agents are doing. I promise to maintain this part by hand, keep it readable, and make it as fun to read as I can. The second part is the automation prompts: Markdown files generated from my rules. Once you understand the rules, you can feed these prompts straight to your agent to set things up.

Specifically, my rules and workflows cover:

1. Environment setup (getting ready):
- Setting up agents and some handy tools on our computers
- Servers, GitHub and SSH
2. Collaborative project development
- Protecting the main branch, GitHub worktrees and PRs
- Code review and change lists (CLs), following Google
- CI and CD
- Versioning, tags and releases
3. Getting more out of agents on long and continuous tasks
- Planning well
- Agent supervision / where people should make decisions
4. Development and maintenance records
- A progress doc you keep by hand, so you know what you're doing and what you've done
- Experiment tables for the project
- Visual experiment reports, which agents are good at, as an artifact or a website (Cloudflare)


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
| `docs/rules/` | People | The rules, that is, the method itself: what to do and why, with only the commands that best show each rule. In English and Chinese; read them once, in the order of the contents below. |
| `docs/tools/` | People | How to use the tools: setting up a workstation, SSH, git. In English and Chinese; look things up when you need them. |
| `prompts/` | Agents | Detailed step-by-step instructions you give an agent so it sets something up or does a task by the same rules. In English only. |
| `templates/` | Your machines and repositories | Real files to copy elsewhere and run: scripts, hooks, CI workflows, blank plans. You rarely copy them by hand; the prompts tell the agent which ones to take. |
| `scripts/`, `.githooks/`, `.github/` | This repository | Its own checks. |

A doc tells a person what to do and why, briefly. A prompt has an agent do it, with every detail spelled out so the result is the same each time. Every doc links to its prompts, and every prompt names the doc it follows. Read the doc before you give its prompt to an agent, so you know what the agent is about to do.

## Contents

### Rules: read in order

| Doc | Prompts for agents |
|---|---|
| [Workspace](docs/rules/workspace.md): one task per worktree, layout, names, starting and finishing a task | [start-task.md](prompts/workspace/start-task.md), [finish-task.md](prompts/workspace/finish-task.md) |
| [Protect main](docs/rules/protect-main.md): branch protection, hooks and CI | [set-up-repo.md](prompts/repository/set-up-repo.md) |
| [Versioning and releases](docs/rules/versioning.md): one version per merged pull request | [set-up-repo.md](prompts/repository/set-up-repo.md) |
| [Commits and pull requests](docs/rules/commits-and-prs.md): small changes, clear titles, stacks | [open-pr.md](prompts/repository/open-pr.md) |
| [Code review](docs/rules/code-review.md): when to approve, what to check | [review-pr.md](prompts/repository/review-pr.md) |
| [Parallel development and overnight review](docs/rules/overnight.md) (trial): a script watches the PRs, a new session reviews, a stronger model fixes, a person merges | [overnight.md](prompts/agents/overnight.md) |
| [Open-sourcing in stages](docs/rules/staged-open-source.md): publish snapshots of tags, or keep a public and a private repository; internal history stays private | |

Files for your repository: [templates/repo/](templates/repo/). Files for the overnight round: [templates/overnight/](templates/overnight/).

### Tools: look up when needed

| Doc | Prompts for agents |
|---|---|
| [Set up a workstation](docs/tools/workstation.md): packages, git settings, Claude Code and Codex, statusline, git prompt, permissions | [workstation.md](prompts/setup/workstation.md) |
| [SSH and GitHub](docs/tools/ssh-and-github.md): SSH key, `~/.ssh/config`, logging in to `gh`, the clipboard on servers | You do keys and logins yourself; for the clipboard on servers, give [workstation.md](prompts/setup/workstation.md) and the server's alias to an agent |
| [Common Git commands](docs/tools/git-commands.md): status and history, syncing with the remote, commits, branches, stash, tags | |
| [Repositories and worktrees](docs/tools/git-repos.md): the ways to open a repository, creating worktrees, cleaning up after a task | [set-up-project.md](prompts/workspace/set-up-project.md), [start-task.md](prompts/workspace/start-task.md), [finish-task.md](prompts/workspace/finish-task.md) |
| [Git first aid](docs/tools/git-first-aid.md): rebase conflicts and common accidents | |

Files for your machine: [templates/workstation/](templates/workstation/).

### Coming next

- Rules: planning with an agent; running a single development session; instructions for agents (how `AGENTS.md`, `CLAUDE.md` and memory divide the work).
- Tools: SSH setup for servers, tmux, and managing Claude Code and Codex sessions.

## Quick start

**For people.** Read the principles above, then the rules in order. Look up the tools when you need them.

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
