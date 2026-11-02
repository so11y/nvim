import { verifyFormatKeysUI } from './ui/format-keys.mjs';
import { verifySelectionUI } from './ui/selection.mjs';
import { verifyNavigationPerformanceUI } from './ui/navigation-performance.mjs';
import { verifyTagActionsUI } from './ui/tag-actions.mjs';
import { verifyCodeActionsUI } from './ui/code-actions.mjs';
import { verifyFoldColorsUI } from './ui/fold-colors.mjs';
import { verifyTypescriptRefactorUI } from './ui/typescript-refactor.mjs';
import { verifyLinkedTagsUI } from './ui/linked-tags.mjs';
import { verifySearchCountUI } from './ui/search-count.mjs';
import { verifyHoverUI } from './ui/hover.mjs';
import { verifyImportPathsUI } from './ui/import-paths.mjs';
import { verifyEmmetUI } from './ui/emmet.mjs';
import { verifyUnoCSSUI } from './ui/unocss.mjs';
import { verifyMulticursorUI } from './ui/multicursor.mjs';
import { verifyGitUI } from './ui/git.mjs';

export const scenarios = {
  'module-loading': { file: 'module-loading.lua', headless: true },
  textobjects: { file: 'textobjects.lua', headless: true },
  'linked-tag-requests': { file: 'linked-tag-requests.lua', headless: true },
  'closed-file': { file: 'closed-file.lua', headless: true },
  formatting: { file: 'formatting.lua', headless: true },
  performance: {
    file: '../check-performance.lua',
    headless: true,
    optional: true,
  },
  'format-keys': { run: verifyFormatKeysUI, fixtures: true },
  selection: { run: verifySelectionUI, fixtures: true },
  'navigation-performance': {
    run: verifyNavigationPerformanceUI,
    fixtures: true,
    optional: true,
    timeout: 120000,
  },
  'tag-ui': { run: verifyTagActionsUI, fixtures: true },
  'action-ui': { run: verifyCodeActionsUI },
  'fold-colors': { run: verifyFoldColorsUI, fixtures: true },
  'typescript-refactor': { run: verifyTypescriptRefactorUI, fixtures: true },
  'linked-tags': { run: verifyLinkedTagsUI, fixtures: true },
  'search-count': { run: verifySearchCountUI },
  hover: { run: verifyHoverUI, fixtures: true },
  'import-paths': { run: verifyImportPathsUI },
  emmet: { run: verifyEmmetUI },
  unocss: { run: verifyUnoCSSUI },
  multicursor: { run: verifyMulticursorUI },
  git: { run: verifyGitUI },
  brackets: { file: 'brackets.lua' },
  'config-audit': { file: 'config-audit.lua' },
  definitions: { file: 'definitions.lua', fixtures: true },
  'editing-regressions': { file: 'editing-regressions.lua', fixtures: true },
  'emmet-context': { file: 'emmet-context.lua' },
  'emmet-vue': { file: 'emmet-vue.lua' },
  'emmet-wrap': { file: 'emmet-wrap.lua' },
  'format-failure': { file: 'format-failure.lua', fixtures: true },
  interactions: { file: 'interactions.lua', fixtures: true },
  'mason-commands': { file: 'mason-commands.lua', fixtures: true },
  'mason-tools': { file: 'mason-tools.lua' },
  'node-debug': { file: 'node-debug.lua', fixtures: true },
  'rust-debug': {
    file: 'rust-debug.lua',
    fixtures: true,
    optional: true,
    timeout: 120000,
  },
  'secondary-languages': { file: 'secondary-languages.lua', fixtures: true },
  'structural-isolation': { file: 'structural-isolation.lua' },
  'tag-actions': { file: 'tag-actions.lua', fixtures: true },
  'tag-jsx': { file: 'tag-jsx.lua' },
  'treesitter-undo': { file: 'treesitter-undo.lua' },
  'vue-folding': { file: 'vue-folding.lua', fixtures: true },
  'vue-tag-colors': { file: 'vue-tag-colors.lua' },
  'vue-textobjects': { file: 'vue-textobjects.lua', fixtures: true },
  'vue-workspaces': { file: 'vue-workspaces.lua', fixtures: true },
  'workspace-sdk': { file: 'workspace-sdk.lua', fixtures: true },
  workflows: { file: '../check-workflows.lua', fixtures: true },
  host: { file: 'host.lua', host: true, optional: true },
  installation: {
    file: 'installation.lua',
    headless: true,
    init: true,
    optional: true,
  },
};
