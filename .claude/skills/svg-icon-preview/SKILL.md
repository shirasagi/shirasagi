---
name: svg-icon-preview
description: SVGアイコンのテキストを受け取り、SHIRASAGIアイコンフォント(ss-icon)に変換して実寸(ユーザーに確認したサイズ)のプレビューHTMLを生成する。さらに必要に応じてSHIRASAGI本体反映用のフルビルド一式(eot/woff/woff2/scss)も出力できる。ユーザーがSVGの中身を貼り付けて表示を確認したいとき、SVGをフォントアイコン化したいとき、ss-icon-XXX の見え方を確認したいとき、SHIRASAGIにアイコンを反映したいときに使う。
---

# SVG → アイコンフォント 実寸プレビュー

ユーザーが貼り付けた(または指定した)SVGアイコンを、SHIRASAGIのアイコンフォント
(`ss-icon` / `fantasticon`)に変換し、**実寸で表示を確認できる自己完結HTML**
(フォントを埋め込み済みなので、ブラウザで開くだけで確認可能)を生成する。

## 前提
- `node` / `npx` が使えること(変換に `fantasticon` を npx 経由で使用)
- `python3` が使えること(HTML生成に使用。標準ライブラリのみ)
- ネットワーク接続(初回は npx が fantasticon を取得する)

## 手順

### 1. SVGをファイルに保存する
ユーザーがSVGの中身をテキストで貼り付けた場合は、その内容をそのまま
一時ファイル(例: `/tmp/<name>.svg`)に書き出す。
既にSVGファイルがある場合はそのパスを使う。

### 2. SVGの中身を確認する（ユーザーにも案内する）
変換前に必ずSVGの内容を確認し、**ユーザーにも確認方法を案内する**。
ユーザーが手元でSVGの中身を確かめる方法として、次を案内すること:

- **ブラウザで開く**: SVGファイルをWebブラウザにドラッグ＆ドロップすると、
  実際の見た目(色・形)が表示される。
- **テキストエディタ/ビューアで開く**: SVGはテキスト(XML)なので、
  メモ帳・VSコード等で開くと中身を直接読める。
  ターミナルなら `cat ファイル.svg`。
- **オンラインビューア**: SVGプレビュー用のWebサービスに貼り付けても確認できる。

確認すべきポイント(ユーザーに伝える):
- `viewBox` の値（ss-icon推奨は `0 0 32 32`。違っても変換は可能だが要確認）。
- `fill` / `stroke` の色。**フォントアイコンは単色になる**ため、複数色や
  「色で区別している情報」は失われる(色は後から CSS の `color` で1色だけ変更可)。
- 余分な背景・枠・不要なパスが含まれていないか。
- 文字化け・壊れたパスデータ(`d="..."`)が無いか。

Claude側でも、保存したSVGの内容を読み上げる/要点(viewBox・色・図形構成)を
ユーザーに伝え、これで合っているか確認する。

### 3. 表示サイズをユーザーに確認する（必須）
**「実際に表示するサイズ(px)」をユーザーに必ず確認する。** 勝手に40pxなどに
決めない。`AskUserQuestion` 等で「このアイコンを実際に何pxで表示しますか?」と尋ね、
回答を `--size` に渡す。用途が分かっている場合は候補(例: 16/24/40/48px)を
提示してもよいが、最終的な値はユーザーに決めてもらう。

### 4. アイコン名を決める
半角英小文字・数字・ハイフンのみ(例: `pdf`, `daily-report`)。
この名前がそのまま CSSクラス `ss-icon-<name>` になる。
ユーザー指定が無ければ内容から妥当な名前を提案して確認する。

### 5. スクリプトを実行する
```bash
python3 .claude/skills/svg-icon-preview/preview_icon.py <svgファイル> <アイコン名> --size <px> [--out 出力HTML]
```
例(ユーザーが「40pxで表示」と回答した場合):
```bash
python3 .claude/skills/svg-icon-preview/preview_icon.py /tmp/pdf.svg pdf --size 40 --out /tmp/pdf-40px-preview.html
```
成功すると、生成したプレビューHTMLのパスを標準出力に表示する。

### 6. プレビューHTMLをユーザーに届ける
`SendUserFile` で生成HTMLを送る。ユーザーはブラウザで開くだけで
確認したサイズでの実寸表示・色違い・文章中での見え方を確認できる。

## オプション: SHIRASAGI本体反映用フルビルド

プレビューで見た目を確認したあと、ユーザーが「SHIRASAGIに反映したい/本体用の
ファイル一式が欲しい」と言った場合は、`build_full.py` でフルビルドする。

このスクリプトは ss-icon リポジトリの**全SVG(既存アイコン)に新しいSVGを加えて**
ビルドするため、既存アイコンを失わず、`eot / woff / woff2 / scss / css / html` を
一括生成する(プレビュー用の単体ビルドとは異なる点に注意)。

```bash
python3 .claude/skills/svg-icon-preview/build_full.py <svgファイル> <アイコン名> [--out-dir DIR]
```
例:
```bash
python3 .claude/skills/svg-icon-preview/build_full.py /tmp/pdf.svg pdf --out-dir /tmp/shirasagi-icons-dist
```

実行後、生成物と SHIRASAGI での配置先を表示する:
- `shirasagi-icons.eot` / `.woff` / `.woff2` → `public/assets/font/`
- `shirasagi-icons.scss` → `app/assets/stylesheets/ss/_shirasagi-icons.scss`(上書き。
  `style.scss` には既に `@use "shirasagi-icons";` がある)
- `.css` / `.html` は参考・プレビュー用

生成された一式を `SendUserFile` でユーザーに届けるか、SHIRASAGI のリポジトリへ
直接配置する。**新アイコンだけの単体ビルドで `_shirasagi-icons.scss` を上書きしないこと**
(既存アイコンが消える)。必ず全SVGを含むこのフルビルドを使う。

## 注意・補足
- アイコンフォントは**単色**。元SVGが複数色でも1色のシルエット/抜き文字になる
  (色は CSS の `color` で自由に変更できる)。仕様として事前にユーザーへ伝える。
- SVGは ss-icon の仕様上 `viewBox="0 0 32 32"` が推奨だが、`--normalize` で
  自動正規化するため他の viewBox でも変換可能。
- ビルド失敗の主因は「ファイル名に使えない文字」「壊れたパスデータ」。
  エラー出力を確認して修正する。
- このプレビューは**確認専用**。SHIRASAGI本体へ反映する場合は、別途 ss-icon で
  フルビルドした `eot/woff/woff2` を `public/assets/font/` へ、`scss` を
  `app/assets/stylesheets/ss/_shirasagi-icons.scss` へ配置する。
