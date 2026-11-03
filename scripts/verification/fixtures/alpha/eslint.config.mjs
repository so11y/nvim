import tsParser from '@typescript-eslint/parser';
import vue from 'eslint-plugin-vue';

export default [
  ...vue.configs['flat/essential'],
  {
    files: ['**/*.{js,vue}'],
    rules: {
      'no-unused-vars': 'error',
      'no-var': 'error',
      eqeqeq: ['error', 'always'],
    },
  },
  {
    files: ['**/*.vue'],
    languageOptions: {
      parserOptions: { parser: tsParser },
    },
  },
];
