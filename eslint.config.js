"use strict";

const {
  defineConfig,
} = require("eslint/config");

const globals = require("globals");
const ignoreErb = require("eslint-plugin-ignore-erb");
const js = require("@eslint/js");

const {
  FlatCompat,
} = require("@eslint/eslintrc");

const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
  allConfig: js.configs.all
});

module.exports = defineConfig([{
  languageOptions: {
    globals: {
      ...globals.browser,
      ...globals.jquery,
    },

    "sourceType": "module",
    parserOptions: {},
  },

  extends: compat.extends("eslint:recommended"),

  plugins: {
    "ignore-erb": ignoreErb,
  },

  "rules": {
    "no-unused-vars": ["warn", {
      "argsIgnorePattern": "^_",
    }],

    "no-undef": "off",
  },
}]);
