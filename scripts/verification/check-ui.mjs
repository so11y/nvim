import {spawn} from 'node:child_process';
import {readFileSync,writeFileSync} from 'node:fs';
import {dirname,resolve,basename} from 'node:path';
import {fileURLToPath} from 'node:url';
import {encode,decodeMultiStream} from '@msgpack/msgpack';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const lock=JSON.parse(readFileSync(resolve(root,'tools.lock.json'),'utf8'));
const suite=process.argv[2] || 'workflows';
const output=resolve(process.argv[3] || (suite.replace(/[^a-zA-Z0-9_-]/g,'_')+'-result.json'));
const host=suite==='host';
const args=['--embed','-i','NONE'];
if(host){
 const runtime=process.env.NVIM_VSCODE_RUNTIME;
 if(!runtime)throw new Error('Set NVIM_VSCODE_RUNTIME to the extension runtime directory');
 args.push('--cmd','let g:vscode_channel=1','--cmd',"execute 'source' fnameescape('"+runtime.replaceAll("'","''")+"/vscode-neovim.vim')");
}
const editor=spawn('C:/tools/neovim/nvim-v'+lock.neovim+'/nvim-win64/bin/nvim.exe',args,{env:{...process.env,NVIM_APPNAME:basename(root)},windowsHide:true});
const errors=[],hostActions=[],calls=new Map();let sequence=0;
editor.stderr.on('data',b=>errors.push(b.toString()));
editor.on('error',e=>errors.push(e.message));
(async()=>{for await(const message of decodeMultiStream(editor.stdout)){
 if(message[0]===1){const pending=calls.get(message[1]);calls.delete(message[1]);if(pending)message[2]?pending.reject(new Error(JSON.stringify(message[2]))):pending.resolve(message[3]);}
 else if(message[0]===0){hostActions.push({kind:'request',method:message[2],params:message[3]});editor.stdin.write(encode([1,message[1],null,message[2]==='vscode-action' && message[3][0]==='get_config'?[]:null]));}
 else if(message[0]===2 && message[1]==='vscode-action')hostActions.push({kind:'notification',method:message[1],params:message[2]});
}})().catch(e=>errors.push(e.message));
function rpc(method,params=[]){return new Promise((resolve,reject)=>{const id=++sequence;calls.set(id,{resolve,reject});editor.stdin.write(encode([0,id,method,params]));});}
const delay=ms=>new Promise(r=>setTimeout(r,ms));
const deadlineMs=suite==='rust-debug.lua'?120000:60000;
const deadline=setTimeout(()=>{errors.push('Verification timed out after '+deadlineMs+' ms');for(const call of calls.values())call.reject(new Error('Verification timed out'));editor.kill();},deadlineMs);
try{
 await rpc('nvim_get_api_info');
 await rpc('nvim_set_client_info',['Upgrade verification',{major:1,minor:0},'ui',{},{}]);
 await rpc('nvim_ui_attach',[130,40,{rgb:true,ext_linegrid:true}]);
 await delay(1500);
 let result;
 if(suite==='selection'){
  await rpc('nvim_exec_lua',["vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/refactor.ts'); assert(vim.wait(15000,function() return #vim.lsp.get_clients({bufnr=0,name='vtsls',method='textDocument/selectionRange'})>0 end,50)); vim.api.nvim_win_set_cursor(0,{2,18})",[]]);
  const phases=[];for(const keys of ['v','<CR>','<CR>','<BS>']){await rpc('nvim_input',[keys]);await delay(350);phases.push(await rpc('nvim_exec_lua',['return {mode=vim.fn.mode(),start=vim.fn.getpos("v"),cursor=vim.api.nvim_win_get_cursor(0),errmsg=vim.v.errmsg}',[]]));}
  const range=p=>JSON.stringify([p.start,p.cursor]);
  writeFileSync(output,JSON.stringify({phases},null,2)+'\n');
  if(range(phases[1])===range(phases[2]) || range(phases[1])!==range(phases[3]))throw new Error('Selection expansion/contraction failed: '+JSON.stringify(phases));
  result={phases};
 }else{
  const lua=suite==='workflows'?"return dofile(vim.fn.stdpath('config')..'/scripts/check-workflows.lua')":readFileSync(resolve(dirname(fileURLToPath(import.meta.url)),suite==='host'?'host.lua':suite),'utf8');
  result=await rpc('nvim_exec_lua',[lua,[]]);
  writeFileSync(output,JSON.stringify(result,null,2)+'\n');
  if(result.failures && Object.keys(result.failures).length)throw new Error(JSON.stringify(result.failures));
  if(result.error || result.errmsg)throw new Error(result.error || result.errmsg);
 }
 if(host){result.hostActions=hostActions;for(const name of ['editor.action.formatDocument','outline.focus','editor.toggleFold','editor.action.smartSelect.expand','editor.action.smartSelect.shrink']){if(!hostActions.some(a=>a.method==='vscode-action' && a.params[0]===name))throw new Error('Host action was not emitted: '+name);}}
 writeFileSync(output,JSON.stringify(result,null,2)+'\n');
 await rpc('nvim_exec_lua',["vim.schedule(function() vim.cmd('qa!') end)",[]]);
 console.log('PASS '+suite+' -> '+output);
}catch(e){errors.push(e.stack);editor.kill();process.exitCode=1;}
finally{clearTimeout(deadline);writeFileSync(output+'.errors',errors.join('\n'));}
