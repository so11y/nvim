import {mkdtempSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {setTimeout as delay} from 'node:timers/promises';

export async function verifyEmmetUI(rpc) {
  const root = mkdtempSync(join(tmpdir(), 'nvim-emmet-ui-'));
  const lua = (code, ...args) => rpc('nvim_exec_lua', [code, args]);
  const input = async keys => { await rpc('nvim_input', [keys]); await delay(100); };
  const cases = [
    {ext:'html',lines:['section.card'],row:1,expected:'<section class="card">'},
    {ext:'vue',name:'template',lines:['<script setup>','const watch = 1;','</script>','<template>','你好😀 section.card','</template>'],row:5,expected:'<section class="card">'},
    {ext:'vue',name:'style',lines:['<template><div /></template>','<style>','.card {','m10','}','</style>'],row:4,expected:'margin: 10px;'},
    {ext:'vue',name:'scss',lines:['<template><div /></template>','<style scoped lang="scss">','.card {','m10','}','</style>'],row:4,expected:'margin: 10px;'},
    {ext:'jsx',lines:['const view = (','section.card',');'],row:2,expected:'<section className="card">'},
    {ext:'tsx',lines:['const view = (','section.card',');'],row:2,expected:'<section className="card">'},
    {ext:'css',lines:['.card {','m10','}'],row:2,expected:'margin: 10px;'},
    {ext:'scss',lines:['.card {','m10','}'],row:2,expected:'margin: 10px;'},
  ];
  await lua("vim.v.errmsg='';assert(not require('lazy.core.config').plugins['emmet-vim']);assert(vim.fn.exists('*emmet#expandWord')==0)");
  const results=[];
  for (const test of cases) {
    await input('<Esc>');
    const file=join(root,'completion-'+(test.name||test.ext)+'.'+test.ext);
    writeFileSync(file,test.lines.join('\n')+'\n');
    await lua(
      "local file,row=...;vim.cmd.edit(file);local b=vim.api.nvim_get_current_buf();"+
      "assert(vim.wait(10000,function() local c=vim.lsp.get_clients({bufnr=b,name='emmet_language_server'})[1];return c and c.initialized end,20),'Emmet did not initialize');"+
      "vim.api.nvim_win_set_cursor(0,{row,0})",file,test.row);
    await input('A');
    await lua("require('blink.cmp').show({providers={'lsp'}})");
    const chosen=await lua(
      "local expected=...;local list=require('blink.cmp.completion.list');local candidate;"+
      "assert(vim.wait(10000,function() for i,item in ipairs(list.items) do "+
      "local client=item.client_id and vim.lsp.get_client_by_id(item.client_id);"+
      "local text=item.textEdit and item.textEdit.newText or item.insertText or '';"+
      "if client and client.name=='emmet_language_server' and text:find(expected,1,true) then candidate=i;return require('blink.cmp').is_visible() end end end,20),'Emmet candidate did not appear in Blink');"+
      "list.select(candidate,{auto_insert=false});return {label=list.items[candidate].label,source=list.items[candidate].source_id}",test.expected);
    await input('<Tab>');
    const accepted=await lua("return {lines=vim.api.nvim_buf_get_lines(0,0,-1,false),snippet=vim.snippet.active(),errmsg=vim.v.errmsg}");
    if(!accepted.lines[test.row-1].includes(test.expected)||accepted.errmsg)
      throw new Error('Tab did not accept Emmet in '+test.ext+': '+JSON.stringify(accepted));
    results.push({extension:test.ext,region:test.name,...chosen,...accepted});
    await input('<Esc>');
    await lua('vim.snippet.stop();vim.bo.modified=false');
  }

  const file=join(root,'indent.txt');writeFileSync(file,'\n');
  await lua('vim.cmd.edit(...);vim.bo.expandtab=true;vim.bo.softtabstop=4',file);
  await input('i<Tab>');
  const indent=await lua("assert(vim.api.nvim_get_current_line()=='    ');return true");
  await lua("vim.snippet.expand('first $'..'{1:one} second $'..'{2:two}$0')");
  const first=await lua('return vim.api.nvim_win_get_cursor(0)');
  await input('<Tab>');
  const second=await lua('return vim.api.nvim_win_get_cursor(0)');
  if(JSON.stringify(first)===JSON.stringify(second))throw new Error('Tab did not move to the next snippet field');
  await input('<Esc>');
  await lua('vim.snippet.stop();vim.bo.modified=false');
  return {root,completions:results,indent,snippet_navigation:{first,second},errmsg:await lua('return vim.v.errmsg')};
}
