import { verifyFormatKeysUI } from './format-keys.mjs';
import { verifySelectionUI } from './selection.mjs';
import { verifyBreadcrumbsUI } from './breadcrumbs.mjs';
import { verifyNavigationPerformanceUI } from './navigation-performance.mjs';
import { verifyTagActionsUI } from './tag-actions.mjs';
import { verifyCodeActionsUI } from './code-actions.mjs';
import { verifyFoldColorsUI } from './fold-colors.mjs';
import { verifyTypescriptRefactorUI } from './typescript-refactor.mjs';
import { verifyLinkedTagsUI } from './linked-tags.mjs';
import { verifySearchCountUI } from './search-count.mjs';
import { verifyHoverUI } from './hover.mjs';
import { verifyImportPathsUI } from './import-paths.mjs';
import { verifyEmmetUI } from './emmet.mjs';
import { verifyUnoCSSUI } from './unocss.mjs';
import { verifyMulticursorUI } from './multicursor.mjs';
import { verifyGitUI } from './git.mjs';

export const uiScenarios = {
  'format-keys': verifyFormatKeysUI,
  selection: verifySelectionUI,
  breadcrumbs: verifyBreadcrumbsUI,
  'navigation-performance': verifyNavigationPerformanceUI,
  'tag-ui': verifyTagActionsUI,
  'action-ui': verifyCodeActionsUI,
  'fold-colors': verifyFoldColorsUI,
  'typescript-refactor.lua': verifyTypescriptRefactorUI,
  'linked-tags': verifyLinkedTagsUI,
  'search-count': verifySearchCountUI,
  hover: verifyHoverUI,
  'import-paths': verifyImportPathsUI,
  emmet: verifyEmmetUI,
  unocss: verifyUnoCSSUI,
  multicursor: verifyMulticursorUI,
  git: verifyGitUI,
};
