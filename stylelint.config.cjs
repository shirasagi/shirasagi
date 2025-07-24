"use strict";

module.exports = {
  "extends": [
    "stylelint-config-recommended-scss",
    "stylelint-config-property-sort-order-smacss"
  ],
  "plugins": [
    "@stylistic/stylelint-plugin"
  ],
  "ignoreFiles": [
    "app/assets/builds/**/*.css",
    "app/assets/stylesheets/ss/_github-markdown.scss",
    "app/assets/stylesheets/ss/_shirasagi-icons.scss"
  ],
  "rules": {
    "no-descending-specificity": null,
    "no-duplicate-selectors": null,
    "font-family-no-missing-generic-family-keyword": [
      true,
      {
        "ignoreFontFamilies": [ "Material Icons", "Material Icons Outlined", "FontAwesome" ]
      }
    ],
    "selector-disallowed-list": [
      // these selectors could be blocked by ad-blockers, so you shouldn't use.
      "/[.#].*(campaign|splash|adsbygoogle|google_ads).*/",
      "/[.#].*ads[-_].*/", "/[.#].*[-_]ads.*/", "/[.#]ads/"
    ],
    // stylistic rules from stylelint-stylistic:
    "declaration-property-value-keyword-no-deprecated": null,
    "no-invalid-position-at-import-rule": null,
    "selector-pseudo-element-colon-notation": "double"
  }
}
