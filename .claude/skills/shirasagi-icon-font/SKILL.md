---
name: shirasagi-icon-font
description: Convert SVG icons into the SHIRASAGI icon font (shirasagi-icons / ss-icon-* classes) and install the result directly into the SHIRASAGI tree (public/assets/font + app/assets/stylesheets/ss/_shirasagi-icons.scss). Use when the user wants to add, replace, or rebuild SVG-based font icons for SHIRASAGI, or asks to "turn an SVG into a font icon", "add a new ss-icon", or integrate icons into the SCSS.
---

# SHIRASAGI Icon Font Builder

Turn SVG files into the SHIRASAGI icon font and wire them into SCSS, matching the
output of [shirasagi/ss-icon](https://github.com/shirasagi/ss-icon) exactly
(fantasticon, `name: shirasagi-icons`, `prefix: ss-icon`, formats `eot/woff/woff2`,
`normalize: true`).

## What it produces

The build rewrites these files in the SHIRASAGI tree:

- `public/assets/font/shirasagi-icons.eot`
- `public/assets/font/shirasagi-icons.woff`
- `public/assets/font/shirasagi-icons.woff2`
- `app/assets/stylesheets/ss/_shirasagi-icons.scss` (the `@font-face`, the
  `$shirasagi-icons-map`, and the `.ss-icon-<name>:before` rules)

`app/assets/stylesheets/ss/style.scss` already does `@use "shirasagi-icons";`, so
no further wiring is needed. Use an icon in a view with:

```erb
<span class="ss-icon-<name>"></span>
```

## How to run

The whole flow is the helper script `scripts/build_icons.sh`. It rebuilds the
**entire** font from the canonical SVG set plus the new SVG(s), so existing icons
are preserved. Codepoints already assigned in the current `_shirasagi-icons.scss`
are pinned, and new icons are appended after the current maximum — existing icons
never shift.

Typical use (add one or more new icons):

```bash
bash .claude/skills/shirasagi-icon-font/scripts/build_icons.sh \
  --add /path/to/my-new-icon.svg
```

- The SVG **file name becomes the icon name**: `my-new-icon.svg` → `.ss-icon-my-new-icon`.
- `--add` may be given multiple times and may point at a directory of `*.svg`.
- Adding an SVG whose name matches an existing icon **replaces** that glyph.

Key options:

- `--source <dir>` — use a local directory as the full existing SVG set instead
  of cloning ss-icon (offline, or when you maintain the SVGs yourself).
- `--root <dir>` — SHIRASAGI repo root (defaults to the git toplevel / CWD).
- `--no-fetch` — do not clone ss-icon; build only from `--add`/`--source`. This
  produces a **fresh** icon set (drops icons you don't supply) — use deliberately.
- `--keep` — keep the temp work dir and print the path to the preview HTML.

Run `bash .claude/skills/shirasagi-icon-font/scripts/build_icons.sh --help` for the
full list.

## Codepoints & drift

- Existing icons keep their codepoints (read from the current scss and pinned).
  New icons take the lowest free codepoint — fantasticon skips ones already used.
- The generated scss is normalized to the project's Sass style
  (`@use "sass:map";` + `map.get(...)`).
- Because fantasticon regenerates the **whole** font, an icon is only kept if a
  source SVG exists for it. If the canonical ss-icon set has drifted from what is
  currently bundled, the script prints a clear report:
  - **added (requested)** — your `--add` icons.
  - **added (from the base set)** — icons present in ss-icon but not yet bundled.
  - **WARNING / dropped** — icons in the current scss with no source SVG; their
    `.ss-icon-*` classes would stop rendering. To keep them, pass `--source <dir>`
    with the full SVG set (including those icons) or add the missing `*.svg`.

## Requirements / notes

- Needs `node` + `npx`. fantasticon is fetched on demand via `npx`, and unless
  `--source`/`--no-fetch` is used, the canonical SVG set is cloned from ss-icon —
  so network access is required for those steps.
- After running, review the diff and commit the four changed files:

  ```bash
  git add public/assets/font/shirasagi-icons.* app/assets/stylesheets/ss/_shirasagi-icons.scss
  ```

## SVG authoring requirements

For clean glyphs (per the ss-icon README):

- `viewBox` must be exactly `0 0 32 32`.
- The design should render cleanly at 128×128 px.
- Minimize path control points.
- Prefer a single filled path; fantasticon flattens to a monochrome glyph.

## Implementation files

- `scripts/build_icons.sh` — entry point (base set → add → build → install → summary).
- `scripts/gen_config.mjs` — emits the fantasticon config and pins existing
  codepoints by reading the current `_shirasagi-icons.scss`.
