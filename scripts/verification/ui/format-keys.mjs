import { readFileSync } from 'node:fs';
import { waitFor } from './wait.mjs';

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
  const normal = await waitFor(
    text,
    (value) => value === "const entry = { message: '你好😀' }",
    'Normal format key or project config failed',
  );
  await setText('const entry={message:"第二次😀"};');
  await rpc('nvim_input', ['i<A-F><Esc>']);
  const insert = await waitFor(
    text,
    (value) => value === "const entry = { message: '第二次😀' }",
    'Insert format key failed',
  );
  await setText('const saved={value:2};');
  await rpc('nvim_input', ['<A-s>']);
  const saved = await waitFor(
    () => readFileSync(filename, 'utf8').trim(),
    (value) => value === 'const saved = { value: 2 }',
    'Save format key failed',
  );
  const result = {
    normal,
    insert,
    saved,
    errmsg: await rpc('nvim_eval', ['v:errmsg']),
  };
  if (result.errmsg) throw new Error(result.errmsg);
  return result;
}
