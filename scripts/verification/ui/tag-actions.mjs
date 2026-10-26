import assert from 'node:assert/strict';
import { setTimeout as delay } from 'node:timers/promises';

export async function verifyTagActionsUI(rpc) {
  const lua = (code) => rpc('nvim_exec_lua', [code, []]);
  const setup = await lua(`vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/TagActions.vue')
assert(vim.wait(15000,function()
 return #vim.lsp.get_clients({bufnr=0,name='tag_fix'})==1 and #vim.lsp.get_clients({bufnr=0,name='vue_ls',method='textDocument/codeAction'})>0
end,20))
require('persistence').stop()
_G.__tag_ui={startup_errmsg=vim.v.errmsg}
vim.v.errmsg=''
return {startup_errmsg=_G.__tag_ui.startup_errmsg,normal_mapped=vim.fn.maparg('gra','n',false,true).callback~=nil,visual_mapped=vim.fn.maparg('gra','x',false,true).callback~=nil}`);
  assert(setup.normal_mapped && setup.visual_mapped);
  try {
    const wrapMenu = await lua(`local s=_G.__tag_ui
s.bufnr=vim.api.nvim_get_current_buf()
s.before=table.concat(vim.api.nvim_buf_get_lines(s.bufnr,0,-1,false),'\\n')
s.input=vim.ui.input
s.prompts=0
vim.ui.input=function(_,callback)s.prompts=s.prompts+1;callback('div.wrapper')end
local line=vim.api.nvim_buf_get_lines(0,5,6,false)[1]
vim.api.nvim_win_set_cursor(0,{6,assert(line:find('visible',1,true))-1})
vim.cmd.normal('gra')
assert(vim.wait(15000,function()local p=Snacks.picker.get({source='select'})[1];return p and p:count()>0 end,20))
local p=Snacks.picker.get({source='select'})[1]
local target
for index=1,p.list:count() do
 if p.list:get(index).text:find('添加外层标签',1,true) then target=index;break end
end
assert(target,'Wrap action is missing from the picker')
p.list:move(target,true)
local names={}
for _,client in ipairs(vim.lsp.get_clients({bufnr=s.bufnr,method='textDocument/codeAction'})) do names[#names+1]=client.name end
return {target=target,prompts=s.prompts,clients=names,height=vim.api.nvim_win_get_height(p.list.win.win),count=p:count()}`);
    await rpc('nvim_input', ['<CR>']);
    await delay(200);
    const wrapped = await lua(`local s=_G.__tag_ui
local after=table.concat(vim.api.nvim_buf_get_lines(s.bufnr,0,-1,false),'\\n')
vim.ui.input=s.input
vim.cmd.undo()
return {prompts=s.prompts,after=after,restored=table.concat(vim.api.nvim_buf_get_lines(s.bufnr,0,-1,false),'\\n')==s.before,errmsg=vim.v.errmsg}`);
    assert.equal(wrapMenu.prompts, 0);
    assert(wrapMenu.height >= 1 && wrapMenu.height <= wrapMenu.count);
    assert(wrapMenu.clients.includes('tag_fix') && wrapMenu.clients.includes('vue_ls'));
    assert.equal(wrapped.prompts, 1);
    assert(wrapped.after.includes('<div class="wrapper"><div v-if="visible">'));
    assert(wrapped.restored && !wrapped.errmsg);

    await rpc('nvim_ui_try_resize', [50, 16]);
    await delay(100);
    await lua(`local items={}
local client=vim.lsp.get_clients({bufnr=0,name='tag_fix'})[1]
for i=1,10 do
 items[i]={action={title=('Action %02d'):format(i),kind='quickfix'},ctx={client_id=client.id,bufnr=vim.api.nvim_get_current_buf()}}
end
vim.ui.select(items,{kind='codeaction',prompt='Code actions',format_item=function(item)return item.action.title end},function()end)`);
    await delay(150);
    const edge = await lua(`local p=assert(Snacks.picker.get({source='select'})[1])
local cfg=vim.api.nvim_win_get_config(p.list.win.win)
local pos=vim.fn.win_screenpos(p.list.win.win)
local result={height=cfg.height,width=cfg.width,row=pos[1],col=pos[2],count=p:count(),errmsg=vim.v.errmsg}
p:close()
return result`);
    assert(edge.row >= 1 && edge.col >= 1);
    assert(edge.row + edge.height <= 17 && edge.col + edge.width <= 51);
    assert(edge.height >= 1 && edge.height < 10 && edge.count === 10 && !edge.errmsg);
    return { setup, wrapMenu, wrapped, edge };
  } finally {
    await lua('if _G.__tag_ui.input then vim.ui.input=_G.__tag_ui.input end');
  }
}
