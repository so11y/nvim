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
const deadlineMs=['rust-debug.lua','navigation-performance'].includes(suite)?120000:60000;
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
   const state=await rpc('nvim_exec_lua',["return {hlsearch=vim.v.hlsearch,condition=require('custom.heirline.components').SearchOccurrence.condition(),statusline=vim.o.statusline}",[]]);
   if(state.condition!==active)throw new Error('Search condition mismatch: '+JSON.stringify(state));
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
  await rpc('nvim_exec_lua',["vim.fn.setreg('/','value'); vim.api.nvim_win_set_cursor(0,{100,0})",[]]);
  const statusline=()=>rpc('nvim_exec_lua',["return vim.api.nvim_eval_statusline(vim.o.statusline,{winid=0}).str",[]]);
  const initialStatusline=await statusline();
  await inputAndWait('j'.repeat(10));
  const movingStatusline=await statusline();
  await delay(250);
  const settledStatusline=await statusline();
  const expectedStatusline=await rpc('nvim_exec_lua',["local c=vim.fn.searchcount({recompute=1,maxcount=0}); return ('[%s/%s]'):format(c.current,c.total)",[]]);
  if(!settledStatusline.includes(expectedStatusline))throw new Error('Search statusline did not catch up after movement: '+JSON.stringify({initialStatusline,movingStatusline,settledStatusline,expectedStatusline}));
  await rpc('nvim_exec_lua',["vim.o.statusline=''; vim.fn.setreg('/','value'); vim.o.hlsearch=true; vim.api.nvim_win_set_cursor(0,{100,0}); vim.fn.searchcount({recompute=1,maxcount=0})",[]]);
  const searchCache=[];
  for(const steps of [1,10,100]){
   await inputAndWait('j'.repeat(steps));
   searchCache.push(await rpc('nvim_exec_lua',["local cached=vim.fn.searchcount({recompute=0,maxcount=0}); local fresh=vim.fn.searchcount({recompute=1,maxcount=0}); return {row=vim.api.nvim_win_get_cursor(0)[1],cached=cached,fresh=fresh}",[]]));
  }
  result={setup,samples,ast,editing,after,search,editSamples,searchStatusline:{initialStatusline,movingStatusline,settledStatusline,expectedStatusline},searchCache};
 }else if(suite==='tag-ui'){
  const setup=await rpc('nvim_exec_lua',[`vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/TagActions.vue')
assert(vim.wait(5000,function() return #vim.lsp.get_clients({bufnr=0,name='tag_fix'})==1 end,20))
require('lazy').load({plugins={'tiny-code-action.nvim'}})
local tiny=require('tiny-code-action')
_G.__tag_ui={original=tiny.code_action}
tiny.code_action=function(opts) _G.__tag_ui.range=opts.range end
local line=vim.api.nvim_buf_get_lines(0,5,6,false)[1]
local first=assert(line:find('你',1,true))-1
local last=assert(line:find('😀',1,true))-1
vim.api.nvim_win_set_cursor(0,{6,first})
return {first=first,last=last,mapped=vim.fn.maparg('gra','x')~=''}`,[]]);
  await rpc('nvim_input',['v']);await delay(50);
  await rpc('nvim_win_set_cursor',[0,[6,setup.last]]);
  await rpc('nvim_input',['gra']);await delay(150);
  const visual=await rpc('nvim_exec_lua',[`local state=_G.__tag_ui
local result={range=state.range,mode=vim.fn.mode(),errmsg=vim.v.errmsg}
state.range=nil
return result`,[]]);
  await rpc('nvim_input',['<Esc>']);await delay(50);
  if(!setup.mapped||!visual.range||visual.range.start[0]!==6||visual.range.start[1]!==setup.first||visual.range.end[1]!==setup.last+4||visual.errmsg)throw new Error('Visual Code Action range failed: '+JSON.stringify({setup,visual}));
  const selection=await rpc('nvim_exec_lua',[`local first=vim.api.nvim_buf_get_lines(0,9,10,false)[1]
local last=vim.api.nvim_buf_get_lines(0,10,11,false)[1]
local start=assert(first:find('<span>A',1,true))-1
local finish=assert(last:find('</span>',1,true))+#'</span>'-2
vim.api.nvim_win_set_cursor(0,{10,start})
return {start=start,finish=finish}`,[]]);
  await rpc('nvim_input',['v']);await delay(50);
  await rpc('nvim_win_set_cursor',[0,[11,selection.finish]]);
  await rpc('nvim_input',['gra']);await delay(150);
  const multiline=await rpc('nvim_exec_lua',[`local state=_G.__tag_ui
require('tiny-code-action').code_action=state.original
return {range=state.range,errmsg=vim.v.errmsg}`,[]]);
  await rpc('nvim_input',['<Esc>']);await delay(50);
  if(!multiline.range||multiline.range.start[0]!==10||multiline.range.start[1]!==selection.start||multiline.range.end[0]!==11||multiline.range.end[1]!==selection.finish+1||multiline.errmsg)throw new Error('Multiline Code Action range failed: '+JSON.stringify({selection,multiline}));
  const merged=await rpc('nvim_exec_lua',[`local line=vim.api.nvim_buf_get_lines(0,5,6,false)[1]
vim.api.nvim_win_set_cursor(0,{6,assert(line:find('visible',1,true))-1})
require('config.code_action').open()
assert(vim.wait(15000,function() return vim.api.nvim_win_get_config(0).relative~='' end,20),'Tag picker did not open')
local names={}
for _,client in ipairs(vim.lsp.get_clients({bufnr=vim.fn.bufnr(vim.env.NVIM_TEST_ROOT..'/alpha/TagActions.vue'),method='textDocument/codeAction'})) do names[#names+1]=client.name end
return {lines=vim.api.nvim_buf_get_lines(0,0,-1,false),clients=names,errmsg=vim.v.errmsg}`,[]]);
  await rpc('nvim_input',['<Esc>']);await delay(50);
  if(!merged.lines.some(line=>line.includes('删除整个元素'))||!merged.clients.includes('tag_fix')||!merged.clients.includes('vue_ls')||merged.lines.some(line=>line.includes('不可用'))||merged.errmsg)throw new Error('Tag and existing LSP action aggregation failed: '+JSON.stringify(merged));
  const wrapMenu=await rpc('nvim_exec_lua',[`local state=_G.__tag_ui
state.bufnr=vim.api.nvim_get_current_buf()
state.before=table.concat(vim.api.nvim_buf_get_lines(state.bufnr,0,-1,false),'\\n')
state.input=vim.ui.input
state.prompts=0
vim.ui.input=function(_,callback) state.prompts=state.prompts+1; callback('div.wrapper') end
local line=vim.api.nvim_buf_get_lines(0,5,6,false)[1]
vim.api.nvim_win_set_cursor(0,{6,assert(line:find('visible',1,true))-1})
require('config.code_action').open()
assert(vim.wait(15000,function() return vim.api.nvim_win_get_config(0).relative~='' end,20))
local lines=vim.api.nvim_buf_get_lines(0,0,-1,false)
local target
for i,title in ipairs(lines) do if title:find('包裹标签',1,true) then target=i;break end end
assert(target,'Wrap action is missing from Tiny picker')
vim.api.nvim_win_set_cursor(0,{target,0})
return {target=target,prompts=state.prompts,lines=lines}`,[]]);
  await rpc('nvim_input',['<CR>']);await delay(150);
  const wrapped=await rpc('nvim_exec_lua',[`local state=_G.__tag_ui
local after=table.concat(vim.api.nvim_buf_get_lines(state.bufnr,0,-1,false),'\\n')
local prompts=state.prompts
vim.ui.input=state.input
vim.cmd.undo()
local restored=table.concat(vim.api.nvim_buf_get_lines(state.bufnr,0,-1,false),'\\n')==state.before
return {prompts=prompts,after=after,restored=restored,errmsg=vim.v.errmsg}`,[]]);
  if(wrapMenu.prompts||wrapped.prompts!==1||!wrapped.after.includes('<div class="wrapper"><div v-if="visible">')||!wrapped.restored||wrapped.errmsg)throw new Error('Tiny Enter to Emmet wrap failed: '+JSON.stringify({wrapMenu,wrapped}));
  await rpc('nvim_ui_try_resize',[50,16]);await delay(100);
  const edge=await rpc('nvim_exec_lua',[`vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/TagActions.html')
assert(vim.wait(5000,function() return #vim.lsp.get_clients({bufnr=0,name='tag_fix'})==1 end,20))
local bufnr=vim.api.nvim_get_current_buf()
local extra={}
for i=1,24 do extra[i]=string.rep('x',80) end
vim.api.nvim_buf_set_lines(bufnr,-1,-1,false,extra)
vim.api.nvim_win_set_cursor(0,{30,40})
local client=vim.lsp.get_clients({bufnr=bufnr,name='tag_fix'})[1]
local uri=vim.uri_from_bufnr(bufnr)
local items={}
for i=1,10 do items[i]={client=client,context={},action={title='Tag action '..i,kind='refactor.rewrite.tag',edit={changes={[uri]={{range={start={line=1,character=0},['end']={line=1,character=0}},newText='x'}}}}}} end
require('tiny-code-action.pickers.buffer').create(require('tiny-code-action').config,items,bufnr)
local main_win=vim.api.nvim_get_current_win()
local preview=require('tiny-code-action.pickers.buffer_utils.preview')
local preview_win=preview.get_preview_state().win
local main=vim.api.nvim_win_get_config(main_win)
local other=vim.api.nvim_win_get_config(preview_win)
local function fits(c) return c.row>=0 and c.col>=0 and c.row+c.height+3<=vim.o.lines and c.col+c.width+2<=vim.o.columns end
local overlaps=main.col<other.col+other.width+2 and other.col<main.col+main.width+2 and main.row<other.row+other.height+2 and other.row<main.row+main.height+2
local result={main=main,preview=other,fits_main=fits(main),fits_preview=fits(other),overlaps=overlaps,errmsg=vim.v.errmsg}
vim.api.nvim_win_close(main_win,true)
preview.close_preview()
return result`,[]]);
  if(!edge.fits_main||!edge.fits_preview||edge.overlaps||edge.main.height!==7||edge.errmsg)throw new Error('Compact Code Action edge layout failed: '+JSON.stringify(edge));
   result={setup,visual,selection,multiline,merged,wrapMenu,wrapped,edge};
 }else if(suite==='action-ui'){
  const setup=await rpc('nvim_exec_lua',[`vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/refactor.ts')
assert(vim.wait(15000,function() return #vim.lsp.get_clients({bufnr=0,name='vtsls',method='textDocument/codeAction'})>0 end,50))
require('lazy').load({plugins={'tiny-code-action.nvim'}})
local bufnr=vim.api.nvim_get_current_buf()
local client=vim.lsp.get_clients({bufnr=bufnr,name='vtsls'})[1]
local response=client:request_sync('textDocument/codeAction',{textDocument=vim.lsp.util.make_text_document_params(),range={start={line=1,character=17},['end']={line=1,character=22}},context={diagnostics={}}},15000,bufnr)
 local disabled
 for _,candidate in ipairs(response.result) do if candidate.disabled then disabled=vim.deepcopy(candidate); break end end
 assert(disabled,'Server did not return a disabled action')
 disabled.edit={changes={[vim.uri_from_bufnr(bufnr)]={{range={start={line=1,character=8},['end']={line=1,character=14}},newText='BLOCKED'}}}}
 local enabled={title='Replace result',kind='quickfix',edit={changes={[vim.uri_from_bufnr(bufnr)]={{range={start={line=1,character=8},['end']={line=1,character=14}},newText='applied'}}}}}
 _G.__action_ui={bufnr=bufnr,before=vim.api.nvim_buf_get_lines(bufnr,0,-1,false),disabled=disabled,client=client}
 require('tiny-code-action.pickers.buffer').create(require('tiny-code-action').config,{{action=disabled,client=client,context={}},{action=enabled,client=client,context={}}},bufnr)
 return {disabled_title=disabled.title,picker=vim.api.nvim_buf_get_lines(0,0,-1,false)}`,[]]);
  await delay(200);
  const preview=await rpc('nvim_exec_lua',["local state=require('tiny-code-action.pickers.buffer_utils.preview').get_preview_state(); return {lines=vim.api.nvim_buf_get_lines(state.buf,0,-1,false),errmsg=vim.v.errmsg}",[]]);
  await rpc('nvim_input',['<Tab>']);await delay(100);
  const applied=await rpc('nvim_exec_lua',[`local ctx=_G.__action_ui
local lines=vim.api.nvim_buf_get_lines(ctx.bufnr,0,-1,false)
local applied=lines[2]:find('const applied =',1,true)~=nil
local original_win=vim.api.nvim_get_current_win()
require('tiny-code-action.pickers.buffer').create(require('tiny-code-action').config,{{action=ctx.disabled,client=ctx.client,context={}}},ctx.bufnr)
local no_empty_picker=vim.api.nvim_get_current_win()==original_win
require('tiny-code-action.pickers.buffer').apply_action(ctx.disabled,ctx.client,{},ctx.bufnr)
local blocked=vim.deep_equal(lines,vim.api.nvim_buf_get_lines(ctx.bufnr,0,-1,false))
vim.api.nvim_buf_set_lines(ctx.bufnr,0,-1,false,ctx.before)
return {applied=applied,blocked=blocked,no_empty_picker=no_empty_picker,errmsg=vim.v.errmsg}`,[]]);
  const filtered=await rpc('nvim_exec_lua',[`vim.api.nvim_win_set_cursor(0,{2,20})
require('config.code_action').open()
assert(vim.wait(15000,function() return vim.api.nvim_win_get_config(0).relative~='' end,20),'Code Action picker did not open')
local win=vim.api.nvim_get_current_win()
return {lines=vim.api.nvim_buf_get_lines(0,0,-1,false),height=vim.api.nvim_win_get_config(win).height,errmsg=vim.v.errmsg}`,[]]);
  await rpc('nvim_input',['<Esc>']);await delay(100);
  if(!setup.picker.some(line=>line.includes('Replace result'))||setup.picker.some(line=>line.includes(setup.disabled_title))||!preview.lines.join('\n').includes('applied')||!applied.applied||!applied.blocked||!applied.no_empty_picker||!filtered.lines.length||filtered.lines.some(line=>line.includes('不可用'))||filtered.height>7||preview.errmsg||applied.errmsg||filtered.errmsg)throw new Error('Code Action UI, filtering or execution guard failed: '+JSON.stringify({setup,preview,applied,filtered}));
  result={setup,preview,applied,filtered};
 }else if(suite==='fold-colors'){
   result=await rpc('nvim_exec_lua',[`local cases={
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
    local function rainbow(row,col)
      local line=vim.api.nvim_buf_get_lines(bufnr,row-1,row,false)[1]
      for _,mark in ipairs(vim.api.nvim_buf_get_extmarks(bufnr,-1,{row-1,0},{row-1,#line},{details=true})) do
        local details=mark[4]
        if mark[2]==row-1 and mark[3]<=col and details.end_row==row-1 and details.end_col and col<details.end_col and type(details.hl_group)=='string' and details.hl_group:match('^RainbowDelimiter') then
          return details.hl_group
        end
      end
    end
    vim.cmd.redraw()
    assert(vim.wait(5000,function() return rainbow(case.first,case.col) and rainbow(case.first+2,case.col+1) and rainbow(case.second,case.col) and rainbow(case.second+2,case.col+1) end,25),case.file..' rainbow tag colors missing')
    local first_open,first_close=rainbow(case.first,case.col),rainbow(case.first+2,case.col+1)
    local second_open,second_close=rainbow(case.second,case.col),rainbow(case.second+2,case.col+1)
    assert(first_open==first_close and second_open==second_close,case.file..' unfurled tag colors differ')
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
   local function tag_highlight(row)
     local line=vim.api.nvim_buf_get_lines(0,row-1,row,false)[1]
      local chunks=require('ufo.render').captureVirtText(bufnr,line,row,false,{},0)
      local handler=require('ufo.decorator'):getVirtTextHandler(bufnr)
      chunks=handler(chunks,row,row+2,200,function(text) return text end,{bufnr=bufnr,text=line})
      local text=table.concat(vim.tbl_map(function(chunk) return chunk[1] end,chunks))
      assert(text:sub(1,#line)==line,case.file..' folded text lost opening tag attributes')
      for _,chunk in ipairs(chunks) do if chunk[1]=='ul' or chunk[1]=='f-div' then return chunk[2],text end end
   end
   local first_hl,first_text=tag_highlight(case.first)
   local second_hl,second_text=tag_highlight(case.second)
    assert(first_hl==first_close and second_hl==second_close,case.file..' folded tag lost rainbow color')
    result[#result+1]={file=case.file,captures=first,normal=normal,folded=folded,ufo_bg=ufo_bg,tag_hl=first_hl,rainbow_hl=first_close,folds={first_fold,second_fold},texts={first_text,second_text}}
   vim.bo.modified=false
 end
 return {cases=result,errmsg=vim.v.errmsg}`,[]]);
 }else if(suite==='linked-tags'){
   const lua=code=>rpc('nvim_exec_lua',[code,[]]);
   await lua("vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/TagActions.vue'); local b=vim.api.nvim_get_current_buf(); assert(vim.wait(15000,function() return #vim.lsp.get_clients({bufnr=b,name='vue_ls'})>0 and #vim.lsp.get_clients({bufnr=b,name='vtsls'})>0 end,50)); local c=vim.lsp.get_clients({bufnr=b,name='vue_ls'})[1]; assert(vim.wait(5000,function() return vim.api.nvim_get_namespaces()['config.linked_tags:'..b] end,20))");
   await delay(200);
   const vue=await lua("local b=vim.api.nvim_get_current_buf(); local c=vim.lsp.get_clients({bufnr=b,name='vue_ls'})[1]; vim.api.nvim_win_set_cursor(0,{5,3}); local params={textDocument={uri=vim.uri_from_bufnr(b)},position={line=4,character=3}}; local reply=c:request_sync('textDocument/linkedEditingRange',params,3000,b); assert(reply and reply.result and #reply.result.ranges==2,'Vue LSP linked response missing'); vim.api.nvim_exec_autocmds('CursorMoved',{buffer=b}); local ns=vim.api.nvim_get_namespaces()['config.linked_tags:'..b]; assert(vim.wait(5000,function() return ns and #vim.api.nvim_buf_get_extmarks(b,ns,0,-1,{details=true})==2 end,20),'Vue linked ranges missing'); return {client=c.name,extmarks=#vim.api.nvim_buf_get_extmarks(b,ns,0,-1,{details=true}),inc=vim.fn.exists(':IncRename'),gra_canonical=vim.fn.maparg('gra','n',false,true).callback==require('config.code_action').open,old_lsp_keys=vim.fn.maparg('<leader>ca','n')~='' or vim.fn.maparg('<leader>cr','n')~=''}");
   await rpc('nvim_input',['ciw']);await delay(120);
   const empty=await lua("local b=vim.api.nvim_get_current_buf(); local ns=vim.api.nvim_get_namespaces()['config.linked_tags:'..b]; return {mode=vim.fn.mode(),open=vim.api.nvim_buf_get_lines(0,4,5,false)[1],close=vim.api.nvim_buf_get_lines(0,12,13,false)[1],extmarks=#vim.api.nvim_buf_get_extmarks(0,ns,0,-1,{details=true}),errmsg=vim.v.errmsg}");
   await rpc('nvim_input',['s']);await delay(120);
   const partial=await lua("return {mode=vim.fn.mode(),open=vim.api.nvim_buf_get_lines(0,4,5,false)[1],close=vim.api.nvim_buf_get_lines(0,12,13,false)[1],errmsg=vim.v.errmsg}");
   await rpc('nvim_input',['ection']);await delay(120);
   const full=await lua("return {mode=vim.fn.mode(),open=vim.api.nvim_buf_get_lines(0,4,5,false)[1],close=vim.api.nvim_buf_get_lines(0,12,13,false)[1],errmsg=vim.v.errmsg}");
   await rpc('nvim_input',['<Esc>']);await delay(50);
   await lua('vim.cmd.undo()');await delay(100);
   const undone=await lua("return {open=vim.api.nvim_buf_get_lines(0,4,5,false)[1],close=vim.api.nvim_buf_get_lines(0,12,13,false)[1],errmsg=vim.v.errmsg}");
   if(vue.inc!==0||!vue.gra_canonical||vue.old_lsp_keys||vue.extmarks!==2||partial.mode!=='i'||!partial.open.includes('<s ')||!partial.close.includes('</s>')||full.mode!=='i'||!full.open.includes('<section ')||!full.close.includes('</section>')||!undone.open.includes('<div ')||!undone.close.includes('</div>')||partial.errmsg||full.errmsg||undone.errmsg)throw new Error('Vue live linked editing failed: '+JSON.stringify({vue,empty,partial,full,undone}));
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
   await lua("vim.api.nvim_win_set_cursor(0,{5,3}); _G.__linked_input=vim.ui.input; vim.ui.input=function(_,done) done('article') end");
   await rpc('nvim_input',['grn']);await delay(500);
   const tagRename=await lua("local lines=vim.api.nvim_buf_get_lines(0,0,-1,false); vim.ui.input=_G.__linked_input; return {open=lines[5],close=lines[13],errmsg=vim.v.errmsg}");
   if(!tagRename.open.includes('<article ')||!tagRename.close.includes('</article>')||tagRename.errmsg)throw new Error('Vue tag LSP rename failed: '+JSON.stringify(tagRename));
   await lua("vim.api.nvim_buf_set_lines(0,12,12,false,{'    <LiveTag'}); vim.api.nvim_win_set_cursor(0,{13,0})");
   await rpc('nvim_input',['A>']);await delay(150);
   const autoClose=await lua("return {mode=vim.fn.mode(),lines=vim.api.nvim_buf_get_lines(0,12,15,false),errmsg=vim.v.errmsg}");
   await rpc('nvim_input',['<Esc>']);await delay(50);
   if(!autoClose.lines.join(' ').includes('</LiveTag>')||autoClose.errmsg)throw new Error('Vue automatic tag closing failed: '+JSON.stringify(autoClose));
   await lua("vim.cmd.edit(vim.env.NVIM_TEST_ROOT..'/alpha/App.vue'); assert(vim.wait(15000,function() return #vim.lsp.get_clients({bufnr=0,name='vtsls'})>0 and #vim.lsp.get_clients({bufnr=0,name='vue_ls'})>0 end,50)); vim.api.nvim_win_set_cursor(0,{3,6}); _G.__linked_input=vim.ui.input; vim.ui.input=function(_,done) done('renamedCount') end");
   await rpc('nvim_input',['grn']);await delay(500);
   const codeRename=await lua("local lines=vim.api.nvim_buf_get_lines(0,0,-1,false); vim.ui.input=_G.__linked_input; return {declaration=lines[3],body=lines[5],template=lines[7],errmsg=vim.v.errmsg}");
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
   result={vue,empty,partial,full,undone,cawEmpty,cawFull,closingEdit,tagRename,autoClose,codeRename,html,htmlPartial,htmlCawEmpty,htmlCawFull};
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
