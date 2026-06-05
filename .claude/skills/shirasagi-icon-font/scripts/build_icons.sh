#!/usr/bin/env bash
#
# Build the SHIRASAGI icon font from SVG files and install the result into the
# SHIRASAGI tree, ready to use from SCSS.
#
# It rebuilds the WHOLE font (existing icons + your new ones) using fantasticon,
# the same tool/config as github.com/shirasagi/ss-icon, while preserving the
# codepoints already assigned to existing icons.
#
# Usage:
#   build_icons.sh --add <svg-file-or-dir> [--add ...] [options]
#
# Options:
#   --add <path>      SVG file, or a directory of *.svg, to add (repeatable).
#                     A file that matches an existing icon name replaces it.
#   --source <dir>    Directory holding the FULL existing SVG set. If omitted,
#                     the canonical set is cloned from shirasagi/ss-icon.
#   --root <dir>      SHIRASAGI repo root. Default: git toplevel, else CWD.
#   --no-fetch        Do not clone ss-icon. Build only from --add / --source
#                     (this REPLACES the whole icon set — use with care).
#   --keep            Keep the temporary work dir and print its path.
#   -h, --help        Show this help.
#
# Requirements: node + npx (network access to fetch fantasticon and, unless
# --source/--no-fetch is used, to clone ss-icon).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SS_ICON_REPO="https://github.com/shirasagi/ss-icon.git"
SCSS_REL="app/assets/stylesheets/ss/_shirasagi-icons.scss"
FONT_REL="public/assets/font"

ADD_PATHS=()
SOURCE_DIR=""
SS_ROOT=""
FETCH=1
KEEP=0

die() { echo "error: $*" >&2; exit 1; }

usage() { sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --add)     [[ $# -ge 2 ]] || die "--add needs a value"; ADD_PATHS+=("$2"); shift 2;;
    --source)  [[ $# -ge 2 ]] || die "--source needs a value"; SOURCE_DIR="$2"; shift 2;;
    --root)    [[ $# -ge 2 ]] || die "--root needs a value"; SS_ROOT="$2"; shift 2;;
    --no-fetch) FETCH=0; shift;;
    --keep)    KEEP=1; shift;;
    -h|--help) usage; exit 0;;
    *) die "unknown argument: $1";;
  esac
done

command -v node >/dev/null 2>&1 || die "node is required"
command -v npx  >/dev/null 2>&1 || die "npx is required"

# Resolve SHIRASAGI root.
if [[ -z "$SS_ROOT" ]]; then
  SS_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
fi
SS_ROOT="$(cd "$SS_ROOT" && pwd)"
SCSS_PATH="$SS_ROOT/$SCSS_REL"
[[ -d "$SS_ROOT/app/assets/stylesheets/ss" ]] || \
  die "does not look like a SHIRASAGI tree: $SS_ROOT (missing app/assets/stylesheets/ss)"

WORK="$(mktemp -d)"
cleanup() { [[ "$KEEP" -eq 1 ]] || rm -rf "$WORK"; }
trap cleanup EXIT
SVG_DIR="$WORK/svg"
DIST_DIR="$WORK/dist"
mkdir -p "$SVG_DIR" "$DIST_DIR"

# 1) Base SVG set ------------------------------------------------------------
if [[ -n "$SOURCE_DIR" ]]; then
  [[ -d "$SOURCE_DIR" ]] || die "--source dir not found: $SOURCE_DIR"
  cp "$SOURCE_DIR"/*.svg "$SVG_DIR"/ 2>/dev/null || true
  echo "base: $SOURCE_DIR"
elif [[ "$FETCH" -eq 1 ]]; then
  echo "base: cloning $SS_ICON_REPO ..."
  git clone --depth 1 --quiet "$SS_ICON_REPO" "$WORK/ss-icon" \
    || die "failed to clone ss-icon (use --source <dir> or --no-fetch)"
  cp "$WORK/ss-icon/src/font/svg/"*.svg "$SVG_DIR"/ 2>/dev/null || true
else
  echo "base: none (--no-fetch) — building a fresh icon set from --add only"
fi
base_count=$(find "$SVG_DIR" -maxdepth 1 -iname '*.svg' | wc -l | tr -d ' ')

# 2) Add / replace new SVGs --------------------------------------------------
[[ ${#ADD_PATHS[@]} -gt 0 ]] || die "nothing to add: pass at least one --add <svg-file-or-dir>"
added_names="$WORK/added.txt"; : > "$added_names"
record_added() { basename "$1" | sed -E 's/\.[sS][vV][gG]$//' >> "$added_names"; }
for p in "${ADD_PATHS[@]}"; do
  if [[ -d "$p" ]]; then
    shopt -s nullglob nocaseglob
    files=("$p"/*.svg)
    shopt -u nullglob nocaseglob
    [[ ${#files[@]} -gt 0 ]] || die "no *.svg in directory: $p"
    for f in "${files[@]}"; do cp "$f" "$SVG_DIR"/; record_added "$f"; done
  elif [[ -f "$p" ]]; then
    [[ "$p" == *.svg || "$p" == *.SVG ]] || die "not an svg file: $p"
    cp "$p" "$SVG_DIR"/; record_added "$p"
  else
    die "--add path not found: $p"
  fi
done
sort -u "$added_names" -o "$added_names"
total_count=$(find "$SVG_DIR" -maxdepth 1 -iname '*.svg' | wc -l | tr -d ' ')
[[ "$total_count" -gt 0 ]] || die "no SVG files to build"

# Record names before/after for a friendly summary.
existing_names="$WORK/existing.txt"
if [[ -f "$SCSS_PATH" ]]; then
  grep -oE '"[^"]+"[[:space:]]*:[[:space:]]*"\\[0-9a-fA-F]+"' "$SCSS_PATH" \
    | sed -E 's/^"([^"]+)".*/\1/' | sort -u > "$existing_names" || true
