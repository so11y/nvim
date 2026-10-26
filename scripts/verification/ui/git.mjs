import { execFileSync } from 'node:child_process';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';

export async function verifyGitUI(rpc) {
  const repo = mkdtempSync(join(tmpdir(), 'nvim-git-ui-'));
  const lazygitConfig = mkdtempSync(join(tmpdir(), 'nvim-lazygit-ui-'));
  writeFileSync(
    join(lazygitConfig, 'config.yml'),
    'disableStartupPopups: true\ngit:\n  autoFetch: false\n',
  );
  const git = (...args) =>
    execFileSync('git', args, {
      cwd: repo,
      encoding: 'utf8',
      windowsHide: true,
    }).trim();
  git('init', '--initial-branch=main');
  for (const [name, value] of Object.entries({
    'user.name': 'Neovim verification',
    'user.email': 'nvim-verification@example.invalid',
    'commit.gpgsign': 'false',
    'core.autocrlf': 'false',
    'core.hooksPath': join(repo, '.git', 'no-hooks'),
  }))
    git('config', '--local', name, value);
  writeFileSync(join(repo, 'sample.txt'), 'alpha\nbeta\ngamma\n');
  git('add', 'sample.txt');
  git('commit', '-m', 'Seed verification repository');
  writeFileSync(join(repo, 'sample.txt'), 'ALPHA\nbeta\ngamma\n');

  const lua = (code, ...args) => rpc('nvim_exec_lua', [code, args]);
  const input = (keys) => rpc('nvim_input', [keys]);
  const waitFor = async (condition, label) => {
    const end = Date.now() + 10000;
    while (Date.now() < end) {
      if (await condition()) return;
      await delay(50);
    }
    const state = await lua(
      "return {ft=vim.bo.filetype,mode=vim.fn.mode(),lines=vim.api.nvim_buf_get_lines(0,0,-1,false),errmsg=vim.v.errmsg,messages=vim.api.nvim_exec2('messages',{output=true}).output}",
    );
    throw new Error(label + ': ' + JSON.stringify(state));
  };
  const hasDiff = () =>
    lua(
      "return package.loaded['codediff.ui.lifecycle'] ~= nil and require('codediff.ui.lifecycle').get_session(vim.api.nvim_get_current_tabpage()) ~= nil",
    );
  await lua(
    "vim.api.nvim_set_current_dir(...); vim.cmd.edit('sample.txt')",
    repo,
  );
  await lua(
    "local dir=...; vim.env.LG_CONFIG_FILE=dir..'/config.yml'; Snacks.config.lazygit={args={'--use-config-dir',dir},theme_path=dir..'/theme.yml'}",
    lazygitConfig,
  );
  const setup = await lua(`
    local executable = vim.fn.exepath('lazygit')
    local version = vim.system({executable,'--version'},{text=true}):wait()
    assert(version.code == 0, version.stderr)
    return {executable=executable,version=version.stdout}
  `);
  await input(' gd');
  await waitFor(
    () =>
      lua(
        "local s=package.loaded['codediff.ui.lifecycle'] and require('codediff.ui.lifecycle').get_session(vim.api.nvim_get_current_tabpage()); return s and s.stored_diff_result and s.stored_diff_result.changes and #s.stored_diff_result.changes > 0",
      ),
    'Compute CodeDiff hunks',
  );
  const diff = await lua(`
    local s=require('codediff.ui.lifecycle').get_session(vim.api.nvim_get_current_tabpage())
    return {root=s.git_root,layout=s.layout,changes=#s.stored_diff_result.changes,
      before=vim.api.nvim_buf_get_lines(s.original_bufnr,0,-1,false),
      after=vim.api.nvim_buf_get_lines(s.modified_bufnr,0,-1,false)}
  `);
  if (diff.before[0] !== 'alpha' || diff.after[0] !== 'ALPHA')
    throw new Error('Wrong diff contents: ' + JSON.stringify(diff));
  await input('q');
  await waitFor(async () => !(await hasDiff()), 'Close CodeDiff');

  await input(' gt');
  await waitFor(
    () =>
      lua(
        "return vim.bo.buftype == 'terminal' and vim.fn.mode() == 't' and table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),'\\n'):find('sample.txt',1,true) ~= nil",
      ),
    'Open LazyGit terminal',
  );
  const terminal = await lua(
    "return {name=vim.api.nvim_buf_get_name(0),ft=vim.bo.filetype,mode=vim.fn.mode(),floating=vim.api.nvim_win_get_config(0).relative ~= ''}",
  );
  await input('2');
  await input('<Space>');
  await waitFor(
    () => git('diff', '--cached', '--name-only') === 'sample.txt',
    'Stage in LazyGit',
  );
  await input('c');
  await delay(100);
  const subject = 'Verify LazyGit CodeDiff integration';
  await input(subject + '<CR>');
  await waitFor(
    () => git('log', '-1', '--format=%s') === subject,
    'Commit in LazyGit',
  );
  await input('q');
  await waitFor(
    () => lua("return vim.bo.buftype ~= 'terminal'"),
    'Close LazyGit',
  );

  const editorLayout =
    "local wins={}; for _,win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do if vim.api.nvim_win_get_config(win).relative == '' then wins[#wins+1]={win=win,buf=vim.api.nvim_win_get_buf(win)} end end; return {tab=vim.api.nvim_get_current_tabpage(),wins=wins}";
  const beforeHistory = await lua(editorLayout);
  for (let attempt = 0; attempt < 2; attempt++) {
    await input(' gh');
    await waitFor(
      () =>
        lua(
          "return require('codediff.ui.lifecycle').get_mode(vim.api.nvim_get_current_tabpage()) == 'history'",
        ),
      'Open Git history',
    );
    await input('<A-w>');
    await waitFor(
      async () => !(await hasDiff()),
      'Close Git history with Alt+w',
    );
    const restored = await lua(editorLayout);
    const closeError = await lua('return vim.v.errmsg');
    if (
      JSON.stringify(restored) !== JSON.stringify(beforeHistory) ||
      closeError
    )
      throw new Error(
        'History close did not restore editor: ' +
          JSON.stringify({ attempt, beforeHistory, restored, closeError }),
      );
  }

  const editor = await lua(
    "return {ft=vim.bo.filetype,u=vim.fn.maparg('u','n'),dd=vim.fn.maparg('dd','n'),errmsg=vim.v.errmsg,messages=vim.api.nvim_exec2('messages',{output=true}).output}",
  );
  if (editor.errmsg || editor.u !== '<Nop>' || editor.dd !== '<Nop>')
    throw new Error(
      'Editor mappings were not restored: ' + JSON.stringify(editor),
    );
  if (git('status', '--short'))
    throw new Error('Verification repository was not clean after commit');
  return {
    repo,
    setup,
    diff,
    terminal,
    stage: true,
    commit: subject,
    history: true,
    editor,
  };
}
