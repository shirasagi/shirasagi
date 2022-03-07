"use strict";

module.exports = {
  "extends": [ "stylelint-config-recommended-scss", "stylelint-config-property-sort-order-smacss" ],
  "rules": {
  "no-descending-specificity": null,
    "font-family-no-missing-generic-family-keyword": [
      true,
      {
        "ignoreFontFamilies": [ "Material Icons", "FontAwesome" ]
      }
    ],
    "selector-disallowed-list": [
      // these selectors could be blocked by ad-blockers, so you shouldn't use.
      "/[.#].*(campaign|splash|adsbygoogle|google_ads).*/",
      "/[.#].*ads[-_].*/", "/[.#].*[-_]ads.*/", "/[.#]ads/"
    ]
  }
}
