# Commit 与 PR

[English](commits-and-prs.md) | **简体中文**

PR 小、只做一件事、标题清楚，审起来容易，回滚也容易。这些规则对人和 agent 一样适用，参考了 Google 的 [CL author's guide](https://google.github.io/eng-practices/review/developer/)。Google 把 PR 叫作 CL（changelist）。

给 agent：[open-pr.md](../../prompts/repository/open-pr.md) 把下面每条规则都写得很细，从第一个 commit 一直到开 PR。

## 规则

- 每个改动一个分支，命名为 `<type>/<short-description>`，例如 `feat/room-settings` 或 `fix/reconnect-after-lock`。
- 一个 PR 只做一件自成一体的事，连同它的测试。重构和行为改动分开。改动 100 行左右比较合适，1000 行通常就太多了。
- commit 标题和 PR 标题写成 `<type>: <summary>`：一句祈使句，单独拿出来也能看懂，小写开头，结尾不加句号。类型有 `feat`、`fix`、`docs`、`refactor`、`test`、`chore`、`ci`、`perf` 和 `revert`。
- PR 描述写清改了什么、为什么改、怎么测的，以及哪些部分是 agent 写的。
- 请人 review 之前，自己把整个 diff 读一遍。agent 写的代码也算你的代码。
- commit 和 PR 里不带 agent 署名。

commit 信息长这样：

```text
fix: return players to their team after reconnecting

The reconnect handler looked players up by socket ID, which changes on
every reconnect. Look them up by their player token instead.
```

## Review 期间

- 追加新的 commit，不要 amend，这样 reviewer 能看到改了什么。反正最后 squash 合并时，这些历史都会被整理掉。
- 每条意见都要回应：要么照改，要么说明为什么不改。reviewer 没看懂的代码，优先把代码改清楚，而不是只在回复里解释。

## 关键命令

在自己的分支上跟上 `main`：

```bash
git fetch origin
git rebase origin/main
git push --force-with-lease
```

别人也会往上推的分支，改用 `git merge origin/main`。

## Stacked PR

一个改动太大、一个 PR 装不下时，把它拆成一串分支，每个建立在下面那个之上，每个分支一个 PR。最底下的以 `main` 为目标，其余每个以它下面那个分支为目标。从下往上合并。

```bash
git switch -c feat/lobby-api                                       # the next layer starts where this one ends
git rebase --update-refs feat/lobby-model                          # from the top, after changing a lower layer
git rebase --update-refs --onto origin/main feat/lobby-model       # from the top, after the bottom was squash-merged
```

互不依赖的部分不要做成 stack，直接开几个以 `main` 为目标的 PR。

## 来源

- [Small CLs](https://google.github.io/eng-practices/review/developer/small-cls.html)
- [Writing good CL descriptions](https://google.github.io/eng-practices/review/developer/cl-descriptions.html)
- [How to handle reviewer comments](https://google.github.io/eng-practices/review/developer/handling-comments.html)

Google 的指南采用 [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) 协议。

<!-- docs-sync: 7085b442696a3ed3d1ce7ee6a9a883eae331be763bc9cfed45aaacb626be2dd8 -->
