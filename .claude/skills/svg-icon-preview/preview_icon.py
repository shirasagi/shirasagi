#!/usr/bin/env python3
"""
SVGアイコンをSHIRASAGIアイコンフォント(ss-icon相当)に変換し、
指定したサイズ(実寸)のプレビューHTML(フォント埋め込み・自己完結)を生成する。

使い方:
  python3 preview_icon.py <svgファイル> <アイコン名> [--size N] [--out 出力HTML]

  <アイコン名> は半角英小文字・数字・ハイフンのみ(例: pdf, daily-report)。
  これがそのまま CSSクラス ss-icon-<アイコン名> になります。
  --size  実際に表示するサイズ(px)。省略時は 40。
          ※ 表示サイズはユーザーに確認してから指定すること。
依存: node / npx (fantasticon を npx 経由で実行)
"""
import sys, os, re, base64, shutil, subprocess, tempfile, argparse

def main():
    p = argparse.ArgumentParser(add_help=True, description="SVG -> アイコンフォント 実寸プレビュー生成")
    p.add_argument("svg", help="SVGファイルのパス")
    p.add_argument("name", help="アイコン名(半角英小文字・数字・ハイフン)")
    p.add_argument("--size", type=int, default=40, help="表示サイズ(px)。既定40。ユーザーに確認のうえ指定。")
    p.add_argument("--out", default=None, help="出力HTMLパス")
    args = p.parse_args()

    svg_path, name, size = args.svg, args.name, args.size
    out_html = args.out or f"{name}-{size}px-preview.html"

    if not re.fullmatch(r"[a-z0-9-]+", name):
        sys.exit(f"アイコン名は半角英小文字・数字・ハイフンのみ: {name!r}")
    if size <= 0:
        sys.exit(f"サイズは正の整数で指定してください: {size}")
    if not os.path.isfile(svg_path):
        sys.exit(f"SVGが見つかりません: {svg_path}")

    work = tempfile.mkdtemp(prefix="ss-icon-")
    svg_dir = os.path.join(work, "svg")
    out_dir = os.path.join(work, "out")
    os.makedirs(svg_dir); os.makedirs(out_dir)
    shutil.copyfile(svg_path, os.path.join(svg_dir, f"{name}.svg"))

    # fantasticon を .fantasticonrc と同等の設定で実行
    cmd = ["npx", "--yes", "fantasticon@^3.0.0", svg_dir, "-o", out_dir,
           "--name", "shirasagi-icons", "--normalize", "true",
           "--font-types", "woff2", "--asset-types", "css",
           "--prefix", "ss-icon", "--tag", "span"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit("fantasticon の実行に失敗しました:\n" + r.stdout + r.stderr)

    woff2 = os.path.join(out_dir, "shirasagi-icons.woff2")
    css = os.path.join(out_dir, "shirasagi-icons.css")
    if not os.path.isfile(woff2) or not os.path.isfile(css):
        sys.exit("出力ファイルが生成されませんでした。")

    # 生成CSSから当該アイコンのコードポイントを取得
    css_text = open(css, encoding="utf-8").read()
    m = re.search(r"\.ss-icon-%s:before\s*\{[^}]*content:\s*[\"']([^\"']+)[\"']" % re.escape(name), css_text)
    if not m:
        sys.exit("生成CSSにアイコン定義が見つかりませんでした。")
    content = m.group(1)

    b64 = base64.b64encode(open(woff2, "rb").read()).decode()
    html = f'''<!DOCTYPE html>
<html lang="ja"><head><meta charset="utf-8">
<title>ss-icon-{name} {size}px 表示確認</title>
<style>
@font-face {{ font-family:"shirasagi-icons"; src:url(data:font/woff2;base64,{b64}) format("woff2"); }}
body {{ font-family: sans-serif; padding: 40px; line-height: 1.6; color:#222; }}
.ss-icon-{name} {{
  font-family:"shirasagi-icons"; font-style:normal; font-weight:normal;
  font-size:{size}px; line-height:{size}px; width:{size}px; height:{size}px;
  display:inline-block; -webkit-font-smoothing:antialiased; -moz-osx-font-smoothing:grayscale;
}}
.ss-icon-{name}:before {{ content:"{content}"; }}
.box {{ display:inline-block; border:1px dashed #ccc; vertical-align:middle; }}
.row {{ display:flex; align-items:center; gap:30px; margin:24px 0; }}
code {{ background:#f0f0f0; padding:2px 6px; border-radius:4px; }}
.red {{ color:#d32d26; }} .navy {{ color:#1b3a6b; }} .gray {{ color:#606060; }}
</style></head>
<body>
<h1>表示確認: <code>ss-icon-{name}</code> を {size}px × {size}px で表示</h1>
<p>HTML: <code>&lt;span class="ss-icon-{name}"&gt;&lt;/span&gt;</code>（CSSで <code>font-size:{size}px</code>）</p>
<div class="row">
  <span class="box"><span class="ss-icon-{name}"></span></span>
  <span style="color:#888">← 点線が {size}px × {size}px の枠</span>
</div>
<h3>色のバリエーション({size}px)</h3>
<div class="row">
  <span class="box"><span class="ss-icon-{name} gray"></span></span>
  <span class="box"><span class="ss-icon-{name} red"></span></span>
  <span class="box"><span class="ss-icon-{name} navy"></span></span>
</div>
<h3>文章中での見え方({size}px)</h3>
<p>資料はこちら <span class="ss-icon-{name}"></span> からご確認ください。</p>
</body></html>'''
    with open(out_html, "w", encoding="utf-8") as f:
        f.write(html)
    shutil.rmtree(work, ignore_errors=True)
    print(out_html)

if __name__ == "__main__":
    main()
