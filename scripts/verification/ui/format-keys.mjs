import { setTimeout as delay } from 'node:timers/promises';
import { readFileSync } from 'node:fs';

export async function verifyFormatKeysUI(rpc) {
  const filename = process.env.NVIM_TEST_ROOT + "/beta/manual 格式's.js";
  const setText = (text) =>
    rpc('nvim_exec_lua', [
      'vim.api.nvim_buf_set_lines(0,0,-1,false,{...})',
      [text],
    ]);
  const text = () =>
    rpc('nvim_exec_lua', [
      "return table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),'\\n')",
      [],
    ]);
  await rpc('nvim_exec_lua', [
    'local file=...; vim.fn.writefile({\'const entry={message:"你好😀"};\'},file); vim.cmd.edit(file)',
    [filename],
  ]);
  await rpc('nvim_input', ['<A-F>']);
  await delay(300);
  const normal = await text();
  if (normal !== "const entry = { message: '你好😀' }")
    throw new Error('Normal format key or project config failed: ' + normal);
  await setText('const entry={message:"第二次😀"};');
  await rpc('nvim_input', ['i<A-F><Esc>']);
  await delay(300);
  const insert = await text();
  if (insert !== "const entry = { message: '第二次😀' }")
    throw new Error('Insert format key failed: ' + insert);
  await setText('const saved={value:2};');
  await rpc('nvim_input', ['<A-s>']);
  await delay(300);
  const saved = readFileSync(filename, 'utf8').trim();
  if (saved !== 'const saved = { value: 2 }')
    throw new Error('Save format key failed: ' + saved);
  const result = {
    normal,
    insert,
    saved,
    errmsg: await rpc('nvim_eval', ['v:errmsg']),
  };
  if (result.errmsg) throw new Error(result.errmsg);
  return result;
}
