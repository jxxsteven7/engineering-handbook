# Code review

[English](code-review.md) | **简体中文**

每个改动合并前都要由作者以外的人审查，不管是人写的还是 agent 写的。审查标准参考了 Google 的 [code reviewer's guide](https://google.github.io/eng-practices/review/reviewer/)。

给 agent：[review-pr.md](../../prompts/repository/review-pr.md) 让 agent 审一个 PR、写出报告，不改任何东西。

## 规则

- 只要 PR 明显让代码整体变好了，就批准，哪怕它不完美。会让代码变差的，一定要拦下来。
- 按这个顺序看：正确性、设计、项目的规则、可读性、范围。每一行都要读。
- agent 按计划写的改动，要和计划对照。要求了但没做的算问题，做了但没要求的也算问题。
- 可改可不改的评论以 `nit:` 开头。评论针对代码，不针对人，并说明理由。
- 一个工作日内给出回应。
- agent 写的每一行都由作者负责，作者在请人 review 之前要自己读过、跑过。
- 先让一个没写过这段代码的新会话审一遍，很有用。只有计划里标明的任务，它才能代替人的审查，见[夜间自动审查](../agents/overnight.zh-CN.md)。agent 从不批准、从不合并。

## 关键命令

`gh pr review` 本身不审代码，它只是把你的结论发到 GitHub 上：批准、要求修改或留评论。代码要你自己读。读之前，可以先开一个新的 agent 会话审一遍，不要用写这段代码的那个会话。Claude Code 用 `/code-review <N>`，带上 PR 号，它就审整个 PR。Codex 用 `codex review --base <base>`，审当前分支相对 base 的改动。

自己的 PR：在它自己的 worktree 里开一个新会话。

```bash
cd ../feat-new-task
claude -n review-pr123                                      # then type: /code-review 123
codex review --base origin/main                             # or Codex
```

别人的 PR，或者 stack 里不在顶层的 PR：它们没有现成的 worktree，就用常驻的 `review-pr`。它是 detached 的，不占用任何分支，所以不会误往别人的分支上提交。

```bash
git worktree add --detach ../review-pr origin/main          # once, from the main checkout

cd ../review-pr
git fetch origin pull/123/head && git switch --detach FETCH_HEAD
claude -n review-pr123                                      # then type: /code-review 123
codex review --base origin/main                             # or Codex
git fetch origin pull/123/head && git range-diff HEAD...FETCH_HEAD   # after a new push: what changed
git switch --detach origin/main                             # park the worktree when done
```

stack 里的 PR 要和它下面那一层比，Codex 就用 `--base origin/<base-branch>`。

最后由你下结论：

```bash
gh pr view 123 --comments
gh pr diff 123                                              # the whole change, against the PR's base
gh pr review 123 --approve                                  # or --request-changes -b "..."
```

## 来源

- [The standard of code review](https://google.github.io/eng-practices/review/reviewer/standard.html)
- [What to look for in a code review](https://google.github.io/eng-practices/review/reviewer/looking-for.html)
- [How to write code review comments](https://google.github.io/eng-practices/review/reviewer/comments.html)
- [Handling pushback in code reviews](https://google.github.io/eng-practices/review/reviewer/pushback.html)

Google 的指南采用 [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) 协议。

<!-- docs-sync: 948bf6ca972d4bf83b3baf8b950d1081bc7c6ccd3321b7054e04cf474e6d043b -->
