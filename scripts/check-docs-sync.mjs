#!/usr/bin/env node
// Checks that every document and its Chinese translation are in sync.
//
// Every Markdown file X.md has a translation X.zh-CN.md next to it, except the files in EXEMPT.
// For each pair it checks that:
//
// - each file links to the other in its first lines (the language switcher);
// - both have the same blocks in the same order: headings at the same levels, paragraphs, list
//   items at the same depth, quotes, tables of the same shape and fenced code blocks;
// - fenced code blocks are identical, so code blocks hold no prose and their comments are in
//   English;
// - both use the same inline code spans and link to the same targets, where a link to another
//   document counts as a link to its pair;
// - X.zh-CN.md links to the Chinese version of another document and X.md to the English one,
//   and links to files in the repository point at files that exist;
// - the sync stamp at the bottom of X.zh-CN.md matches the current content of both files.
//
// The stamp is a hash of both files. Any edit to either file changes it, so the check fails until
// someone brings the other file in line and records a new stamp with --update. The script can't
// judge the translation itself; reviewers check that.
//
// Usage:
//   node scripts/check-docs-sync.mjs                    check every pair (CI runs this)
//   node scripts/check-docs-sync.mjs --update           check, then record new stamps for every
//                                                       pair whose structure matches
//   node scripts/check-docs-sync.mjs --update <file>... the same, for the pairs of these files
//
// Exit codes: 0 in sync, 1 out of sync, 2 usage error.

