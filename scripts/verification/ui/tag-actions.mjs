import { setTimeout as delay } from 'node:timers/promises';

export async function verifyTagActionsUI(rpc) {
  const setup = await rpc('nvim_exec_lua', [
    `vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/TagActions.vue')
assert(vim.wait(15000,function()
 local clients=vim.lsp.get_clients({bufnr=0,name='vtsls'})
 return #vim.lsp.get_clients({bufnr=0,name='tag_fix'})==1 and clients[1] and clients[1].initialized
end,20))
_G.__tag_ui={startup_errmsg=vim.v.errmsg}
vim.v.errmsg=''
return {startup_errmsg=_G.__tag_ui.startup_errmsg,mapped=vim.fn.maparg('gra','n'),visual_mapped=vim.fn.maparg('gra','x')~=''}`,
    [],
  ]);
  if (setup.mapped !== '<Cmd>Lspsaga code_action<CR>' || setup.visual_mapped)
    throw new Error(
      'Saga default action mapping failed: ' + JSON.stringify(setup),
    );
  const wrapMenu = await rpc('nvim_exec_lua', [
    `local state=_G.__tag_ui
state.bufnr=vim.api.nvim_get_current_buf()
state.before=table.concat(vim.api.nvim_buf_get_lines(state.bufnr,0,-1,false),'\\n')
state.input=vim.ui.input
state.prompts=0
vim.ui.input=function(_,callback) state.prompts=state.prompts+1; callback('div.wrapper') end
local line=vim.api.nvim_buf_get_lines(0,5,6,false)[1]
vim.api.nvim_win_set_cursor(0,{6,assert(line:find('visible',1,true))-1})
vim.cmd.Lspsaga('code_action')
local saga=require('lspsaga.codeaction')
assert(vim.wait(15000,function()
 return saga.action_winid and vim.api.nvim_win_is_valid(saga.action_winid)
end,20))
local lines=vim.api.nvim_buf_get_lines(saga.action_bufnr,0,-1,false)
local target
for index,line in ipairs(lines) do
 if line:find('添加外层标签',1,true) then target=index; break end
end
assert(target,'Wrap action is missing from Saga menu')
vim.api.nvim_win_set_cursor(saga.action_winid,{target,1})
local names={}
for _,client in ipairs(vim.lsp.get_clients({bufnr=state.bufnr,method='textDocument/codeAction'})) do names[#names+1]=client.name end
return {target=target,prompts=state.prompts,clients=names,height=vim.api.nvim_win_get_height(saga.action_winid),count=#lines}`,
    [],
  ]);
  await rpc('nvim_input', ['<CR>']);
  await delay(200);
  const wrapped = await rpc('nvim_exec_lua', [
    `local state=_G.__tag_ui
local after=table.concat(vim.api.nvim_buf_get_lines(state.bufnr,0,-1,false),'\\n')
vim.ui.input=state.input
vim.cmd.undo()
return {prompts=state.prompts,after=after,restored=table.concat(vim.api.nvim_buf_get_lines(state.bufnr,0,-1,false),'\\n')==state.before,errmsg=vim.v.errmsg}`,
    [],
  ]);
  if (
    wrapMenu.prompts ||
    wrapMenu.height < 1 ||
    wrapMenu.height > wrapMenu.count ||
    !wrapMenu.clients.includes('tag_fix') ||
    !wrapMenu.clients.includes('vue_ls') ||
    wrapped.prompts !== 1 ||
    !wrapped.after.includes('<div class="wrapper"><div v-if="visible">') ||
    !wrapped.restored ||
    wrapped.errmsg
  )
    throw new Error(
      'Saga Enter to Emmet wrap failed: ' +
        JSON.stringify({ wrapMenu, wrapped }),
    );
  await rpc('nvim_ui_try_resize', [50, 16]);
  await delay(100);
  await rpc('nvim_exec_lua', [
    `vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/TagActions.html')
local extra={}
for i=1,24 do extra[i]=string.rep('x',80) end
vim.api.nvim_buf_set_lines(0,-1,-1,false,extra)
vim.api.nvim_win_set_cursor(0,{30,40})
local client=vim.lsp.get_clients({bufnr=0,name='tag_fix'})[1]
local tuples={}
for i=1,10 do tuples[i]={client.id,{title=('Action %02d'):format(i)}} end
local saga=require('lspsaga.codeaction')
saga.bufnr=vim.api.nvim_get_current_buf()
saga:action_callback(tuples,{bufnr=saga.bufnr})`,
    [],
  ]);
  await delay(150);
  const edge = await rpc('nvim_exec_lua', [
    `local saga=require('lspsaga.codeaction')
local config=vim.api.nvim_win_get_config(saga.action_winid)
local pos=vim.fn.win_screenpos(saga.action_winid)
local result={height=config.height,width=config.width,row=pos[1],col=pos[2],count=vim.api.nvim_buf_line_count(saga.action_bufnr),errmsg=vim.v.errmsg}
saga:close_action_window()
return result`,
    [],
  ]);
  if (
    edge.row < 1 ||
    edge.col < 1 ||
    edge.row + edge.height > 16 ||
    edge.col + edge.width > 50 ||
    edge.height < 1 ||
    edge.height >= 10 ||
    edge.count !== 10 ||
    edge.errmsg
  )
    throw new Error('Saga edge menu failed: ' + JSON.stringify(edge));
  const result = { setup, wrapMenu, wrapped, edge };
  return result;
}
