//= require_self
//= require chartjs-plugin-colorschemes-v3/dist/chartjs-plugin-colorschemes-v3.js

// chartjs-plugin-colorschemes-v3 に問題があり helpers をグローバル変数として定義しておかないとプラグイン内でエラーが発生する
// 現状 colorschemes を利用している箇所はオープンデータのグラフプレビューのみ
window.helpers = Chart.helpers;
