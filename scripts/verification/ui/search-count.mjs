import { setTimeout as delay } from 'node:timers/promises';

export async function verifySearchCountUI(rpc) {
  await rpc('nvim_exec_lua', [
    "vim.cmd.enew(); vim.api.nvim_buf_set_lines(0,0,-1,false,{'needle%value first','x','needle%value second','needle%value third'}); vim.api.nvim_win_set_cursor(0,{1,0})",
    [],
  ]);
  const state = () =>
    rpc('nvim_exec_lua', [
      'local row=vim.fn.screenpos(0,vim.api.nvim_win_get_cursor(0)[1],1).row; local text={}; for col=1,vim.o.columns do text[#text+1]=vim.fn.screenstring(row,col) end; return {source=vim.api.nvim_get_current_line(),text=table.concat(text),hlsearch=vim.v.hlsearch,pattern=vim.fn.getreg("/"),errmsg=vim.v.errmsg}',
      [],
    ]);
  const phases = [];
  for (const [keys, count] of [
    ['<A-f>needle%value<CR>', '[2/3]'],
    ['n', '[3/3]'],
    ['N', '[2/3]'],
  ]) {
    await rpc('nvim_input', [keys]);
    await delay(150);
    const current = await state();
    if (
      !current.text.trimEnd().endsWith(current.source + '  ' + count) ||
      current.errmsg
    )
      throw new Error(
        'Noice search count was not compact: ' +
          JSON.stringify({ keys, count, current }),
      );
    phases.push({ keys, ...current });
  }
  await rpc('nvim_input', ['<Esc>']);
  await delay(150);
  const cleared = await state();
  if (
    cleared.hlsearch !== 0 ||
    cleared.pattern !== 'needle%value' ||
    cleared.text.includes('[2/3]') ||
    cleared.errmsg
  )
    throw new Error(
      'Noice search count did not clear: ' + JSON.stringify(cleared),
    );
  const resumed = [];
  for (const [keys, source] of [
    ['n', 'needle%value third'],
    ['n', 'needle%value first'],
    ['N', 'needle%value third'],
    ['N', 'needle%value second'],
  ]) {
    await rpc('nvim_input', [keys]);
    await delay(150);
    const current = await state();
    if (current.source !== source || current.errmsg)
      throw new Error(
        'Search did not resume after Esc: ' + JSON.stringify({ keys, current }),
      );
    resumed.push({ keys, ...current });
  }
  const result = { phases, cleared, resumed };
  return result;
}
