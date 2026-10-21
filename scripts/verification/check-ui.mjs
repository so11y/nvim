import { spawn } from 'node:child_process';
import { mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { basename, dirname, join, resolve } from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';
import { fileURLToPath } from 'node:url';
import { decodeMultiStream, encode } from '@msgpack/msgpack';
import { uiScenarios } from './ui/index.mjs';

const directory = dirname(fileURLToPath(import.meta.url));
const root = resolve(directory, '../..');
const suite = process.argv[2] || 'workflows';
const output =
  process.argv[3] ||
  join(
    mkdtempSync(join(tmpdir(), 'nvim-check-')),
    suite.replace(/[^a-zA-Z0-9_-]/g, '_') + '.json',
  );
const host = suite === 'host';
const args = ['--embed', '-i', 'NONE', '-n'];
if (host) {
  const runtime = process.env.NVIM_VSCODE_RUNTIME;
  if (!runtime)
    throw new Error(
      'Set NVIM_VSCODE_RUNTIME to the extension runtime directory',
    );
  args.push(
    '--cmd',
    'let g:vscode_channel=1',
    '--cmd',
    "execute 'source' fnameescape('" +
      runtime.replaceAll("'", "''") +
      "/vscode-neovim.vim')",
  );
}
const editor = spawn(process.env.NEOVIM_BIN || 'nvim', args, {
  cwd: root,
  env: { ...process.env, NVIM_APPNAME: basename(root) },
  windowsHide: true,
});
const errors = [],
  hostActions = [],
  calls = new Map();
let sequence = 0;
function rejectCalls(error) {
  for (const call of calls.values()) call.reject(error);
  calls.clear();
}
editor.stderr.on('data', (data) => errors.push(data.toString()));
editor.on('error', (error) => rejectCalls(error));
const exited = new Promise((resolveExit) =>
  editor.once('close', (code, signal) => {
    rejectCalls(new Error('Neovim exited: ' + (signal || code)));
    resolveExit({ code, signal });
  }),
);
(async () => {
  for await (const message of decodeMultiStream(editor.stdout)) {
    if (message[0] === 1) {
      const pending = calls.get(message[1]);
      calls.delete(message[1]);
      if (pending) {
        if (message[2]) pending.reject(new Error(JSON.stringify(message[2])));
        else pending.resolve(message[3]);
      }
    } else if (message[0] === 0) {
      hostActions.push({
        kind: 'request',
        method: message[2],
        params: message[3],
      });
      const result =
        message[2] === 'vscode-action' && message[3][0] === 'get_config'
          ? []
          : null;
      editor.stdin.write(encode([1, message[1], null, result]));
    } else if (message[0] === 2 && message[1] === 'vscode-action') {
      hostActions.push({
        kind: 'notification',
        method: message[1],
        params: message[2],
      });
    }
  }
})().catch((error) => {
  errors.push(error.stack);
  rejectCalls(error);
});
function rpc(method, params = []) {
  return new Promise((resolveCall, reject) => {
    const id = ++sequence;
    calls.set(id, { resolve: resolveCall, reject });
    editor.stdin.write(encode([0, id, method, params]));
  });
}
const deadlineMs = ['rust-debug.lua', 'navigation-performance'].includes(suite)
  ? 120000
  : 60000;
const deadline = setTimeout(() => {
  rejectCalls(new Error('Verification timed out after ' + deadlineMs + ' ms'));
  editor.kill();
}, deadlineMs);
try {
  await rpc('nvim_get_api_info');
  await rpc('nvim_set_client_info', [
    'Configuration verification',
    { major: 1, minor: 0 },
    'ui',
    {},
    {},
  ]);
  await rpc('nvim_ui_attach', [130, 40, { rgb: true, ext_linegrid: true }]);
  await delay(1500);
  if (!host)
    await rpc('nvim_exec_lua', [
      "require('lazy').load({plugins={'blink.cmp'}}); assert(vim.wait(45000,function() return package.loaded['blink.cmp.completion']~=nil end,50),'Blink first-run setup timed out')",
      [],
    ]);
  // Each scenario starts with a fresh error marker after plugin initialization.
  await rpc('nvim_exec_lua', ["vim.v.errmsg=''", []]);
  const file =
    suite === 'workflows'
      ? '../check-workflows.lua'
      : suite === 'host'
        ? 'host.lua'
        : suite;
  const result =
    (uiScenarios[suite]
      ? await uiScenarios[suite](rpc)
      : await rpc('nvim_exec_lua', [
          readFileSync(resolve(directory, file), 'utf8'),
          [],
        ])) ?? {};
  if (host) result.hostActions = hostActions;
  writeFileSync(output, JSON.stringify(result, null, 2) + '\n');
  if (result.failures && Object.keys(result.failures).length)
    throw new Error(JSON.stringify(result.failures));
  if (result.error || result.errmsg)
    throw new Error(result.error || result.errmsg);
  if (host) {
    for (const name of result.expected_actions) {
      if (
        !hostActions.some(
          (action) =>
            action.method === 'vscode-action' && action.params[0] === name,
        )
      ) {
        throw new Error('Host action was not emitted: ' + name);
      }
    }
  }
  editor.stdin.write(encode([2, 'nvim_command', ['qa!']]));
  const exit = await exited;
  if (exit.code !== 0)
    throw new Error('Neovim exited: ' + (exit.signal || exit.code));
  console.log('PASS ' + suite + ' -> ' + output);
} catch (error) {
  errors.push(error.stack);
  console.error(error.stack);
  editor.kill();
  await exited;
  process.exitCode = 1;
} finally {
  clearTimeout(deadline);
  writeFileSync(output + '.errors', errors.join('\n'));
}
