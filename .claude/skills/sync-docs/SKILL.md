---
name: sync-docs
description: Bring each doc in this handbook and its translation back in line after the maintainer edited one of them, usually the Chinese X.zh-CN.md. Use when the user says "sync docs", "/sync-docs", "同步文档", "同步英文", "更新英文", or when scripts/check-docs-sync.mjs reports a stale stamp.
---

# Sync the two languages

The maintainer edits the docs by hand, usually only the Chinese version, and keeps them short and plain on purpose. Your job is to make the other language say the same thing with as little change as possible, then record the sync stamp. CONTRIBUTING.md has the rules for docs.

## 1. Find what changed

```bash
node scripts/check-docs-sync.mjs --status
```

Each line tells you what to do:

| Line | What to do |
|---|---|
| `zh changed: <zh> since <sha>; update <en> ...` | Run `git diff <sha> -- <zh>` and carry the changes over to `<en>` |
| `en changed: <en> since <sha>; update <zh> ...` | The same in the other direction |
| `both changed: ...` | Show the user both diffs and ask which one is right. Don't merge them on your own |
| `new: <file> has no counterpart yet; write <other> from it` | Write the whole counterpart |
| `stamp only: <zh>; ...` | Only record the stamp (step 4) |
| `unknown: ...` | Compare the two files in full and ask the user if they differ in meaning |
| `everything is in sync` | Tell the user and stop |

## 2. Update the other language

- **Change only what changed.** Edit only the blocks that correspond to the changed blocks. Leave every other line exactly as it is, even where you would phrase it differently.
- **Keep the blocks parallel.** Both files have the same headings at the same levels, the same paragraphs, list items at the same depth, quotes and tables with the same rows and columns, in the same order. If the user added, removed, split, merged or moved a block, do the same in the other file.
- **Code blocks are identical.** Copy them byte for byte. Comments inside code are English; if the user wrote Chinese inside a code block, translate that comment into English in both files and tell the user.
- **Inline code is identical** in both files: commands, paths, flags, setting names.
- **Links point to the same targets.** `X.md` links to English docs (`Y.md`), `X.zh-CN.md` to Chinese ones (`Y.zh-CN.md`). The language switcher on the third line stays.
- **Translate the meaning, plainly.** Keep the user's register: if the Chinese is short and plain, the English is short and plain too. Don't add facts, examples, caveats or emphasis that the source doesn't have, and don't drop any. If a sentence is ambiguous, ask instead of guessing.
- Names from user interfaces, such as GitHub's **Squash and merge**, stay in English in both languages.
- In English: sentence-case headings, no em dashes, no filler such as "it is important to note".

## 3. Polish only what you wrote

- English: run the humanizer skill (`/humanizer:humanizer`, or `/humanizer`) on the file, limited to the blocks you changed.
- Chinese: run `/humanizer-zh` on the file, limited to the blocks you changed.
- The polish must not touch code, inline code, links or the block structure. If a skill isn't installed, apply the same idea yourself: plain words, no inflated claims, no forced groups of three, no em dashes.

## 4. Record the stamp and check

```bash
node scripts/check-docs-sync.mjs --update <file>
node scripts/check-docs-sync.mjs
node --test scripts/*.test.mjs templates/repo/scripts/*.test.mjs
```

`--update` refuses a pair whose structure differs and prints why; fix it and run it again. Record a stamp only when the two files really say the same thing.

## 5. Check the prompt

If a doc you synced links a prompt ("For agents: ..."), read that prompt. If the change to the doc makes the prompt wrong or incomplete, tell the user what differs and propose the change. Prompts are in English and spell out every step.

## 6. Report

For each file: a few words on what changed. Then the check results and `git diff --stat`. Don't commit unless the user asks. If they do, put both languages in one commit with an English subject such as `docs: explain when to use a stack`, and no AI or agent attribution.
