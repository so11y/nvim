import assert from 'node:assert/strict';
import { waitFor } from './wait.mjs';

export async function verifyCodeActionsUI(rpc) {
  const lua = (code) => rpc('nvim_exec_lua', [code, []]);
  const setup = await lua(`local root=vim.fn.tempname()
vim.fn.mkdir(root..'/alpha','p')
vim.fn.mkdir(root..'/beta','p')
local filename=root..'/alpha/ActionUI.html'
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
_G.__action_ui={root=root,bufnr=buf,client=client,original=vim.lsp.buf_request_all,actions=actions,original_actions=vim.deepcopy(actions),edit=edit,before=line,column=col,commands=0,request=client.request,supports_method=client.supports_method,encoding=client.offset_encoding}
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
local line=vim.api.nvim_buf_get_lines(s.bufnr,0,-1,false)[1]
local visible=p and p.layout and p.layout.root:win_valid()
local result={active=visible==true,line=line,unchanged=line==s.before,errmsg=vim.v.errmsg,mode=vim.fn.mode(),commands=s.commands}
if visible then
 local item=p:current()
 result.count=p.list:count()
 result.current=item and item.idx
 result.text=item and item.text
 result.focused=vim.api.nvim_get_current_win()==p.list.win.win
 result.preview=p.preview.win:valid()==true
 result.input=p.input.win:valid()==true
 result.preview_focused=vim.api.nvim_get_current_win()==p.preview.win.win
 result.width=vim.api.nvim_win_get_width(p.layout.root.win)
 if result.preview then
  result.preview_lines=vim.api.nvim_buf_get_lines(p.preview.win.buf,0,-1,false)
  result.preview_cursor=vim.api.nvim_win_get_cursor(p.preview.win.win)
  result.list_position=vim.api.nvim_win_get_position(p.list.win.win)
  result.preview_position=vim.api.nvim_win_get_position(p.preview.win.win)
 end
end
return result`);
  const open = async () => {
    await rpc('nvim_input', ['gra']);
    const state = await waitFor(
      snapshot,
      (state) => state.active && state.current && state.focused,
      'Code actions did not open a Snacks picker',
    );
    assert.equal(state.errmsg, '', JSON.stringify(state));
    return state;
  };
  try {
    assert(setup.normal_mapping && setup.visual_mapping);
    const shown = await open();
    assert.equal(shown.count, 12);
    assert(shown.mode === 'n' && shown.unchanged);
    assert.equal(shown.input, false, 'Code actions must not show an input');
    await rpc('nvim_input', ['j']);
    const navigated = await waitFor(
      snapshot,
      (state) => state.current && state.current !== shown.current,
      'Action selection did not move',
    );
    assert(navigated.unchanged && !shown.preview && !navigated.preview);
    await rpc('nvim_input', ['<C-l>']);
    const previewed = await waitFor(
      snapshot,
      (state) =>
        state.preview_lines?.some(
          (line) => line.startsWith('+') && line.includes('second'),
        ),
      'Action preview did not show the selected edit',
    );
    assert(
      previewed.preview &&
        previewed.focused &&
        !previewed.preview_focused &&
        previewed.unchanged,
    );
    assert(previewed.width > shown.width && !previewed.input);
    assert(
      await lua(
        'return vim.deep_equal(_G.__action_ui.actions,_G.__action_ui.original_actions)',
      ),
    );
    await rpc('nvim_input', ['j']);
    const updated = await waitFor(
      snapshot,
      (state) =>
        state.current &&
        state.current !== previewed.current &&
        state.preview_lines?.some(
          (line) => line.startsWith('+') && line.includes('applied'),
        ),
      'Action preview did not follow the selection',
    );
    assert(updated.preview && updated.focused && updated.unchanged);
    await rpc('nvim_input', ['<C-l>']);
    const entered = await waitFor(
      snapshot,
      (state) => state.preview_focused,
      'Ctrl+L did not focus the preview',
    );
    assert.equal(entered.current, updated.current);
    await rpc('nvim_input', ['j']);
    const scrolled = await waitFor(
      snapshot,
      (state) => state.preview_cursor[0] !== entered.preview_cursor[0],
      'Preview cursor did not move',
    );
    assert.equal(
      scrolled.current,
      entered.current,
      'Reading the preview changed the selected action',
    );
    await rpc('nvim_input', ['<C-h>']);
    await waitFor(
      snapshot,
      (state) => state.focused,
      'Ctrl+H did not return to the action list',
    );
    await rpc('nvim_input', ['<A-p>']);
    const compact = await waitFor(
      snapshot,
      (state) => !state.preview && state.focused,
      'Alt+P did not collapse the preview',
    );
    assert.equal(compact.width, shown.width);
    await rpc('nvim_input', ['<C-l>']);
    const revealed = await waitFor(
      snapshot,
      (state) => state.preview && state.focused,
      'Ctrl+L did not reopen the preview',
    );
    assert(!revealed.preview_focused);
    await rpc('nvim_input', ['<C-l>']);
    await waitFor(
      snapshot,
      (state) => state.preview_focused,
      'Preview did not gain focus',
    );
    await rpc('nvim_input', ['<Esc>']);
    const cancelled = await waitFor(
      snapshot,
      (state) => !state.active,
      'Esc did not close the action menu',
    );
    assert(cancelled.unchanged);

    assert.equal(
      (await open()).preview,
      false,
      'A new action menu must start compact',
    );
    await rpc('nvim_input', ['<CR>']);
    await waitFor(
      snapshot,
      (state) => !state.active && state.line.includes('const applied ='),
      'Enter did not apply the action',
    );
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
    const selected = await waitFor(
      snapshot,
      (state) => state.current === 12,
      'G did not select the last action',
    );
    assert.equal(selected.count, 12);
    assert(selected.text.includes('command') && !selected.input);
    await rpc('nvim_input', ['<C-l><C-l>']);
    const commandPreview = await waitFor(
      snapshot,
      (state) =>
        state.preview_focused &&
        state.preview_lines.some(
          (line) => line.startsWith('+') && line.includes('const applied ='),
        ),
      'Command preview did not become ready',
    );
    assert(commandPreview.unchanged && commandPreview.commands === 0);
    await rpc('nvim_input', ['<CR>']);
    await waitFor(
      snapshot,
      (state) => !state.active && state.commands === 1,
      'Enter did not execute the action command',
    );
    const commanded = await lua(`local s=_G.__action_ui
local line=vim.api.nvim_buf_get_lines(s.bufnr,0,-1,false)[1]
vim.cmd.undo()
return {line=line,commands=s.commands,restored=vim.api.nvim_buf_get_lines(s.bufnr,0,-1,false)[1]==s.before,errmsg=vim.v.errmsg}`);
    assert(commanded.line.includes('const applied ='));
    assert(commanded.restored && commanded.commands === 1 && !commanded.errmsg);

    await lua(`local s=_G.__action_ui
local uri=vim.uri_from_bufnr(s.bufnr)
local filename=s.root..'/beta/action-preview.ts'
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
    const multiFile = await waitFor(
      snapshot,
      (state) =>
        state.preview_lines?.some(
          (line) => line.startsWith('+') && line.includes('const new ='),
        ),
      'Multi-file preview did not become ready',
    );
    assert(multiFile.preview && multiFile.focused && multiFile.unchanged);
    assert(
      multiFile.preview_lines.some(
        (line) => line.startsWith('+') && line.includes('const final ='),
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
    await waitFor(
      snapshot,
      (state) => !state.active,
      'Esc did not close the multi-file preview',
    );

    await lua(`local s=_G.__action_ui
s.client.offset_encoding=s.encoding
s.actions={{title='Command only',command='verify.preview.only'}}
s.client.commands['verify.preview.only']=function() s.commands=s.commands+1 end`);
    await open();
    await rpc('nvim_input', ['<C-l>']);
    const commandOnly = await waitFor(
      snapshot,
      (state) => state.preview_lines?.join('\n').includes('没有提供文本修改'),
      'Command-only preview did not become ready',
    );
    assert(commandOnly.unchanged && commandOnly.commands === 1);
    await rpc('nvim_input', ['<Esc>']);
    await waitFor(
      snapshot,
      (state) => !state.active,
      'Esc did not close the command preview',
    );

    await lua(`local s=_G.__action_ui
s.created_file=s.root..'/beta/action-preview-new.ts'
s.actions={{title='Create file',edit={documentChanges={{kind='create',uri=vim.uri_from_fname(s.created_file)}}}}}`);
    await open();
    await rpc('nvim_input', ['<C-l>']);
    const fileOperation = await waitFor(
      snapshot,
      (state) => state.preview_lines?.join('\n').includes('无法完整预览'),
      'File-operation preview did not become ready',
    );
    assert(fileOperation.unchanged);
    assert.equal(
      await lua('return vim.fn.filereadable(_G.__action_ui.created_file)'),
      0,
    );
    await rpc('nvim_input', ['<Esc>']);
    await waitFor(
      snapshot,
      (state) => !state.active,
      'Esc did not close the file-operation preview',
    );

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
    const loading = await waitFor(
      snapshot,
      (state) =>
        state.preview_focused &&
        state.preview_lines.some((line) => line.includes('正在获取')),
      'Unresolved action did not show a loading preview',
    );
    await rpc('nvim_input', ['<C-h>']);
    await waitFor(
      snapshot,
      (state) => state.focused,
      'Ctrl+H did not return to the list',
    );
    const beforeRefresh = await lua(`local s=_G.__action_ui
local p=Snacks.picker.get({source='select'})[1]
p.list:move(2,true)
local stale=vim.deepcopy(s.edit)
stale.changes[vim.uri_from_bufnr(s.bufnr)][1].newText='stale'
s.pending[1].handler(nil,{title='Old response',edit=stale})
return vim.api.nvim_buf_get_lines(p.preview.win.buf,0,-1,false)`);
    assert(!beforeRefresh.join('\n').includes('stale'));
    const switched = await waitFor(
      snapshot,
      (state) =>
        state.preview_lines.some(
          (line) => line.startsWith('+') && line.includes('resolved'),
        ),
      'Preview did not refresh after a stale response',
    );
    assert(switched.focused && switched.unchanged);
    assert(!switched.preview_lines.join('\n').includes('stale'));
    await rpc('nvim_input', ['<Esc>']);
    await waitFor(
      snapshot,
      (state) => !state.active,
      'Esc did not close the resolved preview',
    );

    await open();
    await rpc('nvim_input', ['<C-l><C-l>']);
    await waitFor(
      () => lua('return #_G.__action_ui.pending'),
      (count) => count === 2,
      'Preview did not request action resolution',
    );
    await lua(`local s=_G.__action_ui
assert(s.pending[2].bufnr==s.bufnr)
s.pending[2].handler(nil,{title='Resolved action',edit=s.resolved})`);
    const resolved = await waitFor(
      snapshot,
      (state) =>
        state.preview_focused &&
        state.preview_lines.some(
          (line) => line.startsWith('+') && line.includes('resolved'),
        ),
      'Resolved preview did not become ready',
    );
    assert(resolved.preview_focused && resolved.unchanged);
    assert(await lua('return _G.__action_ui.actions[1].edit==nil'));
    await rpc('nvim_input', ['<CR>']);
    await waitFor(
      () => lua('return #_G.__action_ui.pending'),
      (count) => count === 3,
      'Enter did not request action resolution',
    );
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
    await waitFor(
      () => lua('return #_G.__action_ui.pending'),
      (count) => count === 4,
      'Preview did not request action resolution',
    );
    await lua(
      "_G.__action_ui.pending[4].handler({code=-32603,message='Preview resolution failed'})",
    );
    const failed = await waitFor(
      snapshot,
      (state) =>
        state.preview_lines?.join('\n').includes('Preview resolution failed'),
      'Preview did not show the resolution error',
    );
    assert(failed.unchanged && !failed.errmsg);
    await rpc('nvim_input', ['<Esc>']);
    await waitFor(
      snapshot,
      (state) => !state.active,
      'Esc did not close the failed preview',
    );

    await open();
    await rpc('nvim_input', ['<C-l>']);
    await waitFor(
      () => lua('return #_G.__action_ui.pending'),
      (count) => count === 5,
      'Preview did not request action resolution',
    );
    await rpc('nvim_input', ['<Esc>']);
    await waitFor(
      snapshot,
      (state) => !state.active,
      'Esc did not close the pending preview',
    );
    await lua(
      "local s=_G.__action_ui; s.pending[5].handler(nil,{title='Late action',edit=s.resolved})",
    );
    const late = await snapshot();
    assert(
      !late.active && late.unchanged && !late.errmsg && late.commands === 1,
    );

    await lua('_G.__action_ui.actions={};vim.lsp.buf.code_action()');
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
