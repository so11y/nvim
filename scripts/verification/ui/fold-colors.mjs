export async function verifyFoldColorsUI(rpc) {
  const result = await rpc('nvim_exec_lua', [
    `vim.cmd.colorscheme('vscode')
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
   assert(vim.wo.foldtext=='',case.file..' custom folded text still enabled')
   vim.wo.cursorline=false
    vim.api.nvim_buf_set_lines(0,case.insert,case.insert==0 and -1 or case.insert,false,case.lines)
    vim.cmd.redraw()
   if vim.bo.filetype=='html' or vim.bo.filetype=='vue' then
    assert(vim.wait(5000,function() return vim.fn.foldlevel(case.first)>vim.fn.foldlevel(case.first+3) and vim.fn.foldlevel(case.second)>vim.fn.foldlevel(case.first+3) end,25),case.file..' native tag folds missing')
   else
    vim.wo.foldmethod='manual'
    vim.cmd(('%d,%dfold'):format(case.first,case.first+2))
    vim.cmd(('%d,%dfold'):format(case.second,case.second+2))
   end
   vim.cmd.normal({args={'zR'},bang=true})
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
   local normal=vim.api.nvim_get_hl(0,{name='Normal',link=false})
   local folded=vim.api.nvim_get_hl(0,{name='Folded',link=false})
   assert(folded.bg and folded.bg~=normal.bg,case.file..' folded background highlight missing')
   vim.cmd.redraw()
   local function fold_text(row)
     local line=vim.api.nvim_buf_get_lines(0,row-1,row,false)[1]
     local point=vim.fn.screenpos(vim.api.nvim_get_current_win(),row,1)
     assert(point.row>0,case.file..' folded row is not visible')
     point.col=point.col+case.col-1
     local expected=line:sub(case.col)
     local chars={}
     for col=point.col,point.col+vim.fn.strdisplaywidth(expected)-1 do
       chars[#chars+1]=vim.fn.screenstring(point.row,col)
     end
     local text=table.concat(chars)
     assert(text==expected,case.file..' native fold changed opening tag text: '..text)
     local tag_col=point.col+1
     local color=vim.fn.screenattr(point.row,tag_col)
     assert(color~=vim.fn.screenattr(point.row,point.col),case.file..' native fold lost tag colors')
     return {text=line,color=color}
   end
   local first_text=fold_text(case.first)
   local second_text=fold_text(case.second)
   assert(first_text.color==second_text.color,case.file..' native tag colors differ between folds')
    result[#result+1]={file=case.file,captures=first,normal=normal,folded=folded,folds={first_fold,second_fold},texts={first_text,second_text}}
   vim.bo.modified=false
 end
 return {cases=result,errmsg=vim.v.errmsg}`,
    [],
  ]);
  return result;
}
