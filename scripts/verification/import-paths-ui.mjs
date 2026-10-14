import {mkdtempSync, mkdirSync, writeFileSync, symlinkSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {setTimeout as delay} from 'node:timers/promises';

export async function verifyImportPathsUI(rpc) {
  const root = mkdtempSync(join(tmpdir(), 'nvim-import-paths-'));
  const lua = (code, ...args) => rpc('nvim_exec_lua', [code, args]);
  const input = async keys => { await rpc('nvim_input', [keys]); await delay(100); };
  const data = await lua("return vim.fn.stdpath('data')");
  const modules = join(root, 'node_modules');
  const pkg = join(modules, 'path-fixture');
  mkdirSync(pkg, {recursive: true});
  writeFileSync(join(root, 'package.json'), JSON.stringify({private: true}));
  writeFileSync(join(root, 'tsconfig.json'), JSON.stringify({
    compilerOptions: {
      target: 'ES2022', module: 'ESNext', moduleResolution: 'Bundler',
      allowJs: true, checkJs: true, strict: true, noEmit: true,
    },
    include: ['*.vue', '*.ts'],
  }));
  writeFileSync(join(pkg, 'package.json'), JSON.stringify({name: 'path-fixture', version: '1.0.0'}));
  for (let i = 1; i <= 15; i++) {
    writeFileSync(join(pkg, `module${String(i).padStart(2, '0')}.d.ts`),
      'declare const value: number; export default value;\n');
  }
  // A project SDK is present; vtsls must still select the configured global SDK.
  symlinkSync(join(data, 'mason/packages/vtsls/node_modules/@vtsls/language-server/node_modules/typescript'),
    join(modules, 'typescript'), process.platform === 'win32' ? 'junction' : 'dir');

  const cases = [
    {name: 'script-js', tag: '<script>'},
    {name: 'script-ts', tag: '<script lang="ts">'},
    {name: 'setup-js', tag: '<script setup>'},
    {name: 'setup-ts', tag: '<script setup lang="ts">'},
  ];
  const prefix = "import value from 'path-fixture";
  const results = [];
  let sdk;
  for (const test of cases) {
    await input('<Esc>');
    const file = join(root, `${test.name}.vue`);
    const lines = [test.tag, prefix + "'", ...(test.name.startsWith('setup') ? [] : ['export default {}']),
      '</script>', '<template><div /></template>'];
    writeFileSync(file, lines.join('\n') + '\n');
    await lua(`local file, col = ...; vim.cmd.edit(file)
local buf = vim.api.nvim_get_current_buf()
assert(vim.wait(20000, function()
  local ts = vim.lsp.get_clients({bufnr=buf, name='vtsls'})[1]
  local vue = vim.lsp.get_clients({bufnr=buf, name='vue_ls'})[1]
  return ts and ts.initialized and vue and vue.initialized
end, 50), 'Vue language clients did not initialize')
vim.api.nvim_win_set_cursor(0, {2, col})`, file, prefix.length - 1);

    if (!sdk) {
      sdk = await lua(String.raw`local file = ...
local client = vim.lsp.get_clients({bufnr=0, name='vtsls'})[1]
local reply, err = client:request_sync('workspace/executeCommand', {
  command='typescript.tsserverRequest',
  arguments={'projectInfo', {file=file, needFileNameList=true}},
}, 10000, 0)
assert(reply and not err and not reply.err, vim.inspect(reply or err))
local path = require('lsp.vtsls').settings.vtsls.typescript.globalTsdk
local normalized = vim.fs.normalize(assert(vim.uv.fs_realpath(path))):lower()
local used = false
for _, name in ipairs(reply.result.body.fileNames) do
  if vim.fs.normalize(name):lower():find(normalized, 1, true) then used = true end
end
assert(used, 'vtsls did not use the pinned SDK')
local version = vim.json.decode(table.concat(vim.fn.readfile(vim.fs.dirname(path)..'/package.json'), '\n')).version
assert(version == require('config.mason_tools').versions.typescript_sdk)
return {path=path, version=version}`, file);
    }
    await input('a');
    await lua("require('blink.cmp').hide()");
    await input('/');
    const menu = await lua(`local cmp = require('blink.cmp')
local list = require('blink.cmp.completion.list')
local labels, selected
assert(vim.wait(10000, function()
  labels, selected = {}, nil
  for index, item in ipairs(list.items) do
    local client = item.client_id and vim.lsp.get_client_by_id(item.client_id)
    if client and client.name == 'vtsls' and item.label:find('module', 1, true) then
      labels[#labels+1] = item.label
      if item.label:find('module07', 1, true) then selected = index end
    end
  end
  return #labels == 15 and selected and cmp.is_visible()
end, 20), 'Slash did not automatically show all 15 package paths')
list.select(selected, {auto_insert=false})
return {labels=labels, visible=cmp.is_visible()}`);
    await input('<CR>');
    const accepted = await lua("return {line=vim.api.nvim_buf_get_lines(0,1,2,false)[1], errmsg=vim.v.errmsg}");
    if (accepted.line !== prefix + "/module07'" || accepted.errmsg)
      throw new Error('Enter did not accept the path in ' + test.name + ': ' + JSON.stringify(accepted));
    results.push({name: test.name, ...menu, ...accepted});
    await input('<Esc>');
    await lua('vim.bo.modified=false');
  }

  const html = join(root, 'tags.html');
  writeFileSync(html, '<article\n');
  await lua('vim.cmd.edit(...)', html);
  await input('A>');
  const openingTag = await lua('return vim.api.nvim_get_current_line()');
  if (openingTag !== '<article></article>') throw new Error('Opening-tag autoclose failed: ' + openingTag);
  await input('<Esc>');
  await lua("vim.api.nvim_buf_set_lines(0,0,-1,false,{'<div><'}); vim.api.nvim_win_set_cursor(0,{1,5})");
  await input('A/');
  const closingTag = await lua('return vim.api.nvim_get_current_line()');
  if (closingTag !== '<div></') throw new Error('Closing slash was still intercepted: ' + closingTag);
  await input('<Esc>');
  await lua('vim.bo.modified=false');
  return {root, sdk, completions: results, tags: {openingTag, closingTag}};
}
