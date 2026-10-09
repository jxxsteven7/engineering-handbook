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

在其他 worktree 旁边常驻一个 detached 的审查 worktree。它不占用任何分支，所以不会误往别人的分支上提交。

```bash
git worktree add --detach ../review-pr origin/main          # once, from the main checkout

cd ../review-pr
git fetch origin pull/123/head && git switch --detach FETCH_HEAD
gh pr view 123 --comments
git diff origin/main...HEAD                                 # the change since the branch point
git fetch origin pull/123/head && git range-diff HEAD...FETCH_HEAD   # after a new push: what changed
gh pr review 123 --approve                                  # or --request-changes -b "..."
git switch --detach origin/main                             # park the worktree when done
```

在 Claude Code 里，`/code-review` 会让 agent 审当前分支。

## 来源

- [The standard of code review](https://google.github.io/eng-practices/review/reviewer/standard.html)
- [What to look for in a code review](https://google.github.io/eng-practices/review/reviewer/looking-for.html)
- [How to write code review comments](https://google.github.io/eng-practices/review/reviewer/comments.html)
- [Handling pushback in code reviews](https://google.github.io/eng-practices/review/reviewer/pushback.html)

Google 的指南采用 [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) 协议。

<!-- docs-sync: c819b36e5d02fb8cf1d809861a209c426b16ed427e6ea4783d0305d7ff6df616 -->
