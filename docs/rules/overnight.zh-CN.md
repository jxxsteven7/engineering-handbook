# 并行开发和夜间自动审查

[English](overnight.md) | **简体中文**

> [!NOTE]
> 试行中：在一个真实项目上跑过一轮，4 个 PR 一夜审完、修完。

几个 PR 同时开发，每个 PR 一个 worktree 和一个开发会话。一个 shell 脚本盯着 GitHub，PR 一开出来，就另开一个新会话审查，发现问题后换更强的模型修复，等 CI 跑完，写出能不能合并。人只管两件事：睡前确认计划，早上合并。

给 agent：[overnight.md](../../prompts/agents/overnight.md) 配好 `plans/` 和监视脚本并启动它。要拷的文件在 [templates/overnight/](../../templates/overnight/)。

## 什么时候用

- 需求已经定下来，能拆成几个互不冲突的 PR。
- 仓库有清楚的规则（`AGENTS.md`）和自动测试。
- 有些 PR 你愿意让 agent 的审查代替你逐行看，只看结论就合并。这要在计划里逐个 PR 写明，没写的照常由人审。

需求还在摸索、要边做边看的，不适合。

## 流程

```text
plan (you + one session)  ->  one development prompt per PR
  -> per PR: worktree + tmux + dev session -> plan -> [you confirm] -> code -> open PR -> stop
  -> watcher: PR settled -> fresh session reviews -> stronger model fixes -> push, wait for CI -> verdict
  -> [you] in the morning: read the verdicts, merge in dependency order -> clean up
```

- 人工关口只有两个：确认计划、合并。睡前要把每个开发会话的计划都确认完，否则夜里不会有 PR。
- 盯 GitHub 的是 shell 脚本，不是一直开着的 agent 会话：等待的时候不花 token，也不会忘事。
- 一次只审一个 PR，其余的排队，因为 e2e 测试很吃内存。每个分支只自动审一次。
- 审查用一个全新的会话，不用写代码的那个。修复接着同一个会话，换更强的模型。两段都是 `claude -p`，跑完自己退出，会话会保存下来，早上可以 `claude --resume <ID>` 接着聊。

## 规划

- 在主 clone 开一个会话，把需求逐条讨论到能拍板。拍板要具体到数值：默认值、范围、文案。没拍板的地方，agent 会自己做主。
- 拆 PR：改同一批文件的放进一个 PR；有依赖的排先后；互不相干的并行；两个 PR 共享的接口写成约定，两边的 prompt 里一字不差。
- 计划放在仓库外的 `plans/`，不进 git：`00-plan.md` 是一张 PR 表，再加每个 PR 一份开发 prompt。表里写明每个 PR 由人审还是由 agent 审。
- 开发会话的笔记写到 `plans/notes/`，和你确认的决定写进 PR 描述，都不要写进 memory。memory 是整个仓库的会话共用的，审查会话读到它，审查就不独立了。第一轮就踩过这个坑。

## 关键命令

```bash
# one development session per PR, from the main clone
git worktree add ../feat-xxx -b feat/xxx origin/main
tmux new -s cc-feat-xxx -c ~/code/<repo>/feat-xxx
claude -n feat-xxx "$(cat ~/code/<repo>/plans/01-xxx.md)"

# the watcher, in its own tmux session
tmux new -d -s cc-watch ~/code/<repo>/plans/autoreview/watch.sh

# in the morning
cat ~/code/<repo>/plans/autoreview/watch.log
cat ~/code/<repo>/plans/autoreview/pr<N>-summary.md      # the last line is the VERDICT
tmux attach -t review-pr<N>                              # what the review session printed

# when needed
rm ~/code/<repo>/plans/autoreview/state/feat-xxx.started           # review that branch again
tmux kill-session -t review-pr<N> && rm -f ~/code/<repo>/plans/autoreview/state/busy   # a stuck review
```

## 早上合并

- 按依赖顺序合并。每合并一个，其余会冲突的 PR 就 rebase 一次。
- 计划里写"人审"的 PR：VERDICT 只是参考，自己读 diff、看截图、亲手跑，再批准。
- 写"agent 审"的 PR：看 summary 和 CI，没问题就合并。合并永远由人来点。
- 合并后按[工作区](workspace.zh-CN.md)收尾。`plans/` 里这个 PR 的文件可以留作记录。

## 风险

| 风险 | 对策 |
|---|---|
| 额度：几个高 effort 的开发会话，加上审查和修复，很快用完一周的额度 | 开工前看 statusline 上的 weekly；用量高时降 effort 或少开几个 |
| 权限全开：无人值守只能用 `--dangerously-skip-permissions` | 只在 PR 自己的 worktree 里跑；红线写死在 prompt 里：不合并、不强推、不改版本号、只动这个 PR 的范围 |
| 内存：几个 e2e 同时跑，拖垮机器 | 审查串行；必要时给重任务限内存 |
| 开发会话卡住，或者额度用完中途停下 | 看 `watch.log` 和 tmux。目前还得靠人发现 |
| 修复会话自己给自己下结论 | 只有计划里写"agent 审"的 PR 才只看结论，其余的人再审一遍 |
| PR 之间冲突 | 规划时就把会冲突的文件写进 prompt；合并顺序由人定，后合并的那个 rebase |

## 还没做

- 上游 PR 合并后，自动给下游开 worktree 和开发会话，停在计划关口，也就是由 agent 发出下一条指令。
- 卡住检测：开发会话几个小时没有提交时提醒。
- 修完之后再开一个新会话复核，不让修的人自己下结论。
- 合并一个 PR 后，自动给其余的 PR rebase 并重跑检查。
- 跑完时推送通知到手机。

<!-- docs-sync: 0617e8b7d53bee0132411d5a599ee95c6afee5ec05eebbcd1ef85217aa7b70f5 -->
