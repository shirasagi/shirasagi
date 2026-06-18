#!/usr/bin/env python3
"""
SVGアイコンを追加して、SHIRASAGI本体反映用のフルビルド一式
(eot / woff / woff2 / scss / css / html)を生成する。

ss-icon リポジトリの全SVG(既存アイコン)に新しいSVGを加えてビルドするため、
既存アイコンを失わず、コードポイントも一貫した状態で出力される。

使い方:
  python3 build_full.py <svgファイル> <アイコン名> [--out-dir DIR] [--ss-icon-repo URL]

  <アイコン名> は半角英小文字・数字・ハイフンのみ(例: pdf, daily-report)。
  --out-dir       生成物の出力先(既定: ./shirasagi-icons-dist)
  --ss-icon-repo  ss-icon のクローン元(既定: https://github.com/shirasagi/ss-icon.git)
依存: git / node / npx (fantasticon)、ネットワーク接続
"""
import sys, os, re, shutil, subprocess, tempfile, argparse

SHIRASAGI_DEST = {
    "shirasagi-icons.eot":   "public/assets/font/",
    "shirasagi-icons.woff":  "public/assets/font/",
    "shirasagi-icons.woff2": "public/assets/font/",
    "shirasagi-icons.scss":  "app/assets/stylesheets/ss/_shirasagi-icons.scss (上書き)",
    "shirasagi-icons.css":   "(参考。通常はscssを使用)",
    "shirasagi-icons.html":  "(プレビュー用。本体には不要)",
}

def run(cmd, cwd=None):
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"コマンド失敗: {' '.join(cmd)}\n{r.stdout}\n{r.stderr}")
    return r

def main():
    p = argparse.ArgumentParser(description="SVG追加 → SHIRASAGI反映用フルビルド")
    p.add_argument("svg", help="SVGファイルのパス")
    p.add_argument("name", help="アイコン名(半角英小文字・数字・ハイフン)")
    p.add_argument("--out-dir", default="shirasagi-icons-dist", help="出力先ディレクトリ")
    p.add_argument("--ss-icon-repo", default="https://github.com/shirasagi/ss-icon.git",
                   help="ss-icon のクローン元URL")
    args = p.parse_args()

    if not re.fullmatch(r"[a-z0-9-]+", args.name):
        sys.exit(f"アイコン名は半角英小文字・数字・ハイフンのみ: {args.name!r}")
    if not os.path.isfile(args.svg):
        sys.exit(f"SVGが見つかりません: {args.svg}")

    work = tempfile.mkdtemp(prefix="ss-icon-full-")
    repo = os.path.join(work, "ss-icon")
    try:
        run(["git", "clone", "--depth", "1", args.ss_icon_repo, repo])

        svg_dir = os.path.join(repo, "src", "font", "svg")
        if not os.path.isdir(svg_dir):
            sys.exit("ss-icon の構成が想定と異なります(src/font/svg が無い)。")
        shutil.copyfile(args.svg, os.path.join(svg_dir, f"{args.name}.svg"))

        # 出力先(.fantasticonrc の outputDir)が存在している必要がある
        out_font = os.path.join(repo, "dist", "assets", "font")
        os.makedirs(out_font, exist_ok=True)

        # .fantasticonrc の設定でフルビルド(eot/woff/woff2 + scss/css/html)
        run(["npx", "--yes", "fantasticon@^3.0.0"], cwd=repo)

        out_dir = os.path.abspath(args.out_dir)
        os.makedirs(out_dir, exist_ok=True)
        produced = []
        for fn in sorted(os.listdir(out_font)):
            if fn == ".keep":
                continue
            shutil.copyfile(os.path.join(out_font, fn), os.path.join(out_dir, fn))
            produced.append(fn)

        if not produced:
            sys.exit("生成物が見つかりませんでした。")

        # 新アイコンが scss に含まれているか確認
        scss = os.path.join(out_dir, "shirasagi-icons.scss")
        ok = os.path.isfile(scss) and f'"{args.name}"' in open(scss, encoding="utf-8").read()

        print(f"出力先: {out_dir}")
        print(f"アイコン '{args.name}' を含むビルド: {'OK' if ok else '要確認'}")
        print("生成ファイルとSHIRASAGIでの配置先:")
        for fn in produced:
            print(f"  - {fn}  ->  {SHIRASAGI_DEST.get(fn, '(用途不明)')}")
    finally:
        shutil.rmtree(work, ignore_errors=True)

if __name__ == "__main__":
    main()
