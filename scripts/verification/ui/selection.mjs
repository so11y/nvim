import { setTimeout as delay } from 'node:timers/promises';

export async function verifySelectionUI(rpc) {
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
  const result = { results };
  return result;
}