else
  : > "$existing_names"
fi

# 3) Generate fantasticon config (pins existing codepoints) ------------------
CONFIG="$WORK/.fantasticonrc.json"
node "$SCRIPT_DIR/gen_config.mjs" "$SCSS_PATH" "$SVG_DIR" "$DIST_DIR" "/assets/font" > "$CONFIG"

# 4) Build -------------------------------------------------------------------
echo "building font with fantasticon ($total_count icons) ..."
( cd "$WORK" && npx --yes fantasticon@^3.0.0 ) \
  || die "fantasticon build failed"

for ext in eot woff woff2 scss; do
  [[ -f "$DIST_DIR/shirasagi-icons.$ext" ]] || die "expected output missing: shirasagi-icons.$ext"
done

# 5) Install into the SHIRASAGI tree -----------------------------------------
mkdir -p "$SS_ROOT/$FONT_REL"
cp "$DIST_DIR/shirasagi-icons.eot"   "$SS_ROOT/$FONT_REL/"
cp "$DIST_DIR/shirasagi-icons.woff"  "$SS_ROOT/$FONT_REL/"
cp "$DIST_DIR/shirasagi-icons.woff2" "$SS_ROOT/$FONT_REL/"
cp "$DIST_DIR/shirasagi-icons.scss"  "$SCSS_PATH"   # note leading underscore in dest

# Match SHIRASAGI's Sass style: use the sass:map module instead of the
# deprecated global map-get().
sed -i 's/map-get(/map.get(/g' "$SCSS_PATH"
if ! head -1 "$SCSS_PATH" | grep -q '@use "sass:map"'; then
  printf '@use "sass:map";\n\n%s\n' "$(cat "$SCSS_PATH")" > "$SCSS_PATH.tmp"
  mv "$SCSS_PATH.tmp" "$SCSS_PATH"
fi

# 6) Summary -----------------------------------------------------------------
new_names="$WORK/new.txt"
grep -oE '"[^"]+"[[:space:]]*:[[:space:]]*"\\[0-9a-fA-F]+"' "$SCSS_PATH" \
  | sed -E 's/^"([^"]+)".*/\1/' | sort -u > "$new_names" || true

cp_of() { # codepoint string (\fXXX) for an icon name in the final scss
  grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"\\\\[0-9a-fA-F]+\"" "$SCSS_PATH" \
    | grep -oE '\\[0-9a-fA-F]+' | head -1
}

# requested = added via --add ; appeared = in new not in old ; dropped = in old not in new
appeared="$WORK/appeared.txt"; comm -13 "$existing_names" "$new_names" > "$appeared" || true
dropped="$WORK/dropped.txt";  comm -23 "$existing_names" "$new_names" > "$dropped"  || true
from_base="$WORK/from_base.txt"; comm -23 "$appeared" "$added_names" > "$from_base" || true

echo ""
echo "done."
echo "  SHIRASAGI root : $SS_ROOT"
echo "  base icons     : $base_count"
echo "  total icons    : $total_count"
echo "  fonts          : $FONT_REL/shirasagi-icons.{eot,woff,woff2}"
echo "  scss           : $SCSS_REL"
echo ""
echo "  added (requested):"
while read -r n; do [[ -z "$n" ]] && continue; echo "    .ss-icon-$n   (content: $(cp_of "$n"))"; done < "$added_names"

if [[ -s "$from_base" ]]; then
  echo ""
  echo "  added (from the base/ss-icon set, not via --add):"
  while read -r n; do [[ -z "$n" ]] && continue; echo "    .ss-icon-$n   (content: $(cp_of "$n"))"; done < "$from_base"
fi

if [[ -s "$dropped" ]]; then
  echo ""
  echo "  !! WARNING — these icons are NO LONGER in the font (no source SVG was"
  echo "     supplied for them). Any page using these classes will stop rendering:"
  while read -r n; do [[ -z "$n" ]] && continue; echo "       .ss-icon-$n"; done < "$dropped"
  echo "     To keep them, re-run with --source <dir> containing their SVGs,"
  echo "     or add the missing *.svg via --add."
fi

echo ""
echo "  usage in views: <span class=\"ss-icon-<name>\"></span>"
[[ -f "$DIST_DIR/shirasagi-icons.html" ]] && echo "  preview html  : $DIST_DIR/shirasagi-icons.html (use --keep to retain)"
echo ""
echo "  review/commit:"
echo "    git -C \"$SS_ROOT\" add $FONT_REL/shirasagi-icons.* $SCSS_REL"
