import {spawn} from 'node:child_process';
import {readFileSync,writeFileSync} from 'node:fs';
import {dirname,resolve,basename} from 'node:path';
import {fileURLToPath} from 'node:url';
import {encode,decodeMultiStream} from '@msgpack/msgpack';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const suite=process.argv[2] || 'workflows';
const output=resolve(process.argv[3] || (suite.replace(/[^a-zA-Z0-9_-]/g,'_')+'-result.json'));
const host=suite==='host';
const args=['--embed','-i','NONE'];
if(host){
 const runtime=process.env.NVIM_VSCODE_RUNTIME;
 if(!runtime)throw new Error('Set NVIM_VSCODE_RUNTIME to the extension runtime directory');
 args.push('--cmd','let g:vscode_channel=1','--cmd',"execute 'source' fnameescape('"+runtime.replaceAll("'","''")+"/vscode-neovim.vim')");
}
const editor=spawn(process.env.NEOVIM_BIN || 'nvim',args,{env:{...process.env,NVIM_APPNAME:basename(root)},windowsHide:true});
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
const deadlineMs=['rust-debug.lua','navigation-performance'].includes(suite)?120000:60000;
const deadline=setTimeout(()=>{errors.push('Verification timed out after '+deadlineMs+' ms');for(const call of calls.values())call.reject(new Error('Verification timed out'));editor.kill();},deadlineMs);
try{
 await rpc('nvim_get_api_info');
 await rpc('nvim_set_client_info',['Upgrade verification',{major:1,minor:0},'ui',{},{}]);
 await rpc('nvim_ui_attach',[130,40,{rgb:true,ext_linegrid:true}]);
 await delay(1500);
 if(!host)await rpc('nvim_exec_lua',["require('lazy').load({plugins={'blink.cmp'}}); assert(vim.wait(45000,function() return package.loaded['blink.cmp.completion']~=nil end,50),'Blink first-run setup timed out')",[]]);
 // Start each workflow with a fresh Vim error marker after plugin initialization.
 await rpc('nvim_exec_lua',["vim.v.errmsg=''",[]]);
 let result;
 if(suite==='format-keys'){
  const filename=process.env.NVIM_TEST_ROOT+"/beta/manual 格式's.js";
  const setText=text=>rpc('nvim_exec_lua',['vim.api.nvim_buf_set_lines(0,0,-1,false,{...})',[text]]);
  const text=()=>rpc('nvim_exec_lua',["return table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),'\\n')",[]]);
  await rpc('nvim_exec_lua',["local file=...; vim.fn.writefile({'const entry={message:\"你好😀\"};'},file); vim.cmd.edit(file)",[filename]]);
  await rpc('nvim_input',['<A-F>']);await delay(300);
  const normal=await text();
  if(normal!=="const entry = { message: '你好😀' }")throw new Error('Normal format key or project config failed: '+normal);
  await setText('const entry={message:"第二次😀"};');
  await rpc('nvim_input',['i<A-F><Esc>']);await delay(300);
  const insert=await text();
  if(insert!=="const entry = { message: '第二次😀' }")throw new Error('Insert format key failed: '+insert);
  await setText('const saved={value:2};');
  await rpc('nvim_input',['<A-s>']);await delay(300);
  const saved=readFileSync(filename,'utf8').trim();
  if(saved!=='const saved = { value: 2 }')throw new Error('Save format key failed: '+saved);
  result={normal,insert,saved,errmsg:await rpc('nvim_eval',['v:errmsg'])};
  if(result.errmsg)throw new Error(result.errmsg);
 }else if(suite==='selection'){
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
  await rpc('nvim_exec_lua',["vim.v.errmsg=''; vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/App.vue')",[]]);
  await rpc('nvim_input',['jj']);await delay(100);
  result=await rpc('nvim_exec_lua',[`local autocmds=0
for _,cmd in ipairs(vim.api.nvim_get_autocmds({})) do
 if cmd.group_name and cmd.group_name:lower():find('dropbar',1,true) then autocmds=autocmds+1 end
end
return {configured=require('lazy.core.config').plugins['dropbar.nvim']~=nil,
 loaded=package.loaded['dropbar']~=nil,winbar=vim.wo.winbar,autocmds=autocmds,
 picker=vim.fn.maparg('<Space>;','n'),toggle=vim.fn.maparg('<Space>wd','n'),errmsg=vim.v.errmsg}`,[]]);
  if(result.configured||result.loaded||result.winbar!==''||result.autocmds||result.picker||result.toggle||result.errmsg)throw new Error('Breadcrumb plugin was not disabled: '+JSON.stringify(result));
 }else if(suite==='navigation-performance'){
   const setup=await rpc('nvim_exec_lua',[`vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/refactor.ts')
assert(vim.wait(15000,function() return #vim.lsp.get_clients({bufnr=0,name='vtsls'})>0 end,50))
local lines={}
for i=1,600 do vim.list_extend(lines,{('export function nav%d() {'):format(i),'  const value = 1;','  return value;','}'}) end
lines[2]='// '..string.rep('x',1500)
vim.api.nvim_buf_set_lines(0,0,-1,false,lines)
_G.__navigation_maps={j=vim.fn.maparg('j','n',false,true),k=vim.fn.maparg('k','n',false,true)}
local autocmds={}
for _,autocmd in ipairs(vim.api.nvim_get_autocmds({event='CursorMoved',buffer=0})) do
 autocmds[#autocmds+1]={group=autocmd.group_name,desc=autocmd.desc}
end
return {line_count=vim.api.nvim_buf_line_count(0),filetype=vim.bo.filetype,has_motion=vim.fn.maparg(']f','n')~='',cursor_moved=autocmds}`,[]]);
  await delay(1500);
  const samples=[];
  async function measure(key,mapped,start,expected,steps=300,ignoreCursorMoved=false){
   await rpc('nvim_exec_lua',[`local key='${key}'; local saved=_G.__navigation_maps[key]
pcall(vim.keymap.del,'n',key)
if ${mapped} then vim.keymap.set('n',key,saved.rhs,{expr=saved.expr==1}) end
vim.o.eventignore=${ignoreCursorMoved ? "'CursorMoved'" : "''"}
vim.api.nvim_win_set_cursor(0,{${start[0]},${start[1]}})
vim.g.navigation_done=0`,[]]);
   await delay(100);
   const started=performance.now();
   await rpc('nvim_input',[key.repeat(steps)+':let g:navigation_done=1<CR>']);
   while(!(await rpc('nvim_get_var',['navigation_done'])))await delay(2);
   const elapsed=performance.now()-started;
   const cursor=await rpc('nvim_win_get_cursor',[0]);
   if(JSON.stringify(cursor)!==JSON.stringify(expected))throw new Error('Navigation target failed: '+JSON.stringify({key,mapped,cursor,expected}));
   samples.push({key,mapped,ignoreCursorMoved,elapsed_ms:elapsed,steps,per_key_ms:elapsed/steps});
  }
  for(let i=0;i<7;i++){
   for(const mapped of i%2===0?[true,false]:[false,true]){
    await measure('j',mapped,[100,0],[400,0]);
    await measure('k',mapped,[400,0],[100,0]);
   }
  }
  await measure('l',false,[2,500],[2,800]);
  await measure('h',false,[2,800],[2,500]);
  for(let i=0;i<5;i++)for(const ignoreCursorMoved of i%2===0?[false,true]:[true,false]){
   await measure('j',true,[100,0],[400,0],300,ignoreCursorMoved);
  }
  await rpc('nvim_exec_lua',["vim.o.eventignore=''",[]]);
  await rpc('nvim_exec_lua',[`for key,saved in pairs(_G.__navigation_maps) do vim.keymap.set('n',key,saved.rhs,{expr=saved.expr==1}) end`,[]]);
  async function inputAndWait(keys){
   await rpc('nvim_set_var',['navigation_done',0]);
   const started=performance.now();
   await rpc('nvim_input',[keys+':let g:navigation_done=1<CR>']);
   while(!(await rpc('nvim_get_var',['navigation_done'])))await delay(2);
   return {elapsed_ms:performance.now()-started,cursor:await rpc('nvim_win_get_cursor',[0])};
  }
  await rpc('nvim_win_set_cursor',[0,[1,7]]);
  const ast=[];
  const first=await inputAndWait(']f');
  if(first.cursor[0]!==5)throw new Error('AST forward jump failed: '+JSON.stringify({setup,first}));
  ast.push({keys:']f',...first});
  const counted=await inputAndWait('3]f');
  ast.push({keys:'3]f',...counted});
  await rpc('nvim_win_set_cursor',[0,first.cursor]);
  for(let i=0;i<3;i++)ast.push({keys:']f repeated',...await inputAndWait(']f')});
  if(JSON.stringify(ast.at(-1).cursor)!==JSON.stringify(counted.cursor))throw new Error('AST count differs from three jumps: '+JSON.stringify(ast));
  const backward=await inputAndWait('[f');
  const repeatNext=await inputAndWait(';');
  const repeatPrevious=await inputAndWait(',');
  ast.push({keys:'[f',...backward},{keys:';',...repeatNext},{keys:',',...repeatPrevious});
  if(JSON.stringify(repeatNext.cursor)!==JSON.stringify(counted.cursor)||JSON.stringify(repeatPrevious.cursor)!==JSON.stringify(backward.cursor))throw new Error('AST repeat direction failed: '+JSON.stringify(ast));
  const before=await rpc('nvim_exec_lua',[
   "vim.api.nvim_win_set_cursor(0,{2,3}); return #vim.api.nvim_get_current_line()",[]]);
  const editing=await inputAndWait('i'+'y'.repeat(100)+'<Esc>');
  const after=await rpc('nvim_exec_lua',["return {length=#vim.api.nvim_get_current_line(),mode=vim.fn.mode(),errmsg=vim.v.errmsg}",[]]);
  if(after.length!==before+100||after.mode!=='n'||after.errmsg)throw new Error('Editing sequence failed: '+JSON.stringify({before,editing,after}));
  const search=[];
  for(let i=0;i<5;i++)for(const active of i%2===0?[true,false]:[false,true]){
   await rpc('nvim_exec_lua',[`vim.fn.setreg('/','${active?'value':''}'); vim.o.hlsearch=true`,[]]);
   const state=await rpc('nvim_exec_lua',["return {hlsearch=vim.v.hlsearch,pattern=vim.fn.getreg('/'),statusline=vim.o.statusline}",[]]);
   if(state.pattern!==(active?'value':''))throw new Error('Search pattern mismatch: '+JSON.stringify(state));
   await measure('j',true,[100,0],[400,0]);
   search.push({active,...state,...samples.at(-1)});
  }
  const editSamples=[];
  for(let i=0;i<5;i++)for(const active of i%2===0?[true,false]:[false,true]){
   await rpc('nvim_exec_lua',[`vim.api.nvim_buf_set_lines(0,1,2,false,{'// '..string.rep('x',1500)}); vim.api.nvim_win_set_cursor(0,{2,3}); vim.fn.setreg('/','${active?'value':''}'); vim.o.hlsearch=true`,[]]);
   await delay(100);
   const phase=await inputAndWait('i'+'y'.repeat(100)+'<Esc>');
   const length=await rpc('nvim_exec_lua',["return #vim.api.nvim_get_current_line()",[]]);
   if(length!==1603)throw new Error('Search editing length mismatch: '+JSON.stringify({active,phase,length}));
   editSamples.push({active,elapsed_ms:phase.elapsed_ms,length});
   await delay(200);
  }
   result={setup,samples,ast,editing,after,search,editSamples};
 }else if(suite==='tag-ui'){
  const setup=await rpc('nvim_exec_lua',[`vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/TagActions.vue')
assert(vim.wait(15000,function()
 local clients=vim.lsp.get_clients({bufnr=0,name='vtsls'})
 return #vim.lsp.get_clients({bufnr=0,name='tag_fix'})==1 and clients[1] and clients[1].initialized
end,20))
_G.__tag_ui={startup_errmsg=vim.v.errmsg}
vim.v.errmsg=''
return {startup_errmsg=_G.__tag_ui.startup_errmsg,mapped=vim.fn.maparg('gra','n'),visual_mapped=vim.fn.maparg('gra','x')~=''}`,[]]);
  if(setup.mapped!=='<Cmd>Lspsaga code_action<CR>'||setup.visual_mapped)throw new Error('Saga default action mapping failed: '+JSON.stringify(setup));
  const wrapMenu=await rpc('nvim_exec_lua',[`local state=_G.__tag_ui
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
return {target=target,prompts=state.prompts,clients=names,height=vim.api.nvim_win_get_height(saga.action_winid),count=#lines}`,[]]);
  await rpc('nvim_input',['<CR>']);await delay(200);
  const wrapped=await rpc('nvim_exec_lua',[`local state=_G.__tag_ui
local after=table.concat(vim.api.nvim_buf_get_lines(state.bufnr,0,-1,false),'\\n')
vim.ui.input=state.input
vim.cmd.undo()
return {prompts=state.prompts,after=after,restored=table.concat(vim.api.nvim_buf_get_lines(state.bufnr,0,-1,false),'\\n')==state.before,errmsg=vim.v.errmsg}`,[]]);
  if(wrapMenu.prompts||wrapMenu.height<1||wrapMenu.height>wrapMenu.count||!wrapMenu.clients.includes('tag_fix')||!wrapMenu.clients.includes('vue_ls')||wrapped.prompts!==1||!wrapped.after.includes('<div class="wrapper"><div v-if="visible">')||!wrapped.restored||wrapped.errmsg)throw new Error('Saga Enter to Emmet wrap failed: '+JSON.stringify({wrapMenu,wrapped}));
  await rpc('nvim_ui_try_resize',[50,16]);await delay(100);
  await rpc('nvim_exec_lua',[`vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/TagActions.html')
local extra={}
for i=1,24 do extra[i]=string.rep('x',80) end
vim.api.nvim_buf_set_lines(0,-1,-1,false,extra)
vim.api.nvim_win_set_cursor(0,{30,40})
local client=vim.lsp.get_clients({bufnr=0,name='tag_fix'})[1]
local tuples={}
for i=1,10 do tuples[i]={client.id,{title=('Action %02d'):format(i)}} end
local saga=require('lspsaga.codeaction')
saga.bufnr=vim.api.nvim_get_current_buf()
saga:action_callback(tuples,{bufnr=saga.bufnr})`,[]]);
  await delay(150);
  const edge=await rpc('nvim_exec_lua',[`local saga=require('lspsaga.codeaction')
local config=vim.api.nvim_win_get_config(saga.action_winid)
local pos=vim.fn.win_screenpos(saga.action_winid)
local result={height=config.height,width=config.width,row=pos[1],col=pos[2],count=vim.api.nvim_buf_line_count(saga.action_bufnr),errmsg=vim.v.errmsg}
saga:close_action_window()
return result`,[]]);
  if(edge.row<1||edge.col<1||edge.row+edge.height>16||edge.col+edge.width>50||edge.height<1||edge.height>=10||edge.count!==10||edge.errmsg)throw new Error('Saga edge menu failed: '+JSON.stringify(edge));
  result={setup,wrapMenu,wrapped,edge};
 }else if(suite==='action-ui'){
  const setup=await rpc('nvim_exec_lua',[`vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/TagActions.html')
assert(vim.wait(5000,function() return #vim.lsp.get_clients({bufnr=0,name='tag_fix'})==1 end,20))
local bufnr=vim.api.nvim_get_current_buf()
local client=vim.lsp.get_clients({bufnr=bufnr,name='tag_fix'})[1]
local line='const 文本 = "😀"; const value = 1;'
vim.api.nvim_buf_set_lines(bufnr,0,-1,false,{line})
local col=assert(line:find('value',1,true))-1
vim.api.nvim_win_set_cursor(0,{1,col})
local edit={changes={[vim.uri_from_bufnr(bufnr)]={{range={start={line=0,character=col},['end']={line=0,character=col+5}},newText='applied'}}}}
local actions={}
for i=1,12 do actions[i]={title=('Action %02d'):format(i),edit=edit,kind='quickfix'} end
actions[12].title='Action with a command'
actions[12].command={title='After edit',command='verify.saga.action'}
_G.__action_ui={bufnr=bufnr,client=client,original=vim.lsp.buf_request_all,actions=actions,before=line,commands=0}
client.commands['verify.saga.action']=function()
 assert(vim.api.nvim_buf_get_lines(bufnr,0,-1,false)[1]:find('const applied =',1,true),'Command ran before its edit')
 _G.__action_ui.commands=_G.__action_ui.commands+1
end
vim.lsp.buf_request_all=function(buf,method,params,callback)
 local state=_G.__action_ui
 callback({[state.client.id]={result=state.actions}})
end
vim.cmd.Lspsaga('code_action')
return {before=line}`,[]]);
  await delay(150);
  const snapshot=()=>rpc('nvim_exec_lua',[`local saga=require('lspsaga.codeaction')
local preview={}
for _,win in ipairs(vim.api.nvim_list_wins()) do
 local buf=vim.api.nvim_win_get_buf(win)
 if vim.bo[buf].filetype=='diff' and vim.api.nvim_win_get_config(win).relative~='' then
  preview=vim.api.nvim_buf_get_lines(buf,0,-1,false)
 end
end
return {config=vim.api.nvim_win_get_config(saga.action_winid),lines=vim.api.nvim_buf_get_lines(saga.action_bufnr,0,-1,false),height=vim.api.nvim_win_get_height(saga.action_winid),preview=preview,unchanged=vim.api.nvim_buf_get_lines(_G.__action_ui.bufnr,0,-1,false)[1]==_G.__action_ui.before,errmsg=vim.v.errmsg}`,[]]);
  const shown=await snapshot();
  if(shown.lines.length!==12||!shown.unchanged||shown.errmsg)throw new Error('Saga action list failed: '+JSON.stringify(shown));
  await rpc('nvim_input',['j']);await delay(150);
  const previewed=await snapshot();
  if(shown.preview.length||previewed.preview.length||!previewed.unchanged||previewed.errmsg)throw new Error('Saga navigation opened a preview or changed source: '+JSON.stringify({shown,previewed}));
  await rpc('nvim_input',['<Esc>']);await delay(100);
  const cancelled=await rpc('nvim_exec_lua',[`local saga=require('lspsaga.codeaction')
return {unchanged=vim.api.nvim_buf_get_lines(_G.__action_ui.bufnr,0,-1,false)[1]==_G.__action_ui.before,closed=not (saga.action_winid and vim.api.nvim_win_is_valid(saga.action_winid))}`,[]]);
  if(!cancelled.unchanged||!cancelled.closed)throw new Error('Saga cancellation failed: '+JSON.stringify(cancelled));
  await rpc('nvim_exec_lua',["vim.cmd.Lspsaga('code_action')",[]]);await delay(100);
  await rpc('nvim_input',['j'.repeat(11)]);await delay(100);
  await rpc('nvim_input',['<Tab>']);await delay(150);
  const applied=await rpc('nvim_exec_lua',[`local state=_G.__action_ui
local line=vim.api.nvim_buf_get_lines(state.bufnr,0,-1,false)[1]
vim.cmd.undo()
return {line=line,commands=state.commands,errmsg=vim.v.errmsg}`,[]]);
  if(!applied.line.includes('const applied =')||!applied.line.includes('😀')||applied.commands!==1||applied.errmsg)throw new Error('Saga Tab, Unicode edit or command failed: '+JSON.stringify(applied));
  await rpc('nvim_exec_lua',["vim.cmd.Lspsaga('code_action')",[]]);await delay(100);
  await rpc('nvim_input',['2']);await delay(150);
  const numbered=await rpc('nvim_exec_lua',[`local state=_G.__action_ui
local line=vim.api.nvim_buf_get_lines(state.bufnr,0,-1,false)[1]
state.actions={}
vim.cmd.Lspsaga('code_action')
vim.lsp.buf_request_all=state.original
local saga=require('lspsaga.codeaction')
return {line=line,no_empty_menu=not (saga.action_winid and vim.api.nvim_win_is_valid(saga.action_winid)),errmsg=vim.v.errmsg}`,[]]);
  if(!numbered.line.includes('const applied =')||!numbered.no_empty_menu||numbered.errmsg)throw new Error('Saga number shortcut or empty response failed: '+JSON.stringify(numbered));
  result={setup,shown,previewed,cancelled,applied,numbered};
 }else if(suite==='fold-colors'){
   result=await rpc('nvim_exec_lua',[`vim.cmd.colorscheme('catppuccin-mocha')
 local cases={
   {file='TagActions.html',insert=6,lines={'','<ul class="top">','  <li>上方</li>','</ul>','','<ul class="bottom">','  <li>下方</li>','</ul>'},first=8,second=12,col=1},
   {file='TagActions.vue',insert=13,lines={'  <ul v-if="visible">','    <li>上方</li>','  </ul>','','  <ul v-for="item in items">','    <li>下方</li>','  </ul>'},first=14,second=18,col=3},
   {file='TagActions.jsx',insert=0,lines={'const View = () => (','  <f-div>','    <f-div>','      <span>上方</span>','    </f-div>','    <f-div>','      <span>下方</span>','    </f-div>','  </f-div>',');'},first=3,second=6,col=5},
   {file='TagActions.tsx',insert=0,lines={'const View = () => (','  <f-div>','    <f-div>','      <span>上方</span>','    </f-div>','    <f-div>','      <span>下方</span>','    </f-div>','  </f-div>',');'},first=3,second=6,col=5},
 }
 local result={}
 for _,case in ipairs(cases) do
   vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/'..case.file)
    if case.insert==0 then vim.bo.filetype=assert(vim.filetype.match({filename=case.file})) end
   local ufo=require('ufo'); ufo.attach(0); assert(ufo.hasAttached(0),case.file..' UFO unavailable')
    vim.api.nvim_buf_set_lines(0,case.insert,case.insert==0 and -1 or case.insert,false,case.lines)
    local bufnr=vim.api.nvim_get_current_buf()
    vim.cmd.redraw()
   if vim.bo.filetype=='html' or vim.bo.filetype=='vue' then
    ufo.enableFold(bufnr)
    assert(vim.wait(5000,function() return vim.fn.foldlevel(case.first)>vim.fn.foldlevel(case.first+3) and vim.fn.foldlevel(case.second)>vim.fn.foldlevel(case.first+3) end,25),case.file..' native tag folds missing')
   else
    vim.cmd(('%d,%dfold'):format(case.first,case.first+2))
    vim.cmd(('%d,%dfold'):format(case.second,case.second+2))
   end
   ufo.openAllFolds()
   vim.api.nvim_win_set_cursor(0,{case.first,0})
   vim.cmd.normal({args={'zc'},bang=true})
   vim.cmd.redraw()
   assert(vim.fn.foldclosed(case.first)==case.first and vim.fn.foldclosedend(case.first)==case.first+2,case.file..' first tag fold did not include closing tag')
   local first_fold={start=vim.fn.foldclosed(case.first),finish=vim.fn.foldclosedend(case.first)}
   vim.api.nvim_win_set_cursor(0,{case.second,0})
   vim.cmd.normal({args={'zc'},bang=true})
   assert(vim.fn.foldclosed(case.second)==case.second and vim.fn.foldclosedend(case.second)==case.second+2,case.file..' second tag fold did not include closing tag')
   local second_fold={start=vim.fn.foldclosed(case.second),finish=vim.fn.foldclosedend(case.second)}
   local function captures(row)
     return vim.tbl_map(function(x) return x.capture end,vim.treesitter.get_captures_at_pos(0,row-1,case.col))
   end
   local first,second=captures(case.first),captures(case.second)
    assert(vim.deep_equal(first,second) and (vim.list_contains(first,'tag') or vim.list_contains(first,'tag.builtin')),case.file..' tag captures differ')
   local normal=vim.api.nvim_get_hl(0,{name='Normal'})
   local folded=vim.api.nvim_get_hl(0,{name='Folded'})
   local ufo_bg=vim.api.nvim_get_hl(0,{name='UfoFoldedBg'})
   assert(normal.fg==folded.fg and normal.bg==folded.bg and normal.bg==ufo_bg.bg,case.file..' folded background differs')
   local function fold_text(row)
     local line=vim.api.nvim_buf_get_lines(0,row-1,row,false)[1]
      local chunks=require('ufo.render').captureVirtText(bufnr,line,row,false,{},0)
      local handler=require('ufo.decorator'):getVirtTextHandler(bufnr)
      chunks=handler(chunks,row,row+2,200,function(text) return text end)
      local text=table.concat(vim.tbl_map(function(chunk) return chunk[1] end,chunks))
      assert(text:sub(1,#line)==line,case.file..' folded text lost opening tag attributes')
      return text
   end
   local first_text=fold_text(case.first)
   local second_text=fold_text(case.second)
    result[#result+1]={file=case.file,captures=first,normal=normal,folded=folded,ufo_bg=ufo_bg,folds={first_fold,second_fold},texts={first_text,second_text}}
   vim.bo.modified=false
 end
 return {cases=result,errmsg=vim.v.errmsg}`,[]]);
 }else if(suite==='typescript-refactor.lua'){
  const setup=await rpc('nvim_exec_lua',[readFileSync(resolve(dirname(fileURLToPath(import.meta.url)),suite),'utf8'),[]]);
  await delay(150);
  await rpc('nvim_input',['sumValue<CR>']);await delay(200);
  const applied=await rpc('nvim_exec_lua',[`local b=...
assert(vim.wait(10000,function()
 return table.concat(vim.api.nvim_buf_get_lines(b,0,-1,false)):find('function sumValue',1,true)~=nil
end,50),'Extracted function could not be renamed')
return {text=vim.api.nvim_buf_get_lines(b,0,-1,false),errmsg=vim.v.errmsg}`,[setup.bufnr]]);
  if(applied.errmsg)throw new Error(applied.errmsg);
  result={...setup,...applied,rename_applied:true};
 }else if(suite==='linked-tags'){
   const lua=code=>rpc('nvim_exec_lua',[code,[]]);
   await lua("vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/TagActions.vue'); local b=vim.api.nvim_get_current_buf(); assert(vim.wait(15000,function() return #vim.lsp.get_clients({bufnr=b,name='vue_ls'})>0 and #vim.lsp.get_clients({bufnr=b,name='vtsls'})>0 end,50)); local c=vim.lsp.get_clients({bufnr=b,name='vue_ls'})[1]; assert(vim.wait(5000,function() return vim.api.nvim_get_namespaces()['config.linked_tags:'..b] end,20))");
   await delay(200);
   const vue=await lua("local b=vim.api.nvim_get_current_buf(); local c=vim.lsp.get_clients({bufnr=b,name='vue_ls'})[1]; vim.api.nvim_win_set_cursor(0,{5,3}); local params={textDocument={uri=vim.uri_from_bufnr(b)},position={line=4,character=3}}; local reply=c:request_sync('textDocument/linkedEditingRange',params,3000,b); assert(reply and reply.result and #reply.result.ranges==2,'Vue LSP linked response missing'); vim.api.nvim_exec_autocmds('CursorMoved',{buffer=b}); local ns=vim.api.nvim_get_namespaces()['config.linked_tags:'..b]; assert(vim.wait(5000,function() return ns and #vim.api.nvim_buf_get_extmarks(b,ns,0,-1,{details=true})==2 end,20),'Vue linked ranges missing'); return {client=c.name,extmarks=#vim.api.nvim_buf_get_extmarks(b,ns,0,-1,{details=true}),inc=vim.fn.exists(':IncRename'),gra_mapped=vim.fn.maparg('gra','n')~='',old_lsp_keys=vim.fn.maparg('<leader>ca','n')~='' or vim.fn.maparg('<leader>cr','n')~=''}");
   await rpc('nvim_input',['ciw']);await delay(120);
   const empty=await lua("local b=vim.api.nvim_get_current_buf(); local ns=vim.api.nvim_get_namespaces()['config.linked_tags:'..b]; return {mode=vim.fn.mode(),open=vim.api.nvim_buf_get_lines(0,4,5,false)[1],close=vim.api.nvim_buf_get_lines(0,12,13,false)[1],extmarks=#vim.api.nvim_buf_get_extmarks(0,ns,0,-1,{details=true}),errmsg=vim.v.errmsg}");
   await rpc('nvim_input',['s']);await delay(120);
   const partial=await lua("return {mode=vim.fn.mode(),open=vim.api.nvim_buf_get_lines(0,4,5,false)[1],close=vim.api.nvim_buf_get_lines(0,12,13,false)[1],errmsg=vim.v.errmsg}");
   await rpc('nvim_input',['ection']);await delay(120);
   const full=await lua("return {mode=vim.fn.mode(),open=vim.api.nvim_buf_get_lines(0,4,5,false)[1],close=vim.api.nvim_buf_get_lines(0,12,13,false)[1],errmsg=vim.v.errmsg}");
   await rpc('nvim_input',['<Esc>']);await delay(50);
   await lua('vim.cmd.undo()');await delay(100);
   const undone=await lua("return {open=vim.api.nvim_buf_get_lines(0,4,5,false)[1],close=vim.api.nvim_buf_get_lines(0,12,13,false)[1],errmsg=vim.v.errmsg}");
   if(vue.inc!==0||!vue.gra_mapped||vue.old_lsp_keys||vue.extmarks!==2||partial.mode!=='i'||!partial.open.includes('<s ')||!partial.close.includes('</s>')||full.mode!=='i'||!full.open.includes('<section ')||!full.close.includes('</section>')||!undone.open.includes('<div ')||!undone.close.includes('</div>')||partial.errmsg||full.errmsg||undone.errmsg)throw new Error('Vue live linked editing failed: '+JSON.stringify({vue,empty,partial,full,undone}));
   await lua("vim.api.nvim_win_set_cursor(0,{9,7}); vim.api.nvim_exec_autocmds('CursorMoved',{buffer=0})");await delay(200);
   await rpc('nvim_input',['caw']);await delay(120);
   const cawEmpty=await lua("return {mode=vim.fn.mode(),open=vim.api.nvim_buf_get_lines(0,8,9,false)[1],close=vim.api.nvim_buf_get_lines(0,11,12,false)[1],errmsg=vim.v.errmsg}");
   await rpc('nvim_input',['Panel']);await delay(120);
   const cawFull=await lua("return {mode=vim.fn.mode(),open=vim.api.nvim_buf_get_lines(0,8,9,false)[1],close=vim.api.nvim_buf_get_lines(0,11,12,false)[1],errmsg=vim.v.errmsg}");
   await rpc('nvim_input',['<Esc>']);await delay(50);
   if(cawEmpty.mode!=='i'||!cawEmpty.open.includes('<>')||!cawEmpty.close.includes('</>')||cawFull.mode!=='i'||!cawFull.open.includes('<Panel>')||!cawFull.close.includes('</Panel>')||cawFull.errmsg)throw new Error('Vue caw linked editing failed: '+JSON.stringify({cawEmpty,cawFull}));
   await lua("vim.api.nvim_win_set_cursor(0,{12,8}); vim.api.nvim_exec_autocmds('CursorMoved',{buffer=0})");await delay(200);
   await rpc('nvim_input',['ciw']);await delay(120);
   await rpc('nvim_input',['Aside']);await delay(120);
   const closingEdit=await lua("return {mode=vim.fn.mode(),open=vim.api.nvim_buf_get_lines(0,8,9,false)[1],close=vim.api.nvim_buf_get_lines(0,11,12,false)[1],errmsg=vim.v.errmsg}");
   await rpc('nvim_input',['<Esc>']);await delay(50);
   if(closingEdit.mode!=='i'||!closingEdit.open.includes('<Aside>')||!closingEdit.close.includes('</Aside>')||closingEdit.errmsg)throw new Error('Vue closing-tag edit failed: '+JSON.stringify(closingEdit));
   await lua("vim.api.nvim_win_set_cursor(0,{5,3})");
   await rpc('nvim_input',['grn']);await delay(150);
   const tagDialog=await lua("local r=require('lspsaga.rename'); assert(r.winid and vim.api.nvim_win_is_valid(r.winid)); assert(vim.bo[r.bufnr].filetype=='sagarename'); return {initial=vim.api.nvim_buf_get_lines(r.bufnr,0,-1,false),mode=vim.fn.mode()}");
   await rpc('nvim_input',['<Esc>']);await delay(100);
   const cancelled=await lua("local r=require('lspsaga.rename'); local lines=vim.api.nvim_buf_get_lines(0,0,-1,false); return {closed=not vim.api.nvim_win_is_valid(r.winid),open=lines[5],close=lines[13],errmsg=vim.v.errmsg}");
   if(!cancelled.closed||!cancelled.open.includes('<div ')||!cancelled.close.includes('</div>')||cancelled.errmsg)throw new Error('Saga rename cancellation failed: '+JSON.stringify(cancelled));
   await rpc('nvim_input',['grn']);await delay(150);
   await rpc('nvim_input',['article<CR>']);await delay(500);
   const tagRename=await lua("local lines=vim.api.nvim_buf_get_lines(0,0,-1,false); return {open=lines[5],close=lines[13],errmsg=vim.v.errmsg}");
   if(!tagRename.open.includes('<article ')||!tagRename.close.includes('</article>')||tagRename.errmsg)throw new Error('Vue tag LSP rename failed: '+JSON.stringify(tagRename));
   await lua("vim.api.nvim_buf_set_lines(0,12,12,false,{'    <LiveTag'}); vim.api.nvim_win_set_cursor(0,{13,0})");
   await rpc('nvim_input',['A>']);await delay(150);
   const autoClose=await lua("return {mode=vim.fn.mode(),lines=vim.api.nvim_buf_get_lines(0,12,15,false),errmsg=vim.v.errmsg}");
   await rpc('nvim_input',['<Esc>']);await delay(50);
   if(!autoClose.lines.join(' ').includes('</LiveTag>')||autoClose.errmsg)throw new Error('Vue automatic tag closing failed: '+JSON.stringify(autoClose));
   await lua("vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/App.vue'); assert(vim.wait(15000,function() return #vim.lsp.get_clients({bufnr=0,name='vtsls'})>0 and #vim.lsp.get_clients({bufnr=0,name='vue_ls'})>0 end,50)); vim.api.nvim_win_set_cursor(0,{3,6})");
   await rpc('nvim_input',['grn']);await delay(150);
   const codeDialog=await lua("local r=require('lspsaga.rename'); assert(r.winid and vim.api.nvim_win_is_valid(r.winid)); return vim.api.nvim_buf_get_lines(r.bufnr,0,-1,false)");
   await rpc('nvim_input',['renamedCount<CR>']);await delay(500);
   const codeRename=await lua("local lines=vim.api.nvim_buf_get_lines(0,0,-1,false); return {declaration=lines[3],body=lines[5],template=lines[7],errmsg=vim.v.errmsg}");
   if(!codeRename.declaration.includes('renamedCount')||!codeRename.body.includes('renamedCount')||!codeRename.template.includes('renamedCount')||codeRename.errmsg)throw new Error('Vue script LSP rename failed: '+JSON.stringify(codeRename));
   await lua("vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/TagActions.html'); local b=vim.api.nvim_get_current_buf(); assert(vim.wait(15000,function() return #vim.lsp.get_clients({bufnr=b,name='html'})>0 end,50)); assert(vim.wait(5000,function() return vim.api.nvim_get_namespaces()['config.linked_tags:'..b] end,20))");
   await delay(200);
   const html=await lua("local b=vim.api.nvim_get_current_buf(); local c=vim.lsp.get_clients({bufnr=b,name='html'})[1]; vim.api.nvim_win_set_cursor(0,{1,1}); local params={textDocument={uri=vim.uri_from_bufnr(b)},position={line=0,character=1}}; local reply=c:request_sync('textDocument/linkedEditingRange',params,3000,b); assert(reply and reply.result and #reply.result.ranges==2,'HTML LSP linked response missing'); vim.api.nvim_exec_autocmds('CursorMoved',{buffer=b}); local ns=vim.api.nvim_get_namespaces()['config.linked_tags:'..b]; assert(vim.wait(5000,function() return ns and #vim.api.nvim_buf_get_extmarks(b,ns,0,-1,{details=true})==2 end,20),'HTML linked ranges missing'); return {client=c.name,extmarks=#vim.api.nvim_buf_get_extmarks(b,ns,0,-1,{details=true})}");
   await rpc('nvim_input',['ciws']);await delay(120);
   const htmlPartial=await lua("return {mode=vim.fn.mode(),open=vim.api.nvim_buf_get_lines(0,0,1,false)[1],close=vim.api.nvim_buf_get_lines(0,4,5,false)[1],errmsg=vim.v.errmsg}");
   await rpc('nvim_input',['<Esc>']);await delay(50);
   if(html.extmarks!==2||htmlPartial.mode!=='i'||!htmlPartial.open.startsWith('<s ')||!htmlPartial.close.includes('</s>')||htmlPartial.errmsg)throw new Error('HTML live linked editing failed: '+JSON.stringify({html,htmlPartial}));
   await lua("vim.cmd.undo(); vim.api.nvim_win_set_cursor(0,{2,9}); vim.api.nvim_exec_autocmds('CursorMoved',{buffer=0})");await delay(200);
   await rpc('nvim_input',['caw']);await delay(120);
   const htmlCawEmpty=await lua("return {mode=vim.fn.mode(),line=vim.api.nvim_buf_get_lines(0,1,2,false)[1],errmsg=vim.v.errmsg}");
   await rpc('nvim_input',['strong']);await delay(120);
   const htmlCawFull=await lua("return {mode=vim.fn.mode(),line=vim.api.nvim_buf_get_lines(0,1,2,false)[1],errmsg=vim.v.errmsg}");
   await rpc('nvim_input',['<Esc>']);await delay(50);
   if(htmlCawEmpty.mode!=='i'||!htmlCawEmpty.line.includes('<>')||!htmlCawEmpty.line.includes('</>')||htmlCawFull.mode!=='i'||!htmlCawFull.line.includes('<strong>')||!htmlCawFull.line.includes('</strong>')||htmlCawFull.errmsg)throw new Error('HTML caw linked editing failed: '+JSON.stringify({htmlCawEmpty,htmlCawFull}));
   result={vue,empty,partial,full,undone,cawEmpty,cawFull,closingEdit,tagDialog,cancelled,tagRename,autoClose,codeDialog,codeRename,html,htmlPartial,htmlCawEmpty,htmlCawFull};
  }else if(suite==='search-count'){
   await rpc('nvim_exec_lua',["vim.cmd.enew(); vim.api.nvim_buf_set_lines(0,0,-1,false,{'needle%value first','x','needle%value second','needle%value third'}); vim.api.nvim_win_set_cursor(0,{1,0})",[]]);
   const state=()=>rpc('nvim_exec_lua',["local row=vim.fn.screenpos(0,vim.api.nvim_win_get_cursor(0)[1],1).row; local text={}; for col=1,vim.o.columns do text[#text+1]=vim.fn.screenstring(row,col) end; return {source=vim.api.nvim_get_current_line(),text=table.concat(text),hlsearch=vim.v.hlsearch,errmsg=vim.v.errmsg}",[]]);
   const phases=[];
   for(const [keys,count] of [['/needle%value<CR>','[2/3]'],['n','[3/3]'],['N','[2/3]']]){
    await rpc('nvim_input',[keys]);await delay(150);
    const current=await state();
    if(!current.text.trimEnd().endsWith(current.source+'  '+count)||current.errmsg)throw new Error('Noice search count was not compact: '+JSON.stringify({keys,count,current}));
    phases.push({keys,...current});
   }
   await rpc('nvim_input',['<Esc>']);await delay(150);
   const cleared=await state();
   if(cleared.hlsearch!==0||cleared.text.includes('[2/3]')||cleared.errmsg)throw new Error('Noice search count did not clear: '+JSON.stringify(cleared));
   result={phases,cleared};
  }else if(suite==='hover'){
  await rpc('nvim_exec_lua',["vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/refactor.ts'); assert(vim.wait(15000,function() return #vim.lsp.get_clients({bufnr=0,name='vtsls',method='textDocument/hover'})>0 end,50)); vim.api.nvim_win_set_cursor(0,{1,16})",[]]);
   const hoverState=()=>rpc('nvim_exec_lua',["local wins,details,hover={},{},nil; for _,win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do local ok,source=pcall(vim.api.nvim_win_get_var,win,'textDocument/hover'); local buf=vim.api.nvim_win_get_buf(win); details[#details+1]={win=win,relative=vim.api.nvim_win_get_config(win).relative,source=ok and source or nil,ft=vim.bo[buf].filetype}; if ok then wins[#wins+1]=win; hover={first=vim.api.nvim_buf_get_lines(buf,0,1,false)[1],conceallevel=vim.wo[win].conceallevel,concealcursor=vim.wo[win].concealcursor} end end; return {wins=wins,details=details,hover=hover,current=vim.api.nvim_get_current_win(),errmsg=vim.v.errmsg}",[]]);
  const waitForHover=async()=>{for(let i=0;i<40;i++){await delay(100);const state=await hoverState();if(state.wins.length)return state;}return hoverState();};
  const phases=[];
  await rpc('nvim_exec_lua',['vim.lsp.buf.hover()',[]]);phases.push(await waitForHover());
  const foldState=await rpc('nvim_exec_lua',[`local win=assert(vim.tbl_filter(function(w) return vim.w[w]['textDocument/hover']~=nil end,vim.api.nvim_tabpage_list_wins(0))[1])
local buf=vim.api.nvim_win_get_buf(win)
assert(vim.wait(1000,function() return require('ufo').hasAttached(buf) end,20),'UFO did not attach to Hover buffer')
require('ufo').enableFold(buf)
vim.wait(2000)
return {buftype=vim.bo[buf].buftype,filetype=vim.bo[buf].filetype,errmsg=vim.v.errmsg,messages=vim.api.nvim_exec2('messages',{output=true}).output}`,[]]);
  await rpc('nvim_input',['<Esc>']);await delay(100);phases.push(await hoverState());
  await rpc('nvim_exec_lua',['vim.lsp.buf.hover()',[]]);phases.push(await waitForHover());
  await rpc('nvim_exec_lua',['vim.lsp.buf.hover()',[]]);await delay(100);phases.push(await hoverState());
  const rendered=await rpc('nvim_exec_lua',[`local win=assert(vim.tbl_filter(function(w) return vim.w[w]['textDocument/hover']~=nil end,vim.api.nvim_tabpage_list_wins(0))[1])
local pos=vim.api.nvim_win_get_position(win)
vim.cmd.redraw()
local rows={}
for row=math.max(1,pos[1]),math.min(vim.o.lines,pos[1]+5) do
  local chars={}
  for col=math.max(1,pos[2]),math.min(vim.o.columns,pos[2]+45) do chars[#chars+1]=vim.fn.screenstring(row,col) end
  rows[#rows+1]=table.concat(chars)
end
return {rows=rows,errmsg=vim.v.errmsg}`,[]]);
  await rpc('nvim_input',['<Esc>']);await delay(100);phases.push(await hoverState());
  const screen=rendered.rows.join('\n');
  if(foldState.buftype!=='nofile'||foldState.filetype!=='markdown'||foldState.errmsg||foldState.messages.includes('UnhandledPromiseRejection')||phases[0].wins.length!==1||!phases[0].hover?.first.startsWith('```')||phases[1].wins.length||phases[2].wins.length!==1||phases[3].current!==phases[3].wins[0]||phases[3].hover?.conceallevel!==2||!phases[3].hover?.concealcursor.includes('n')||screen.includes('```')||!screen.includes('function demo')||rendered.errmsg||phases[4].wins.length||phases.some(p=>p.errmsg))throw new Error('Hover folding, Markdown conceal or Esc behavior failed: '+JSON.stringify({foldState,phases,rendered}));
  result={foldState,phases,rendered};
 }else if(suite==='import-paths'){
  const {verifyImportPathsUI}=await import('./import-paths-ui.mjs');
  result=await verifyImportPathsUI(rpc);
 }else if(suite==='emmet'){
  const {verifyEmmetUI}=await import('./emmet-ui.mjs');
  result=await verifyEmmetUI(rpc);
 }else if(suite==='multicursor'){
  const {verifyMulticursorUI}=await import('./multicursor-ui.mjs');
  result=await verifyMulticursorUI(rpc);
 }else if(suite==='git'){
  const {verifyGitUI}=await import('./git-ui.mjs');
  result=await verifyGitUI(rpc);
 }else{
  const lua=suite==='workflows'?"return dofile(vim.fn.stdpath('config')..'/scripts/check-workflows.lua')":readFileSync(resolve(dirname(fileURLToPath(import.meta.url)),suite==='host'?'host.lua':suite),'utf8');
  result=await rpc('nvim_exec_lua',[lua,[]]);
  writeFileSync(output,JSON.stringify(result,null,2)+'\n');
  if(result.failures && Object.keys(result.failures).length)throw new Error(JSON.stringify(result.failures));
  if(result.error || result.errmsg)throw new Error(result.error || result.errmsg);
 }
 if(host){result.hostActions=hostActions;for(const name of result.expected_actions){if(!hostActions.some(a=>a.method==='vscode-action' && a.params[0]===name))throw new Error('Host action was not emitted: '+name);}}
 writeFileSync(output,JSON.stringify(result,null,2)+'\n');
 await rpc('nvim_exec_lua',["vim.schedule(function() vim.cmd('qa!') end)",[]]);
 console.log('PASS '+suite+' -> '+output);
}catch(e){errors.push(e.stack);editor.kill();process.exitCode=1;}
finally{clearTimeout(deadline);writeFileSync(output+'.errors',errors.join('\n'));}