import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, realpathSync, writeFileSync } from 'node:fs';
import { basename, dirname, join, normalize, relative, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

// Files that are written in English only: instructions and prompts for agents, files to copy into
// other repositories, and GitHub's own files.
export const EXEMPT = [/^AGENTS\.md$/, /^CLAUDE\.md$/, /^prompts\//, /^templates\//, /^\.github\//];
const ZH_SUFFIX = '.zh-CN.md';
const STAMP_LINE = /^<!-- docs-sync: ([0-9a-f]{64}) -->[ \t]*$/gm;
const SWITCHER_LINES = 5;

const isZh = (path) => path.endsWith(ZH_SUFFIX);
export const zhPathOf = (en) => en.replace(/\.md$/, ZH_SUFFIX);
export const enPathOf = (zh) => zh.slice(0, -ZH_SUFFIX.length) + '.md';

// --------------------------------------------------------------------------------------------
// Outline
// --------------------------------------------------------------------------------------------

const FENCE_RE = /^(\s*)(`{3,}|~{3,})(.*)$/;
const HEADING_RE = /^(#{1,6})\s+(.+?)\s*#*\s*$/;
const LIST_RE = /^(\s*)([-*+]|\d+[.)])\s+/;
const HR_RE = /^\s{0,3}([-*_])(\s*\1){2,}\s*$/;
const ALERT_RE = /^\s*>\s*\[!(\w+)\]/;

// The blocks of a Markdown file, with what must match between the languages. A block is
// { kind, line }, where kind is "h2", "p", "li0" (a list item and its depth), "quote", "table 3x2",
// "code" or "html". Code blocks, inline code spans and link targets are collected separately.
export function outline(markdown) {
  const blocks = [];
  const codeBlocks = [];
  const inlineCode = [];
  const links = [];
  let fence = null;
  let open = null; // the kind of block that the next non-blank line continues
  let afterBlank = false;
  let table = null;

  const add = (kind, line) => {
    blocks.push({ kind, line });
    open = kind;
  };
  const endTable = () => {
    if (!table) return;
    // The first two rows of a table are the header and the separator.
    table.block.kind = `table ${Math.max(table.rows - 2, 0)}x${table.columns}`;
    table = null;
  };

  markdown.split('\n').forEach((line, index) => {
    const number = index + 1;
    if (fence) {
      if (fence.close.test(line)) {
        codeBlocks.push({ text: fence.lines.join('\n'), line: fence.line });
        fence = null;
      } else {
        // Remove the fence's own indentation so code blocks inside list items compare cleanly.
        fence.lines.push(line.replace(fence.indent, ''));
      }
      return;
    }

    const opening = line.match(FENCE_RE);
    if (opening) {
      endTable();
      const [, indent, marker, info] = opening;
      fence = {
        indent: new RegExp(`^ {0,${indent.length}}`),
        close: new RegExp(`^\\s*${marker[0]}{${marker.length},}\\s*$`),
        lines: [`${marker}${info.trim()}`],
        line: number,
      };
      add('code', number);
      open = null;
      afterBlank = false;
      return;
    }

    if (!line.trim()) {
      endTable();
      afterBlank = true;
      if (open !== 'li' && !open?.startsWith('li')) open = null;
      return;
    }

    collectInline(line, inlineCode, links);

    if (line.trim().startsWith('|')) {
      if (!table) {
        const columns = line.trim().replace(/^\||\|$/g, '').split('|').length;
        add('table', number);
        table = { block: blocks.at(-1), rows: 0, columns };
      }
      table.rows += 1;
      afterBlank = false;
      return;
    }
    endTable();

    const heading = line.match(HEADING_RE);
    const listItem = line.match(LIST_RE);
    const isListItem = listItem && !HR_RE.test(line);
    const indented = /^\s{2,}/.test(line);
    const continuesItem = open?.startsWith('li') && (indented || !afterBlank);

    if (heading) {
      add(`h${heading[1].length}`, number);
      open = null;
    } else if (/^\s*<!--/.test(line)) {
      // Comments, such as the sync stamp, are not part of the content.
    } else if (/^\s*>/.test(line)) {
      if (open !== 'quote' || afterBlank) {
        const alert = line.match(ALERT_RE);
        add(alert ? `quote ${alert[1].toUpperCase()}` : 'quote', number);
        open = 'quote';
      }
    } else if (HR_RE.test(line)) {
      add('hr', number);
      open = null;
    } else if (isListItem) {
      add(`li${Math.floor(listItem[1].length / 2)}`, number);
    } else if (/^\s*</.test(line) && !continuesItem && (open === null || afterBlank)) {
      add('html', number);
    } else if (continuesItem || (open && !afterBlank)) {
      // A continuation line of the open paragraph, list item, quote or HTML block.
    } else {
      add('p', number);
    }
    afterBlank = false;
  });
  endTable();

  return { blocks, codeBlocks, inlineCode, links };
}

function collectInline(line, inlineCode, links) {
  for (const match of line.matchAll(/(`+)(.+?)\1/g)) inlineCode.push(match[2].trim());
  const text = line.replace(/(`+)(.+?)\1/g, '');
  for (const match of text.matchAll(/\]\(\s*<?([^)\s>]+)>?(?:\s+"[^"]*")?\s*\)/g)) links.push(match[1]);
  for (const match of text.matchAll(/<(https?:\/\/[^>\s]+)>/g)) links.push(match[1]);
  for (const match of text.matchAll(/\bhref="([^"]+)"/g)) links.push(match[1]);
  const reference = text.match(/^\s*\[[^\]]+\]:\s*<?(\S+?)>?(\s|$)/);
  if (reference) links.push(reference[1]);
}

// --------------------------------------------------------------------------------------------
// Links
// --------------------------------------------------------------------------------------------

const isExternal = (target) => /^[a-z][a-z0-9+.-]*:/i.test(target);

// Where a link points inside the repository, relative to the root, without its anchor; null for
// external links and in-page anchors.
function localTarget(target, from) {
  if (isExternal(target) || target.startsWith('#')) return null;
  const path = decodeURI(target.split('#')[0].split('?')[0]);
  if (!path) return null;
  return normalize(join(dirname(from), path));
}

// The link targets that must match between a pair, with links to documents mapped to the
// English member of their pair. In-page anchors and the language switcher legitimately differ.
function comparableLinks(links, from, pair) {
  return links.flatMap((target) => {
    if (target.startsWith('#')) return [];
    const local = localTarget(target, from);
    if (local === null) return [target];
    if (local === pair) return [];
    return [isZh(local) ? enPathOf(local) : local];
  });
}

function checkLinks(links, from, pair, root) {
  const problems = [];
  for (const target of links) {
    const local = localTarget(target, from);
    if (local === null || local === pair) continue;
    if (local.startsWith('..')) {
      problems.push(`${from} links outside the repository: ${target}`);
      continue;
    }
    if (!existsSync(join(root, local))) {
      problems.push(`${from} links to ${target}, which does not exist.`);
      continue;
    }
    if (!local.endsWith('.md')) continue;
    if (isZh(from) && !isZh(local) && existsSync(join(root, zhPathOf(local)))) {
      problems.push(`${from} links to ${target}; link to the Chinese version, ${basename(zhPathOf(local))}.`);
    }
    if (!isZh(from) && isZh(local)) {
      problems.push(`${from} links to ${target}; link to the English version, ${basename(enPathOf(local))}.`);
    }
  }
  return problems;
}

// --------------------------------------------------------------------------------------------
// Comparison
// --------------------------------------------------------------------------------------------

export function comparePair(en, zh, enText, zhText, root = '.') {
  const problems = [];
  const a = outline(enText);
  const b = outline(zhText);

  const switcher = (text, other) =>
    text
      .split('\n')
      .slice(0, SWITCHER_LINES)
      .some((line) => line.includes(`](${basename(other)})`));
  if (!switcher(enText, zh)) problems.push(`${en} has no link to ${basename(zh)} in its first ${SWITCHER_LINES} lines.`);
  if (!switcher(zhText, en)) problems.push(`${zh} has no link to ${basename(en)} in its first ${SWITCHER_LINES} lines.`);

  const length = Math.max(a.blocks.length, b.blocks.length);
  for (let i = 0; i < length; i += 1) {
    const x = a.blocks[i];
    const y = b.blocks[i];
    if (!x || !y || x.kind !== y.kind) {
      const describe = (block, file) => (block ? `${block.kind} at ${file}:${block.line}` : `nothing in ${file}`);
      problems.push(`Block ${i + 1} is ${describe(x, en)} but ${describe(y, zh)}.`);
      break;
    }
  }

  a.codeBlocks.forEach((block, i) => {
    const other = b.codeBlocks[i];
    if (other && block.text !== other.text) {
      problems.push(
        `The code block at ${en}:${block.line} differs from the one at ${zh}:${other.line}. ` +
          'Code blocks must be identical.',
      );
    }
  });

  const onlyIn = (list, other) => subtract(list, other);
  const codeA = onlyIn(a.inlineCode, b.inlineCode);
  const codeB = onlyIn(b.inlineCode, a.inlineCode);
  if (codeA.length) problems.push(`Inline code only in ${en}: ${codeA.map((c) => `\`${c}\``).join(', ')}`);
  if (codeB.length) problems.push(`Inline code only in ${zh}: ${codeB.map((c) => `\`${c}\``).join(', ')}`);

  const linksA = comparableLinks(a.links, en, zh);
  const linksB = comparableLinks(b.links, zh, en);
  const onlyA = onlyIn(linksA, linksB);
  const onlyB = onlyIn(linksB, linksA);
  if (onlyA.length) problems.push(`Links only in ${en}: ${onlyA.join(', ')}`);
  if (onlyB.length) problems.push(`Links only in ${zh}: ${onlyB.join(', ')}`);

  problems.push(...checkLinks(a.links, en, zh, root), ...checkLinks(b.links, zh, en, root));
  return problems;
}

// Returns the items of `list` that `other` lacks, counting duplicates.
function subtract(list, other) {
  const remaining = [...other];
  return list.filter((item) => {
    const index = remaining.indexOf(item);
    if (index === -1) return true;
    remaining.splice(index, 1);
    return false;
  });
}

export function stampFor(enText, zhBody) {
  return createHash('sha256').update(enText.trimEnd()).update('\0').update(zhBody).digest('hex');
}

// The translation without its stamp lines, and the last stamp it records.
export function splitStamp(zhText) {
  const body = zhText.replace(STAMP_LINE, '').trimEnd();
  const recorded = [...zhText.matchAll(STAMP_LINE)].at(-1)?.[1];
  return { body, recorded };
}

// --------------------------------------------------------------------------------------------
// Files
// --------------------------------------------------------------------------------------------

function markdownFiles(root) {
  const result = spawnSync('git', ['ls-files', '--cached', '--others', '--exclude-standard', '-z', '--', '*.md'], {
    cwd: root,
    encoding: 'utf8',
  });
  if (result.status !== 0) throw new Error(`git ls-files: ${result.stderr.trim()}`);
  return [...new Set(result.stdout.split('\0').filter(Boolean))].filter((path) => existsSync(join(root, path))).sort();
}

const read = (root, path) => readFileSync(join(root, path), 'utf8').replace(/\r\n/g, '\n');

export function findPairs(files) {
  const problems = [];
  const pairs = [];
  const set = new Set(files);
  for (const path of files) {
    if (EXEMPT.some((pattern) => pattern.test(path))) continue;
    if (isZh(path)) {
      if (!set.has(enPathOf(path))) problems.push(`${path} has no English original, ${enPathOf(path)}.`);
    } else if (!set.has(zhPathOf(path))) {
      problems.push(`${path} has no Chinese translation, ${zhPathOf(path)}.`);
    } else {
      pairs.push([path, zhPathOf(path)]);
    }
  }
  return { pairs, problems };
}

export function main(argv, root) {
  const update = argv[0] === '--update';
  const only = update ? argv.slice(1) : argv;
  if (!update && only.length) {
    console.error('Usage: node scripts/check-docs-sync.mjs [--update [<file>...]]');
    return 2;
  }
  const wanted = new Set(
    only.map((path) => {
      const relativePath = relative(root, resolve(path));
      return isZh(relativePath) ? enPathOf(relativePath) : relativePath;
    }),
  );

  const { pairs, problems } = findPairs(markdownFiles(root));
  const stale = [];
  for (const [en, zh] of pairs) {
    const enText = read(root, en);
    const { body, recorded } = splitStamp(read(root, zh));
    const pairProblems = comparePair(en, zh, enText, body, root);
    problems.push(...pairProblems);
    const expected = stampFor(enText, body);
    if (recorded === expected) continue;
    if (update && !pairProblems.length && (!wanted.size || wanted.has(en))) {
      writeFileSync(join(root, zh), `${body}\n\n<!-- docs-sync: ${expected} -->\n`);
      console.log(`Recorded a new sync stamp in ${zh}.`);
    } else {
      stale.push([en, zh, recorded]);
    }
  }

  for (const [en, zh, recorded] of stale) {
    problems.push(
      recorded
        ? `The sync stamp in ${zh} is out of date: ${en} or ${zh} changed after the last sync.`
        : `${zh} has no sync stamp.`,
    );
  }

  if (problems.length) {
    console.error('Documents out of sync:\n');
    for (const problem of problems) console.error(`- ${problem}\n`);
    if (stale.length) {
      console.error(
        'Bring both languages in line, then record the stamp with:\n\n' +
          '  node scripts/check-docs-sync.mjs --update <file>\n',
      );
    }
    return 1;
  }
  console.log(`check-docs-sync: ${pairs.length} pair(s) in sync.`);
  return 0;
}

// Run as a script, not when imported by the tests.
if (process.argv[1] && import.meta.url === pathToFileURL(realpathSync(process.argv[1])).href) {
  const root = join(dirname(fileURLToPath(import.meta.url)), '..');
  process.exitCode = main(process.argv.slice(2), root);
}
