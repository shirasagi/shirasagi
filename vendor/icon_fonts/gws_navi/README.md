# GWS サイドメニュー用アイコンフォント (gws-navi-icons)

GWS のサイドメニューで使う「矢印 / 下矢印 / ゴミ箱」を、PNG 背景画像から
SVG 由来のアイコンフォントに置き換えるためのソース一式です。
文字色を継承するため、コントラスト設定に追従します。

※ 歯車（設定）アイコンは、シラサギ既存の Material Icons (settings) に統一したため
   このフォントには含めていません（SCSS 側で Material Icons Outlined を参照）。

## 構成
- `svg/` … グリフのソース SVG（24x24, 単色パス）
  - `arrow.svg`（右矢印） / `arrow-down.svg`（下矢印） / `trash.svg`（ゴミ箱）
- `fantasticon.json` … フォント生成設定（出力: `public/assets/font/gws-navi-icons.{woff2,woff}`）
- `codepoints.json` … 各グリフのコードポイント（arrow=U+F101 / arrow-down=U+F102 / trash=U+F104）

## 再生成
```sh
cd vendor/icon_fonts/gws_navi
npx fantasticon --config fantasticon.json
```
生成後、`app/assets/stylesheets/ss/_gws_navi_icons.scss` の `?v=` を更新するとキャッシュが切り替わります。

## SCSS からの利用
`app/assets/stylesheets/ss/_gws_navi_icons.scss` に @font-face と mixin（`icon-base` / `icon` / `icon-material-setting`）を定義。
`app/assets/stylesheets/ss/_pc_mb.scss` のナビ各所で `@include nav.icon-base(...)` / `@include nav.icon("trash")` /
歯車は `@include nav.icon-material-setting` として適用しています。
