import assert from 'node:assert/strict';
import { setTimeout as delay } from 'node:timers/promises';

async function verifyCursorline(rpc) {
  const lua = (code) => rpc('nvim_exec_lua', [code, []]);
  const input = async (keys) => {
    await rpc('nvim_input', [keys]);
    await delay(50);
  };
  const buf = await lua(`require('persistence').stop()
local buf=vim.api.nvim_create_buf(true,false)
vim.api.nvim_set_current_buf(buf)
vim.api.nvim_buf_set_lines(buf,0,-1,false,{'first plain line','second plain line','third plain line'})
vim.bo.filetype='text'
vim.api.nvim_win_set_cursor(0,{2,0})
return buf`);
  // The first screen inspection rebuilds Neovim's highlight table.
  await lua('vim.api.nvim__inspect_cell(1,0,0)');
  await delay(50);
  const snapshot = () => lua(`vim.cmd('redraw!')
local win=vim.api.nvim_get_current_win()
local row=vim.api.nvim_win_get_cursor(win)[1]
local point=vim.fn.screenpos(win,row,1)
local other=vim.fn.screenpos(win,row==2 and 3 or 2,1)
local start=vim.fn.win_screenpos(win)[2]
local normal=vim.api.nvim_get_hl(0,{name='Normal',link=false}).bg
local function background(row,col)
 local cell=vim.api.nvim__inspect_cell(1,row-1,col-1)
 return cell[2].background or normal
end
local result={mode=vim.fn.mode(),text=background(point.row,point.col+10),
 tail=background(point.row,point.col+25),selected=background(point.row,point.col),
 gutter=background(point.row,start),other=background(other.row,other.col+10),errmsg=vim.v.errmsg}
for _,inactive in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
 if inactive~=win and vim.api.nvim_win_get_buf(inactive)==vim.api.nvim_get_current_buf() then
  local p=vim.fn.screenpos(inactive,2,1)
  result.inactive=background(p.row,p.col+10)
 end
end
local ns=vim.api.nvim_get_namespaces().CursorLineSelection
result.marks=#vim.api.nvim_buf_get_extmarks(0,ns,0,-1,{})
return result`);
  const continuous = (state) => {
    assert.notEqual(state.text, state.other, 'Cursor line disappeared from editor text');
    assert.equal(state.text, state.tail, 'Cursor line stops at the end of the text');
    assert.equal(state.text, state.gutter, 'Gutter and editor text have different cursor line backgrounds');
    assert.equal(state.marks, 0, 'Cursor line left persistent buffer decorations');
    assert.equal(state.errmsg, '');
  };
  const normal = await snapshot();
  continuous(normal);
  const selections = [];
  for (const [keys, mode] of [['v2l', 'v'], ['<C-v>2l', '\u0016'], ['v2l<C-g>', 's']]) {
    await lua('vim.api.nvim_win_set_cursor(0,{2,0})');
    await input(keys);
    const state = await snapshot();
    assert.equal(state.mode, mode);
    continuous(state);
    assert.notEqual(state.selected, state.text, 'Selection color was hidden by the cursor line');
    selections.push(state);
    await input('<Esc>');
  }
  await lua('vim.api.nvim_win_set_cursor(0,{3,0})');
  await input('v2l');
  const lastLine = await snapshot();
  continuous(lastLine);
  await lua('vim.wo.cursorline=false');
  const disabled = await snapshot();
  assert.equal(disabled.text, disabled.other, 'Disabled cursor line is still visible');
  await lua('vim.wo.cursorline=true');
  await input('<Esc>');
  const moved = await snapshot();
  continuous(moved);
  await lua("vim.cmd.vsplit();vim.api.nvim_win_set_cursor(0,{2,0})");
  await input('v2l');
  const split = await snapshot();
  continuous(split);
  assert.equal(split.inactive, split.other, 'Selection cursor line leaked into the other window');
  await input('<Esc>');
  await lua(`vim.cmd.close();vim.bo.modified=false;vim.cmd.enew();vim.api.nvim_buf_delete(${buf},{force=true})`);
  return { normal, selections, lastLine, disabled, moved, split };
}

