# 分阶段开源

[English](staged-open-source.md) | **简体中文**

一个大项目要出好几篇论文。第一篇发表时开源一部分，后面几篇的代码还在开发，暂时不能公开。不管用哪种做法，公开仓库都不带内部的提交历史，因为历史里可能有删掉的密钥、别的论文的实验和内部路径。

## 选一种做法

| 做法 | 适合 |
|---|---|
| 发布快照：内部仓库照常开发，每次发表把一个 tag 做成公开仓库里的一个 commit | 开源主要是为了复现论文，很少接外部 PR |
| 两个仓库：公开仓库放核心包，没发表的论文放在私有仓库里 | 要长期维护、接外部 PR 的工具或平台 |

也有人只用一个仓库，挂两个 remote，没公开的论文放在长期分支上，发表时再合回 `main`。这样分支只能按时间把没公开的东西隔开，几篇论文改的是同一批文件，发布时很难拆。两边的 `main` 还要一直保持一模一样，和分支保护、squash 合并都对不上。

## 发布快照

从 tag 开一个临时 worktree，删掉还不能公开的目录，把剩下的做成公开仓库 `main` 上的一个新 commit。内部仓库的分支和历史都不会动。

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

- 不要直接推内部的 tag 或分支。推一个 tag，它之前的全部历史都会一起公开。也不要用 `git push public --tags`，它会把内部的 tag 全推上去。
- 除了用 gitleaks 扫密钥，还要自己读一遍：有没有内部路径、服务器地址，有没有别的论文的实验。LFS 文件和 submodule 也不能指向私有地址。
- 外部 PR 合进公开仓库后，要手动搬回内部仓库：`git fetch public && git cherry-pick <sha>`。

## 两个仓库

| 仓库 | 放什么 | 谁能看 |
|---|---|---|
| `<project>` | 核心包（环境、接口、基础 pipeline），加上已经发表的论文 | 所有人 |
| `<project>-internal` | 还没发表的论文，每篇一个目录，比如 `paper2/` | 团队 |

- 两个仓库都按本手册的流程走：保护 `main`，每个改动一个 PR，squash 合并。外部贡献者的 PR 提到公开仓库。
- 私有仓库用 submodule 引入公开仓库，锁在一个版本上。公开仓库从不依赖私有仓库。
- 论文代码通过注册机制或插件接口接进核心包，不改核心文件。这样发布时只是搬一个目录。
- 不会透露新想法的核心改动，直接提 PR 到公开仓库。会透露的，先在私有仓库里用子类或注册接口实现，发布时再并进核心。
- 第一次开源时，公开仓库的第一个 commit 用上面的快照做法生成。原来的仓库改名为 `<project>-internal`，删掉已经公开的部分，换成 submodule。

私有仓库引入公开仓库：

```bash
git submodule add git@github.com:<org>/<project>.git <project>
git -C <project> switch --detach v0.3.0
git add <project> && git commit -m "chore: pin <project> to v0.3.0"
```

新 clone 要用 `git clone --recurse-submodules`。要用公开仓库的新版本，把 submodule 切到新的 tag，再提交一次。

发布一篇论文：论文发表后，在公开仓库按[工作区](workspace.zh-CN.md)的做法开一个任务，把论文目录拷进来，走一个 PR。

```bash
mkdir -p extensions
cp -r ~/code/<project>-internal/<project>-internal/paper2 extensions/paper2
gitleaks dir extensions/paper2                     # secrets in the files about to go public
git add extensions && git commit -m "feat: release the paper2 code"
```

拷过去的只有当前的文件。合并时由维护者把版本号改成 minor，见[版本与发布](versioning.zh-CN.md)。合并后私有仓库删掉 `paper2/`，把 submodule 切到这个新版本。

团队大了、想按路径规则自动同步，可以看 Google 的 [Copybara](https://github.com/google/copybara)。一开始手动就够了。

## 来源

- [git-commit-tree](https://git-scm.com/docs/git-commit-tree)、[git-submodule](https://git-scm.com/docs/git-submodule)
- [gitleaks](https://github.com/gitleaks/gitleaks)

<!-- docs-sync: b61b4a19423d1d459e6445375bbe2d668e0d1747c5a3e68f8d0cbf270a86a2e0 -->
