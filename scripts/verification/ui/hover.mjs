import { setTimeout as delay } from 'node:timers/promises';

export async function verifyHoverUI(rpc) {
  await rpc('nvim_exec_lua', [
    "vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/refactor.ts'); assert(vim.wait(15000,function() return #vim.lsp.get_clients({bufnr=0,name='vtsls',method='textDocument/hover'})>0 end,50)); vim.api.nvim_win_set_cursor(0,{1,16})",
    [],
  ]);
  const sourceWin = await rpc('nvim_exec_lua', [
    'return vim.api.nvim_get_current_win()',
    [],
  ]);
  const hoverState = () =>
    rpc('nvim_exec_lua', [
      "local wins,details,hover={},{},nil; for _,win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do local ok,source=pcall(vim.api.nvim_win_get_var,win,'textDocument/hover'); local buf=vim.api.nvim_win_get_buf(win); details[#details+1]={win=win,relative=vim.api.nvim_win_get_config(win).relative,source=ok and source or nil,ft=vim.bo[buf].filetype}; if ok then wins[#wins+1]=win; hover={first=vim.api.nvim_buf_get_lines(buf,0,1,false)[1],conceallevel=vim.wo[win].conceallevel,focusable=vim.api.nvim_win_get_config(win).focusable} end end; return {wins=wins,details=details,hover=hover,current=vim.api.nvim_get_current_win(),errmsg=vim.v.errmsg}",
      [],
    ]);
  const waitForHover = async () => {
    for (let i = 0; i < 40; i++) {
      await delay(100);
      const state = await hoverState();
      if (state.wins.length) return state;
    }
    return hoverState();
  };
  const phases = [];
  await rpc('nvim_input', ['<Space>ch']);
  phases.push(await waitForHover());
  await rpc('nvim_input', ['<Esc>']);
  await delay(100);
  phases.push(await hoverState());
  await rpc('nvim_input', ['<Space>ch']);
  phases.push(await waitForHover());
  await rpc('nvim_input', ['<Space>ch']);
  await delay(100);
  phases.push(await hoverState());
  const rendered = await rpc('nvim_exec_lua', [
    `local win=assert(vim.tbl_filter(function(w) return vim.w[w]['textDocument/hover']~=nil end,vim.api.nvim_tabpage_list_wins(0))[1])
local pos=vim.api.nvim_win_get_position(win)
vim.cmd.redraw()
local rows={}
for row=math.max(1,pos[1]),math.min(vim.o.lines,pos[1]+5) do
  local chars={}
  for col=math.max(1,pos[2]),math.min(vim.o.columns,pos[2]+45) do chars[#chars+1]=vim.fn.screenstring(row,col) end
  rows[#rows+1]=table.concat(chars)
end
return {rows=rows,errmsg=vim.v.errmsg}`,
    [],
  ]);
  await rpc('nvim_input', ['<Esc>']);
  await delay(100);
  phases.push(await hoverState());
  await rpc('nvim_input', ['<Space>ch']);
  phases.push(await waitForHover());
  await rpc('nvim_input', ['<C-w>w']);
  await delay(100);
  phases.push(await hoverState());
  await rpc('nvim_input', ['<Esc>']);
  await delay(100);
  phases.push(await hoverState());
  const screen = rendered.rows.join('\n');
  if (
    phases[0].wins.length !== 1 ||
    !phases[0].hover?.first.startsWith('```') ||
    phases[1].wins.length ||
    phases[2].wins.length !== 1 ||
    phases[3].wins.length !== 1 ||
    phases[3].hover?.conceallevel !== 2 ||
    [phases[0], phases[2], phases[3], phases[5], phases[6]].some(
      (phase) => phase.hover?.focusable !== true,
    ) ||
    [phases[0], phases[2], phases[4], phases[5], phases[7]].some(
      (phase) => phase.current !== sourceWin,
    ) ||
    phases[3].current !== phases[3].wins[0] ||
    phases[6].current !== phases[6].wins[0] ||
    screen.includes('```') ||
    !screen.includes('function demo') ||
    rendered.errmsg ||
    phases[4].wins.length ||
    phases[7].wins.length ||
    phases.some((p) => p.errmsg)
  )
    throw new Error(
      'Hover focus, Markdown conceal or Esc behavior failed: ' +
        JSON.stringify({ phases, rendered }),
    );
  return { phases, rendered };
}
