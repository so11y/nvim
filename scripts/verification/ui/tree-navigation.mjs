import { setTimeout as delay } from "node:timers/promises";
import { waitFor } from "./wait.mjs";

export async function verifyTreeNavigationUI(rpc) {
  const lua = (code, args = []) => rpc("nvim_exec_lua", [code, args]);
  const press = (key) => rpc("nvim_input", [key]);
  const fixture = await lua(`
    require('persistence').stop()
    local utils = require('neo-tree.utils')
    local directory = vim.fn.tempname() .. '-tree-navigation'
    vim.fn.mkdir(directory, 'p')
    directory = utils.normalize_path(assert(vim.uv.fs_realpath(directory)))
    local branch = utils.path_join(directory, 'branch')
    local child = utils.path_join(branch, 'child')
    local leaf = utils.path_join(child, 'leaf.txt')
    local root_file = utils.path_join(directory, 'root.txt')
    local empty = utils.path_join(directory, 'empty')
    local markdown = utils.path_join(directory, 'breadcrumbs.md')
    vim.fn.mkdir(child, 'p')
    vim.fn.mkdir(empty, 'p')
    vim.fn.writefile({ 'leaf contents' }, leaf)
    vim.fn.writefile({ 'root contents' }, root_file)
    vim.fn.writefile({ '# First', 'first body', '', '# Sibling', 'sibling body' }, markdown)
    return { directory = directory, branch = branch, child = child, leaf = leaf,
      root_file = root_file, empty = empty, markdown = markdown, cwd = vim.fn.getcwd() }
  `);
  const treeState = () =>
    lua(`
    local state = require('neo-tree.sources.manager').get_state('filesystem')
    local node = state.tree and state.tree:get_node()
    return { id = node and node:get_id(), expanded = node and node:is_expanded(),
      path = state.path, cwd = vim.fn.getcwd(),
      file = require('neo-tree.utils').normalize_path(vim.api.nvim_buf_get_name(0)), errmsg = vim.v.errmsg }
  `);
  const focusNode = (id) =>
    lua(
      `
    local state = require('neo-tree.sources.manager').get_state('filesystem')
    assert(require('neo-tree.ui.renderer').focus_node(state, ...), 'Tree node is missing')
  `,
      [id]
    );
  const waitNode = (id, expanded, message) =>
    waitFor(
      treeState,
      (state) =>
        state.id === id &&
        (expanded === undefined || state.expanded === expanded),
      message
    );
  await lua(
    "require('neo-tree.command').execute({ action = 'focus', dir = ... })",
    [fixture.directory]
  );
  await waitNode(fixture.directory, true, "File tree did not load");
  const treeCwd = (await treeState()).cwd;
  await focusNode(fixture.branch);
  await press("l");
  await waitNode(fixture.branch, true, "l did not expand the directory");
  await press("l");
  await waitNode(
    fixture.branch,
    false,
    "l did not collapse the directory in place"
  );
  await press("l");
  await waitNode(
    fixture.branch,
    true,
    "l did not reopen the directory in place"
  );
  await press("j");
  await waitNode(fixture.child, false, "j did not select the first child");
  await press("l");
  await waitNode(fixture.child, true, "l did not expand the nested directory");
  await press("l");
  await waitNode(
    fixture.child,
    false,
    "l did not collapse the nested directory in place"
  );
  await press("l");
  await waitNode(
    fixture.child,
    true,
    "l did not reopen the nested directory in place"
  );
  await press("j");
  await waitNode(fixture.leaf, false, "j did not select the nested file");
  await press("h");
  await waitNode(
    fixture.child,
    false,
    "h did not return to and collapse the parent"
  );
  await press("h");
  await waitNode(
    fixture.branch,
    false,
    "h did not return to the outer directory"
  );
  await press("h");
  await waitNode(fixture.directory, true, "h did not focus the tree root");
  await press("h");
  const boundary = await waitNode(
    fixture.directory,
    true,
    "h crossed the root"
  );
  if (boundary.path !== fixture.directory || boundary.cwd !== treeCwd)
    throw new Error("h changed the tree root: " + JSON.stringify(boundary));
  await focusNode(fixture.empty);
  await press("l");
  await press("l");
  await waitNode(
    fixture.empty,
    undefined,
    "An empty directory changed the selection"
  );
  await focusNode(fixture.leaf);
  await press("l");
  await waitFor(
    treeState,
    (state) => state.file === fixture.leaf,
    "l did not open the file"
  );
  await lua("require('neo-tree.command').execute({ action = 'focus' })");
  await focusNode(fixture.root_file);
  await press("<CR>");
  await waitFor(
    treeState,
    (state) => state.file === fixture.root_file,
    "Enter stopped opening files"
  );
  await lua(
    "require('neo-tree.command').execute({ action = 'close' }); vim.api.nvim_set_current_dir(...)",
    [fixture.cwd]
  );

  const openMarkdown = (row) =>
    lua(
      `
    local file, row = ...
    vim.cmd.edit(file)
    vim.api.nvim_win_set_cursor(0, { row, 0 })
  `,
      [fixture.markdown, row]
    );
  const editorState = () =>
    lua(`
    require('dropbar.menu')
    local menu = require('dropbar.utils.menu').get_current()
    return { win = vim.api.nvim_get_current_win(), line = vim.api.nvim_win_get_cursor(0)[1],
      file = require('neo-tree.utils').normalize_path(vim.api.nvim_buf_get_name(0)),
      menu = menu ~= nil, parent = menu and menu.prev_menu and menu.prev_menu.win,
      text = menu and table.concat(vim.api.nvim_buf_get_lines(menu.buf, 0, -1, false), string.char(10))
        or vim.api.nvim_eval_statusline(vim.wo.winbar, { winid = 0, use_winbar = true }).str,
      errmsg = vim.v.errmsg }
  `);
  const pickComponent = async (field, value) => {
    // Finish the source bar debounce before opening a menu on its components.
    await delay(50);
    await lua(
      `
      local field, value = ...
      local api = require('dropbar.api')
      local bar = api.get_dropbar(vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win())
      for index, component in ipairs(bar.components) do
        if component[field] == value then api.pick(index); return end
      end
      error('Breadcrumb component is missing: ' .. value)
    `,
      [field, value]
    );
    return waitFor(
      editorState,
      (state) => state.menu,
      "Breadcrumb menu did not open"
    );
  };
  const selectEntry = (name) =>
    lua(
      `
    local name = ...
    local menu = assert(require('dropbar.utils.menu').get_current())
    for row, line in ipairs(vim.api.nvim_buf_get_lines(menu.buf, 0, -1, false)) do
      local col = line:find(name, 1, true)
      if col then vim.api.nvim_win_set_cursor(menu.win, { row, col - 1 }); return row end
    end
    error('Menu entry is missing: ' .. name)
  `,
      [name]
    );
  await openMarkdown(2);
  await waitFor(
    editorState,
    (state) => state.text.includes("First"),
    "Initial breadcrumb heading is missing"
  );
  const parent = await pickComponent("name_hl", "DropBarKindFile");
  const parentRow = await selectEntry("branch");
  await press("l");
  await waitFor(
    editorState,
    (state) => state.parent === parent.win && state.text.includes("child"),
    "l on the label did not expand the directory"
  );
  await press("h");
  await waitFor(
    editorState,
    (state) => state.win === parent.win && state.line === parentRow,
    "h lost the parent menu or selection"
  );
  await press("l");
  await waitFor(
    editorState,
    (state) => state.parent === parent.win,
    "l did not reopen the child menu"
  );
  await selectEntry("child");
  await press("l");
  await waitFor(
    editorState,
    (state) => state.menu && state.text.includes("leaf.txt"),
    "l did not open the nested menu"
  );
  await selectEntry("leaf.txt");
  await press("l");
  await waitFor(
    editorState,
    (state) => !state.menu && state.file === fixture.leaf,
    "l did not open the breadcrumb file"
  );
  await openMarkdown(5);
  await waitFor(
    editorState,
    (state) => !state.menu && state.text.includes("Sibling"),
    "Breadcrumb heading did not follow the cursor"
  );
  await pickComponent("name", "Sibling");
  await selectEntry("Sibling");
  await press("l");
  const jumped = await waitFor(
    editorState,
    (state) =>
      !state.menu && state.file === fixture.markdown && state.line === 4,
    "l did not jump to the leaf symbol"
  );
  await pickComponent("name", "Sibling");
  await press("h");
  const returned = await waitFor(
    editorState,
    (state) => !state.menu && state.file === fixture.markdown,
    "h at the outer menu did not return to the editor"
  );
  if (jumped.errmsg || returned.errmsg)
    throw new Error(jumped.errmsg || returned.errmsg);
  return {
    neotree: {
      expand: true,
      stay_on_directory: true,
      toggle_directory: true,
      collapse_parent: true,
      root_boundary: true,
      empty_directory: true,
      open_file: true,
      enter_preserved: true
    },
    dropbar: {
      expand_from_label: true,
      return_to_parent: true,
      preserve_selection: true,
      open_file: true,
      leaf_jump: jumped.line,
      close_outer_menu: true
    }
  };
}
