# 版本与发布

[English](versioning.md) | **简体中文**

每个 PR 都用 squash 合并，所以它在 `main` 上就是一个 commit，这个 commit 带一个版本号。这样 `git log --oneline main` 读起来就像更新日志，撤回一个版本也只要 revert 一个 commit。

给 agent：[set-up-repo.md](../../prompts/repository/set-up-repo.md) 会装好负责这件事的 CI。

## 格式

| 位置 | 名称 | 谁来改 |
|---|---|---|
| `Z` | patch | CI：每合并一个 PR 加一 |
| `Y` | minor | 维护者，用于带新功能的发布 |
| `X` | major | 维护者，用于里程碑，比如第一次公开发布 |

`main` 上的 commit 长这样：`v0.4.2 fix: return players to their team after reconnecting (#31)`。` (#N)` 是 GitHub 合并时加的。

## 怎么运作

1. PR 标题写成 `<type>: <summary>`，不写版本号。
2. CI 把下一个版本号加到标题前面；如果别的 PR 先合并了，它会更新这个号。
3. 维护者用 **Squash and merge** 合并，commit 标题就是 PR 标题，包括版本号。
4. 要发 minor 或 major 版本，由维护者改标题里的版本号。合并后 CI 给这个 commit 打 tag，并发布 GitHub Release。patch 版本不打 tag，只存在于 commit 标题里。

## 规则

- 分支上的 commit 不带版本号，只有 PR 标题带。
- minor 和 major 版本只由维护者决定。agent 从不决定，也从不打 tag。
- 不要跳号、重复用号或往回改号，CI 只接受下一个号。

## 关键命令

```bash
git fetch origin && node scripts/check-commits.mjs next        # the next patch version
node scripts/check-commits.mjs next --minor                     # or the next minor
git log --oneline main                                          # the history, one version per line
```

<!-- docs-sync: 02fe7dca62aa8cd390fb08173475f8bc883959f880eb79579899c0fb81946e12 -->
