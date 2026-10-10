import {mkdtempSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {setTimeout as delay} from 'node:timers/promises';

export async function verifyMulticursorUI(rpc) {
  const root = mkdtempSync(join(tmpdir(), 'nvim-multicursor-ui-'));
  const lua = (code, ...args) => rpc('nvim_exec_lua', [code, args]);
  const input = async keys => { await rpc('nvim_input', [keys]); await delay(120); };
  const state = () => lua(`
    return {mode=vim.fn.mode(),lines=vim.api.nvim_buf_get_lines(0,0,-1,false),
      active=vim.b.visual_multi==1,regions=vim.b.visual_multi==1 and #vim.b.VM_Selection.Regions or 0,
      cursor=vim.api.nvim_win_get_cursor(0),messages=vim.api.nvim_exec2('messages',{output=true}).output}
  `);
  const expect = async (label, lines, mode='i') => {
    const actual = await state();
    if (JSON.stringify(actual.lines) !== JSON.stringify(lines) || actual.mode !== mode)
      throw new Error(label + ': ' + JSON.stringify(actual));
    return {label,...actual};
  };
  let sequence=0;
  const open = async lines => {
    await input('<Esc>');
    await lua("if vim.b.visual_multi==1 then vim.cmd.VMClear() end");
    const file=join(root,`case-${++sequence}.txt`);
    writeFileSync(file,lines.join('\n')+'\n');
    await lua("vim.cmd.edit(...);vim.api.nvim_win_set_cursor(0,{1,0});vim.o.clipboard='';vim.bo.autoindent=false",file);
  };
  await lua(`local plugins=require('lazy.core.config').plugins
    assert(plugins['vim-visual-multi'] and not plugins['multicursor.nvim'])
    assert(vim.g.VM_live_editing==1)`);

  await open(['abc','abc','abc']);
  await input('<A-J>'); await input('<A-J>'); await input('mi');
  const realtime=[];
  await input('X'); realtime.push(await expect('First character before Escape',['Xabc','Xabc','Xabc']));
  await input('ABCD'); realtime.push(await expect('Continuous input',['XABCDabc','XABCDabc','XABCDabc']));
  await input('中文'); realtime.push(await expect('Chinese input',['XABCD中文abc','XABCD中文abc','XABCD中文abc']));
  await input('<BS>'); realtime.push(await expect('Backspace',['XABCD中abc','XABCD中abc','XABCD中abc']));
  await input('('); realtime.push(await expect('Parenthesis',['XABCD中(abc','XABCD中(abc','XABCD中(abc']));
  await input('<CR>'); realtime.push(await expect('Newline',['XABCD中(','abc','XABCD中(','abc','XABCD中(','abc']));
  await input('同步'); realtime.push(await expect('Input after newline',['XABCD中(','同步abc','XABCD中(','同步abc','XABCD中(','同步abc']));
  const integrations = await lua(`
    local blink=require('blink.cmp.config')
    local pairs=require('nvim-autopairs').config
    assert(not blink.enabled())
    assert(not pairs.enabled(vim.api.nvim_get_current_buf()))
    return {completion_paused=true,autopairs_paused=true}
  `);
  await input('<Esc>'); await input('<Esc>');
  await lua(`assert(vim.b.visual_multi~=1)
    assert(require('blink.cmp.config').enabled())
    assert(require('nvim-autopairs').config.enabled(vim.api.nvim_get_current_buf()))
    assert(vim.fn.maparg('u','n')=='<Nop>')
    assert(vim.fn.maparg('dd','n')=='<Nop>')`);
  integrations.restored=true;

  await open(['one','middle','two']);
  await input('mc'); await input('jj'); await input('mc'); await input('mm'); await input('l'); await input('mi');
  await input('Z'); const manual=await expect('Manual marks and enabled movement',['oZne','middle','tZwo']);
  await input('<Esc>'); await input('<Esc>');
  if ((await state()).active) throw new Error('Escape did not clear cursors');

  await open(['abc','abc']);
  await input('<A-J>'); await input('ma'); await input('!');
  const append=await expect('Append after each cursor',['a!bc','a!bc']);

  await open(['foo = 1','foo = 2','other = 3']);
  await input('gb'); await input('gb'); await input('c'); await input('bar');
  const matches=await expect('Replace selected occurrences',['bar = 1','bar = 2','other = 3']);

  await open(['foo','foo']);
  await input('i'); await input('gb'); await input('gb'); await input('X');
  const insertMatches=await expect('Select matches while inserting',['Xfoo','Xfoo']);

  await open(['abc','abc']);
  await input('<A-J>'); await input('<CR>'); await input('Q');
  const enter=await expect('Enter appends at all cursors',['aQbc','aQbc']);

  await open(['abc','abc','abc']);
  await input('i'); await input('<A-J>'); await input('<A-J>'); await input('T');
  const insertAdd=await expect('Add cursors while inserting',['Tabc','Tabc','Tabc']);

  await open(['abc','abc']);
  await input('l'); await input('i'); await input('<A-J>'); await input('T');
  const insertAtColumn=await expect('Keep insertion column when adding cursors',['aTbc','aTbc']);

  await open(['abc','abc']);
  await input('A'); await input('<A-J>'); await input('T');
  const insertAtEnd=await state();
  // VM keeps a temporary cursor space at EOL while inserting.
  if (insertAtEnd.mode !== 'i' || insertAtEnd.lines.some(line => line.trimEnd() !== 'abcT'))
    throw new Error('Live insertion at end of line: '+JSON.stringify(insertAtEnd));
  await input('<Esc>');
  await expect('End of line after insertion',['abcT','abcT'],'n');

  await open(['abc','abc']);
  await input('v'); await input('l'); await input('<A-J>');
  await expect('Add cursors from visual mode',['abc','abc'],'n');
  await input('mi'); await input('W');
  const visualAdd=await expect('Edit cursors added from visual mode',['aWbc','aWbc']);

  await open(['abc','abc']);
  await input('<A-J>'); await input('mi');
  await rpc('nvim_paste',['PASTE',false,-1]); await delay(120);
  const paste=await expect('Paste at all cursors',['PASTEabc','PASTEabc']);

  await input('<Esc>'); await input('<Esc>');
  await open(['']); await input('i'); await input('(');
  const restoredPairs=await expect('Automatic pairs after exiting',['()']);
  await input('<Esc>');
  return {root,realtime,manual,append,matches,insertMatches,enter,insertAdd,insertAtColumn,insertAtEnd,visualAdd,paste,restoredPairs,integrations,messages:(await state()).messages};
}
