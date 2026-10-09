// Tests for scripts/check-docs-sync.mjs. Run them with: node --test scripts/check-docs-sync.test.mjs

import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { after, describe, test } from 'node:test';

import { comparePair, findPairs, main, outline } from './check-docs-sync.mjs';

const kinds = (markdown) => outline(markdown).blocks.map((block) => block.kind);

const EN = `# Title

**English** | [简体中文](a.zh-CN.md)

Run \`git fetch\`, then read [the guide](b.md#start).

- one
- two
  continued

  \`\`\`bash
  echo hi
  \`\`\`

| a | b |
|---|---|
| 1 | 2 |

> [!NOTE]
> A note.
`;

const ZH = `# 标题

[English](a.md) | **简体中文**

先运行 \`git fetch\`，再读[指南](b.zh-CN.md#开始)。

- 一
- 二
  续

  \`\`\`bash
  echo hi
  \`\`\`

| a | b |
|---|---|
| 1 | 2 |

> [!NOTE]
> 注意。
`;

describe('outline', () => {
  test('lists the blocks of a document', () => {
    assert.deepEqual(kinds(EN), ['h1', 'p', 'p', 'li0', 'li0', 'code', 'table 1x2', 'quote NOTE']);
  });

  test('keeps continuation lines in their paragraph or list item', () => {
    assert.deepEqual(kinds('one\ntwo\n\n- a\n  b\nc\n\n  d\n\ne'), ['p', 'li0', 'p']);
    assert.deepEqual(kinds('- a\n  - b\n    - c'), ['li0', 'li1', 'li2']);
    assert.deepEqual(kinds('1. a\n2. b\n\n---\n\ntext'), ['li0', 'li0', 'hr', 'p']);
  });

  test('ignores comments, such as the sync stamp', () => {
    assert.deepEqual(kinds('text\n\n<!-- docs-sync: 00 -->'), ['p']);
  });
});

describe('comparePair', () => {
  const compare = (en, zh) => comparePair('a.md', 'a.zh-CN.md', en, zh, '/nonexistent');
  const structural = (problems) => problems.filter((problem) => !problem.includes('does not exist'));

  test('accepts a faithful translation', () => {
    assert.deepEqual(structural(compare(EN, ZH)), []);
  });

  test('finds a missing paragraph', () => {
    const problems = compare(EN, ZH.replace('- 一\n', '- 一\n\n多出来的一段。\n\n'));
    assert.match(problems.join('\n'), /Block 5 is li0 at a\.md:\d+ but p at a\.zh-CN\.md:\d+/);
  });

  test('requires identical code blocks', () => {
    const problems = compare(EN, ZH.replace('echo hi', 'echo 你好'));
    assert.match(problems.join('\n'), /code block .* differs/);
  });

  test('requires the same inline code and links', () => {
    const problems = compare(EN, ZH.replace('`git fetch`', '`git pull`').replace('b.zh-CN.md', 'c.zh-CN.md'));
    assert.match(problems.join('\n'), /Inline code only in a\.md: `git fetch`/);
    assert.match(problems.join('\n'), /Links only in a\.md: b\.md/);
  });

  test('requires the language switcher', () => {
    const problems = compare(EN.replace('[简体中文](a.zh-CN.md)', '简体中文'), ZH);
    assert.match(problems.join('\n'), /a\.md has no link to a\.zh-CN\.md/);
  });

  test('requires table shapes to match', () => {
    const problems = compare(EN, ZH.replace('| 1 | 2 |', '| 1 | 2 |\n| 3 | 4 |'));
    assert.match(problems.join('\n'), /table 1x2 .* but table 2x2/);
  });
});

describe('findPairs', () => {
  test('pairs each document with its translation and skips exempt files', () => {
    const { pairs, problems } = findPairs(['AGENTS.md', 'README.md', 'README.zh-CN.md', 'x.md', 'y.zh-CN.md', '.github/t.md']);
    assert.deepEqual(pairs, [['README.md', 'README.zh-CN.md']]);
    assert.deepEqual(problems, ['x.md has no Chinese translation, x.zh-CN.md.', 'y.zh-CN.md has no English original, y.md.']);
  });
});

