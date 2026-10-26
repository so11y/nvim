import { setTimeout as delay } from 'node:timers/promises';
import { readFileSync } from 'node:fs';

export async function verifyTypescriptRefactorUI(rpc) {
  const setup = await rpc('nvim_exec_lua', [
    readFileSync(
      new URL('../typescript-refactor.lua', import.meta.url),
      'utf8',
    ),
    [],
  ]);
  await delay(150);
  await rpc('nvim_input', ['<C-u>sumValue<CR>']);
  await delay(200);
  const applied = await rpc('nvim_exec_lua', [
    `local b=...
assert(vim.wait(10000,function()
 return table.concat(vim.api.nvim_buf_get_lines(b,0,-1,false)):find('function sumValue',1,true)~=nil
end,50),'Extracted function could not be renamed')
return {text=vim.api.nvim_buf_get_lines(b,0,-1,false),errmsg=vim.v.errmsg}`,
    [setup.bufnr],
  ]);
  if (applied.errmsg) throw new Error(applied.errmsg);
  const result = { ...setup, ...applied, rename_applied: true };
  return result;
}
