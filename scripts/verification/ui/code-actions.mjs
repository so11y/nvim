import assert from 'node:assert/strict';
import { setTimeout as delay } from 'node:timers/promises';

export async function verifyCodeActionsUI(rpc) {
  const lua = (code) => rpc('nvim_exec_lua', [code, []]);
  const setup =
    await lua(`local filename=vim.env.NVIM_TEST_ROOT..'/alpha/ActionUI.html'
vim.fn.writefile({'<!-- action UI fixture -->'},filename)
vim.cmd.edit(filename)
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
for i=1,12 do actions[i]={title=('Action %02d'):format(i),edit=vim.deepcopy(edit),kind='quickfix'} end
actions[2].edit.changes[vim.uri_from_bufnr(buf)][1].newText='second'
actions[12].title='Action with a command'
actions[12].command={title='After edit',command='verify.code.action'}
_G.__action_ui={bufnr=buf,client=client,original=vim.lsp.buf_request_all,actions=actions,original_actions=vim.deepcopy(actions),edit=edit,before=line,column=col,commands=0,request=client.request,supports_method=client.supports_method,encoding=client.offset_encoding}
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
  const snapshot = () =>
    lua(`local p=Snacks.picker.get({source='select'})[1]
local s=_G.__action_ui
local result={active=p~=nil,unchanged=vim.api.nvim_buf_get_lines(s.bufnr,0,-1,false)[1]==s.before,errmsg=vim.v.errmsg,mode=vim.fn.mode(),commands=s.commands}
if p then
 result.count=p.list:count()
 result.current=p:current().idx
 result.text=p:current().text
 result.focused=vim.api.nvim_get_current_win()==p.list.win.win
 result.preview=p.preview.win:valid()==true
 result.input=p.input.win:valid()==true
 result.preview_focused=vim.api.nvim_get_current_win()==p.preview.win.win
 result.width=vim.api.nvim_win_get_width(p.layout.root.win)
 if result.preview then
  result.preview_lines=vim.api.nvim_buf_get_lines(p.preview.win.buf,0,-1,false)
  result.list_position=vim.api.nvim_win_get_position(p.list.win.win)
  result.preview_position=vim.api.nvim_win_get_position(p.preview.win.win)
 end
end
return result`);
  const open = async () => {
    await rpc('nvim_input', ['gra']);
    await delay(150);
    const state = await snapshot();
    assert.equal(
      state.active,
      true,
      'Code actions did not open a Snacks picker',
    );
    assert.equal(state.errmsg, '', JSON.stringify(state));
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
    await rpc('nvim_input', ['<C-l>']);
    await delay(150);
    const previewed = await snapshot();
    assert(
      previewed.preview &&
        previewed.focused &&
        !previewed.preview_focused &&
        previewed.unchanged,
    );
    assert(previewed.width > shown.width && !previewed.input);
    assert(
      previewed.preview_lines.some(
        (line) => line.startsWith('+') && line.includes('second'),
      ),
    );
    assert(
      await lua(
        'return vim.deep_equal(_G.__action_ui.actions,_G.__action_ui.original_actions)',
      ),
    );
    await rpc('nvim_input', ['j']);
    await delay(150);
    const updated = await snapshot();
    assert(updated.preview && updated.focused && updated.unchanged);
    assert.notEqual(updated.current, previewed.current);
    assert(
      updated.preview_lines.some(
        (line) => line.startsWith('+') && line.includes('applied'),
      ),
    );
    await rpc('nvim_input', ['<C-l>']);
    await delay(80);
    const entered = await snapshot();
    assert(entered.preview_focused && entered.current === updated.current);
    await rpc('nvim_input', ['j']);
    await delay(80);
    assert.equal(
      (await snapshot()).current,
      entered.current,
      'Reading the preview changed the selected action',
    );
    await rpc('nvim_input', ['<C-h>']);
    await delay(80);
    assert(
      (await snapshot()).focused,
      'Ctrl+H did not return to the action list',
    );
    await rpc('nvim_input', ['<A-p>']);
    await delay(100);
    const compact = await snapshot();
    assert(
      !compact.preview && compact.focused && compact.width === shown.width,
    );
    await rpc('nvim_input', ['<C-l>']);
    await delay(100);
    const revealed = await snapshot();
    assert(revealed.preview && revealed.focused && !revealed.preview_focused);
    await rpc('nvim_input', ['<C-l>']);
    await delay(80);
    await rpc('nvim_input', ['<Esc>']);
    await delay(100);
    const cancelled = await snapshot();
    assert(cancelled.unchanged && !cancelled.active);

    assert.equal(
      (await open()).preview,
      false,
      'A new action menu must start compact',
    );
    await rpc('nvim_input', ['<CR>']);
    await delay(150);
    const applied = await lua(`local s=_G.__action_ui
local line=vim.api.nvim_buf_get_lines(s.bufnr,0,-1,false)[1]
vim.cmd.undo()
return {line=line,commands=s.commands,restored=vim.api.nvim_buf_get_lines(s.bufnr,0,-1,false)[1]==s.before,errmsg=vim.v.errmsg}`);
    assert(
      applied.line.includes('const applied =') && applied.line.includes('😀'),
    );
    assert(
      applied.restored && applied.commands === 0 && !applied.errmsg,
      JSON.stringify(applied),
    );

    await open();
    await rpc('nvim_input', ['G']);
    await delay(200);
    const selected = await snapshot();
    assert.equal(selected.count, 12);
    assert(selected.text.includes('command') && !selected.input);
    await rpc('nvim_input', ['<C-l><C-l>']);
    await delay(120);
    const commandPreview = await snapshot();
    assert(
      commandPreview.preview_focused &&
        commandPreview.unchanged &&
        commandPreview.commands === 0,
    );
    assert(
      commandPreview.preview_lines.some(
        (line) => line.startsWith('+') && line.includes('const applied ='),
      ),
    );
    await rpc('nvim_input', ['<CR>']);
    await delay(150);
    const commanded = await lua(`local s=_G.__action_ui
local line=vim.api.nvim_buf_get_lines(s.bufnr,0,-1,false)[1]
vim.cmd.undo()
return {line=line,commands=s.commands,restored=vim.api.nvim_buf_get_lines(s.bufnr,0,-1,false)[1]==s.before,errmsg=vim.v.errmsg}`);
    assert(commanded.line.includes('const applied ='));
    assert(commanded.restored && commanded.commands === 1 && !commanded.errmsg);

    await lua(`local s=_G.__action_ui
local uri=vim.uri_from_bufnr(s.bufnr)
local filename=vim.env.NVIM_TEST_ROOT..'/beta/action-preview.ts'
local other='const face = "😀"; const old = 1;'
vim.fn.writefile({other},filename)
local col=vim.str_utfindex(s.before,'utf-16',s.column)
local other_col=vim.str_utfindex(other,'utf-16',assert(other:find('old',1,true))-1)
local function change(start,length,text) return {range={start={line=0,character=start},['end']={line=0,character=start+length}},newText=text,annotationId='review'} end
s.preview_file=filename
s.preview_file_before=other
s.client.offset_encoding='utf-16'
s.actions={{title='Multi-file UTF-16',edit={documentChanges={
 {textDocument={uri=uri},edits={change(col,5,'first')}},
 {textDocument={uri=uri},edits={change(col,5,'final')}},
 {textDocument={uri=vim.uri_from_fname(filename)},edits={change(other_col,3,'new')}}
},changeAnnotations={review={label='Needs confirmation only when applying',needsConfirmation=true}}}}}
s.preview_original=vim.deepcopy(s.actions)`);
    await open();
    await rpc('nvim_input', ['<C-l>']);
    await delay(150);
    const multiFile = await snapshot();
    assert(multiFile.preview && multiFile.focused && multiFile.unchanged);
    assert(
      multiFile.preview_lines.some(
        (line) => line.startsWith('+') && line.includes('const final ='),
      ),
    );
    assert(
      multiFile.preview_lines.some(
        (line) => line.startsWith('+') && line.includes('const new ='),
      ),
    );
    assert.equal(
      multiFile.preview_lines.filter((line) => line.startsWith('--- ')).length,
      2,
    );
    assert(
      await lua(`local s=_G.__action_ui
return vim.deep_equal(s.actions,s.preview_original) and vim.fn.readfile(s.preview_file)[1]==s.preview_file_before and vim.fn.bufnr(s.preview_file)==-1`),
    );
    await rpc('nvim_input', ['<Esc>']);
    await delay(80);

    await lua(`local s=_G.__action_ui
s.client.offset_encoding=s.encoding
s.actions={{title='Command only',command='verify.preview.only'}}
s.client.commands['verify.preview.only']=function() s.commands=s.commands+1 end`);
    await open();
    await rpc('nvim_input', ['<C-l>']);
    await delay(100);
    const commandOnly = await snapshot();
    assert(commandOnly.unchanged && commandOnly.commands === 1);
    assert(commandOnly.preview_lines.join('\n').includes('没有提供文本修改'));
    await rpc('nvim_input', ['<Esc>']);
    await delay(80);

    await lua(`local s=_G.__action_ui
s.created_file=vim.env.NVIM_TEST_ROOT..'/beta/action-preview-new.ts'
s.actions={{title='Create file',edit={documentChanges={{kind='create',uri=vim.uri_from_fname(s.created_file)}}}}}`);
    await open();
    await rpc('nvim_input', ['<C-l>']);
    await delay(100);
    const fileOperation = await snapshot();
    assert(
      fileOperation.unchanged &&
        fileOperation.preview_lines.join('\n').includes('无法完整预览'),
    );
    assert.equal(
      await lua('return vim.fn.filereadable(_G.__action_ui.created_file)'),
      0,
    );
    await rpc('nvim_input', ['<Esc>']);
    await delay(80);

    await lua(`local s=_G.__action_ui
s.pending={}
s.client.supports_method=function(self,method,...)
 if method=='codeAction/resolve' then return true end
 return s.supports_method(self,method,...)
end
s.client.request=function(self,method,params,handler,bufnr)
 if method~='codeAction/resolve' then return s.request(self,method,params,handler,bufnr) end
 s.pending[#s.pending+1]={handler=handler,params=vim.deepcopy(params),bufnr=bufnr}
 return true,#s.pending
end
s.resolved=vim.deepcopy(s.edit)
s.resolved.changes[vim.uri_from_bufnr(s.bufnr)][1].newText='resolved'
s.actions={{title='Needs resolve',data={id=1}},{title='Direct edit',edit=s.resolved}}`);
    await open();
    assert.equal(
      await lua('return #_G.__action_ui.pending'),
      0,
      'Opening a compact menu must not resolve actions',
    );
    await rpc('nvim_input', ['<C-l><C-l>']);
    await delay(100);
    const loading = await snapshot();
    assert(loading.preview_lines.join('\n').includes('正在获取'));
    await rpc('nvim_input', ['<C-h>']);
    await delay(80);
    const beforeRefresh = await lua(`local s=_G.__action_ui
local p=Snacks.picker.get({source='select'})[1]
p.list:move(2,true)
local stale=vim.deepcopy(s.edit)
stale.changes[vim.uri_from_bufnr(s.bufnr)][1].newText='stale'
s.pending[1].handler(nil,{title='Old response',edit=stale})
return vim.api.nvim_buf_get_lines(p.preview.win.buf,0,-1,false)`);
    assert(!beforeRefresh.join('\n').includes('stale'));
    await delay(150);
    const switched = await snapshot();
    assert(switched.focused && switched.unchanged);
    assert(
      switched.preview_lines.some(
        (line) => line.startsWith('+') && line.includes('resolved'),
      ),
    );
    assert(!switched.preview_lines.join('\n').includes('stale'));
    await rpc('nvim_input', ['<Esc>']);
    await delay(80);

    await open();
    await rpc('nvim_input', ['<C-l><C-l>']);
    await delay(100);
    await lua(`local s=_G.__action_ui
assert(s.pending[2].bufnr==s.bufnr)
s.pending[2].handler(nil,{title='Resolved action',edit=s.resolved})`);
    const resolved = await snapshot();
    assert(resolved.preview_focused && resolved.unchanged);
    assert(
      resolved.preview_lines.some(
        (line) => line.startsWith('+') && line.includes('resolved'),
      ),
    );
    assert(await lua('return _G.__action_ui.actions[1].edit==nil'));
    await rpc('nvim_input', ['<CR>']);
    await delay(100);
    const resolvedApplied = await lua(`local s=_G.__action_ui
s.pending[3].handler(nil,{title='Resolved action',edit=s.resolved})
local line=vim.api.nvim_buf_get_lines(s.bufnr,0,-1,false)[1]
vim.cmd.undo()
return {line=line,restored=vim.api.nvim_buf_get_lines(s.bufnr,0,-1,false)[1]==s.before}`);
    assert(
      resolvedApplied.line.includes('const resolved =') &&
        resolvedApplied.restored,
    );

    await open();
    await rpc('nvim_input', ['<C-l>']);
    await delay(100);
    await lua(
      "_G.__action_ui.pending[4].handler({code=-32603,message='Preview resolution failed'})",
    );
    const failed = await snapshot();
    assert(failed.unchanged && !failed.errmsg);
    assert(
      failed.preview_lines.join('\n').includes('Preview resolution failed'),
    );
    await rpc('nvim_input', ['<Esc>']);
    await delay(80);

    await open();
    await rpc('nvim_input', ['<C-l>']);
    await delay(100);
    await rpc('nvim_input', ['<Esc>']);
    await delay(80);
    await lua(
      "local s=_G.__action_ui; s.pending[5].handler(nil,{title='Late action',edit=s.resolved})",
    );
    const late = await snapshot();
    assert(
      !late.active && late.unchanged && !late.errmsg && late.commands === 1,
    );

    await lua('_G.__action_ui.actions={};vim.lsp.buf.code_action()');
    await delay(100);
    const empty = await snapshot();
    assert(!empty.active && empty.unchanged && !empty.errmsg);
    return {
      setup,
      shown,
      navigated,
      previewed,
      updated,
      entered,
      compact,
      cancelled,
      applied,
      selected,
      commanded,
      multiFile,
      commandOnly,
      fileOperation,
      loading,
      switched,
      resolved,
      resolvedApplied,
      failed,
      late,
      empty,
    };
  } finally {
    await lua(`local s=_G.__action_ui
vim.lsp.buf_request_all=s.original
s.client.request=s.request
s.client.supports_method=s.supports_method
s.client.offset_encoding=s.encoding`);
  }
}
