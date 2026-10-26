import assert from 'node:assert/strict';
import { setTimeout as delay } from 'node:timers/promises';

export async function verifyCodeActionsUI(rpc) {
  const lua = (code) => rpc('nvim_exec_lua', [code, []]);
  const setup = await lua(`vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/TagActions.html')
assert(vim.wait(5000,function()return #vim.lsp.get_clients({bufnr=0,name='tag_fix'})==1 end,20))
require('persistence').stop()
local buf=vim.api.nvim_get_current_buf()
local client=vim.lsp.get_clients({bufnr=buf,name='tag_fix'})[1]
local line='const 文本 = "😀"; const value = 1;'
vim.api.nvim_buf_set_lines(buf,0,-1,false,{line})
local col=assert(line:find('value',1,true))-1
vim.api.nvim_win_set_cursor(0,{1,col})
local edit={changes={[vim.uri_from_bufnr(buf)]={{range={start={line=0,character=col},['end']={line=0,character=col+5}},newText='applied'}}}}
local actions={}
for i=1,12 do actions[i]={title=('Action %02d'):format(i),edit=edit,kind='quickfix'} end
actions[12].title='Action with a command'
actions[12].command={title='After edit',command='verify.code.action'}
_G.__action_ui={bufnr=buf,client=client,original=vim.lsp.buf_request_all,actions=actions,before=line,commands=0}
client.commands['verify.code.action']=function()
 assert(vim.api.nvim_buf_get_lines(buf,0,-1,false)[1]:find('const applied =',1,true),'Command ran before its edit')
 _G.__action_ui.commands=_G.__action_ui.commands+1
end
vim.lsp.buf_request_all=function(_,method,params,callback)
 local s=_G.__action_ui
 local p=type(params)=='function' and params(s.client) or params
 callback({[s.client.id]={result=s.actions,context={client_id=s.client.id,bufnr=s.bufnr,method=method,params=p}}})
end
return {before=line,normal_mapping=vim.fn.maparg('gra','n',false,true).callback~=nil,visual_mapping=vim.fn.maparg('gra','x',false,true).callback~=nil}`);
  const snapshot = () => lua(`local p=Snacks.picker.get({source='select'})[1]
local s=_G.__action_ui
local result={active=p~=nil,unchanged=vim.api.nvim_buf_get_lines(s.bufnr,0,-1,false)[1]==s.before,errmsg=vim.v.errmsg,mode=vim.fn.mode()}
if p then
 result.count=p.list:count()
 result.current=p:current().idx
 result.text=p:current().text
 result.focused=vim.api.nvim_get_current_win()==p.list.win.win
 result.preview=p.preview.win:valid()
 result.input=p.input.win:valid()==true
end
return result`);
  const open = async () => {
    await rpc('nvim_input', ['gra']);
    await delay(150);
    const state = await snapshot();
    assert.equal(state.active, true, 'Code actions did not open a Snacks picker');
    return state;
  };
  try {
    assert(setup.normal_mapping && setup.visual_mapping);
    const shown = await open();
    assert.equal(shown.count, 12);
    assert(shown.focused && shown.mode === 'n' && shown.unchanged);
    assert.equal(shown.input, false, 'Code actions must not show an input');
    await rpc('nvim_input', ['j']);
    await delay(100);
    const navigated = await snapshot();
    assert.notEqual(navigated.current, shown.current);
    assert(navigated.unchanged && !shown.preview && !navigated.preview);
    await rpc('nvim_input', ['<Esc>']);
    await delay(100);
    const cancelled = await snapshot();
    assert(cancelled.unchanged && !cancelled.active);

    await open();
    await rpc('nvim_input', ['<CR>']);
    await delay(150);
    const applied = await lua(`local s=_G.__action_ui
local line=vim.api.nvim_buf_get_lines(s.bufnr,0,-1,false)[1]
vim.cmd.undo()
return {line=line,commands=s.commands,restored=vim.api.nvim_buf_get_lines(s.bufnr,0,-1,false)[1]==s.before,errmsg=vim.v.errmsg}`);
    assert(applied.line.includes('const applied =') && applied.line.includes('😀'));
    assert(applied.restored && applied.commands === 0 && !applied.errmsg);

    await open();
    await rpc('nvim_input', ['G']);
    await delay(200);
    const selected = await snapshot();
    assert.equal(selected.count, 12);
    assert(selected.text.includes('command') && !selected.input);
    await rpc('nvim_input', ['<CR>']);
    await delay(150);
    const commanded = await lua(`local s=_G.__action_ui
local line=vim.api.nvim_buf_get_lines(s.bufnr,0,-1,false)[1]
vim.cmd.undo()
return {line=line,commands=s.commands,restored=vim.api.nvim_buf_get_lines(s.bufnr,0,-1,false)[1]==s.before,errmsg=vim.v.errmsg}`);
    assert(commanded.line.includes('const applied ='));
    assert(commanded.restored && commanded.commands === 1 && !commanded.errmsg);
    await lua("_G.__action_ui.actions={};vim.lsp.buf.code_action()");
    await delay(100);
    const empty = await snapshot();
    assert(!empty.active && empty.unchanged && !empty.errmsg);
    return { setup, shown, navigated, cancelled, applied, selected, commanded, empty };
  } finally {
    await lua("vim.lsp.buf_request_all=_G.__action_ui.original");
  }
}
