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
  const cases=[
   {name:'typescript',file:'refactor.ts',row:2,needle:'a + b'},
   {name:'vue-script',file:'App.vue',row:3,needle:'ref'},
   {name:'vue-function',file:'App.vue',row:5,needle:'count'},
   {name:'vue-template',file:'App.vue',row:7,needle:'greet'},
  ];
  const range=p=>JSON.stringify([p.start,p.cursor]);
  const selected=()=>rpc('nvim_exec_lua',['return {mode=vim.fn.mode(),start=vim.fn.getpos("v"),cursor=vim.api.nvim_win_get_cursor(0),errmsg=vim.v.errmsg}',[]]);
  const results=[];
  for(const c of cases){
   await rpc('nvim_exec_lua',[`vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/${c.file}'); assert(vim.wait(15000,function() return vim.treesitter.get_parser(0,nil,{error=false})~=nil end,50)); local line=vim.api.nvim_buf_get_lines(0,${c.row-1},${c.row},false)[1]; vim.api.nvim_win_set_cursor(0,{${c.row},assert(line:find('${c.needle}',1,true))-1})`,[]]);
   const phases=[];
   for(const keys of ['v','<CR>','<CR>','<BS>']){await rpc('nvim_input',[keys]);await delay(100);phases.push(await selected());}
   if(phases.some(p=>p.mode!=='v'||p.errmsg)||range(phases[0])===range(phases[1])||range(phases[1])===range(phases[2])||range(phases[1])!==range(phases[3]))throw new Error('Selection expansion/contraction failed for '+c.name+': '+JSON.stringify(phases));
   const growth=[];
   for(let i=0;i<20;i++){await rpc('nvim_input',['<CR>']);await delay(30);growth.push(await selected());}
   const root=growth.at(-1);
   if(root.start[1]!==1||root.start[2]!==1)throw new Error('Selection did not reach file root for '+c.name+': '+JSON.stringify(root));
   if(c.name==='vue-function'&&!growth.some(p=>p.start[1]===5&&p.start[2]===1&&p.cursor[0]===5))throw new Error('Selection skipped Vue function node: '+JSON.stringify(growth));
   if(c.name==='vue-template'&&!growth.some(p=>p.start[1]===7&&p.start[2]===11&&p.cursor[0]===7&&p.cursor[1]>=62))throw new Error('Selection skipped Vue template tag: '+JSON.stringify(growth));
   const levels=[phases[1],phases[2],...growth].filter((p,i,all)=>i===0||range(p)!==range(all[i-1]));
   const shrink=[];
   for(let i=levels.length-2;i>=0;i--){await rpc('nvim_input',['<BS>']);await delay(30);const p=await selected();shrink.push(p);if(range(p)!==range(levels[i]))throw new Error('Selection did not shrink through '+c.name+' level '+i+': '+JSON.stringify({levels,shrink}));}
   results.push({name:c.name,phases,growth:levels.slice(2),shrink});
   await rpc('nvim_input',['<Esc>']);await delay(50);
  }
  result={results};
 }else if(suite==='breadcrumbs'){
  await rpc('nvim_exec_lua',["vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/App.vue'); assert(vim.wait(5000,function() return vim.treesitter.get_parser(0,nil,{error=false})~=nil end,50))",[]]);
  const barState=()=>rpc('nvim_exec_lua',["return {winbar=vim.wo.winbar,loaded=package.loaded['dropbar']~=nil,errmsg=vim.v.errmsg}",[]]);
  const phases=[await barState()];
  await rpc('nvim_input',[' wd']);await delay(200);phases.push(await barState());
  await rpc('nvim_input',[' wd']);await delay(100);phases.push(await barState());
  if(phases[0].winbar!==''||phases[0].loaded||phases[1].winbar===''||!phases[1].loaded||phases[2].winbar!==''||phases.some(p=>p.errmsg))throw new Error('Breadcrumb default-off or toggle failed: '+JSON.stringify(phases));
  result={phases};
 }else if(suite==='action-ui'){
  const setup=await rpc('nvim_exec_lua',[`vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/refactor.ts')
assert(vim.wait(15000,function() return #vim.lsp.get_clients({bufnr=0,name='vtsls',method='textDocument/codeAction'})>0 end,50))
require('lazy').load({plugins={'tiny-code-action.nvim'}})
local bufnr=vim.api.nvim_get_current_buf()
local client=vim.lsp.get_clients({bufnr=bufnr,name='vtsls'})[1]
local response=client:request_sync('textDocument/codeAction',{textDocument=vim.lsp.util.make_text_document_params(),range={start={line=1,character=17},['end']={line=1,character=22}},context={diagnostics={}}},15000,bufnr)
local action
for _,candidate in ipairs(response.result) do if candidate.disabled then action=vim.deepcopy(candidate); break end end
assert(action,'Server did not return a disabled action')
action.edit={changes={[vim.uri_from_bufnr(bufnr)]={{range={start={line=1,character=8},['end']={line=1,character=14}},newText='BLOCKED'}}}}
_G.__action_ui={bufnr=bufnr,before=vim.api.nvim_buf_get_lines(bufnr,0,-1,false),reason=action.disabled.reason}
require('tiny-code-action.pickers.buffer').create(require('tiny-code-action').config,{{action=action,client=client,context={}}},bufnr)
return {reason=action.disabled.reason,picker=vim.api.nvim_buf_get_lines(0,0,-1,false)}`,[]]);
  await delay(200);
  const preview=await rpc('nvim_exec_lua',["local state=require('tiny-code-action.pickers.buffer_utils.preview').get_preview_state(); return {lines=vim.api.nvim_buf_get_lines(state.buf,0,-1,false),errmsg=vim.v.errmsg}",[]]);
  await rpc('nvim_input',['<Tab>']);await delay(100);
  const applied=await rpc('nvim_exec_lua',["return {same=vim.deep_equal(_G.__action_ui.before,vim.api.nvim_buf_get_lines(_G.__action_ui.bufnr,0,-1,false)),errmsg=vim.v.errmsg}",[]]);
  const enabled=await rpc('nvim_exec_lua',[`local ctx=_G.__action_ui
local action={title='Replace result',kind='quickfix',edit={changes={[vim.uri_from_bufnr(ctx.bufnr)]={{range={start={line=1,character=8},['end']={line=1,character=14}},newText='applied'}}}}}
local client=vim.lsp.get_clients({bufnr=ctx.bufnr,name='vtsls'})[1]
require('tiny-code-action.pickers.buffer').create(require('tiny-code-action').config,{{action=action,client=client,context={}}},ctx.bufnr)
return {picker=vim.api.nvim_buf_get_lines(0,0,-1,false),errmsg=vim.v.errmsg}`,[]]);
  await rpc('nvim_input',['<Tab>']);await delay(100);
  const enabledApplied=await rpc('nvim_exec_lua',[`local ctx=_G.__action_ui; local lines=vim.api.nvim_buf_get_lines(ctx.bufnr,0,-1,false); local applied=lines[2]:find('const applied =',1,true)~=nil; vim.api.nvim_buf_set_lines(ctx.bufnr,0,-1,false,ctx.before); return {applied=applied,errmsg=vim.v.errmsg}`,[]]);
  if(!setup.picker.some(line=>line.includes('不可用')&&line.includes(setup.reason))||!preview.lines.join('\n').includes(setup.reason)||!applied.same||!enabledApplied.applied||preview.errmsg||applied.errmsg||enabled.errmsg||enabledApplied.errmsg)throw new Error('Code Action UI or execution guard failed: '+JSON.stringify({setup,preview,applied,enabled,enabledApplied}));
  result={setup,preview,applied,enabled,enabledApplied};
 }else if(suite==='hover'){
  await rpc('nvim_exec_lua',["vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/refactor.ts'); assert(vim.wait(15000,function() return #vim.lsp.get_clients({bufnr=0,name='vtsls',method='textDocument/hover'})>0 end,50)); vim.api.nvim_win_set_cursor(0,{1,16})",[]]);
  const hoverState=()=>rpc('nvim_exec_lua',["local wins,details={},{}; for _,win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do local ok,source=pcall(vim.api.nvim_win_get_var,win,'textDocument/hover'); details[#details+1]={win=win,relative=vim.api.nvim_win_get_config(win).relative,source=ok and source or nil,ft=vim.bo[vim.api.nvim_win_get_buf(win)].filetype}; if ok then wins[#wins+1]=win end end; return {wins=wins,details=details,current=vim.api.nvim_get_current_win(),errmsg=vim.v.errmsg}",[]]);
  const waitForHover=async()=>{for(let i=0;i<40;i++){await delay(100);const state=await hoverState();if(state.wins.length)return state;}return hoverState();};
  const phases=[];
  await rpc('nvim_exec_lua',['vim.lsp.buf.hover()',[]]);phases.push(await waitForHover());
  await rpc('nvim_input',['<Esc>']);await delay(100);phases.push(await hoverState());
  await rpc('nvim_exec_lua',['vim.lsp.buf.hover()',[]]);phases.push(await waitForHover());
  await rpc('nvim_exec_lua',['vim.lsp.buf.hover()',[]]);await delay(100);phases.push(await hoverState());
  await rpc('nvim_input',['<Esc>']);await delay(100);phases.push(await hoverState());
  if(phases[0].wins.length!==1||phases[1].wins.length||phases[2].wins.length!==1||phases[3].current!==phases[3].wins[0]||phases[4].wins.length||phases.some(p=>p.errmsg))throw new Error('Hover Esc behavior failed: '+JSON.stringify(phases));
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
