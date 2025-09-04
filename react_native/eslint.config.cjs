const babelParser = require('@babel/eslint-parser');

module.exports = [
  {
    ignores: ['node_modules/', 'babel.config.js', 'eslint.config.cjs']
  },
  {
    files: ['**/*.js'],
    languageOptions: {
      parser: babelParser,
      ecmaVersion: 'latest',
      sourceType: 'module',
      parserOptions: {
        requireConfigFile: false,
        babelOptions: { configFile: false, presets: ['@babel/preset-react'] },
        ecmaFeatures: { jsx: true }
      },
      globals: { console: 'readonly' }
    },
    rules: {}
  }
];
