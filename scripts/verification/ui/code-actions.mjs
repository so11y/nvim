import { setTimeout as delay } from 'node:timers/promises';

export async function verifyCodeActionsUI(rpc) {
  const setup = await rpc('nvim_exec_lua', [
    `vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/TagActions.html')
assert(vim.wait(5000,function() return #vim.lsp.get_clients({bufnr=0,name='tag_fix'})==1 end,20))
local bufnr=vim.api.nvim_get_current_buf()
local client=vim.lsp.get_clients({bufnr=bufnr,name='tag_fix'})[1]
local line='const 文本 = "😀"; const value = 1;'
vim.api.nvim_buf_set_lines(bufnr,0,-1,false,{line})
local col=assert(line:find('value',1,true))-1
vim.api.nvim_win_set_cursor(0,{1,col})
local edit={changes={[vim.uri_from_bufnr(bufnr)]={{range={start={line=0,character=col},['end']={line=0,character=col+5}},newText='applied'}}}}
local actions={}
for i=1,12 do actions[i]={title=('Action %02d'):format(i),edit=edit,kind='quickfix'} end
actions[12].title='Action with a command'
actions[12].command={title='After edit',command='verify.saga.action'}
_G.__action_ui={bufnr=bufnr,client=client,original=vim.lsp.buf_request_all,actions=actions,before=line,commands=0}
client.commands['verify.saga.action']=function()
 assert(vim.api.nvim_buf_get_lines(bufnr,0,-1,false)[1]:find('const applied =',1,true),'Command ran before its edit')
 _G.__action_ui.commands=_G.__action_ui.commands+1
end
vim.lsp.buf_request_all=function(buf,method,params,callback)
 local state=_G.__action_ui
 callback({[state.client.id]={result=state.actions}})
end
vim.cmd.Lspsaga('code_action')
return {before=line}`,
    [],
  ]);
  await delay(150);
  const snapshot = () =>
    rpc('nvim_exec_lua', [
      `local saga=require('lspsaga.codeaction')
local preview={}
for _,win in ipairs(vim.api.nvim_list_wins()) do
 local buf=vim.api.nvim_win_get_buf(win)
 if vim.bo[buf].filetype=='diff' and vim.api.nvim_win_get_config(win).relative~='' then
  preview=vim.api.nvim_buf_get_lines(buf,0,-1,false)
 end
end
return {config=vim.api.nvim_win_get_config(saga.action_winid),lines=vim.api.nvim_buf_get_lines(saga.action_bufnr,0,-1,false),height=vim.api.nvim_win_get_height(saga.action_winid),preview=preview,unchanged=vim.api.nvim_buf_get_lines(_G.__action_ui.bufnr,0,-1,false)[1]==_G.__action_ui.before,errmsg=vim.v.errmsg}`,
      [],
    ]);
  const shown = await snapshot();
  if (shown.lines.length !== 12 || !shown.unchanged || shown.errmsg)
    throw new Error('Saga action list failed: ' + JSON.stringify(shown));
  await rpc('nvim_input', ['j']);
  await delay(150);
  const previewed = await snapshot();
  if (
    shown.preview.length ||
    previewed.preview.length ||
    !previewed.unchanged ||
    previewed.errmsg
  )
    throw new Error(
      'Saga navigation opened a preview or changed source: ' +
        JSON.stringify({ shown, previewed }),
    );
  await rpc('nvim_input', ['<Esc>']);
  await delay(100);
  const cancelled = await rpc('nvim_exec_lua', [
    `local saga=require('lspsaga.codeaction')
return {unchanged=vim.api.nvim_buf_get_lines(_G.__action_ui.bufnr,0,-1,false)[1]==_G.__action_ui.before,closed=not (saga.action_winid and vim.api.nvim_win_is_valid(saga.action_winid))}`,
    [],
  ]);
  if (!cancelled.unchanged || !cancelled.closed)
    throw new Error('Saga cancellation failed: ' + JSON.stringify(cancelled));
  await rpc('nvim_exec_lua', ["vim.cmd.Lspsaga('code_action')", []]);
  await delay(100);
  await rpc('nvim_input', ['j'.repeat(11)]);
  await delay(100);
  await rpc('nvim_input', ['<Tab>']);
  await delay(150);
  const applied = await rpc('nvim_exec_lua', [
    `local state=_G.__action_ui
local line=vim.api.nvim_buf_get_lines(state.bufnr,0,-1,false)[1]
vim.cmd.undo()
return {line=line,commands=state.commands,errmsg=vim.v.errmsg}`,
    [],
  ]);
  if (
    !applied.line.includes('const applied =') ||
    !applied.line.includes('😀') ||
    applied.commands !== 1 ||
    applied.errmsg
  )
    throw new Error(
      'Saga Tab, Unicode edit or command failed: ' + JSON.stringify(applied),
    );
  await rpc('nvim_exec_lua', ["vim.cmd.Lspsaga('code_action')", []]);
  await delay(100);
  await rpc('nvim_input', ['2']);
  await delay(150);
  const numbered = await rpc('nvim_exec_lua', [
    `local state=_G.__action_ui
local line=vim.api.nvim_buf_get_lines(state.bufnr,0,-1,false)[1]
state.actions={}
vim.cmd.Lspsaga('code_action')
vim.lsp.buf_request_all=state.original
local saga=require('lspsaga.codeaction')
return {line=line,no_empty_menu=not (saga.action_winid and vim.api.nvim_win_is_valid(saga.action_winid)),errmsg=vim.v.errmsg}`,
    [],
  ]);
  if (
    !numbered.line.includes('const applied =') ||
    !numbered.no_empty_menu ||
    numbered.errmsg
  )
    throw new Error(
      'Saga number shortcut or empty response failed: ' +
        JSON.stringify(numbered),
    );
  const result = { setup, shown, previewed, cancelled, applied, numbered };
  return result;
}