describe('in a repository', () => {
  const directories = [];
  after(() => directories.forEach((directory) => rmSync(directory, { recursive: true, force: true })));

  function makeRepo(files) {
    const root = mkdtempSync(join(tmpdir(), 'check-docs-sync-'));
    directories.push(root);
    spawnSync('git', ['init', '-q'], { cwd: root });
    for (const [path, text] of Object.entries(files)) {
      mkdirSync(dirname(join(root, path)), { recursive: true });
      writeFileSync(join(root, path), text);
    }
    return root;
  }

  const B_EN = '# B\n\n**English** | [简体中文](b.zh-CN.md)\n\n<a id="start"></a>\n';
  const B_ZH = '# B\n\n[English](b.md) | **简体中文**\n\n<a id="start"></a>\n';
  const quiet = (fn) => {
    const { log, error } = console;
    console.log = console.error = () => {};
    try {
      return fn();
    } finally {
      Object.assign(console, { log, error });
    }
  };

  test('fails without stamps, records them with --update, then passes', () => {
    const root = makeRepo({ 'a.md': EN, 'a.zh-CN.md': ZH, 'b.md': B_EN, 'b.zh-CN.md': B_ZH });
    assert.equal(quiet(() => main([], root)), 1);
    assert.equal(quiet(() => main(['--update'], root)), 0);
    assert.match(readFileSync(join(root, 'a.zh-CN.md'), 'utf8'), /<!-- docs-sync: [0-9a-f]{64} -->\n$/);
    assert.equal(quiet(() => main([], root)), 0);
  });

  test('fails again after either file changes', () => {
    const root = makeRepo({ 'a.md': EN, 'a.zh-CN.md': ZH, 'b.md': B_EN, 'b.zh-CN.md': B_ZH });
    quiet(() => main(['--update'], root));
    writeFileSync(join(root, 'a.md'), EN.replace('A note.', 'A changed note.'));
    assert.equal(quiet(() => main([], root)), 1);
  });

  test('refuses to stamp a pair whose structure differs', () => {
    const root = makeRepo({ 'a.md': EN, 'a.zh-CN.md': ZH.replace('- 二\n', ''), 'b.md': B_EN, 'b.zh-CN.md': B_ZH });
    assert.equal(quiet(() => main(['--update'], root)), 1);
    assert.doesNotMatch(readFileSync(join(root, 'a.zh-CN.md'), 'utf8'), /docs-sync/);
  });

  test('requires links to the same language and to files that exist', () => {
    const root = makeRepo({
      'a.md': EN.replace('b.md#start', 'b.zh-CN.md#start'),
      'a.zh-CN.md': ZH.replace('b.zh-CN.md#开始', 'missing.md'),
      'b.md': B_EN,
      'b.zh-CN.md': B_ZH,
    });
    const errors = [];
    const { error, log } = console;
    console.error = (text) => errors.push(text);
    console.log = () => {};
    try {
      main([], root);
    } finally {
      Object.assign(console, { error, log });
    }
    const text = errors.join('\n');
    assert.match(text, /a\.md links to b\.zh-CN\.md#start; link to the English version/);
    assert.match(text, /a\.zh-CN\.md links to missing\.md, which does not exist/);
  });
});

describe('--status', () => {
  const directories = [];
  after(() => directories.forEach((directory) => rmSync(directory, { recursive: true, force: true })));

  const B_EN = '# B\n\n**English** | [简体中文](b.zh-CN.md)\n';
  const B_ZH = '# B\n\n[English](b.md) | **简体中文**\n';

  function syncedRepo() {
    const root = mkdtempSync(join(tmpdir(), 'check-docs-sync-status-'));
    directories.push(root);
    const git = (...args) => spawnSync('git', ['-c', 'user.name=t', '-c', 'user.email=t@t', '-c', 'core.hooksPath=/dev/null', ...args], { cwd: root });
    git('init', '-q');
    writeFileSync(join(root, 'a.md'), EN);
    writeFileSync(join(root, 'a.zh-CN.md'), ZH);
    writeFileSync(join(root, 'b.md'), B_EN);
    writeFileSync(join(root, 'b.zh-CN.md'), B_ZH);
    capture(() => main(['--update'], root));
    git('add', '-A');
    git('commit', '-q', '-m', 'docs: sync');
    return root;
  }

  function capture(fn) {
    const lines = [];
    const { log, error } = console;
    console.log = console.error = (text) => lines.push(text);
    try {
      return { code: fn(), text: lines.join('\n') };
    } finally {
      Object.assign(console, { log, error });
    }
  }

  test('reports nothing when everything is in sync', () => {
    const root = syncedRepo();
    const { code, text } = capture(() => main(['--status'], root));
    assert.equal(code, 0);
    assert.match(text, /everything is in sync/);
  });

  test('says which side changed since the last synced commit', () => {
    const root = syncedRepo();
    writeFileSync(join(root, 'a.zh-CN.md'), readFileSync(join(root, 'a.zh-CN.md'), 'utf8').replace('注意。', '请注意。'));
    let { code, text } = capture(() => main(['--status'], root));
    assert.equal(code, 1);
    assert.match(text, /^zh changed: a\.zh-CN\.md since [0-9a-f]{7}; update a\.md/);

    writeFileSync(join(root, 'a.md'), EN.replace('A note.', 'Note this.'));
    ({ text } = capture(() => main(['--status'], root)));
    assert.match(text, /^both changed: a\.md and a\.zh-CN\.md/);
  });

  test('reports a document without a counterpart', () => {
    const root = syncedRepo();
    writeFileSync(join(root, 'c.zh-CN.md'), '# C\n');
    const { text } = capture(() => main(['--status'], root));
    assert.match(text, /new: c\.zh-CN\.md has no counterpart yet; write c\.md from it/);
  });
});
