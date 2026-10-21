import { setTimeout as delay } from 'node:timers/promises';

export async function verifyBreadcrumbsUI(rpc) {
  await rpc('nvim_exec_lua', [
    "vim.v.errmsg=''; vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/App.vue')",
    [],
  ]);
  await rpc('nvim_input', ['jj']);
  await delay(100);
  const result = await rpc('nvim_exec_lua', [
    `local autocmds=0
for _,cmd in ipairs(vim.api.nvim_get_autocmds({})) do
 if cmd.group_name and cmd.group_name:lower():find('dropbar',1,true) then autocmds=autocmds+1 end
end
return {configured=require('lazy.core.config').plugins['dropbar.nvim']~=nil,
 loaded=package.loaded['dropbar']~=nil,winbar=vim.wo.winbar,autocmds=autocmds,
 picker=vim.fn.maparg('<Space>;','n'),toggle=vim.fn.maparg('<Space>wd','n'),errmsg=vim.v.errmsg}`,
    [],
  ]);
  if (
    result.configured ||
    result.loaded ||
    result.winbar !== '' ||
    result.autocmds ||
    result.picker ||
    result.toggle ||
    result.errmsg
  )
    throw new Error(
      'Breadcrumb plugin was not disabled: ' + JSON.stringify(result),
    );
  return result;
}
