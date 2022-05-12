"use strict";

module.exports = {
  "env": {
    "browser": true,
    "es2021": true,
    "node": true,
    "jquery": true
  },
  "extends": [
    "eslint:recommended"
  ],
  "plugins": [
    "ignore-erb"
  ],
  "rules": {
    "no-unused-vars": ["warn", { "argsIgnorePattern": "^_" }],
    "no-undef": "off",
  }
};
