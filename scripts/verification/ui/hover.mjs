import { setTimeout as delay } from 'node:timers/promises';

export async function verifyHoverUI(rpc) {
  await rpc('nvim_exec_lua', [
    "vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/refactor.ts'); assert(vim.wait(15000,function() return #vim.lsp.get_clients({bufnr=0,name='vtsls',method='textDocument/hover'})>0 end,50)); vim.api.nvim_win_set_cursor(0,{1,16})",
    [],
  ]);
  const hoverState = () =>
    rpc('nvim_exec_lua', [
      "local wins,details,hover={},{},nil; for _,win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do local ok,source=pcall(vim.api.nvim_win_get_var,win,'textDocument/hover'); local buf=vim.api.nvim_win_get_buf(win); details[#details+1]={win=win,relative=vim.api.nvim_win_get_config(win).relative,source=ok and source or nil,ft=vim.bo[buf].filetype}; if ok then wins[#wins+1]=win; hover={first=vim.api.nvim_buf_get_lines(buf,0,1,false)[1],conceallevel=vim.wo[win].conceallevel,concealcursor=vim.wo[win].concealcursor} end end; return {wins=wins,details=details,hover=hover,current=vim.api.nvim_get_current_win(),errmsg=vim.v.errmsg}",
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
  await rpc('nvim_exec_lua', ['vim.lsp.buf.hover()', []]);
  phases.push(await waitForHover());
  const foldState = await rpc('nvim_exec_lua', [
    `local win=assert(vim.tbl_filter(function(w) return vim.w[w]['textDocument/hover']~=nil end,vim.api.nvim_tabpage_list_wins(0))[1])
local buf=vim.api.nvim_win_get_buf(win)
assert(vim.wait(1000,function() return require('ufo').hasAttached(buf) end,20),'UFO did not attach to Hover buffer')
require('ufo').enableFold(buf)
vim.wait(2000)
return {buftype=vim.bo[buf].buftype,filetype=vim.bo[buf].filetype,errmsg=vim.v.errmsg,messages=vim.api.nvim_exec2('messages',{output=true}).output}`,
    [],
  ]);
  await rpc('nvim_input', ['<Esc>']);
  await delay(100);
  phases.push(await hoverState());
  await rpc('nvim_exec_lua', ['vim.lsp.buf.hover()', []]);
  phases.push(await waitForHover());
  await rpc('nvim_exec_lua', ['vim.lsp.buf.hover()', []]);
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
  const screen = rendered.rows.join('\n');
  if (
    foldState.buftype !== 'nofile' ||
    foldState.filetype !== 'markdown' ||
    foldState.errmsg ||
    foldState.messages.includes('UnhandledPromiseRejection') ||
    phases[0].wins.length !== 1 ||
    !phases[0].hover?.first.startsWith('```') ||
    phases[1].wins.length ||
    phases[2].wins.length !== 1 ||
    phases[3].current !== phases[3].wins[0] ||
    phases[3].hover?.conceallevel !== 2 ||
    !phases[3].hover?.concealcursor.includes('n') ||
    screen.includes('```') ||
    !screen.includes('function demo') ||
    rendered.errmsg ||
    phases[4].wins.length ||
    phases.some((p) => p.errmsg)
  )
    throw new Error(
      'Hover folding, Markdown conceal or Esc behavior failed: ' +
        JSON.stringify({ foldState, phases, rendered }),
    );
  const result = { foldState, phases, rendered };
  return result;
}
