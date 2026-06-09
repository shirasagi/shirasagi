# GWS サイドメニュー用アイコンフォント (gws-navi-icons)

GWS のサイドメニューで使う「矢印 / 下矢印」を、PNG 背景画像から SVG 由来の
アイコンフォントに置き換えるためのソース一式です。
文字色を継承するため、コントラスト設定に追従します。

※ 歯車（設定）= Material Icons (settings)、ゴミ箱 = Material Icons (delete) に
   統一したため、これらはこのフォントには含めず SCSS 側で Material Icons Outlined を参照します。

## 構成
- `svg/` … グリフのソース SVG（24x24, 単色パス）
  - `arrow.svg`（右矢印） / `arrow-down.svg`（下矢印）
- `fantasticon.json` … フォント生成設定（出力: `public/assets/font/gws-navi-icons.{woff2,woff}`）
- `codepoints.json` … コードポイント（arrow=U+F101 / arrow-down=U+F102）

## 再生成
```sh
cd vendor/icon_fonts/gws_navi
npx fantasticon --config fantasticon.json
```

## SCSS からの利用
`app/assets/stylesheets/ss/_gws_navi_icons.scss` に @font-face と mixin
（`icon-base` / `icon` / `icon-material-setting` / `icon-material-trash`）を定義。
`_pc_mb.scss` のナビで、矢印は `icon-base`/`icon`、歯車は `icon-material-setting`、
ゴミ箱は `icon-material-trash` として適用しています。
