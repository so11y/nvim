import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';

export async function verifyUnoCSSUI(rpc) {
  const root = mkdtempSync(join(tmpdir(), 'nvim-unocss-ui-'));
  const lua = (code, ...args) => rpc('nvim_exec_lua', [code, args]);
  const input = async (keys) => {
    await rpc('nvim_input', [keys]);
    await delay(100);
  };
  writeFileSync(join(root, 'package.json'), '{"private":true}\n');
  writeFileSync(
    join(root, 'uno.config.ts'),
    `export default {
  theme: { colors: { brand: '#12ab34' } },
  shortcuts: { 'qa-button': 'px-4 py-2 bg-brand' },
};
`,
  );

  const cases = [
    {
      name: 'html',
      ext: 'html',
      before: '<div class="',
      value: 'bg-red-5',
      after: '"></div>',
      label: 'bg-red-500',
    },
    {
      name: 'vue-theme',
      ext: 'vue',
      before: '<template><div class="',
      value: 'bg-br',
      after: '" /></template>',
      label: 'bg-brand',
    },
    {
      name: 'tsx-variant',
      ext: 'tsx',
      before: 'export const view = <div className="',
      value: 'hover:bg-br',
      after: '" />;',
      label: 'hover:bg-brand',
    },
    {
      name: 'vue-shortcut',
      ext: 'vue',
      before: '<template><div class="',
      value: 'qa-b',
      after: '" /></template>',
      label: 'qa-button',
    },
  ];
  const results = [];
  for (const test of cases) {
    await input('<Esc>');
    const file = join(root, test.name + '.' + test.ext);
    const prefix = test.before + test.value.slice(0, -1);
    writeFileSync(file, prefix + test.after + '\n');
    await lua(
      `local file, col = ...
vim.cmd.edit(file)
assert(vim.wait(15000, function()
  local client = vim.lsp.get_clients({bufnr=0, name='unocss'})[1]
  return client and client.initialized
end, 50), 'UnoCSS did not attach to its project')
vim.api.nvim_win_set_cursor(0, {1, col})`,
      file,
      Buffer.byteLength(prefix),
    );
    await input('i');
    await lua("require('blink.cmp').hide()");
    await input(test.value.slice(-1));
    const menu = await lua(
      `local expected = ...
local cmp = require('blink.cmp')
local list = require('blink.cmp.completion.list')
local selected
assert(vim.wait(10000, function()
  selected = nil
  for index, item in ipairs(list.items) do
    local client = item.client_id and vim.lsp.get_client_by_id(item.client_id)
    if client and client.name == 'unocss' and item.label == expected then
      selected = index
      break
    end
  end
  return selected and cmp.is_visible()
end, 20), 'UnoCSS completion missing: ' .. expected)
list.select(selected, {auto_insert=false})
return {label=list.items[selected].label, source='unocss'}`,
      test.label,
    );
    await input('<Tab>');
    const accepted = await lua(
      'return {line=vim.api.nvim_get_current_line(), errmsg=vim.v.errmsg}',
    );
    if (
      accepted.line !== test.before + test.label + test.after ||
      accepted.errmsg
    )
      throw new Error(test.name + ': ' + JSON.stringify(accepted));
    results.push({ name: test.name, ...menu, ...accepted });
    await input('<Esc>');
    await lua('vim.bo.modified=false');
  }

  const plain = mkdtempSync(join(tmpdir(), 'nvim-without-unocss-'));
  const plainFile = join(plain, 'plain.html');
  writeFileSync(plainFile, '<div class="bg-red-500"></div>\n');
  await lua('vim.cmd.edit(...)', plainFile);
  await delay(300);
  await lua(`assert(not vim.fs.root(0, vim.lsp.config.unocss.root_markers))
assert(#vim.lsp.get_clients({bufnr=0, name='unocss'})==0,
  'UnoCSS attached outside a configured project')`);
  return { root, completions: results, plainProjectSkipped: true };
}
