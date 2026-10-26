import { spawn } from 'node:child_process';
import { cp, mkdir, mkdtemp, symlink, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { basename, dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createFixtures } from './create-fixtures.mjs';
import { uiScenarios } from './ui/index.mjs';

const directory = dirname(fileURLToPath(import.meta.url));
const root = resolve(directory, '../..');
const standalone = new Map([
  ['module-loading', 'module-loading.lua'],
  ['textobjects', 'textobjects.lua'],
  ['linked-tag-requests', 'linked-tag-requests.lua'],
  ['closed-file', 'closed-file.lua'],
  ['formatting', 'formatting.lua'],
  ['performance', '../check-performance.lua'],
]);
const ui = new Map(
  Object.keys(uiScenarios).map((name) => [name.replace(/\.lua$/, ''), name]),
);
for (const name of [
  'brackets',
  'config-audit',
  'definitions',
  'editing-regressions',
  'emmet-context',
  'emmet-vue',
  'emmet-wrap',
  'format-failure',
  'interactions',
  'mason-commands',
  'mason-tools',
  'node-debug',
  'rust-debug',
  'secondary-languages',
  'tag-actions',
  'tag-jsx',
  'treesitter-undo',
  'vue-folding',
  'vue-textobjects',
  'vue-workspaces',
  'workspace-sdk',
])
  ui.set(name, name + '.lua');
ui.set('workflows', 'workflows');
ui.set('host', 'host');
const selfContained = new Set([
  'brackets',
  'emmet',
  'emmet-context',
  'emmet-vue',
  'emmet-wrap',
  'git',
  'host',
  'import-paths',
  'mason-tools',
  'multicursor',
  'search-count',
  'tag-jsx',
  'treesitter-undo',
  'unocss',
]);
const optional = new Set([
  'performance',
  'navigation-performance',
  'rust-debug',
  'host',
  'installation',
]);
const names = [...standalone.keys(), ...ui.keys(), 'installation'];
const requested = process.argv.slice(2);
if (requested.includes('--list') || requested.includes('--help')) {
  console.log(
    'Usage: npm test -- [suite ...]\nWithout suite names, runs all entries except those marked optional.\n',
  );
  for (const name of names)
    console.log(name + (optional.has(name) ? ' (optional)' : ''));
  process.exit(0);
}
const selected = requested.length
  ? requested
  : names.filter((name) => !optional.has(name));
for (const name of selected) {
  if (!names.includes(name))
    throw new Error('Unknown suite: ' + name + '. Run npm run test:list.');
}
if (selected.includes('host') && !process.env.NVIM_VSCODE_RUNTIME) {
  throw new Error(
    'Set NVIM_VSCODE_RUNTIME to the vscode-neovim extension runtime directory.',
  );
}

const output = await mkdtemp(join(tmpdir(), 'nvim-verification-results-'));
console.log('Results: ' + output);
const fixtureSuites = new Set(
  selected.filter((name) => ui.has(name) && !selfContained.has(name)),
);
const template = fixtureSuites.size
  ? await createFixtures(join(output, 'template'))
  : null;
const results = [];
for (const name of selected) {
  console.log('RUN ' + name);
  const env = {
    ...process.env,
    NVIM_APPNAME: basename(root),
    NVIM_TEST_OUTPUT: join(output, name + '.json'),
  };
  if (fixtureSuites.has(name)) {
    // Share installed dependencies, but give every scenario its own editable files.
    const fixture = join(output, 'fixtures', name);
    await mkdir(dirname(fixture), { recursive: true });
    await cp(template, fixture, {
      recursive: true,
      filter: (source) => basename(source) !== 'node_modules',
    });
    for (const project of ['alpha', 'beta']) {
      await symlink(
        join(template, 'alpha/node_modules'),
        join(fixture, project, 'node_modules'),
        process.platform === 'win32' ? 'junction' : 'dir',
      );
    }
    env.NVIM_TEST_ROOT = fixture;
  }
  let executable, args;
  if (ui.has(name)) {
    executable = process.execPath;
    args = [
      join(directory, 'check-ui.mjs'),
      ui.get(name),
      env.NVIM_TEST_OUTPUT,
    ];
  } else {
    executable = process.env.NEOVIM_BIN || 'nvim';
    args = ['--headless', '-i', 'NONE', '-n'];
    if (name === 'installation') {
      args.push('-c', "lua dofile('scripts/verification/installation.lua')");
    } else {
      args.push('-u', 'NONE', '-l', resolve(directory, standalone.get(name)));
    }
  }
  const started = Date.now();
  const child = spawn(executable, args, { cwd: root, env, windowsHide: true });
  const log = [];
  child.stdout.on('data', (data) => log.push(data.toString()));
  child.stderr.on('data', (data) => log.push(data.toString()));
  child.on('error', (error) => log.push(error.stack));
  const timeout = setTimeout(() => {
    log.push('Suite timed out after 150000 ms');
    child.kill();
  }, 150000);
  const exit = await new Promise((resolveExit) =>
    child.once('close', (code, signal) => resolveExit({ code, signal })),
  );
  clearTimeout(timeout);
  await writeFile(join(output, name + '.log'), log.join(''));
  results.push({
    suite: name,
    passed: exit.code === 0,
    ...exit,
    duration_ms: Date.now() - started,
  });
  await writeFile(
    join(output, 'results.json'),
    JSON.stringify(results, null, 2) + '\n',
  );
  console.log((exit.code === 0 ? 'PASS ' : 'FAIL ') + name);
  if (exit.code !== 0) console.error(log.join(''));
}
const passed = results.filter((result) => result.passed).length;
console.log(
  passed + '/' + results.length + ' suites passed. Results: ' + output,
);
if (passed !== results.length) process.exitCode = 1;
