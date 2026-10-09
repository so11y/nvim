import {execFileSync} from 'node:child_process';
import {mkdtempSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {setTimeout as delay} from 'node:timers/promises';

export async function verifyGitUI(rpc) {
  const repo = mkdtempSync(join(tmpdir(), 'nvim-git-ui-'));
  const git = (...args) => execFileSync('git', args, {cwd: repo, encoding: 'utf8', windowsHide: true}).trim();
  git('init', '--initial-branch=main');
  for (const [name, value] of Object.entries({
    'user.name': 'Neovim verification',
    'user.email': 'nvim-verification@example.invalid',
    'commit.gpgsign': 'false',
    'core.autocrlf': 'false',
    'core.hooksPath': join(repo, '.git', 'no-hooks'),
  })) git('config', '--local', name, value);
  writeFileSync(join(repo, 'sample.txt'), 'alpha\nbeta\ngamma\n');
  git('add', 'sample.txt');
  git('commit', '-m', 'Seed verification repository');
  writeFileSync(join(repo, 'sample.txt'), 'ALPHA\nbeta\ngamma\n');

  const lua = (code, ...args) => rpc('nvim_exec_lua', [code, args]);
  const input = keys => rpc('nvim_input', [keys]);
  const waitFor = async (condition, label) => {
    const end = Date.now() + 10000;
    while (Date.now() < end) {
      if (await condition()) return;
      await delay(50);
    }
    const state = await lua("return {ft=vim.bo.filetype,mode=vim.fn.mode(),lines=vim.api.nvim_buf_get_lines(0,0,-1,false),errmsg=vim.v.errmsg,messages=vim.api.nvim_exec2('messages',{output=true}).output}");
    throw new Error(label + ': ' + JSON.stringify(state));
  };
  const hasDiff = () => lua("return package.loaded['codediff.ui.lifecycle'] ~= nil and require('codediff.ui.lifecycle').get_session(vim.api.nvim_get_current_tabpage()) ~= nil");
  await lua("vim.api.nvim_set_current_dir(...); vim.cmd.edit('sample.txt')", repo);
  const setup = await lua(`
    local executable = vim.fn.exepath('lazygit')
    local version = vim.system({executable,'--version'},{text=true}):wait()
    assert(version.code == 0 and version.stdout:find('version=0.65.1',1,true))
    return {executable=executable,version=version.stdout}
  `);
  await input(' gd');
  await waitFor(() => lua("local s=package.loaded['codediff.ui.lifecycle'] and require('codediff.ui.lifecycle').get_session(vim.api.nvim_get_current_tabpage()); return s and s.stored_diff_result and s.stored_diff_result.changes and #s.stored_diff_result.changes > 0"), 'Compute CodeDiff hunks');
  const diff = await lua(`
    local s=require('codediff.ui.lifecycle').get_session(vim.api.nvim_get_current_tabpage())
    return {root=s.git_root,layout=s.layout,changes=#s.stored_diff_result.changes,
      before=vim.api.nvim_buf_get_lines(s.original_bufnr,0,-1,false),
      after=vim.api.nvim_buf_get_lines(s.modified_bufnr,0,-1,false)}
  `);
  if (diff.before[0] !== 'alpha' || diff.after[0] !== 'ALPHA') throw new Error('Wrong diff contents: ' + JSON.stringify(diff));
  await input('q');
  await waitFor(async () => !(await hasDiff()), 'Close CodeDiff');

  await input(' gt');
  await waitFor(() => lua("return vim.bo.buftype == 'terminal' and vim.fn.mode() == 't' and table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),'\\n'):find('sample.txt',1,true) ~= nil"), 'Open LazyGit terminal');
  const terminal = await lua("return {name=vim.api.nvim_buf_get_name(0),ft=vim.bo.filetype,mode=vim.fn.mode(),floating=vim.api.nvim_win_get_config(0).relative ~= ''}");
  await input('<Esc>');
  await input('2');
  await input('<Space>');
  await waitFor(() => git('diff', '--cached', '--name-only') === 'sample.txt', 'Stage in LazyGit');
  await input('c');
  await delay(100);
  const subject = 'Verify LazyGit CodeDiff integration';
  await input(subject + '<CR>');
  await waitFor(() => git('log', '-1', '--format=%s') === subject, 'Commit in LazyGit');
  await input('q');
  await waitFor(() => lua("return vim.bo.buftype ~= 'terminal'"), 'Close LazyGit');

  await input(' gh');
  await waitFor(() => lua("return require('codediff.ui.lifecycle').get_mode(vim.api.nvim_get_current_tabpage()) == 'history'"), 'Open Git history');
  await input('q');
  await waitFor(async () => !(await hasDiff()), 'Close Git history');

  // Create from an older branch, so choosing the wrong base cannot pass.
  const base = git('rev-parse', 'HEAD~1');
  git('branch', 'base-for-neogit', base);
  await input(' gn');
  await waitFor(() => lua("return vim.bo.filetype == 'NeogitStatus'"), 'Open Neogit');
  await input('y');
  await waitFor(() => lua("return vim.bo.filetype == 'NeogitRefsView' and table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),'\\n'):find('base-for-neogit',1,true) ~= nil"), 'List branches');
  const refs = await lua("return vim.api.nvim_buf_get_lines(0,0,-1,false)");
  await lua("assert(vim.fn.search('base-for-neogit','w') > 0)");
  await input('b');
  await waitFor(() => lua("return vim.api.nvim_buf_get_name(0):find('NeogitBranchPopup',1,true) ~= nil"), 'Open branch menu');
  await input('c');
  await waitFor(() => lua("return vim.bo.filetype == 'snacks_picker_input' and vim.fn.mode() == 'i'"), 'Choose branch base');
  await input('base-for-neogit');
  await delay(100);
  await input('<CR>');
  await waitFor(() => lua("return vim.bo.filetype == 'snacks_input' and vim.fn.mode() == 'i'"), 'Enter branch name');
  const branch = 'trial/neogit';
  await input('<C-u>' + branch + '<CR>');
  await waitFor(() => git('branch', '--show-current') === branch, 'Create and checkout branch');
  if (git('rev-parse', 'HEAD') !== base) throw new Error('Neogit created the branch from the wrong base');
  await waitFor(() => lua("return vim.bo.filetype == 'NeogitRefsView' or vim.bo.filetype == 'NeogitStatus'"), 'Return from branch picker');
  if (await lua("return vim.bo.filetype == 'NeogitRefsView'")) await input('q');
  await waitFor(() => lua("return vim.bo.filetype == 'NeogitStatus'"), 'Return to Neogit status');

  writeFileSync(join(repo, 'sample.txt'), 'NEOGIT\nbeta\ngamma\n');
  await input('<C-r>');
  await waitFor(() => lua("return table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),'\\n'):find('sample.txt',1,true) ~= nil"), 'Refresh Neogit changes');
  await lua("assert(vim.fn.search('sample.txt','w') > 0)");
  await input('d');
  await waitFor(() => lua("return vim.api.nvim_buf_get_name(0):find('NeogitDiffPopup',1,true) ~= nil"), 'Open diff menu');
  await input('d');
  await waitFor(() => lua("local s=require('codediff.ui.lifecycle').get_session(vim.api.nvim_get_current_tabpage()); return s and s.stored_diff_result and s.stored_diff_result.changes and #s.stored_diff_result.changes > 0"), 'Open CodeDiff from selected Neogit file');
  const neogitDiff = await lua(`
    local s=require('codediff.ui.lifecycle').get_session(vim.api.nvim_get_current_tabpage())
    return {mode=s.mode,changes=#s.stored_diff_result.changes,
      before=vim.api.nvim_buf_get_lines(s.original_bufnr,0,-1,false),
      after=vim.api.nvim_buf_get_lines(s.modified_bufnr,0,-1,false)}
  `);
  if (neogitDiff.before[0] !== 'alpha' || neogitDiff.after[0] !== 'NEOGIT') throw new Error('Wrong Neogit diff: ' + JSON.stringify(neogitDiff));
  await input('q');
  await waitFor(() => lua("return vim.bo.filetype == 'NeogitStatus'"), 'Return from CodeDiff to Neogit');
  await lua("assert(vim.fn.search('sample.txt','w') > 0)");
  await input('s');
  await waitFor(() => git('diff', '--cached', '--name-only') === 'sample.txt', 'Stage in Neogit');
  await input('c');
  await waitFor(() => lua("return vim.api.nvim_buf_get_name(0):find('NeogitCommitPopup',1,true) ~= nil"), 'Open commit menu');
  await input('c');
  await waitFor(() => lua("return vim.bo.filetype == 'gitcommit'"), 'Open Neogit commit editor');
  const neogitSubject = 'Verify Neogit branch and CodeDiff workflow';
  await input(neogitSubject + '<Esc><C-c><C-c>');
  await waitFor(() => git('log', '-1', '--format=%s') === neogitSubject, 'Commit in Neogit');
  await waitFor(() => lua("return vim.bo.filetype == 'NeogitStatus'"), 'Return after Neogit commit');
  await input('q');
  await waitFor(() => lua("return vim.bo.filetype ~= 'NeogitStatus'"), 'Close Neogit');

  const editor = await lua("return {ft=vim.bo.filetype,u=vim.fn.maparg('u','n'),dd=vim.fn.maparg('dd','n'),errmsg=vim.v.errmsg,messages=vim.api.nvim_exec2('messages',{output=true}).output}");
  if (editor.errmsg || editor.u !== '<Nop>' || editor.dd !== '<Nop>') throw new Error('Editor mappings were not restored: ' + JSON.stringify(editor));
  if (git('status', '--short')) throw new Error('Verification repository was not clean after commit');
  return {repo,setup,diff,terminal,stage:true,commit:subject,history:true,
    neogit:{refs,base,branch,diff:neogitDiff,stage:true,commit:neogitSubject,commit_count:Number(git('rev-list','--count','HEAD'))},editor};
}
