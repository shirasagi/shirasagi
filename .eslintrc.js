"use strict";

module.exports = {
  "env": {
    "browser": true,
    "es2022": true,
    // "node": true,
    "jquery": true
  },
  "extends": [
    "eslint:recommended"
  ],
  "parserOptions": {
    "sourceType": "module"
  },
  "plugins": [
    "ignore-erb"
  ],
  "rules": {
    "no-unused-vars": ["warn", { "argsIgnorePattern": "^_" }],
    "no-undef": "off",
  }
};