export async function verifySelectionUI(rpc) {
  const cursorline = await verifyCursorline(rpc);
  const cases = [
    { name: 'typescript', file: 'refactor.ts', row: 2, needle: 'a + b' },
    { name: 'vue-script', file: 'App.vue', row: 3, needle: 'ref' },
    { name: 'vue-function', file: 'App.vue', row: 5, needle: 'count' },
    { name: 'vue-template', file: 'App.vue', row: 7, needle: 'greet' },
  ];
  const range = (p) => JSON.stringify([p.start, p.cursor]);
  const selected = () =>
    rpc('nvim_exec_lua', [
      'return {mode=vim.fn.mode(),start=vim.fn.getpos("v"),cursor=vim.api.nvim_win_get_cursor(0),errmsg=vim.v.errmsg}',
      [],
    ]);
  const results = [];
  for (const c of cases) {
    await rpc('nvim_exec_lua', [
      `vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/${c.file}'); assert(vim.wait(15000,function() return vim.treesitter.get_parser(0,nil,{error=false})~=nil end,50)); local line=vim.api.nvim_buf_get_lines(0,${c.row - 1},${c.row},false)[1]; vim.api.nvim_win_set_cursor(0,{${c.row},assert(line:find('${c.needle}',1,true))-1})`,
      [],
    ]);
    const phases = [];
    for (const keys of ['v', '<CR>', '<CR>', '<BS>']) {
      await rpc('nvim_input', [keys]);
      await delay(100);
      phases.push(await selected());
    }
    if (
      phases.some((p) => p.mode !== 'v' || p.errmsg) ||
      range(phases[0]) === range(phases[1]) ||
      range(phases[1]) === range(phases[2]) ||
      range(phases[1]) !== range(phases[3])
    )
      throw new Error(
        'Selection expansion/contraction failed for ' +
          c.name +
          ': ' +
          JSON.stringify(phases),
      );
    const growth = [];
    for (let i = 0; i < 20; i++) {
      await rpc('nvim_input', ['<CR>']);
      await delay(30);
      growth.push(await selected());
    }
    const root = growth.at(-1);
    if (root.start[1] !== 1 || root.start[2] !== 1)
      throw new Error(
        'Selection did not reach file root for ' +
          c.name +
          ': ' +
          JSON.stringify(root),
      );
    if (
      c.name === 'vue-function' &&
      !growth.some(
        (p) => p.start[1] === 5 && p.start[2] === 1 && p.cursor[0] === 5,
      )
    )
      throw new Error(
        'Selection skipped Vue function node: ' + JSON.stringify(growth),
      );
    if (
      c.name === 'vue-template' &&
      !growth.some(
        (p) =>
          p.start[1] === 7 &&
          p.start[2] === 11 &&
          p.cursor[0] === 7 &&
          p.cursor[1] >= 62,
      )
    )
      throw new Error(
        'Selection skipped Vue template tag: ' + JSON.stringify(growth),
      );
    const levels = [phases[1], phases[2], ...growth].filter(
      (p, i, all) => i === 0 || range(p) !== range(all[i - 1]),
    );
    const shrink = [];
    for (let i = levels.length - 2; i >= 0; i--) {
      await rpc('nvim_input', ['<BS>']);
      await delay(30);
      const p = await selected();
      shrink.push(p);
      if (range(p) !== range(levels[i]))
        throw new Error(
          'Selection did not shrink through ' +
            c.name +
            ' level ' +
            i +
            ': ' +
            JSON.stringify({ levels, shrink }),
        );
    }
    results.push({ name: c.name, phases, growth: levels.slice(2), shrink });
    await rpc('nvim_input', ['<Esc>']);
    await delay(50);
  }
  const result = { results, cursorline };
  return result;
}
