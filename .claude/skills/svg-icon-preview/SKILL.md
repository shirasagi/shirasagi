---
name: svg-icon-preview
description: SVGアイコンのテキストを受け取り、SHIRASAGIアイコンフォント(ss-icon)に変換して40px×40px実寸のプレビューHTMLを生成する。ユーザーがSVGの中身を貼り付けて表示を確認したいとき、SVGをフォントアイコン化したいとき、ss-icon-XXX の見え方を確認したいときに使う。
---

# SVG → アイコンフォント 40px実寸プレビュー

ユーザーが貼り付けた(または指定した)SVGアイコンを、SHIRASAGIのアイコンフォント
(`ss-icon` / `fantasticon`)に変換し、**40px×40pxの実寸で表示を確認できる
自己完結HTML**(フォントを埋め込み済みなので、ブラウザで開くだけで確認可能)を生成する。

## 前提
- `node` / `npx` が使えること(変換に `fantasticon` を npx 経由で使用)
- `python3` が使えること(HTML生成に使用。標準ライブラリのみ)
- ネットワーク接続(初回は npx が fantasticon を取得する)

## 手順

1. **SVGをファイルに保存する。**
   ユーザーがSVGの中身をテキストで貼り付けた場合は、その内容をそのまま
   一時ファイル(例: `/tmp/<name>.svg`)に書き出す。
   既にSVGファイルがある場合はそのパスを使う。

2. **アイコン名を決める。**
   半角英小文字・数字・ハイフンのみ(例: `pdf`, `daily-report`)。
   この名前がそのまま CSSクラス `ss-icon-<name>` になる。
   ユーザー指定が無ければ内容から妥当な名前を提案する。

3. **スクリプトを実行する。**
   ```bash
   python3 .claude/skills/svg-icon-preview/preview_icon.py <svgファイル> <アイコン名> [出力HTML]
   ```
   例:
   ```bash
   python3 .claude/skills/svg-icon-preview/preview_icon.py /tmp/pdf.svg pdf /tmp/pdf-40px-preview.html
   ```
   成功すると、生成したプレビューHTMLのパスを標準出力に表示する。

4. **プレビューHTMLをユーザーに届ける。**
   `SendUserFile` で生成HTMLを送る。ユーザーはブラウザで開くだけで
   40px実寸・色違い・文章中での見え方を確認できる。

## 注意・補足
- アイコンフォントは**単色**。元SVGが複数色でも1色のシルエット/抜き文字になる
  (色は CSS の `color` で自由に変更できる)。これは仕様であり、必要なら
  事前にユーザーへ伝える。
- SVGは ss-icon の仕様上 `viewBox="0 0 32 32"` が推奨だが、`--normalize` で
  自動正規化するため、他の viewBox でも変換は可能(今回のスクリプトは正規化済み)。
- ビルドが失敗する主因は「ファイル名に使えない文字」「壊れたパスデータ」。
  エラー出力を確認して修正する。
- このプレビューは**確認専用**。SHIRASAGI本体へ反映する場合は、別途 ss-icon で
  フルビルドした `eot/woff/woff2` を `public/assets/font/` へ、`scss` を
  `app/assets/stylesheets/ss/_shirasagi-icons.scss` へ配置する。
