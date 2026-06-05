#!/usr/bin/env node
// Generate a fantasticon config (.fantasticonrc.json content) for SHIRASAGI icons.
//
// Usage:
//   node gen_config.mjs <existing_scss_path> <svg_dir> <output_dir> [fonts_url]
//
// - Reuses the codepoints already assigned in the existing `_shirasagi-icons.scss`
//   so that existing icons keep their codepoints. Only icons whose SVG is still
//   present are pinned. fantasticon auto-assigns the lowest free codepoint to any
//   new SVG, skipping every codepoint already used by the pinned set, so existing
//   icons never collide or shift.
// - Prints the config JSON to stdout.

import fs from "node:fs";
import path from "node:path";

const [, , scssPath, svgDir, outputDir, fontsUrl = "/assets/font"] = process.argv;

if (!svgDir || !outputDir) {
  console.error("usage: node gen_config.mjs <existing_scss_path> <svg_dir> <output_dir> [fonts_url]");
  process.exit(1);
}

// SVG basenames that will be part of the font.
const svgNames = new Set(
  fs
    .readdirSync(svgDir)
    .filter((f) => f.toLowerCase().endsWith(".svg"))
    .map((f) => path.basename(f, path.extname(f)))
);

// Parse existing map entries like:   "workload": "\f101",
const codepoints = {};
if (scssPath && fs.existsSync(scssPath)) {
  const txt = fs.readFileSync(scssPath, "utf8");
  const re = /"([^"]+)"\s*:\s*"\\([0-9a-fA-F]+)"/g;
  let m;
  while ((m = re.exec(txt)) !== null) {
    const name = m[1];
    const cp = parseInt(m[2], 16);
    if (Number.isNaN(cp)) continue;
    // Only pin icons that still have a source SVG.
    if (svgNames.has(name)) codepoints[name] = cp;
  }
}

const config = {
  name: "shirasagi-icons",
  inputDir: path.resolve(svgDir),
  outputDir: path.resolve(outputDir),
  fontsUrl,
  normalize: true,
  fontTypes: ["eot", "woff", "woff2"],
  assetTypes: ["scss", "css", "html"],
  prefix: "ss-icon",
  tag: "span",
  // Pin existing icons; fantasticon assigns free codepoints to new ones.
  codepoints,
};

process.stdout.write(JSON.stringify(config, null, 2) + "\n");
