import { setTimeout as delay } from 'node:timers/promises';

export async function verifyNavigationPerformanceUI(rpc) {
  const setup = await rpc('nvim_exec_lua', [
    `vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/refactor.ts')
assert(vim.wait(15000,function() return #vim.lsp.get_clients({bufnr=0,name='vtsls'})>0 end,50))
local lines={}
for i=1,600 do vim.list_extend(lines,{('export function nav%d() {'):format(i),'  const value = 1;','  return value;','}'}) end
lines[2]='// '..string.rep('x',1500)
vim.api.nvim_buf_set_lines(0,0,-1,false,lines)
_G.__navigation_maps={j=vim.fn.maparg('j','n',false,true),k=vim.fn.maparg('k','n',false,true)}
local autocmds={}
for _,autocmd in ipairs(vim.api.nvim_get_autocmds({event='CursorMoved',buffer=0})) do
 autocmds[#autocmds+1]={group=autocmd.group_name,desc=autocmd.desc}
end
return {line_count=vim.api.nvim_buf_line_count(0),filetype=vim.bo.filetype,has_motion=vim.fn.maparg(']f','n')~='',cursor_moved=autocmds}`,
    [],
  ]);
  await delay(1500);
  const samples = [];
  async function measure(
    key,
    mapped,
    start,
    expected,
    steps = 300,
    ignoreCursorMoved = false,
  ) {
    await rpc('nvim_exec_lua', [
      `local key='${key}'; local saved=_G.__navigation_maps[key]
pcall(vim.keymap.del,'n',key)
if ${mapped} then vim.keymap.set('n',key,saved.rhs,{expr=saved.expr==1}) end
vim.o.eventignore=${ignoreCursorMoved ? "'CursorMoved'" : "''"}
vim.api.nvim_win_set_cursor(0,{${start[0]},${start[1]}})
vim.g.navigation_done=0`,
      [],
    ]);
    await delay(100);
    const started = performance.now();
    await rpc('nvim_input', [
      key.repeat(steps) + ':let g:navigation_done=1<CR>',
    ]);
    while (!(await rpc('nvim_get_var', ['navigation_done']))) await delay(2);
    const elapsed = performance.now() - started;
    const cursor = await rpc('nvim_win_get_cursor', [0]);
    if (JSON.stringify(cursor) !== JSON.stringify(expected))
      throw new Error(
        'Navigation target failed: ' +
          JSON.stringify({ key, mapped, cursor, expected }),
      );
    samples.push({
      key,
      mapped,
      ignoreCursorMoved,
      elapsed_ms: elapsed,
      steps,
      per_key_ms: elapsed / steps,
    });
  }
  for (let i = 0; i < 7; i++) {
    for (const mapped of i % 2 === 0 ? [true, false] : [false, true]) {
      await measure('j', mapped, [100, 0], [400, 0]);
      await measure('k', mapped, [400, 0], [100, 0]);
    }
  }
  await measure('l', false, [2, 500], [2, 800]);
  await measure('h', false, [2, 800], [2, 500]);
  for (let i = 0; i < 5; i++)
    for (const ignoreCursorMoved of i % 2 === 0
      ? [false, true]
      : [true, false]) {
      await measure('j', true, [100, 0], [400, 0], 300, ignoreCursorMoved);
    }
  await rpc('nvim_exec_lua', ["vim.o.eventignore=''", []]);
  await rpc('nvim_exec_lua', [
    `for key,saved in pairs(_G.__navigation_maps) do vim.keymap.set('n',key,saved.rhs,{expr=saved.expr==1}) end`,
    [],
  ]);
  async function inputAndWait(keys) {
    await rpc('nvim_set_var', ['navigation_done', 0]);
    const started = performance.now();
    await rpc('nvim_input', [keys + ':let g:navigation_done=1<CR>']);
    while (!(await rpc('nvim_get_var', ['navigation_done']))) await delay(2);
    return {
      elapsed_ms: performance.now() - started,
      cursor: await rpc('nvim_win_get_cursor', [0]),
    };
  }
  await rpc('nvim_win_set_cursor', [0, [1, 7]]);
  const ast = [];
  const first = await inputAndWait(']f');
  if (first.cursor[0] !== 5)
    throw new Error(
      'AST forward jump failed: ' + JSON.stringify({ setup, first }),
    );
  ast.push({ keys: ']f', ...first });
  const counted = await inputAndWait('3]f');
  ast.push({ keys: '3]f', ...counted });
  await rpc('nvim_win_set_cursor', [0, first.cursor]);
  for (let i = 0; i < 3; i++)
    ast.push({ keys: ']f repeated', ...(await inputAndWait(']f')) });
  if (JSON.stringify(ast.at(-1).cursor) !== JSON.stringify(counted.cursor))
    throw new Error(
      'AST count differs from three jumps: ' + JSON.stringify(ast),
    );
  const backward = await inputAndWait('[f');
  const repeatNext = await inputAndWait(';');
  const repeatPrevious = await inputAndWait(',');
  ast.push(
    { keys: '[f', ...backward },
    { keys: ';', ...repeatNext },
    { keys: ',', ...repeatPrevious },
  );
  if (
    JSON.stringify(repeatNext.cursor) !== JSON.stringify(counted.cursor) ||
    JSON.stringify(repeatPrevious.cursor) !== JSON.stringify(backward.cursor)
  )
    throw new Error('AST repeat direction failed: ' + JSON.stringify(ast));
  const before = await rpc('nvim_exec_lua', [
    'vim.api.nvim_win_set_cursor(0,{2,3}); return #vim.api.nvim_get_current_line()',
    [],
  ]);
  const editing = await inputAndWait('i' + 'y'.repeat(100) + '<Esc>');
  const after = await rpc('nvim_exec_lua', [
    'return {length=#vim.api.nvim_get_current_line(),mode=vim.fn.mode(),errmsg=vim.v.errmsg}',
    [],
  ]);
  if (after.length !== before + 100 || after.mode !== 'n' || after.errmsg)
    throw new Error(
      'Editing sequence failed: ' + JSON.stringify({ before, editing, after }),
    );
  const search = [];
  for (let i = 0; i < 5; i++)
    for (const active of i % 2 === 0 ? [true, false] : [false, true]) {
      await rpc('nvim_exec_lua', [
        `vim.fn.setreg('/','${active ? 'value' : ''}'); vim.o.hlsearch=true`,
        [],
      ]);
      const state = await rpc('nvim_exec_lua', [
        "return {hlsearch=vim.v.hlsearch,pattern=vim.fn.getreg('/'),statusline=vim.o.statusline}",
        [],
      ]);
      if (state.pattern !== (active ? 'value' : ''))
        throw new Error('Search pattern mismatch: ' + JSON.stringify(state));
      await measure('j', true, [100, 0], [400, 0]);
      search.push({ active, ...state, ...samples.at(-1) });
    }
  const editSamples = [];
  for (let i = 0; i < 5; i++)
    for (const active of i % 2 === 0 ? [true, false] : [false, true]) {
      await rpc('nvim_exec_lua', [
        `vim.api.nvim_buf_set_lines(0,1,2,false,{'// '..string.rep('x',1500)}); vim.api.nvim_win_set_cursor(0,{2,3}); vim.fn.setreg('/','${active ? 'value' : ''}'); vim.o.hlsearch=true`,
        [],
      ]);
      await delay(100);
      const phase = await inputAndWait('i' + 'y'.repeat(100) + '<Esc>');
      const length = await rpc('nvim_exec_lua', [
        'return #vim.api.nvim_get_current_line()',
        [],
      ]);
      if (length !== 1603)
        throw new Error(
          'Search editing length mismatch: ' +
            JSON.stringify({ active, phase, length }),
        );
      editSamples.push({ active, elapsed_ms: phase.elapsed_ms, length });
      await delay(200);
    }
  const result = { setup, samples, ast, editing, after, search, editSamples };
  return result;
}
