import { setTimeout as delay } from 'node:timers/promises';

export async function verifyLinkedTagsUI(rpc) {
  const lua = (code) => rpc('nvim_exec_lua', [code, []]);
  const renameDialog = (stage) =>
    rpc('nvim_exec_lua', [
      `local stage=...
local input_win
assert(vim.wait(5000,function()
  for _,win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype=='snacks_input' then
      input_win=win
      return true
    end
  end
end,20),stage..': native rename input missing')
local input_buf=vim.api.nvim_win_get_buf(input_win)
assert(vim.b[input_buf].completion==false,'Rename input enabled completion')
return {winid=input_win,initial=vim.api.nvim_buf_get_lines(input_buf,0,-1,false),mode=vim.fn.mode()}`,
      [stage],
    ]);
  await lua(
    "vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/TagActions.vue'); local b=vim.api.nvim_get_current_buf(); assert(vim.wait(15000,function() return #vim.lsp.get_clients({bufnr=b,name='vue_ls'})>0 and #vim.lsp.get_clients({bufnr=b,name='vtsls'})>0 end,50)); local c=vim.lsp.get_clients({bufnr=b,name='vue_ls'})[1]; assert(vim.wait(5000,function() return vim.api.nvim_get_namespaces()['modules.language.lsp.linked_tags:'..b] end,20))",
  );
  await delay(200);
  const vue = await lua(
    "local b=vim.api.nvim_get_current_buf(); local c=vim.lsp.get_clients({bufnr=b,name='vue_ls'})[1]; vim.api.nvim_win_set_cursor(0,{5,3}); local params={textDocument={uri=vim.uri_from_bufnr(b)},position={line=4,character=3}}; local reply=c:request_sync('textDocument/linkedEditingRange',params,3000,b); assert(reply and reply.result and #reply.result.ranges==2,'Vue LSP linked response missing'); vim.api.nvim_exec_autocmds('CursorMoved',{buffer=b}); local ns=vim.api.nvim_get_namespaces()['modules.language.lsp.linked_tags:'..b]; assert(vim.wait(5000,function() return ns and #vim.api.nvim_buf_get_extmarks(b,ns,0,-1,{details=true})==2 end,20),'Vue linked ranges missing'); return {client=c.name,extmarks=#vim.api.nvim_buf_get_extmarks(b,ns,0,-1,{details=true}),inc=vim.fn.exists(':IncRename'),gra_mapped=vim.fn.maparg('gra','n')~='',old_lsp_keys=vim.fn.maparg('<leader>ca','n')~='' or vim.fn.maparg('<leader>cr','n')~=''}",
  );
  await rpc('nvim_input', ['ciw']);
  await delay(120);
  const empty = await lua(
    "local b=vim.api.nvim_get_current_buf(); local ns=vim.api.nvim_get_namespaces()['modules.language.lsp.linked_tags:'..b]; return {mode=vim.fn.mode(),open=vim.api.nvim_buf_get_lines(0,4,5,false)[1],close=vim.api.nvim_buf_get_lines(0,12,13,false)[1],extmarks=#vim.api.nvim_buf_get_extmarks(0,ns,0,-1,{details=true}),errmsg=vim.v.errmsg}",
  );
  await rpc('nvim_input', ['s']);
  await delay(120);
  const partial = await lua(
    'return {mode=vim.fn.mode(),open=vim.api.nvim_buf_get_lines(0,4,5,false)[1],close=vim.api.nvim_buf_get_lines(0,12,13,false)[1],errmsg=vim.v.errmsg}',
  );
  await rpc('nvim_input', ['ection']);
  await delay(120);
  const full = await lua(
    'return {mode=vim.fn.mode(),open=vim.api.nvim_buf_get_lines(0,4,5,false)[1],close=vim.api.nvim_buf_get_lines(0,12,13,false)[1],errmsg=vim.v.errmsg}',
  );
  await rpc('nvim_input', ['<Esc>']);
  await delay(50);
  await lua('vim.cmd.undo()');
  await delay(100);
  const undone = await lua(
    'return {open=vim.api.nvim_buf_get_lines(0,4,5,false)[1],close=vim.api.nvim_buf_get_lines(0,12,13,false)[1],errmsg=vim.v.errmsg}',
  );
  if (
    vue.inc !== 0 ||
    !vue.gra_mapped ||
    vue.old_lsp_keys ||
    vue.extmarks !== 2 ||
    partial.mode !== 'i' ||
    !partial.open.includes('<s ') ||
    !partial.close.includes('</s>') ||
    full.mode !== 'i' ||
    !full.open.includes('<section ') ||
    !full.close.includes('</section>') ||
    !undone.open.includes('<div ') ||
    !undone.close.includes('</div>') ||
    partial.errmsg ||
    full.errmsg ||
    undone.errmsg
  )
    throw new Error(
      'Vue live linked editing failed: ' +
        JSON.stringify({ vue, empty, partial, full, undone }),
    );
  await lua(
    "vim.api.nvim_win_set_cursor(0,{9,7}); vim.api.nvim_exec_autocmds('CursorMoved',{buffer=0})",
  );
  await delay(200);
  await rpc('nvim_input', ['caw']);
  await delay(120);
  const cawEmpty = await lua(
    'return {mode=vim.fn.mode(),open=vim.api.nvim_buf_get_lines(0,8,9,false)[1],close=vim.api.nvim_buf_get_lines(0,11,12,false)[1],errmsg=vim.v.errmsg}',
  );
  await rpc('nvim_input', ['Panel']);
  await delay(120);
  const cawFull = await lua(
    'return {mode=vim.fn.mode(),open=vim.api.nvim_buf_get_lines(0,8,9,false)[1],close=vim.api.nvim_buf_get_lines(0,11,12,false)[1],errmsg=vim.v.errmsg}',
  );
  await rpc('nvim_input', ['<Esc>']);
  await delay(50);
  if (
    cawEmpty.mode !== 'i' ||
    !cawEmpty.open.includes('<>') ||
    !cawEmpty.close.includes('</>') ||
    cawFull.mode !== 'i' ||
    !cawFull.open.includes('<Panel>') ||
    !cawFull.close.includes('</Panel>') ||
    cawFull.errmsg
  )
    throw new Error(
      'Vue caw linked editing failed: ' + JSON.stringify({ cawEmpty, cawFull }),
    );
  await lua(
    "vim.api.nvim_win_set_cursor(0,{12,8}); vim.api.nvim_exec_autocmds('CursorMoved',{buffer=0})",
  );
  await delay(200);
  await rpc('nvim_input', ['ciw']);
  await delay(120);
  await rpc('nvim_input', ['Aside']);
  await delay(120);
  const closingEdit = await lua(
    'return {mode=vim.fn.mode(),open=vim.api.nvim_buf_get_lines(0,8,9,false)[1],close=vim.api.nvim_buf_get_lines(0,11,12,false)[1],errmsg=vim.v.errmsg}',
  );
  await rpc('nvim_input', ['<Esc>']);
  await delay(50);
  if (
    closingEdit.mode !== 'i' ||
    !closingEdit.open.includes('<Aside>') ||
    !closingEdit.close.includes('</Aside>') ||
    closingEdit.errmsg
  )
    throw new Error(
      'Vue closing-tag edit failed: ' + JSON.stringify(closingEdit),
    );
  await lua('vim.api.nvim_win_set_cursor(0,{5,3})');
  await rpc('nvim_input', ['grn']);
  await delay(150);
  const tagDialog = await renameDialog('cancel tag');
  await rpc('nvim_input', ['<C-c>']);
  await delay(100);
  const cancelled = await rpc('nvim_exec_lua', [
    "local win=...; local lines=vim.api.nvim_buf_get_lines(0,0,-1,false); return {closed=not vim.api.nvim_win_is_valid(win),open=lines[5],close=lines[13],mode=vim.fn.mode(),errmsg=vim.v.errmsg}",
    [tagDialog.winid],
  ]);
  if (
    !cancelled.closed ||
    cancelled.mode !== 'n' ||
    !cancelled.open.includes('<div ') ||
    !cancelled.close.includes('</div>') ||
    cancelled.errmsg
  )
    throw new Error(
      'Native rename cancellation failed: ' + JSON.stringify({ tagDialog, cancelled }),
    );
  await lua('vim.api.nvim_win_set_cursor(0,{5,3})');
  await rpc('nvim_input', ['grn']);
  await delay(150);
  const tagRenameDialog = await renameDialog('rename tag');
  await rpc('nvim_input', ['<C-u>article<CR>']);
  await delay(500);
  const tagRename = await lua(
    'local lines=vim.api.nvim_buf_get_lines(0,0,-1,false); return {open=lines[5],close=lines[13],errmsg=vim.v.errmsg}',
  );
  if (
    !tagRename.open.includes('<article ') ||
    !tagRename.close.includes('</article>') ||
    tagRename.errmsg
  )
    throw new Error('Vue tag LSP rename failed: ' + JSON.stringify({ tagRenameDialog, tagRename }));
  await lua(
    "vim.api.nvim_buf_set_lines(0,12,12,false,{'    <LiveTag'}); vim.api.nvim_win_set_cursor(0,{13,0})",
  );
  await rpc('nvim_input', ['A>']);
  await delay(150);
  const autoClose = await lua(
    'return {mode=vim.fn.mode(),lines=vim.api.nvim_buf_get_lines(0,12,15,false),errmsg=vim.v.errmsg}',
  );
  await rpc('nvim_input', ['<Esc>']);
  await delay(50);
  if (!autoClose.lines.join(' ').includes('</LiveTag>') || autoClose.errmsg)
    throw new Error(
      'Vue automatic tag closing failed: ' + JSON.stringify(autoClose),
    );
  await lua(
    "vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/App.vue'); assert(vim.wait(15000,function() return #vim.lsp.get_clients({bufnr=0,name='vtsls'})>0 and #vim.lsp.get_clients({bufnr=0,name='vue_ls'})>0 end,50)); vim.api.nvim_win_set_cursor(0,{3,6})",
  );
  await rpc('nvim_input', ['grn']);
  await delay(150);
  const codeDialog = await renameDialog('rename variable');
  await rpc('nvim_input', ['<C-u>renamedCount<CR>']);
  await delay(500);
  const codeRename = await lua(
    'local lines=vim.api.nvim_buf_get_lines(0,0,-1,false); return {declaration=lines[3],body=lines[5],template=lines[7],errmsg=vim.v.errmsg}',
  );
  if (
    !codeRename.declaration.includes('renamedCount') ||
    !codeRename.body.includes('renamedCount') ||
    !codeRename.template.includes('renamedCount') ||
    codeRename.errmsg
  )
    throw new Error(
      'Vue script LSP rename failed: ' + JSON.stringify(codeRename),
    );
  await lua(
    "vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/TagActions.html'); local b=vim.api.nvim_get_current_buf(); assert(vim.wait(15000,function() return #vim.lsp.get_clients({bufnr=b,name='html'})>0 end,50)); assert(vim.wait(5000,function() return vim.api.nvim_get_namespaces()['modules.language.lsp.linked_tags:'..b] end,20))",
  );
  await delay(200);
  const html = await lua(
    "local b=vim.api.nvim_get_current_buf(); local c=vim.lsp.get_clients({bufnr=b,name='html'})[1]; vim.api.nvim_win_set_cursor(0,{1,1}); local params={textDocument={uri=vim.uri_from_bufnr(b)},position={line=0,character=1}}; local reply=c:request_sync('textDocument/linkedEditingRange',params,3000,b); assert(reply and reply.result and #reply.result.ranges==2,'HTML LSP linked response missing'); vim.api.nvim_exec_autocmds('CursorMoved',{buffer=b}); local ns=vim.api.nvim_get_namespaces()['modules.language.lsp.linked_tags:'..b]; assert(vim.wait(5000,function() return ns and #vim.api.nvim_buf_get_extmarks(b,ns,0,-1,{details=true})==2 end,20),'HTML linked ranges missing'); return {client=c.name,extmarks=#vim.api.nvim_buf_get_extmarks(b,ns,0,-1,{details=true})}",
  );
  await rpc('nvim_input', ['ciws']);
  await delay(120);
  const htmlPartial = await lua(
    'return {mode=vim.fn.mode(),open=vim.api.nvim_buf_get_lines(0,0,1,false)[1],close=vim.api.nvim_buf_get_lines(0,4,5,false)[1],errmsg=vim.v.errmsg}',
  );
  await rpc('nvim_input', ['<Esc>']);
  await delay(50);
  if (
    html.extmarks !== 2 ||
    htmlPartial.mode !== 'i' ||
    !htmlPartial.open.startsWith('<s ') ||
    !htmlPartial.close.includes('</s>') ||
    htmlPartial.errmsg
  )
    throw new Error(
      'HTML live linked editing failed: ' +
        JSON.stringify({ html, htmlPartial }),
    );
  await lua(
    "vim.cmd.undo(); vim.api.nvim_win_set_cursor(0,{2,9}); vim.api.nvim_exec_autocmds('CursorMoved',{buffer=0})",
  );
  await delay(200);
  await rpc('nvim_input', ['caw']);
  await delay(120);
  const htmlCawEmpty = await lua(
    'return {mode=vim.fn.mode(),line=vim.api.nvim_buf_get_lines(0,1,2,false)[1],errmsg=vim.v.errmsg}',
  );
  await rpc('nvim_input', ['strong']);
  await delay(120);
  const htmlCawFull = await lua(
    'return {mode=vim.fn.mode(),line=vim.api.nvim_buf_get_lines(0,1,2,false)[1],errmsg=vim.v.errmsg}',
  );
  await rpc('nvim_input', ['<Esc>']);
  await delay(50);
  if (
    htmlCawEmpty.mode !== 'i' ||
    !htmlCawEmpty.line.includes('<>') ||
    !htmlCawEmpty.line.includes('</>') ||
    htmlCawFull.mode !== 'i' ||
    !htmlCawFull.line.includes('<strong>') ||
    !htmlCawFull.line.includes('</strong>') ||
    htmlCawFull.errmsg
  )
    throw new Error(
      'HTML caw linked editing failed: ' +
        JSON.stringify({ htmlCawEmpty, htmlCawFull }),
    );
  const result = {
    vue,
    empty,
    partial,
    full,
    undone,
    cawEmpty,
    cawFull,
    closingEdit,
    tagDialog,
    tagRenameDialog,
    cancelled,
    tagRename,
    autoClose,
    codeDialog,
    codeRename,
    html,
    htmlPartial,
    htmlCawEmpty,
    htmlCawFull,
  };
  return result;
}
