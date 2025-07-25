


// chartjs-plugin-colorschemes-v3 に問題があり helpers をグローバル変数として定義しておかないとプラグイン内でエラーが発生する
// 現状 colorschemes を利用している箇所はオープンデータのグラフプレビューのみ
window.helpers = Chart.helpers;
/*!
 * chartjs-plugin-colorschemes-v3 v0.5.4
 * https://nagix.github.io/chartjs-plugin-colorschemes
 * (c) 2022 Akihiko Kusanagi
 * Released under the MIT license
 */
(function (global, factory) {
typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory(require('chart.js'), require('chart.js/helpers')) :
typeof define === 'function' && define.amd ? define(['chart.js', 'chart.js/helpers'], factory) :
(global = global || self, global.ChartColorSchemes = factory(global.Chart, global.helpers));
}(this, (function (chart_js, helpers) { 'use strict';

// eslint-disable-next-line one-var
var
	// Sequential
	YlGn3 = ['#f7fcb9', '#addd8e', '#31a354'],
	YlGn4 = ['#ffffcc', '#c2e699', '#78c679', '#238443'],
	YlGn5 = ['#ffffcc', '#c2e699', '#78c679', '#31a354', '#006837'],
	YlGn6 = ['#ffffcc', '#d9f0a3', '#addd8e', '#78c679', '#31a354', '#006837'],
	YlGn7 = ['#ffffcc', '#d9f0a3', '#addd8e', '#78c679', '#41ab5d', '#238443', '#005a32'],
	YlGn8 = ['#ffffe5', '#f7fcb9', '#d9f0a3', '#addd8e', '#78c679', '#41ab5d', '#238443', '#005a32'],
	YlGn9 = ['#ffffe5', '#f7fcb9', '#d9f0a3', '#addd8e', '#78c679', '#41ab5d', '#238443', '#006837', '#004529'],

	YlGnBu3 = ['#edf8b1', '#7fcdbb', '#2c7fb8'],
	YlGnBu4 = ['#ffffcc', '#a1dab4', '#41b6c4', '#225ea8'],
	YlGnBu5 = ['#ffffcc', '#a1dab4', '#41b6c4', '#2c7fb8', '#253494'],
	YlGnBu6 = ['#ffffcc', '#c7e9b4', '#7fcdbb', '#41b6c4', '#2c7fb8', '#253494'],
	YlGnBu7 = ['#ffffcc', '#c7e9b4', '#7fcdbb', '#41b6c4', '#1d91c0', '#225ea8', '#0c2c84'],
	YlGnBu8 = ['#ffffd9', '#edf8b1', '#c7e9b4', '#7fcdbb', '#41b6c4', '#1d91c0', '#225ea8', '#0c2c84'],
	YlGnBu9 = ['#ffffd9', '#edf8b1', '#c7e9b4', '#7fcdbb', '#41b6c4', '#1d91c0', '#225ea8', '#253494', '#081d58'],

	GnBu3 = ['#e0f3db', '#a8ddb5', '#43a2ca'],
	GnBu4 = ['#f0f9e8', '#bae4bc', '#7bccc4', '#2b8cbe'],
	GnBu5 = ['#f0f9e8', '#bae4bc', '#7bccc4', '#43a2ca', '#0868ac'],
	GnBu6 = ['#f0f9e8', '#ccebc5', '#a8ddb5', '#7bccc4', '#43a2ca', '#0868ac'],
	GnBu7 = ['#f0f9e8', '#ccebc5', '#a8ddb5', '#7bccc4', '#4eb3d3', '#2b8cbe', '#08589e'],
	GnBu8 = ['#f7fcf0', '#e0f3db', '#ccebc5', '#a8ddb5', '#7bccc4', '#4eb3d3', '#2b8cbe', '#08589e'],
	GnBu9 = ['#f7fcf0', '#e0f3db', '#ccebc5', '#a8ddb5', '#7bccc4', '#4eb3d3', '#2b8cbe', '#0868ac', '#084081'],

	BuGn3 = ['#e5f5f9', '#99d8c9', '#2ca25f'],
	BuGn4 = ['#edf8fb', '#b2e2e2', '#66c2a4', '#238b45'],
	BuGn5 = ['#edf8fb', '#b2e2e2', '#66c2a4', '#2ca25f', '#006d2c'],
	BuGn6 = ['#edf8fb', '#ccece6', '#99d8c9', '#66c2a4', '#2ca25f', '#006d2c'],
	BuGn7 = ['#edf8fb', '#ccece6', '#99d8c9', '#66c2a4', '#41ae76', '#238b45', '#005824'],
	BuGn8 = ['#f7fcfd', '#e5f5f9', '#ccece6', '#99d8c9', '#66c2a4', '#41ae76', '#238b45', '#005824'],
	BuGn9 = ['#f7fcfd', '#e5f5f9', '#ccece6', '#99d8c9', '#66c2a4', '#41ae76', '#238b45', '#006d2c', '#00441b'],

	PuBuGn3 = ['#ece2f0', '#a6bddb', '#1c9099'],
	PuBuGn4 = ['#f6eff7', '#bdc9e1', '#67a9cf', '#02818a'],
	PuBuGn5 = ['#f6eff7', '#bdc9e1', '#67a9cf', '#1c9099', '#016c59'],
	PuBuGn6 = ['#f6eff7', '#d0d1e6', '#a6bddb', '#67a9cf', '#1c9099', '#016c59'],
	PuBuGn7 = ['#f6eff7', '#d0d1e6', '#a6bddb', '#67a9cf', '#3690c0', '#02818a', '#016450'],
	PuBuGn8 = ['#fff7fb', '#ece2f0', '#d0d1e6', '#a6bddb', '#67a9cf', '#3690c0', '#02818a', '#016450'],
	PuBuGn9 = ['#fff7fb', '#ece2f0', '#d0d1e6', '#a6bddb', '#67a9cf', '#3690c0', '#02818a', '#016c59', '#014636'],

	PuBu3 = ['#ece7f2', '#a6bddb', '#2b8cbe'],
	PuBu4 = ['#f1eef6', '#bdc9e1', '#74a9cf', '#0570b0'],
	PuBu5 = ['#f1eef6', '#bdc9e1', '#74a9cf', '#2b8cbe', '#045a8d'],
	PuBu6 = ['#f1eef6', '#d0d1e6', '#a6bddb', '#74a9cf', '#2b8cbe', '#045a8d'],
	PuBu7 = ['#f1eef6', '#d0d1e6', '#a6bddb', '#74a9cf', '#3690c0', '#0570b0', '#034e7b'],
	PuBu8 = ['#fff7fb', '#ece7f2', '#d0d1e6', '#a6bddb', '#74a9cf', '#3690c0', '#0570b0', '#034e7b'],
	PuBu9 = ['#fff7fb', '#ece7f2', '#d0d1e6', '#a6bddb', '#74a9cf', '#3690c0', '#0570b0', '#045a8d', '#023858'],

	BuPu3 = ['#e0ecf4', '#9ebcda', '#8856a7'],
	BuPu4 = ['#edf8fb', '#b3cde3', '#8c96c6', '#88419d'],
	BuPu5 = ['#edf8fb', '#b3cde3', '#8c96c6', '#8856a7', '#810f7c'],
	BuPu6 = ['#edf8fb', '#bfd3e6', '#9ebcda', '#8c96c6', '#8856a7', '#810f7c'],
	BuPu7 = ['#edf8fb', '#bfd3e6', '#9ebcda', '#8c96c6', '#8c6bb1', '#88419d', '#6e016b'],
	BuPu8 = ['#f7fcfd', '#e0ecf4', '#bfd3e6', '#9ebcda', '#8c96c6', '#8c6bb1', '#88419d', '#6e016b'],
	BuPu9 = ['#f7fcfd', '#e0ecf4', '#bfd3e6', '#9ebcda', '#8c96c6', '#8c6bb1', '#88419d', '#810f7c', '#4d004b'],

	RdPu3 = ['#fde0dd', '#fa9fb5', '#c51b8a'],
	RdPu4 = ['#feebe2', '#fbb4b9', '#f768a1', '#ae017e'],
	RdPu5 = ['#feebe2', '#fbb4b9', '#f768a1', '#c51b8a', '#7a0177'],
	RdPu6 = ['#feebe2', '#fcc5c0', '#fa9fb5', '#f768a1', '#c51b8a', '#7a0177'],
	RdPu7 = ['#feebe2', '#fcc5c0', '#fa9fb5', '#f768a1', '#dd3497', '#ae017e', '#7a0177'],
	RdPu8 = ['#fff7f3', '#fde0dd', '#fcc5c0', '#fa9fb5', '#f768a1', '#dd3497', '#ae017e', '#7a0177'],
	RdPu9 = ['#fff7f3', '#fde0dd', '#fcc5c0', '#fa9fb5', '#f768a1', '#dd3497', '#ae017e', '#7a0177', '#49006a'],

	PuRd3 = ['#e7e1ef', '#c994c7', '#dd1c77'],
	PuRd4 = ['#f1eef6', '#d7b5d8', '#df65b0', '#ce1256'],
	PuRd5 = ['#f1eef6', '#d7b5d8', '#df65b0', '#dd1c77', '#980043'],
	PuRd6 = ['#f1eef6', '#d4b9da', '#c994c7', '#df65b0', '#dd1c77', '#980043'],
	PuRd7 = ['#f1eef6', '#d4b9da', '#c994c7', '#df65b0', '#e7298a', '#ce1256', '#91003f'],
	PuRd8 = ['#f7f4f9', '#e7e1ef', '#d4b9da', '#c994c7', '#df65b0', '#e7298a', '#ce1256', '#91003f'],
	PuRd9 = ['#f7f4f9', '#e7e1ef', '#d4b9da', '#c994c7', '#df65b0', '#e7298a', '#ce1256', '#980043', '#67001f'],

	OrRd3 = ['#fee8c8', '#fdbb84', '#e34a33'],
	OrRd4 = ['#fef0d9', '#fdcc8a', '#fc8d59', '#d7301f'],
	OrRd5 = ['#fef0d9', '#fdcc8a', '#fc8d59', '#e34a33', '#b30000'],
	OrRd6 = ['#fef0d9', '#fdd49e', '#fdbb84', '#fc8d59', '#e34a33', '#b30000'],
	OrRd7 = ['#fef0d9', '#fdd49e', '#fdbb84', '#fc8d59', '#ef6548', '#d7301f', '#990000'],
	OrRd8 = ['#fff7ec', '#fee8c8', '#fdd49e', '#fdbb84', '#fc8d59', '#ef6548', '#d7301f', '#990000'],
	OrRd9 = ['#fff7ec', '#fee8c8', '#fdd49e', '#fdbb84', '#fc8d59', '#ef6548', '#d7301f', '#b30000', '#7f0000'],

	YlOrRd3 = ['#ffeda0', '#feb24c', '#f03b20'],
	YlOrRd4 = ['#ffffb2', '#fecc5c', '#fd8d3c', '#e31a1c'],
	YlOrRd5 = ['#ffffb2', '#fecc5c', '#fd8d3c', '#f03b20', '#bd0026'],
	YlOrRd6 = ['#ffffb2', '#fed976', '#feb24c', '#fd8d3c', '#f03b20', '#bd0026'],
	YlOrRd7 = ['#ffffb2', '#fed976', '#feb24c', '#fd8d3c', '#fc4e2a', '#e31a1c', '#b10026'],
	YlOrRd8 = ['#ffffcc', '#ffeda0', '#fed976', '#feb24c', '#fd8d3c', '#fc4e2a', '#e31a1c', '#b10026'],
	YlOrRd9 = ['#ffffcc', '#ffeda0', '#fed976', '#feb24c', '#fd8d3c', '#fc4e2a', '#e31a1c', '#bd0026', '#800026'],

	YlOrBr3 = ['#fff7bc', '#fec44f', '#d95f0e'],
	YlOrBr4 = ['#ffffd4', '#fed98e', '#fe9929', '#cc4c02'],
	YlOrBr5 = ['#ffffd4', '#fed98e', '#fe9929', '#d95f0e', '#993404'],
	YlOrBr6 = ['#ffffd4', '#fee391', '#fec44f', '#fe9929', '#d95f0e', '#993404'],
	YlOrBr7 = ['#ffffd4', '#fee391', '#fec44f', '#fe9929', '#ec7014', '#cc4c02', '#8c2d04'],
	YlOrBr8 = ['#ffffe5', '#fff7bc', '#fee391', '#fec44f', '#fe9929', '#ec7014', '#cc4c02', '#8c2d04'],
	YlOrBr9 = ['#ffffe5', '#fff7bc', '#fee391', '#fec44f', '#fe9929', '#ec7014', '#cc4c02', '#993404', '#662506'],

	Purples3 = ['#efedf5', '#bcbddc', '#756bb1'],
	Purples4 = ['#f2f0f7', '#cbc9e2', '#9e9ac8', '#6a51a3'],
	Purples5 = ['#f2f0f7', '#cbc9e2', '#9e9ac8', '#756bb1', '#54278f'],
	Purples6 = ['#f2f0f7', '#dadaeb', '#bcbddc', '#9e9ac8', '#756bb1', '#54278f'],
	Purples7 = ['#f2f0f7', '#dadaeb', '#bcbddc', '#9e9ac8', '#807dba', '#6a51a3', '#4a1486'],
	Purples8 = ['#fcfbfd', '#efedf5', '#dadaeb', '#bcbddc', '#9e9ac8', '#807dba', '#6a51a3', '#4a1486'],
	Purples9 = ['#fcfbfd', '#efedf5', '#dadaeb', '#bcbddc', '#9e9ac8', '#807dba', '#6a51a3', '#54278f', '#3f007d'],

	Blues3 = ['#deebf7', '#9ecae1', '#3182bd'],
	Blues4 = ['#eff3ff', '#bdd7e7', '#6baed6', '#2171b5'],
	Blues5 = ['#eff3ff', '#bdd7e7', '#6baed6', '#3182bd', '#08519c'],
	Blues6 = ['#eff3ff', '#c6dbef', '#9ecae1', '#6baed6', '#3182bd', '#08519c'],
	Blues7 = ['#eff3ff', '#c6dbef', '#9ecae1', '#6baed6', '#4292c6', '#2171b5', '#084594'],
	Blues8 = ['#f7fbff', '#deebf7', '#c6dbef', '#9ecae1', '#6baed6', '#4292c6', '#2171b5', '#084594'],
	Blues9 = ['#f7fbff', '#deebf7', '#c6dbef', '#9ecae1', '#6baed6', '#4292c6', '#2171b5', '#08519c', '#08306b'],

	Greens3 = ['#e5f5e0', '#a1d99b', '#31a354'],
	Greens4 = ['#edf8e9', '#bae4b3', '#74c476', '#238b45'],
	Greens5 = ['#edf8e9', '#bae4b3', '#74c476', '#31a354', '#006d2c'],
	Greens6 = ['#edf8e9', '#c7e9c0', '#a1d99b', '#74c476', '#31a354', '#006d2c'],
	Greens7 = ['#edf8e9', '#c7e9c0', '#a1d99b', '#74c476', '#41ab5d', '#238b45', '#005a32'],
	Greens8 = ['#f7fcf5', '#e5f5e0', '#c7e9c0', '#a1d99b', '#74c476', '#41ab5d', '#238b45', '#005a32'],
	Greens9 = ['#f7fcf5', '#e5f5e0', '#c7e9c0', '#a1d99b', '#74c476', '#41ab5d', '#238b45', '#006d2c', '#00441b'],

	Oranges3 = ['#fee6ce', '#fdae6b', '#e6550d'],
	Oranges4 = ['#feedde', '#fdbe85', '#fd8d3c', '#d94701'],
	Oranges5 = ['#feedde', '#fdbe85', '#fd8d3c', '#e6550d', '#a63603'],
	Oranges6 = ['#feedde', '#fdd0a2', '#fdae6b', '#fd8d3c', '#e6550d', '#a63603'],
	Oranges7 = ['#feedde', '#fdd0a2', '#fdae6b', '#fd8d3c', '#f16913', '#d94801', '#8c2d04'],
	Oranges8 = ['#fff5eb', '#fee6ce', '#fdd0a2', '#fdae6b', '#fd8d3c', '#f16913', '#d94801', '#8c2d04'],
	Oranges9 = ['#fff5eb', '#fee6ce', '#fdd0a2', '#fdae6b', '#fd8d3c', '#f16913', '#d94801', '#a63603', '#7f2704'],

	Reds3 = ['#fee0d2', '#fc9272', '#de2d26'],
	Reds4 = ['#fee5d9', '#fcae91', '#fb6a4a', '#cb181d'],
	Reds5 = ['#fee5d9', '#fcae91', '#fb6a4a', '#de2d26', '#a50f15'],
	Reds6 = ['#fee5d9', '#fcbba1', '#fc9272', '#fb6a4a', '#de2d26', '#a50f15'],
	Reds7 = ['#fee5d9', '#fcbba1', '#fc9272', '#fb6a4a', '#ef3b2c', '#cb181d', '#99000d'],
	Reds8 = ['#fff5f0', '#fee0d2', '#fcbba1', '#fc9272', '#fb6a4a', '#ef3b2c', '#cb181d', '#99000d'],
	Reds9 = ['#fff5f0', '#fee0d2', '#fcbba1', '#fc9272', '#fb6a4a', '#ef3b2c', '#cb181d', '#a50f15', '#67000d'],

	Greys3 = ['#f0f0f0', '#bdbdbd', '#636363'],
	Greys4 = ['#f7f7f7', '#cccccc', '#969696', '#525252'],
	Greys5 = ['#f7f7f7', '#cccccc', '#969696', '#636363', '#252525'],
	Greys6 = ['#f7f7f7', '#d9d9d9', '#bdbdbd', '#969696', '#636363', '#252525'],
	Greys7 = ['#f7f7f7', '#d9d9d9', '#bdbdbd', '#969696', '#737373', '#525252', '#252525'],
	Greys8 = ['#ffffff', '#f0f0f0', '#d9d9d9', '#bdbdbd', '#969696', '#737373', '#525252', '#252525'],
	Greys9 = ['#ffffff', '#f0f0f0', '#d9d9d9', '#bdbdbd', '#969696', '#737373', '#525252', '#252525', '#000000'],

	// Diverging
	PuOr3 = ['#f1a340', '#f7f7f7', '#998ec3'],
	PuOr4 = ['#e66101', '#fdb863', '#b2abd2', '#5e3c99'],
	PuOr5 = ['#e66101', '#fdb863', '#f7f7f7', '#b2abd2', '#5e3c99'],
	PuOr6 = ['#b35806', '#f1a340', '#fee0b6', '#d8daeb', '#998ec3', '#542788'],
	PuOr7 = ['#b35806', '#f1a340', '#fee0b6', '#f7f7f7', '#d8daeb', '#998ec3', '#542788'],
	PuOr8 = ['#b35806', '#e08214', '#fdb863', '#fee0b6', '#d8daeb', '#b2abd2', '#8073ac', '#542788'],
	PuOr9 = ['#b35806', '#e08214', '#fdb863', '#fee0b6', '#f7f7f7', '#d8daeb', '#b2abd2', '#8073ac', '#542788'],
	PuOr10 = ['#7f3b08', '#b35806', '#e08214', '#fdb863', '#fee0b6', '#d8daeb', '#b2abd2', '#8073ac', '#542788', '#2d004b'],
	PuOr11 = ['#7f3b08', '#b35806', '#e08214', '#fdb863', '#fee0b6', '#f7f7f7', '#d8daeb', '#b2abd2', '#8073ac', '#542788', '#2d004b'],

	BrBG3 = ['#d8b365', '#f5f5f5', '#5ab4ac'],
	BrBG4 = ['#a6611a', '#dfc27d', '#80cdc1', '#018571'],
	BrBG5 = ['#a6611a', '#dfc27d', '#f5f5f5', '#80cdc1', '#018571'],
	BrBG6 = ['#8c510a', '#d8b365', '#f6e8c3', '#c7eae5', '#5ab4ac', '#01665e'],
	BrBG7 = ['#8c510a', '#d8b365', '#f6e8c3', '#f5f5f5', '#c7eae5', '#5ab4ac', '#01665e'],
	BrBG8 = ['#8c510a', '#bf812d', '#dfc27d', '#f6e8c3', '#c7eae5', '#80cdc1', '#35978f', '#01665e'],
	BrBG9 = ['#8c510a', '#bf812d', '#dfc27d', '#f6e8c3', '#f5f5f5', '#c7eae5', '#80cdc1', '#35978f', '#01665e'],
	BrBG10 = ['#543005', '#8c510a', '#bf812d', '#dfc27d', '#f6e8c3', '#c7eae5', '#80cdc1', '#35978f', '#01665e', '#003c30'],
	BrBG11 = ['#543005', '#8c510a', '#bf812d', '#dfc27d', '#f6e8c3', '#f5f5f5', '#c7eae5', '#80cdc1', '#35978f', '#01665e', '#003c30'],

	PRGn3 = ['#af8dc3', '#f7f7f7', '#7fbf7b'],
	PRGn4 = ['#7b3294', '#c2a5cf', '#a6dba0', '#008837'],
	PRGn5 = ['#7b3294', '#c2a5cf', '#f7f7f7', '#a6dba0', '#008837'],
	PRGn6 = ['#762a83', '#af8dc3', '#e7d4e8', '#d9f0d3', '#7fbf7b', '#1b7837'],
	PRGn7 = ['#762a83', '#af8dc3', '#e7d4e8', '#f7f7f7', '#d9f0d3', '#7fbf7b', '#1b7837'],
	PRGn8 = ['#762a83', '#9970ab', '#c2a5cf', '#e7d4e8', '#d9f0d3', '#a6dba0', '#5aae61', '#1b7837'],
	PRGn9 = ['#762a83', '#9970ab', '#c2a5cf', '#e7d4e8', '#f7f7f7', '#d9f0d3', '#a6dba0', '#5aae61', '#1b7837'],
	PRGn10 = ['#40004b', '#762a83', '#9970ab', '#c2a5cf', '#e7d4e8', '#d9f0d3', '#a6dba0', '#5aae61', '#1b7837', '#00441b'],
	PRGn11 = ['#40004b', '#762a83', '#9970ab', '#c2a5cf', '#e7d4e8', '#f7f7f7', '#d9f0d3', '#a6dba0', '#5aae61', '#1b7837', '#00441b'],

	PiYG3 = ['#e9a3c9', '#f7f7f7', '#a1d76a'],
	PiYG4 = ['#d01c8b', '#f1b6da', '#b8e186', '#4dac26'],
	PiYG5 = ['#d01c8b', '#f1b6da', '#f7f7f7', '#b8e186', '#4dac26'],
	PiYG6 = ['#c51b7d', '#e9a3c9', '#fde0ef', '#e6f5d0', '#a1d76a', '#4d9221'],
	PiYG7 = ['#c51b7d', '#e9a3c9', '#fde0ef', '#f7f7f7', '#e6f5d0', '#a1d76a', '#4d9221'],
	PiYG8 = ['#c51b7d', '#de77ae', '#f1b6da', '#fde0ef', '#e6f5d0', '#b8e186', '#7fbc41', '#4d9221'],
	PiYG9 = ['#c51b7d', '#de77ae', '#f1b6da', '#fde0ef', '#f7f7f7', '#e6f5d0', '#b8e186', '#7fbc41', '#4d9221'],
	PiYG10 = ['#8e0152', '#c51b7d', '#de77ae', '#f1b6da', '#fde0ef', '#e6f5d0', '#b8e186', '#7fbc41', '#4d9221', '#276419'],
	PiYG11 = ['#8e0152', '#c51b7d', '#de77ae', '#f1b6da', '#fde0ef', '#f7f7f7', '#e6f5d0', '#b8e186', '#7fbc41', '#4d9221', '#276419'],

	RdBu3 = ['#ef8a62', '#f7f7f7', '#67a9cf'],
	RdBu4 = ['#ca0020', '#f4a582', '#92c5de', '#0571b0'],
	RdBu5 = ['#ca0020', '#f4a582', '#f7f7f7', '#92c5de', '#0571b0'],
	RdBu6 = ['#b2182b', '#ef8a62', '#fddbc7', '#d1e5f0', '#67a9cf', '#2166ac'],
	RdBu7 = ['#b2182b', '#ef8a62', '#fddbc7', '#f7f7f7', '#d1e5f0', '#67a9cf', '#2166ac'],
	RdBu8 = ['#b2182b', '#d6604d', '#f4a582', '#fddbc7', '#d1e5f0', '#92c5de', '#4393c3', '#2166ac'],
	RdBu9 = ['#b2182b', '#d6604d', '#f4a582', '#fddbc7', '#f7f7f7', '#d1e5f0', '#92c5de', '#4393c3', '#2166ac'],
	RdBu10 = ['#67001f', '#b2182b', '#d6604d', '#f4a582', '#fddbc7', '#d1e5f0', '#92c5de', '#4393c3', '#2166ac', '#053061'],
	RdBu11 = ['#67001f', '#b2182b', '#d6604d', '#f4a582', '#fddbc7', '#f7f7f7', '#d1e5f0', '#92c5de', '#4393c3', '#2166ac', '#053061'],

	RdGy3 = ['#ef8a62', '#ffffff', '#999999'],
	RdGy4 = ['#ca0020', '#f4a582', '#bababa', '#404040'],
	RdGy5 = ['#ca0020', '#f4a582', '#ffffff', '#bababa', '#404040'],
	RdGy6 = ['#b2182b', '#ef8a62', '#fddbc7', '#e0e0e0', '#999999', '#4d4d4d'],
	RdGy7 = ['#b2182b', '#ef8a62', '#fddbc7', '#ffffff', '#e0e0e0', '#999999', '#4d4d4d'],
	RdGy8 = ['#b2182b', '#d6604d', '#f4a582', '#fddbc7', '#e0e0e0', '#bababa', '#878787', '#4d4d4d'],
	RdGy9 = ['#b2182b', '#d6604d', '#f4a582', '#fddbc7', '#ffffff', '#e0e0e0', '#bababa', '#878787', '#4d4d4d'],
	RdGy10 = ['#67001f', '#b2182b', '#d6604d', '#f4a582', '#fddbc7', '#e0e0e0', '#bababa', '#878787', '#4d4d4d', '#1a1a1a'],
	RdGy11 = ['#67001f', '#b2182b', '#d6604d', '#f4a582', '#fddbc7', '#ffffff', '#e0e0e0', '#bababa', '#878787', '#4d4d4d', '#1a1a1a'],

	RdYlBu3 = ['#fc8d59', '#ffffbf', '#91bfdb'],
	RdYlBu4 = ['#d7191c', '#fdae61', '#abd9e9', '#2c7bb6'],
	RdYlBu5 = ['#d7191c', '#fdae61', '#ffffbf', '#abd9e9', '#2c7bb6'],
	RdYlBu6 = ['#d73027', '#fc8d59', '#fee090', '#e0f3f8', '#91bfdb', '#4575b4'],
	RdYlBu7 = ['#d73027', '#fc8d59', '#fee090', '#ffffbf', '#e0f3f8', '#91bfdb', '#4575b4'],
	RdYlBu8 = ['#d73027', '#f46d43', '#fdae61', '#fee090', '#e0f3f8', '#abd9e9', '#74add1', '#4575b4'],
	RdYlBu9 = ['#d73027', '#f46d43', '#fdae61', '#fee090', '#ffffbf', '#e0f3f8', '#abd9e9', '#74add1', '#4575b4'],
	RdYlBu10 = ['#a50026', '#d73027', '#f46d43', '#fdae61', '#fee090', '#e0f3f8', '#abd9e9', '#74add1', '#4575b4', '#313695'],
	RdYlBu11 = ['#a50026', '#d73027', '#f46d43', '#fdae61', '#fee090', '#ffffbf', '#e0f3f8', '#abd9e9', '#74add1', '#4575b4', '#313695'],

	Spectral3 = ['#fc8d59', '#ffffbf', '#99d594'],
	Spectral4 = ['#d7191c', '#fdae61', '#abdda4', '#2b83ba'],
	Spectral5 = ['#d7191c', '#fdae61', '#ffffbf', '#abdda4', '#2b83ba'],
	Spectral6 = ['#d53e4f', '#fc8d59', '#fee08b', '#e6f598', '#99d594', '#3288bd'],
	Spectral7 = ['#d53e4f', '#fc8d59', '#fee08b', '#ffffbf', '#e6f598', '#99d594', '#3288bd'],
	Spectral8 = ['#d53e4f', '#f46d43', '#fdae61', '#fee08b', '#e6f598', '#abdda4', '#66c2a5', '#3288bd'],
	Spectral9 = ['#d53e4f', '#f46d43', '#fdae61', '#fee08b', '#ffffbf', '#e6f598', '#abdda4', '#66c2a5', '#3288bd'],
	Spectral10 = ['#9e0142', '#d53e4f', '#f46d43', '#fdae61', '#fee08b', '#e6f598', '#abdda4', '#66c2a5', '#3288bd', '#5e4fa2'],
	Spectral11 = ['#9e0142', '#d53e4f', '#f46d43', '#fdae61', '#fee08b', '#ffffbf', '#e6f598', '#abdda4', '#66c2a5', '#3288bd', '#5e4fa2'],

	RdYlGn3 = ['#fc8d59', '#ffffbf', '#91cf60'],
	RdYlGn4 = ['#d7191c', '#fdae61', '#a6d96a', '#1a9641'],
	RdYlGn5 = ['#d7191c', '#fdae61', '#ffffbf', '#a6d96a', '#1a9641'],
	RdYlGn6 = ['#d73027', '#fc8d59', '#fee08b', '#d9ef8b', '#91cf60', '#1a9850'],
	RdYlGn7 = ['#d73027', '#fc8d59', '#fee08b', '#ffffbf', '#d9ef8b', '#91cf60', '#1a9850'],
	RdYlGn8 = ['#d73027', '#f46d43', '#fdae61', '#fee08b', '#d9ef8b', '#a6d96a', '#66bd63', '#1a9850'],
	RdYlGn9 = ['#d73027', '#f46d43', '#fdae61', '#fee08b', '#ffffbf', '#d9ef8b', '#a6d96a', '#66bd63', '#1a9850'],
	RdYlGn10 = ['#a50026', '#d73027', '#f46d43', '#fdae61', '#fee08b', '#d9ef8b', '#a6d96a', '#66bd63', '#1a9850', '#006837'],
	RdYlGn11 = ['#a50026', '#d73027', '#f46d43', '#fdae61', '#fee08b', '#ffffbf', '#d9ef8b', '#a6d96a', '#66bd63', '#1a9850', '#006837'],

	// Qualitative
	Accent3 = ['#7fc97f', '#beaed4', '#fdc086'],
	Accent4 = ['#7fc97f', '#beaed4', '#fdc086', '#ffff99'],
	Accent5 = ['#7fc97f', '#beaed4', '#fdc086', '#ffff99', '#386cb0'],
	Accent6 = ['#7fc97f', '#beaed4', '#fdc086', '#ffff99', '#386cb0', '#f0027f'],
	Accent7 = ['#7fc97f', '#beaed4', '#fdc086', '#ffff99', '#386cb0', '#f0027f', '#bf5b17'],
	Accent8 = ['#7fc97f', '#beaed4', '#fdc086', '#ffff99', '#386cb0', '#f0027f', '#bf5b17', '#666666'],

	DarkTwo3 = ['#1b9e77', '#d95f02', '#7570b3'],
	DarkTwo4 = ['#1b9e77', '#d95f02', '#7570b3', '#e7298a'],
	DarkTwo5 = ['#1b9e77', '#d95f02', '#7570b3', '#e7298a', '#66a61e'],
	DarkTwo6 = ['#1b9e77', '#d95f02', '#7570b3', '#e7298a', '#66a61e', '#e6ab02'],
	DarkTwo7 = ['#1b9e77', '#d95f02', '#7570b3', '#e7298a', '#66a61e', '#e6ab02', '#a6761d'],
	DarkTwo8 = ['#1b9e77', '#d95f02', '#7570b3', '#e7298a', '#66a61e', '#e6ab02', '#a6761d', '#666666'],

	Paired3 = ['#a6cee3', '#1f78b4', '#b2df8a'],
	Paired4 = ['#a6cee3', '#1f78b4', '#b2df8a', '#33a02c'],
	Paired5 = ['#a6cee3', '#1f78b4', '#b2df8a', '#33a02c', '#fb9a99'],
	Paired6 = ['#a6cee3', '#1f78b4', '#b2df8a', '#33a02c', '#fb9a99', '#e31a1c'],
	Paired7 = ['#a6cee3', '#1f78b4', '#b2df8a', '#33a02c', '#fb9a99', '#e31a1c', '#fdbf6f'],
	Paired8 = ['#a6cee3', '#1f78b4', '#b2df8a', '#33a02c', '#fb9a99', '#e31a1c', '#fdbf6f', '#ff7f00'],
	Paired9 = ['#a6cee3', '#1f78b4', '#b2df8a', '#33a02c', '#fb9a99', '#e31a1c', '#fdbf6f', '#ff7f00', '#cab2d6'],
	Paired10 = ['#a6cee3', '#1f78b4', '#b2df8a', '#33a02c', '#fb9a99', '#e31a1c', '#fdbf6f', '#ff7f00', '#cab2d6', '#6a3d9a'],
	Paired11 = ['#a6cee3', '#1f78b4', '#b2df8a', '#33a02c', '#fb9a99', '#e31a1c', '#fdbf6f', '#ff7f00', '#cab2d6', '#6a3d9a', '#ffff99'],
	Paired12 = ['#a6cee3', '#1f78b4', '#b2df8a', '#33a02c', '#fb9a99', '#e31a1c', '#fdbf6f', '#ff7f00', '#cab2d6', '#6a3d9a', '#ffff99', '#b15928'],

	PastelOne3 = ['#fbb4ae', '#b3cde3', '#ccebc5'],
	PastelOne4 = ['#fbb4ae', '#b3cde3', '#ccebc5', '#decbe4'],
	PastelOne5 = ['#fbb4ae', '#b3cde3', '#ccebc5', '#decbe4', '#fed9a6'],
	PastelOne6 = ['#fbb4ae', '#b3cde3', '#ccebc5', '#decbe4', '#fed9a6', '#ffffcc'],
	PastelOne7 = ['#fbb4ae', '#b3cde3', '#ccebc5', '#decbe4', '#fed9a6', '#ffffcc', '#e5d8bd'],
	PastelOne8 = ['#fbb4ae', '#b3cde3', '#ccebc5', '#decbe4', '#fed9a6', '#ffffcc', '#e5d8bd', '#fddaec'],
	PastelOne9 = ['#fbb4ae', '#b3cde3', '#ccebc5', '#decbe4', '#fed9a6', '#ffffcc', '#e5d8bd', '#fddaec', '#f2f2f2'],

	PastelTwo3 = ['#b3e2cd', '#fdcdac', '#cbd5e8'],
	PastelTwo4 = ['#b3e2cd', '#fdcdac', '#cbd5e8', '#f4cae4'],
	PastelTwo5 = ['#b3e2cd', '#fdcdac', '#cbd5e8', '#f4cae4', '#e6f5c9'],
	PastelTwo6 = ['#b3e2cd', '#fdcdac', '#cbd5e8', '#f4cae4', '#e6f5c9', '#fff2ae'],
	PastelTwo7 = ['#b3e2cd', '#fdcdac', '#cbd5e8', '#f4cae4', '#e6f5c9', '#fff2ae', '#f1e2cc'],
	PastelTwo8 = ['#b3e2cd', '#fdcdac', '#cbd5e8', '#f4cae4', '#e6f5c9', '#fff2ae', '#f1e2cc', '#cccccc'],

	SetOne3 = ['#e41a1c', '#377eb8', '#4daf4a'],
	SetOne4 = ['#e41a1c', '#377eb8', '#4daf4a', '#984ea3'],
	SetOne5 = ['#e41a1c', '#377eb8', '#4daf4a', '#984ea3', '#ff7f00'],
	SetOne6 = ['#e41a1c', '#377eb8', '#4daf4a', '#984ea3', '#ff7f00', '#ffff33'],
	SetOne7 = ['#e41a1c', '#377eb8', '#4daf4a', '#984ea3', '#ff7f00', '#ffff33', '#a65628'],
	SetOne8 = ['#e41a1c', '#377eb8', '#4daf4a', '#984ea3', '#ff7f00', '#ffff33', '#a65628', '#f781bf'],
	SetOne9 = ['#e41a1c', '#377eb8', '#4daf4a', '#984ea3', '#ff7f00', '#ffff33', '#a65628', '#f781bf', '#999999'],

	SetTwo3 = ['#66c2a5', '#fc8d62', '#8da0cb'],
	SetTwo4 = ['#66c2a5', '#fc8d62', '#8da0cb', '#e78ac3'],
	SetTwo5 = ['#66c2a5', '#fc8d62', '#8da0cb', '#e78ac3', '#a6d854'],
	SetTwo6 = ['#66c2a5', '#fc8d62', '#8da0cb', '#e78ac3', '#a6d854', '#ffd92f'],
	SetTwo7 = ['#66c2a5', '#fc8d62', '#8da0cb', '#e78ac3', '#a6d854', '#ffd92f', '#e5c494'],
	SetTwo8 = ['#66c2a5', '#fc8d62', '#8da0cb', '#e78ac3', '#a6d854', '#ffd92f', '#e5c494', '#b3b3b3'],

	SetThree3 = ['#8dd3c7', '#ffffb3', '#bebada'],
	SetThree4 = ['#8dd3c7', '#ffffb3', '#bebada', '#fb8072'],
	SetThree5 = ['#8dd3c7', '#ffffb3', '#bebada', '#fb8072', '#80b1d3'],
	SetThree6 = ['#8dd3c7', '#ffffb3', '#bebada', '#fb8072', '#80b1d3', '#fdb462'],
	SetThree7 = ['#8dd3c7', '#ffffb3', '#bebada', '#fb8072', '#80b1d3', '#fdb462', '#b3de69'],
	SetThree8 = ['#8dd3c7', '#ffffb3', '#bebada', '#fb8072', '#80b1d3', '#fdb462', '#b3de69', '#fccde5'],
	SetThree9 = ['#8dd3c7', '#ffffb3', '#bebada', '#fb8072', '#80b1d3', '#fdb462', '#b3de69', '#fccde5', '#d9d9d9'],
	SetThree10 = ['#8dd3c7', '#ffffb3', '#bebada', '#fb8072', '#80b1d3', '#fdb462', '#b3de69', '#fccde5', '#d9d9d9', '#bc80bd'],
	SetThree11 = ['#8dd3c7', '#ffffb3', '#bebada', '#fb8072', '#80b1d3', '#fdb462', '#b3de69', '#fccde5', '#d9d9d9', '#bc80bd', '#ccebc5'],
	SetThree12 = ['#8dd3c7', '#ffffb3', '#bebada', '#fb8072', '#80b1d3', '#fdb462', '#b3de69', '#fccde5', '#d9d9d9', '#bc80bd', '#ccebc5', '#ffed6f'];

var brewer = /*#__PURE__*/Object.freeze({
__proto__: null,
YlGn3: YlGn3,
YlGn4: YlGn4,
YlGn5: YlGn5,
YlGn6: YlGn6,
YlGn7: YlGn7,
YlGn8: YlGn8,
YlGn9: YlGn9,
YlGnBu3: YlGnBu3,
YlGnBu4: YlGnBu4,
YlGnBu5: YlGnBu5,
YlGnBu6: YlGnBu6,
YlGnBu7: YlGnBu7,
YlGnBu8: YlGnBu8,
YlGnBu9: YlGnBu9,
GnBu3: GnBu3,
GnBu4: GnBu4,
GnBu5: GnBu5,
GnBu6: GnBu6,
GnBu7: GnBu7,
GnBu8: GnBu8,
GnBu9: GnBu9,
BuGn3: BuGn3,
BuGn4: BuGn4,
BuGn5: BuGn5,
BuGn6: BuGn6,
BuGn7: BuGn7,
BuGn8: BuGn8,
BuGn9: BuGn9,
PuBuGn3: PuBuGn3,
PuBuGn4: PuBuGn4,
PuBuGn5: PuBuGn5,
PuBuGn6: PuBuGn6,
PuBuGn7: PuBuGn7,
PuBuGn8: PuBuGn8,
PuBuGn9: PuBuGn9,
PuBu3: PuBu3,
PuBu4: PuBu4,
PuBu5: PuBu5,
PuBu6: PuBu6,
PuBu7: PuBu7,
PuBu8: PuBu8,
PuBu9: PuBu9,
BuPu3: BuPu3,
BuPu4: BuPu4,
BuPu5: BuPu5,
BuPu6: BuPu6,
BuPu7: BuPu7,
BuPu8: BuPu8,
BuPu9: BuPu9,
RdPu3: RdPu3,
RdPu4: RdPu4,
RdPu5: RdPu5,
RdPu6: RdPu6,
RdPu7: RdPu7,
RdPu8: RdPu8,
RdPu9: RdPu9,
PuRd3: PuRd3,
PuRd4: PuRd4,
PuRd5: PuRd5,
PuRd6: PuRd6,
PuRd7: PuRd7,
PuRd8: PuRd8,
PuRd9: PuRd9,
OrRd3: OrRd3,
OrRd4: OrRd4,
OrRd5: OrRd5,
OrRd6: OrRd6,
OrRd7: OrRd7,
OrRd8: OrRd8,
OrRd9: OrRd9,
YlOrRd3: YlOrRd3,
YlOrRd4: YlOrRd4,
YlOrRd5: YlOrRd5,
YlOrRd6: YlOrRd6,
YlOrRd7: YlOrRd7,
YlOrRd8: YlOrRd8,
YlOrRd9: YlOrRd9,
YlOrBr3: YlOrBr3,
YlOrBr4: YlOrBr4,
YlOrBr5: YlOrBr5,
YlOrBr6: YlOrBr6,
YlOrBr7: YlOrBr7,
YlOrBr8: YlOrBr8,
YlOrBr9: YlOrBr9,
Purples3: Purples3,
Purples4: Purples4,
Purples5: Purples5,
Purples6: Purples6,
Purples7: Purples7,
Purples8: Purples8,
Purples9: Purples9,
Blues3: Blues3,
Blues4: Blues4,
Blues5: Blues5,
Blues6: Blues6,
Blues7: Blues7,
Blues8: Blues8,
Blues9: Blues9,
Greens3: Greens3,
Greens4: Greens4,
Greens5: Greens5,
Greens6: Greens6,
Greens7: Greens7,
Greens8: Greens8,
Greens9: Greens9,
Oranges3: Oranges3,
Oranges4: Oranges4,
Oranges5: Oranges5,
Oranges6: Oranges6,
Oranges7: Oranges7,
Oranges8: Oranges8,
Oranges9: Oranges9,
Reds3: Reds3,
Reds4: Reds4,
Reds5: Reds5,
Reds6: Reds6,
Reds7: Reds7,
Reds8: Reds8,
Reds9: Reds9,
Greys3: Greys3,
Greys4: Greys4,
Greys5: Greys5,
Greys6: Greys6,
Greys7: Greys7,
Greys8: Greys8,
Greys9: Greys9,
PuOr3: PuOr3,
PuOr4: PuOr4,
PuOr5: PuOr5,
PuOr6: PuOr6,
PuOr7: PuOr7,
PuOr8: PuOr8,
PuOr9: PuOr9,
PuOr10: PuOr10,
PuOr11: PuOr11,
BrBG3: BrBG3,
BrBG4: BrBG4,
BrBG5: BrBG5,
BrBG6: BrBG6,
BrBG7: BrBG7,
BrBG8: BrBG8,
BrBG9: BrBG9,
BrBG10: BrBG10,
BrBG11: BrBG11,
PRGn3: PRGn3,
PRGn4: PRGn4,
PRGn5: PRGn5,
PRGn6: PRGn6,
PRGn7: PRGn7,
PRGn8: PRGn8,
PRGn9: PRGn9,
PRGn10: PRGn10,
PRGn11: PRGn11,
PiYG3: PiYG3,
PiYG4: PiYG4,
PiYG5: PiYG5,
PiYG6: PiYG6,
PiYG7: PiYG7,
PiYG8: PiYG8,
PiYG9: PiYG9,
PiYG10: PiYG10,
PiYG11: PiYG11,
RdBu3: RdBu3,
RdBu4: RdBu4,
RdBu5: RdBu5,
RdBu6: RdBu6,
RdBu7: RdBu7,
RdBu8: RdBu8,
RdBu9: RdBu9,
RdBu10: RdBu10,
RdBu11: RdBu11,
RdGy3: RdGy3,
RdGy4: RdGy4,
RdGy5: RdGy5,
RdGy6: RdGy6,
RdGy7: RdGy7,
RdGy8: RdGy8,
RdGy9: RdGy9,
RdGy10: RdGy10,
RdGy11: RdGy11,
RdYlBu3: RdYlBu3,
RdYlBu4: RdYlBu4,
RdYlBu5: RdYlBu5,
RdYlBu6: RdYlBu6,
RdYlBu7: RdYlBu7,
RdYlBu8: RdYlBu8,
RdYlBu9: RdYlBu9,
RdYlBu10: RdYlBu10,
RdYlBu11: RdYlBu11,
Spectral3: Spectral3,
Spectral4: Spectral4,
Spectral5: Spectral5,
Spectral6: Spectral6,
Spectral7: Spectral7,
Spectral8: Spectral8,
Spectral9: Spectral9,
Spectral10: Spectral10,
Spectral11: Spectral11,
RdYlGn3: RdYlGn3,
RdYlGn4: RdYlGn4,
RdYlGn5: RdYlGn5,
RdYlGn6: RdYlGn6,
RdYlGn7: RdYlGn7,
RdYlGn8: RdYlGn8,
RdYlGn9: RdYlGn9,
RdYlGn10: RdYlGn10,
RdYlGn11: RdYlGn11,
Accent3: Accent3,
Accent4: Accent4,
Accent5: Accent5,
Accent6: Accent6,
Accent7: Accent7,
Accent8: Accent8,
DarkTwo3: DarkTwo3,
DarkTwo4: DarkTwo4,
DarkTwo5: DarkTwo5,
DarkTwo6: DarkTwo6,
DarkTwo7: DarkTwo7,
DarkTwo8: DarkTwo8,
Paired3: Paired3,
Paired4: Paired4,
Paired5: Paired5,
Paired6: Paired6,
Paired7: Paired7,
Paired8: Paired8,
Paired9: Paired9,
Paired10: Paired10,
Paired11: Paired11,
Paired12: Paired12,
PastelOne3: PastelOne3,
PastelOne4: PastelOne4,
PastelOne5: PastelOne5,
PastelOne6: PastelOne6,
PastelOne7: PastelOne7,
PastelOne8: PastelOne8,
PastelOne9: PastelOne9,
PastelTwo3: PastelTwo3,
PastelTwo4: PastelTwo4,
PastelTwo5: PastelTwo5,
PastelTwo6: PastelTwo6,
PastelTwo7: PastelTwo7,
PastelTwo8: PastelTwo8,
SetOne3: SetOne3,
SetOne4: SetOne4,
SetOne5: SetOne5,
SetOne6: SetOne6,
SetOne7: SetOne7,
SetOne8: SetOne8,
SetOne9: SetOne9,
SetTwo3: SetTwo3,
SetTwo4: SetTwo4,
SetTwo5: SetTwo5,
SetTwo6: SetTwo6,
SetTwo7: SetTwo7,
SetTwo8: SetTwo8,
SetThree3: SetThree3,
SetThree4: SetThree4,
SetThree5: SetThree5,
SetThree6: SetThree6,
SetThree7: SetThree7,
SetThree8: SetThree8,
SetThree9: SetThree9,
SetThree10: SetThree10,
SetThree11: SetThree11,
SetThree12: SetThree12
});

// eslint-disable-next-line one-var
var
	Adjacency6 = ['#a9a57c', '#9cbebd', '#d2cb6c', '#95a39d', '#c89f5d', '#b1a089'],
	Advantage6 = ['#663366', '#330f42', '#666699', '#999966', '#f7901e', '#a3a101'],
	Angles6 = ['#797b7e', '#f96a1b', '#08a1d9', '#7c984a', '#c2ad8d', '#506e94'],
	Apex6 = ['#ceb966', '#9cb084', '#6bb1c9', '#6585cf', '#7e6bc9', '#a379bb'],
	Apothecary6 = ['#93a299', '#cf543f', '#b5ae53', '#848058', '#e8b54d', '#786c71'],
	Aspect6 = ['#f07f09', '#9f2936', '#1b587c', '#4e8542', '#604878', '#c19859'],
	Atlas6 = ['#f81b02', '#fc7715', '#afbf41', '#50c49f', '#3b95c4', '#b560d4'],
	Austin6 = ['#94c600', '#71685a', '#ff6700', '#909465', '#956b43', '#fea022'],
	Badge6 = ['#f8b323', '#656a59', '#46b2b5', '#8caa7e', '#d36f68', '#826276'],
	Banded6 = ['#ffc000', '#a5d028', '#08cc78', '#f24099', '#828288', '#f56617'],
	Basis6 = ['#f09415', '#c1b56b', '#4baf73', '#5aa6c0', '#d17df9', '#fa7e5c'],
	Berlin6 = ['#a6b727', '#df5327', '#fe9e00', '#418ab3', '#d7d447', '#818183'],
	BlackTie6 = ['#6f6f74', '#a7b789', '#beae98', '#92a9b9', '#9c8265', '#8d6974'],
	Blue6 = ['#0f6fc6', '#009dd9', '#0bd0d9', '#10cf9b', '#7cca62', '#a5c249'],
	BlueGreen6 = ['#3494ba', '#58b6c0', '#75bda7', '#7a8c8e', '#84acb6', '#2683c6'],
	BlueII6 = ['#1cade4', '#2683c6', '#27ced7', '#42ba97', '#3e8853', '#62a39f'],
	BlueRed6 = ['#4a66ac', '#629dd1', '#297fd5', '#7f8fa9', '#5aa2ae', '#9d90a0'],
	BlueWarm6 = ['#4a66ac', '#629dd1', '#297fd5', '#7f8fa9', '#5aa2ae', '#9d90a0'],
	Breeze6 = ['#2c7c9f', '#244a58', '#e2751d', '#ffb400', '#7eb606', '#c00000'],
	Capital6 = ['#4b5a60', '#9c5238', '#504539', '#c1ad79', '#667559', '#bad6ad'],
	Celestial6 = ['#ac3ec1', '#477bd1', '#46b298', '#90ba4c', '#dd9d31', '#e25247'],
	Circuit6 = ['#9acd4c', '#faa93a', '#d35940', '#b258d3', '#63a0cc', '#8ac4a7'],
	Civic6 = ['#d16349', '#ccb400', '#8cadae', '#8c7b70', '#8fb08c', '#d19049'],
	Clarity6 = ['#93a299', '#ad8f67', '#726056', '#4c5a6a', '#808da0', '#79463d'],
	Codex6 = ['#990000', '#efab16', '#78ac35', '#35aca2', '#4083cf', '#0d335e'],
	Composite6 = ['#98c723', '#59b0b9', '#deae00', '#b77bb4', '#e0773c', '#a98d63'],
	Concourse6 = ['#2da2bf', '#da1f28', '#eb641b', '#39639d', '#474b78', '#7d3c4a'],
	Couture6 = ['#9e8e5c', '#a09781', '#85776d', '#aeafa9', '#8d878b', '#6b6149'],
	Crop6 = ['#8c8d86', '#e6c069', '#897b61', '#8dab8e', '#77a2bb', '#e28394'],
	Damask6 = ['#9ec544', '#50bea3', '#4a9ccc', '#9a66ca', '#c54f71', '#de9c3c'],
	Depth6 = ['#41aebd', '#97e9d5', '#a2cf49', '#608f3d', '#f4de3a', '#fcb11c'],
	Dividend6 = ['#4d1434', '#903163', '#b2324b', '#969fa7', '#66b1ce', '#40619d'],
	Droplet6 = ['#2fa3ee', '#4bcaad', '#86c157', '#d99c3f', '#ce6633', '#a35dd1'],
	Elemental6 = ['#629dd1', '#297fd5', '#7f8fa9', '#4a66ac', '#5aa2ae', '#9d90a0'],
	Equity6 = ['#d34817', '#9b2d1f', '#a28e6a', '#956251', '#918485', '#855d5d'],
	Essential6 = ['#7a7a7a', '#f5c201', '#526db0', '#989aac', '#dc5924', '#b4b392'],
	Excel16 = ['#9999ff', '#993366', '#ffffcc', '#ccffff', '#660066', '#ff8080', '#0066cc', '#ccccff', '#000080', '#ff00ff', '#ffff00', '#0000ff', '#800080', '#800000', '#008080', '#0000ff'],
	Executive6 = ['#6076b4', '#9c5252', '#e68422', '#846648', '#63891f', '#758085'],
	Exhibit6 = ['#3399ff', '#69ffff', '#ccff33', '#3333ff', '#9933ff', '#ff33ff'],
	Expo6 = ['#fbc01e', '#efe1a2', '#fa8716', '#be0204', '#640f10', '#7e13e3'],
	Facet6 = ['#90c226', '#54a021', '#e6b91e', '#e76618', '#c42f1a', '#918655'],
	Feathered6 = ['#606372', '#79a8a4', '#b2ad8f', '#ad8082', '#dec18c', '#92a185'],
	Flow6 = ['#0f6fc6', '#009dd9', '#0bd0d9', '#10cf9b', '#7cca62', '#a5c249'],
	Focus6 = ['#ffb91d', '#f97817', '#6de304', '#ff0000', '#732bea', '#c913ad'],
	Folio6 = ['#294171', '#748cbc', '#8e887c', '#834736', '#5a1705', '#a0a16a'],
	Formal6 = ['#907f76', '#a46645', '#cd9c47', '#9a92cd', '#7d639b', '#733678'],
	Forte6 = ['#c70f0c', '#dd6b0d', '#faa700', '#93e50d', '#17c7ba', '#0a96e4'],
	Foundry6 = ['#72a376', '#b0ccb0', '#a8cdd7', '#c0beaf', '#cec597', '#e8b7b7'],
	Frame6 = ['#40bad2', '#fab900', '#90bb23', '#ee7008', '#1ab39f', '#d5393d'],
	Gallery6 = ['#b71e42', '#de478e', '#bc72f0', '#795faf', '#586ea6', '#6892a0'],
	Genesis6 = ['#80b606', '#e29f1d', '#2397e2', '#35aca2', '#5430bb', '#8d34e0'],
	Grayscale6 = ['#dddddd', '#b2b2b2', '#969696', '#808080', '#5f5f5f', '#4d4d4d'],
	Green6 = ['#549e39', '#8ab833', '#c0cf3a', '#029676', '#4ab5c4', '#0989b1'],
	GreenYellow6 = ['#99cb38', '#63a537', '#37a76f', '#44c1a3', '#4eb3cf', '#51c3f9'],
	Grid6 = ['#c66951', '#bf974d', '#928b70', '#87706b', '#94734e', '#6f777d'],
	Habitat6 = ['#f8c000', '#f88600', '#f83500', '#8b723d', '#818b3d', '#586215'],
	Hardcover6 = ['#873624', '#d6862d', '#d0be40', '#877f6c', '#972109', '#aeb795'],
	Headlines6 = ['#439eb7', '#e28b55', '#dcb64d', '#4ca198', '#835b82', '#645135'],
	Horizon6 = ['#7e97ad', '#cc8e60', '#7a6a60', '#b4936d', '#67787b', '#9d936f'],
	Infusion6 = ['#8c73d0', '#c2e8c4', '#c5a6e8', '#b45ec7', '#9fdafb', '#95c5b0'],
	Inkwell6 = ['#860908', '#4a0505', '#7a500a', '#c47810', '#827752', '#b5bb83'],
	Inspiration6 = ['#749805', '#bacc82', '#6e9ec2', '#2046a5', '#5039c6', '#7411d0'],
	Integral6 = ['#1cade4', '#2683c6', '#27ced7', '#42ba97', '#3e8853', '#62a39f'],
	Ion6 = ['#b01513', '#ea6312', '#e6b729', '#6aac90', '#5f9c9d', '#9e5e9b'],
	IonBoardroom6 = ['#b31166', '#e33d6f', '#e45f3c', '#e9943a', '#9b6bf2', '#d53dd0'],
	Kilter6 = ['#76c5ef', '#fea022', '#ff6700', '#70a525', '#a5d848', '#20768c'],
	Madison6 = ['#a1d68b', '#5ec795', '#4dadcf', '#cdb756', '#e29c36', '#8ec0c1'],
	MainEvent6 = ['#b80e0f', '#a6987d', '#7f9a71', '#64969f', '#9b75b2', '#80737a'],
	Marquee6 = ['#418ab3', '#a6b727', '#f69200', '#838383', '#fec306', '#df5327'],
	Median6 = ['#94b6d2', '#dd8047', '#a5ab81', '#d8b25c', '#7ba79d', '#968c8c'],
	Mesh6 = ['#6f6f6f', '#bfbfa5', '#dcd084', '#e7bf5f', '#e9a039', '#cf7133'],
	Metail6 = ['#6283ad', '#324966', '#5b9ea4', '#1d5b57', '#1b4430', '#2f3c35'],
	Metro6 = ['#7fd13b', '#ea157a', '#feb80a', '#00addc', '#738ac8', '#1ab39f'],
	Metropolitan6 = ['#50b4c8', '#a8b97f', '#9b9256', '#657689', '#7a855d', '#84ac9d'],
	Module6 = ['#f0ad00', '#60b5cc', '#e66c7d', '#6bb76d', '#e88651', '#c64847'],
	NewsPrint6 = ['#ad0101', '#726056', '#ac956e', '#808da9', '#424e5b', '#730e00'],
	Office6 = ['#5b9bd5', '#ed7d31', '#a5a5a5', '#ffc000', '#4472c4', '#70ad47'],
	OfficeClassic6 = ['#4f81bd', '#c0504d', '#9bbb59', '#8064a2', '#4bacc6', '#f79646'],
	Opulent6 = ['#b83d68', '#ac66bb', '#de6c36', '#f9b639', '#cf6da4', '#fa8d3d'],
	Orange6 = ['#e48312', '#bd582c', '#865640', '#9b8357', '#c2bc80', '#94a088'],
	OrangeRed6 = ['#d34817', '#9b2d1f', '#a28e6a', '#956251', '#918485', '#855d5d'],
	Orbit6 = ['#f2d908', '#9de61e', '#0d8be6', '#c61b1b', '#e26f08', '#8d35d1'],
	Organic6 = ['#83992a', '#3c9770', '#44709d', '#a23c33', '#d97828', '#deb340'],
	Oriel6 = ['#fe8637', '#7598d9', '#b32c16', '#f5cd2d', '#aebad5', '#777c84'],
	Origin6 = ['#727ca3', '#9fb8cd', '#d2da7a', '#fada7a', '#b88472', '#8e736a'],
	Paper6 = ['#a5b592', '#f3a447', '#e7bc29', '#d092a7', '#9c85c0', '#809ec2'],
	Parallax6 = ['#30acec', '#80c34f', '#e29d3e', '#d64a3b', '#d64787', '#a666e1'],
	Parcel6 = ['#f6a21d', '#9bafb5', '#c96731', '#9ca383', '#87795d', '#a0988c'],
	Perception6 = ['#a2c816', '#e07602', '#e4c402', '#7dc1ef', '#21449b', '#a2b170'],
	Perspective6 = ['#838d9b', '#d2610c', '#80716a', '#94147c', '#5d5ad2', '#6f6c7d'],
	Pixel6 = ['#ff7f01', '#f1b015', '#fbec85', '#d2c2f1', '#da5af4', '#9d09d1'],
	Plaza6 = ['#990000', '#580101', '#e94a00', '#eb8f00', '#a4a4a4', '#666666'],
	Precedent6 = ['#993232', '#9b6c34', '#736c5d', '#c9972b', '#c95f2b', '#8f7a05'],
	Pushpin6 = ['#fda023', '#aa2b1e', '#71685c', '#64a73b', '#eb5605', '#b9ca1a'],
	Quotable6 = ['#00c6bb', '#6feba0', '#b6df5e', '#efb251', '#ef755f', '#ed515c'],
	Red6 = ['#a5300f', '#d55816', '#e19825', '#b19c7d', '#7f5f52', '#b27d49'],
	RedOrange6 = ['#e84c22', '#ffbd47', '#b64926', '#ff8427', '#cc9900', '#b22600'],
	RedViolet6 = ['#e32d91', '#c830cc', '#4ea6dc', '#4775e7', '#8971e1', '#d54773'],
	Retrospect6 = ['#e48312', '#bd582c', '#865640', '#9b8357', '#c2bc80', '#94a088'],
	Revolution6 = ['#0c5986', '#ddf53d', '#508709', '#bf5e00', '#9c0001', '#660075'],
	Saddle6 = ['#c6b178', '#9c5b14', '#71b2bc', '#78aa5d', '#867099', '#4c6f75'],
	Savon6 = ['#1cade4', '#2683c6', '#27ced7', '#42ba97', '#3e8853', '#62a39f'],
	Sketchbook6 = ['#a63212', '#e68230', '#9bb05e', '#6b9bc7', '#4e66b2', '#8976ac'],
	Sky6 = ['#073779', '#8fd9fb', '#ffcc00', '#eb6615', '#c76402', '#b523b4'],
	Slate6 = ['#bc451b', '#d3ba68', '#bb8640', '#ad9277', '#a55a43', '#ad9d7b'],
	Slice6 = ['#052f61', '#a50e82', '#14967c', '#6a9e1f', '#e87d37', '#c62324'],
	Slipstream6 = ['#4e67c8', '#5eccf3', '#a7ea52', '#5dceaf', '#ff8021', '#f14124'],
	SOHO6 = ['#61625e', '#964d2c', '#66553e', '#848058', '#afa14b', '#ad7d4d'],
	Solstice6 = ['#3891a7', '#feb80a', '#c32d2e', '#84aa33', '#964305', '#475a8d'],
	Spectrum6 = ['#990000', '#ff6600', '#ffba00', '#99cc00', '#528a02', '#333333'],
	Story6 = ['#1d86cd', '#732e9a', '#b50b1b', '#e8950e', '#55992b', '#2c9c89'],
	Studio6 = ['#f7901e', '#fec60b', '#9fe62f', '#4ea5d1', '#1c4596', '#542d90'],
	Summer6 = ['#51a6c2', '#51c2a9', '#7ec251', '#e1dc53', '#b54721', '#a16bb1'],
	Technic6 = ['#6ea0b0', '#ccaf0a', '#8d89a4', '#748560', '#9e9273', '#7e848d'],
	Thatch6 = ['#759aa5', '#cfc60d', '#99987f', '#90ac97', '#ffad1c', '#b9ab6f'],
	Tradition6 = ['#6b4a0b', '#790a14', '#908342', '#423e5c', '#641345', '#748a2f'],
	Travelogue6 = ['#b74d21', '#a32323', '#4576a3', '#615d9a', '#67924b', '#bf7b1b'],
	Trek6 = ['#f0a22e', '#a5644e', '#b58b80', '#c3986d', '#a19574', '#c17529'],
	Twilight6 = ['#e8bc4a', '#83c1c6', '#e78d35', '#909ce1', '#839c41', '#cc5439'],
	Urban6 = ['#53548a', '#438086', '#a04da3', '#c4652d', '#8b5d3d', '#5c92b5'],
	UrbanPop6 = ['#86ce24', '#00a2e6', '#fac810', '#7d8f8c', '#d06b20', '#958b8b'],
	VaporTrail6 = ['#df2e28', '#fe801a', '#e9bf35', '#81bb42', '#32c7a9', '#4a9bdc'],
	Venture6 = ['#9eb060', '#d09a08', '#f2ec86', '#824f1c', '#511818', '#553876'],
	Verve6 = ['#ff388c', '#e40059', '#9c007f', '#68007f', '#005bd3', '#00349e'],
	View6 = ['#6f6f74', '#92a9b9', '#a7b789', '#b9a489', '#8d6374', '#9b7362'],
	Violet6 = ['#ad84c6', '#8784c7', '#5d739a', '#6997af', '#84acb6', '#6f8183'],
	VioletII6 = ['#92278f', '#9b57d3', '#755dd9', '#665eb8', '#45a5ed', '#5982db'],
	Waveform6 = ['#31b6fd', '#4584d3', '#5bd078', '#a5d028', '#f5c040', '#05e0db'],
	Wisp6 = ['#a53010', '#de7e18', '#9f8351', '#728653', '#92aa4c', '#6aac91'],
	WoodType6 = ['#d34817', '#9b2d1f', '#a28e6a', '#956251', '#918485', '#855d5d'],
	Yellow6 = ['#ffca08', '#f8931d', '#ce8d3e', '#ec7016', '#e64823', '#9c6a6a'],
	YellowOrange6 = ['#f0a22e', '#a5644e', '#b58b80', '#c3986d', '#a19574', '#c17529'];

var office = /*#__PURE__*/Object.freeze({
__proto__: null,
Adjacency6: Adjacency6,
Advantage6: Advantage6,
Angles6: Angles6,
Apex6: Apex6,
Apothecary6: Apothecary6,
Aspect6: Aspect6,
Atlas6: Atlas6,
Austin6: Austin6,
Badge6: Badge6,
Banded6: Banded6,
Basis6: Basis6,
Berlin6: Berlin6,
BlackTie6: BlackTie6,
Blue6: Blue6,
BlueGreen6: BlueGreen6,
BlueII6: BlueII6,
BlueRed6: BlueRed6,
BlueWarm6: BlueWarm6,
Breeze6: Breeze6,
Capital6: Capital6,
Celestial6: Celestial6,
Circuit6: Circuit6,
Civic6: Civic6,
Clarity6: Clarity6,
Codex6: Codex6,
Composite6: Composite6,
Concourse6: Concourse6,
Couture6: Couture6,
Crop6: Crop6,
Damask6: Damask6,
Depth6: Depth6,
Dividend6: Dividend6,
Droplet6: Droplet6,
Elemental6: Elemental6,
Equity6: Equity6,
Essential6: Essential6,
Excel16: Excel16,
Executive6: Executive6,
Exhibit6: Exhibit6,
Expo6: Expo6,
Facet6: Facet6,
Feathered6: Feathered6,
Flow6: Flow6,
Focus6: Focus6,
Folio6: Folio6,
Formal6: Formal6,
Forte6: Forte6,
Foundry6: Foundry6,
Frame6: Frame6,
Gallery6: Gallery6,
Genesis6: Genesis6,
Grayscale6: Grayscale6,
Green6: Green6,
GreenYellow6: GreenYellow6,
Grid6: Grid6,
Habitat6: Habitat6,
Hardcover6: Hardcover6,
Headlines6: Headlines6,
Horizon6: Horizon6,
Infusion6: Infusion6,
Inkwell6: Inkwell6,
Inspiration6: Inspiration6,
Integral6: Integral6,
Ion6: Ion6,
IonBoardroom6: IonBoardroom6,
Kilter6: Kilter6,
Madison6: Madison6,
MainEvent6: MainEvent6,
Marquee6: Marquee6,
Median6: Median6,
Mesh6: Mesh6,
Metail6: Metail6,
Metro6: Metro6,
Metropolitan6: Metropolitan6,
Module6: Module6,
NewsPrint6: NewsPrint6,
Office6: Office6,
OfficeClassic6: OfficeClassic6,
Opulent6: Opulent6,
Orange6: Orange6,
OrangeRed6: OrangeRed6,
Orbit6: Orbit6,
Organic6: Organic6,
Oriel6: Oriel6,
Origin6: Origin6,
Paper6: Paper6,
Parallax6: Parallax6,
Parcel6: Parcel6,
Perception6: Perception6,
Perspective6: Perspective6,
Pixel6: Pixel6,
Plaza6: Plaza6,
Precedent6: Precedent6,
Pushpin6: Pushpin6,
Quotable6: Quotable6,
Red6: Red6,
RedOrange6: RedOrange6,
RedViolet6: RedViolet6,
Retrospect6: Retrospect6,
Revolution6: Revolution6,
Saddle6: Saddle6,
Savon6: Savon6,
Sketchbook6: Sketchbook6,
Sky6: Sky6,
Slate6: Slate6,
Slice6: Slice6,
Slipstream6: Slipstream6,
SOHO6: SOHO6,
Solstice6: Solstice6,
Spectrum6: Spectrum6,
Story6: Story6,
Studio6: Studio6,
Summer6: Summer6,
Technic6: Technic6,
Thatch6: Thatch6,
Tradition6: Tradition6,
Travelogue6: Travelogue6,
Trek6: Trek6,
Twilight6: Twilight6,
Urban6: Urban6,
UrbanPop6: UrbanPop6,
VaporTrail6: VaporTrail6,
Venture6: Venture6,
Verve6: Verve6,
View6: View6,
Violet6: Violet6,
VioletII6: VioletII6,
Waveform6: Waveform6,
Wisp6: Wisp6,
WoodType6: WoodType6,
Yellow6: Yellow6,
YellowOrange6: YellowOrange6
});

// eslint-disable-next-line one-var
var
	// New
	Tableau10 = ['#4E79A7', '#F28E2B', '#E15759', '#76B7B2', '#59A14F', '#EDC948', '#B07AA1', '#FF9DA7', '#9C755F', '#BAB0AC'],
	Tableau20 = ['#4E79A7', '#A0CBE8', '#F28E2B', '#FFBE7D', '#59A14F', '#8CD17D', '#B6992D', '#F1CE63', '#499894', '#86BCB6', '#E15759', '#FF9D9A', '#79706E', '#BAB0AC', '#D37295', '#FABFD2', '#B07AA1', '#D4A6C8', '#9D7660', '#D7B5A6'],
	ColorBlind10 = ['#1170aa', '#fc7d0b', '#a3acb9', '#57606c', '#5fa2ce', '#c85200', '#7b848f', '#a3cce9', '#ffbc79', '#c8d0d9'],
	SeattleGrays5 = ['#767f8b', '#b3b7b8', '#5c6068', '#d3d3d3', '#989ca3'],
	Traffic9 = ['#b60a1c', '#e39802', '#309143', '#e03531', '#f0bd27', '#51b364', '#ff684c', '#ffda66', '#8ace7e'],
	MillerStone11 = ['#4f6980', '#849db1', '#a2ceaa', '#638b66', '#bfbb60', '#f47942', '#fbb04e', '#b66353', '#d7ce9f', '#b9aa97', '#7e756d'],
	SuperfishelStone10 = ['#6388b4', '#ffae34', '#ef6f6a', '#8cc2ca', '#55ad89', '#c3bc3f', '#bb7693', '#baa094', '#a9b5ae', '#767676'],
	NurielStone9 = ['#8175aa', '#6fb899', '#31a1b3', '#ccb22b', '#a39fc9', '#94d0c0', '#959c9e', '#027b8e', '#9f8f12'],
	JewelBright9 = ['#eb1e2c', '#fd6f30', '#f9a729', '#f9d23c', '#5fbb68', '#64cdcc', '#91dcea', '#a4a4d5', '#bbc9e5'],
	Summer8 = ['#bfb202', '#b9ca5d', '#cf3e53', '#f1788d', '#00a2b3', '#97cfd0', '#f3a546', '#f7c480'],
	Winter10 = ['#90728f', '#b9a0b4', '#9d983d', '#cecb76', '#e15759', '#ff9888', '#6b6b6b', '#bab2ae', '#aa8780', '#dab6af'],
	GreenOrangeTeal12 = ['#4e9f50', '#87d180', '#ef8a0c', '#fcc66d', '#3ca8bc', '#98d9e4', '#94a323', '#c3ce3d', '#a08400', '#f7d42a', '#26897e', '#8dbfa8'],
	RedBlueBrown12 = ['#466f9d', '#91b3d7', '#ed444a', '#feb5a2', '#9d7660', '#d7b5a6', '#3896c4', '#a0d4ee', '#ba7e45', '#39b87f', '#c8133b', '#ea8783'],
	PurplePinkGray12 = ['#8074a8', '#c6c1f0', '#c46487', '#ffbed1', '#9c9290', '#c5bfbe', '#9b93c9', '#ddb5d5', '#7c7270', '#f498b6', '#b173a0', '#c799bc'],
	HueCircle19 = ['#1ba3c6', '#2cb5c0', '#30bcad', '#21B087', '#33a65c', '#57a337', '#a2b627', '#d5bb21', '#f8b620', '#f89217', '#f06719', '#e03426', '#f64971', '#fc719e', '#eb73b3', '#ce69be', '#a26dc2', '#7873c0', '#4f7cba'],
	OrangeBlue7 = ['#9e3d22', '#d45b21', '#f69035', '#d9d5c9', '#77acd3', '#4f81af', '#2b5c8a'],
	RedGreen7 = ['#a3123a', '#e33f43', '#f8816b', '#ced7c3', '#73ba67', '#44914e', '#24693d'],
	GreenBlue7 = ['#24693d', '#45934d', '#75bc69', '#c9dad2', '#77a9cf', '#4e7fab', '#2a5783'],
	RedBlue7 = ['#a90c38', '#e03b42', '#f87f69', '#dfd4d1', '#7eaed3', '#5383af', '#2e5a87'],
	RedBlack7 = ['#ae123a', '#e33e43', '#f8816b', '#d9d9d9', '#a0a7a8', '#707c83', '#49525e'],
	GoldPurple7 = ['#ad9024', '#c1a33b', '#d4b95e', '#e3d8cf', '#d4a3c3', '#c189b0', '#ac7299'],
	RedGreenGold7 = ['#be2a3e', '#e25f48', '#f88f4d', '#f4d166', '#90b960', '#4b9b5f', '#22763f'],
	SunsetSunrise7 = ['#33608c', '#9768a5', '#e7718a', '#f6ba57', '#ed7846', '#d54c45', '#b81840'],
	OrangeBlueWhite7 = ['#9e3d22', '#e36621', '#fcad52', '#ffffff', '#95c5e1', '#5b8fbc', '#2b5c8a'],
	RedGreenWhite7 = ['#ae123a', '#ee574d', '#fdac9e', '#ffffff', '#91d183', '#539e52', '#24693d'],
	GreenBlueWhite7 = ['#24693d', '#529c51', '#8fd180', '#ffffff', '#95c1dd', '#598ab5', '#2a5783'],
	RedBlueWhite7 = ['#a90c38', '#ec534b', '#feaa9a', '#ffffff', '#9ac4e1', '#5c8db8', '#2e5a87'],
	RedBlackWhite7 = ['#ae123a', '#ee574d', '#fdac9d', '#ffffff', '#bdc0bf', '#7d888d', '#49525e'],
	OrangeBlueLight7 = ['#ffcc9e', '#f9d4b6', '#f0dccd', '#e5e5e5', '#dae1ea', '#cfdcef', '#c4d8f3'],
	Temperature7 = ['#529985', '#6c9e6e', '#99b059', '#dbcf47', '#ebc24b', '#e3a14f', '#c26b51'],
	BlueGreen7 = ['#feffd9', '#f2fabf', '#dff3b2', '#c4eab1', '#94d6b7', '#69c5be', '#41b7c4'],
	BlueLight7 = ['#e5e5e5', '#e0e3e8', '#dbe1ea', '#d5dfec', '#d0dcef', '#cadaf1', '#c4d8f3'],
	OrangeLight7 = ['#e5e5e5', '#ebe1d9', '#f0ddcd', '#f5d9c2', '#f9d4b6', '#fdd0aa', '#ffcc9e'],
	Blue20 = ['#b9ddf1', '#afd6ed', '#a5cfe9', '#9bc7e4', '#92c0df', '#89b8da', '#80b0d5', '#79aacf', '#72a3c9', '#6a9bc3', '#6394be', '#5b8cb8', '#5485b2', '#4e7fac', '#4878a6', '#437a9f', '#3d6a98', '#376491', '#305d8a', '#2a5783'],
	Orange20 = ['#ffc685', '#fcbe75', '#f9b665', '#f7ae54', '#f5a645', '#f59c3c', '#f49234', '#f2882d', '#f07e27', '#ee7422', '#e96b20', '#e36420', '#db5e20', '#d25921', '#ca5422', '#c14f22', '#b84b23', '#af4623', '#a64122', '#9e3d22'],
	Green20 = ['#b3e0a6', '#a5db96', '#98d687', '#8ed07f', '#85ca77', '#7dc370', '#75bc69', '#6eb663', '#67af5c', '#61a956', '#59a253', '#519c51', '#49964f', '#428f4d', '#398949', '#308344', '#2b7c40', '#27763d', '#256f3d', '#24693d'],
	Red20 = ['#ffbeb2', '#feb4a6', '#fdab9b', '#fca290', '#fb9984', '#fa8f79', '#f9856e', '#f77b66', '#f5715d', '#f36754', '#f05c4d', '#ec5049', '#e74545', '#e13b42', '#da323f', '#d3293d', '#ca223c', '#c11a3b', '#b8163a', '#ae123a'],
	Purple20 = ['#eec9e5', '#eac1df', '#e6b9d9', '#e0b2d2', '#daabcb', '#d5a4c4', '#cf9dbe', '#ca96b8', '#c48fb2', '#be89ac', '#b882a6', '#b27ba1', '#aa759d', '#a27099', '#9a6a96', '#926591', '#8c5f86', '#865986', '#81537f', '#7c4d79'],
	Brown20 = ['#eedbbd', '#ecd2ad', '#ebc994', '#eac085', '#e8b777', '#e5ae6c', '#e2a562', '#de9d5a', '#d99455', '#d38c54', '#ce8451', '#c9784d', '#c47247', '#c16941', '#bd6036', '#b85636', '#b34d34', '#ad4433', '#a63d32', '#9f3632'],
	Gray20 = ['#d5d5d5', '#cdcecd', '#c5c7c6', '#bcbfbe', '#b4b7b7', '#acb0b1', '#a4a9ab', '#9ca3a4', '#939c9e', '#8b9598', '#848e93', '#7c878d', '#758087', '#6e7a81', '#67737c', '#616c77', '#5b6570', '#555f6a', '#4f5864', '#49525e'],
	GrayWarm20 = ['#dcd4d0', '#d4ccc8', '#cdc4c0', '#c5bdb9', '#beb6b2', '#b7afab', '#b0a7a4', '#a9a09d', '#a29996', '#9b938f', '#948c88', '#8d8481', '#867e7b', '#807774', '#79706e', '#736967', '#6c6260', '#665c51', '#5f5654', '#59504e'],
	BlueTeal20 = ['#bce4d8', '#aedcd5', '#a1d5d2', '#95cecf', '#89c8cc', '#7ec1ca', '#72bac6', '#66b2c2', '#59acbe', '#4ba5ba', '#419eb6', '#3b96b2', '#358ead', '#3586a7', '#347ea1', '#32779b', '#316f96', '#2f6790', '#2d608a', '#2c5985'],
	OrangeGold20 = ['#f4d166', '#f6c760', '#f8bc58', '#f8b252', '#f7a84a', '#f69e41', '#f49538', '#f38b2f', '#f28026', '#f0751e', '#eb6c1c', '#e4641e', '#de5d1f', '#d75521', '#cf4f22', '#c64a22', '#bc4623', '#b24223', '#a83e24', '#9e3a26'],
	GreenGold20 = ['#f4d166', '#e3cd62', '#d3c95f', '#c3c55d', '#b2c25b', '#a3bd5a', '#93b958', '#84b457', '#76af56', '#67a956', '#5aa355', '#4f9e53', '#479751', '#40914f', '#3a8a4d', '#34844a', '#2d7d45', '#257740', '#1c713b', '#146c36'],
	RedGold21 = ['#f4d166', '#f5c75f', '#f6bc58', '#f7b254', '#f9a750', '#fa9d4f', '#fa9d4f', '#fb934d', '#f7894b', '#f47f4a', '#f0774a', '#eb6349', '#e66549', '#e15c48', '#dc5447', '#d64c45', '#d04344', '#ca3a42', '#c43141', '#bd273f', '#b71d3e'],

	// Classic
	Classic10 = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b', '#e377c2', '#7f7f7f', '#bcbd22', '#17becf'],
	ClassicMedium10 = ['#729ece', '#ff9e4a', '#67bf5c', '#ed665d', '#ad8bc9', '#a8786e', '#ed97ca', '#a2a2a2', '#cdcc5d', '#6dccda'],
	ClassicLight10 = ['#aec7e8', '#ffbb78', '#98df8a', '#ff9896', '#c5b0d5', '#c49c94', '#f7b6d2', '#c7c7c7', '#dbdb8d', '#9edae5'],
	Classic20 = ['#1f77b4', '#aec7e8', '#ff7f0e', '#ffbb78', '#2ca02c', '#98df8a', '#d62728', '#ff9896', '#9467bd', '#c5b0d5', '#8c564b', '#c49c94', '#e377c2', '#f7b6d2', '#7f7f7f', '#c7c7c7', '#bcbd22', '#dbdb8d', '#17becf', '#9edae5'],
	ClassicGray5 = ['#60636a', '#a5acaf', '#414451', '#8f8782', '#cfcfcf'],
	ClassicColorBlind10 = ['#006ba4', '#ff800e', '#ababab', '#595959', '#5f9ed1', '#c85200', '#898989', '#a2c8ec', '#ffbc79', '#cfcfcf'],
	ClassicTrafficLight9 = ['#b10318', '#dba13a', '#309343', '#d82526', '#ffc156', '#69b764', '#f26c64', '#ffdd71', '#9fcd99'],
	ClassicPurpleGray6 = ['#7b66d2', '#dc5fbd', '#94917b', '#995688', '#d098ee', '#d7d5c5'],
	ClassicPurpleGray12 = ['#7b66d2', '#a699e8', '#dc5fbd', '#ffc0da', '#5f5a41', '#b4b19b', '#995688', '#d898ba', '#ab6ad5', '#d098ee', '#8b7c6e', '#dbd4c5'],
	ClassicGreenOrange6 = ['#32a251', '#ff7f0f', '#3cb7cc', '#ffd94a', '#39737c', '#b85a0d'],
	ClassicGreenOrange12 = ['#32a251', '#acd98d', '#ff7f0f', '#ffb977', '#3cb7cc', '#98d9e4', '#b85a0d', '#ffd94a', '#39737c', '#86b4a9', '#82853b', '#ccc94d'],
	ClassicBlueRed6 = ['#2c69b0', '#f02720', '#ac613c', '#6ba3d6', '#ea6b73', '#e9c39b'],
	ClassicBlueRed12 = ['#2c69b0', '#b5c8e2', '#f02720', '#ffb6b0', '#ac613c', '#e9c39b', '#6ba3d6', '#b5dffd', '#ac8763', '#ddc9b4', '#bd0a36', '#f4737a'],
	ClassicCyclic13 = ['#1f83b4', '#12a2a8', '#2ca030', '#78a641', '#bcbd22', '#ffbf50', '#ffaa0e', '#ff7f0e', '#d63a3a', '#c7519c', '#ba43b4', '#8a60b0', '#6f63bb'],
	ClassicGreen7 = ['#bccfb4', '#94bb83', '#69a761', '#339444', '#27823b', '#1a7232', '#09622a'],
	ClassicGray13 = ['#c3c3c3', '#b2b2b2', '#a2a2a2', '#929292', '#838383', '#747474', '#666666', '#585858', '#4b4b4b', '#3f3f3f', '#333333', '#282828', '#1e1e1e'],
	ClassicBlue7 = ['#b4d4da', '#7bc8e2', '#67add4', '#3a87b7', '#1c73b1', '#1c5998', '#26456e'],
	ClassicRed9 = ['#eac0bd', '#f89a90', '#f57667', '#e35745', '#d8392c', '#cf1719', '#c21417', '#b10c1d', '#9c0824'],
	ClassicOrange7 = ['#f0c294', '#fdab67', '#fd8938', '#f06511', '#d74401', '#a33202', '#7b3014'],
	ClassicAreaRed11 = ['#f5cac7', '#fbb3ab', '#fd9c8f', '#fe8b7a', '#fd7864', '#f46b55', '#ea5e45', '#e04e35', '#d43e25', '#c92b14', '#bd1100'],
	ClassicAreaGreen11 = ['#dbe8b4', '#c3e394', '#acdc7a', '#9ad26d', '#8ac765', '#7abc5f', '#6cae59', '#60a24d', '#569735', '#4a8c1c', '#3c8200'],
	ClassicAreaBrown11 = ['#f3e0c2', '#f6d29c', '#f7c577', '#f0b763', '#e4aa63', '#d89c63', '#cc8f63', '#c08262', '#bb7359', '#bb6348', '#bb5137'],
	ClassicRedGreen11 = ['#9c0824', '#bd1316', '#d11719', '#df513f', '#fc8375', '#cacaca', '#a2c18f', '#69a761', '#2f8e41', '#1e7735', '#09622a'],
	ClassicRedBlue11 = ['#9c0824', '#bd1316', '#d11719', '#df513f', '#fc8375', '#cacaca', '#67add4', '#3a87b7', '#1c73b1', '#1c5998', '#26456e'],
	ClassicRedBlack11 = ['#9c0824', '#bd1316', '#d11719', '#df513f', '#fc8375', '#cacaca', '#9b9b9b', '#777777', '#565656', '#383838', '#1e1e1e'],
	ClassicAreaRedGreen21 = ['#bd1100', '#c82912', '#d23a21', '#dc4930', '#e6583e', '#ef654d', '#f7705b', '#fd7e6b', '#fe8e7e', '#fca294', '#e9dabe', '#c7e298', '#b1de7f', '#a0d571', '#90cb68', '#82c162', '#75b65d', '#69aa56', '#5ea049', '#559633', '#4a8c1c'],
	ClassicOrangeBlue13 = ['#7b3014', '#a33202', '#d74401', '#f06511', '#fd8938', '#fdab67', '#cacaca', '#7bc8e2', '#67add4', '#3a87b7', '#1c73b1', '#1c5998', '#26456e'],
	ClassicGreenBlue11 = ['#09622a', '#1e7735', '#2f8e41', '#69a761', '#a2c18f', '#cacaca', '#67add4', '#3a87b7', '#1c73b1', '#1c5998', '#26456e'],
	ClassicRedWhiteGreen11 = ['#9c0824', '#b41f27', '#cc312b', '#e86753', '#fcb4a5', '#ffffff', '#b9d7b7', '#74af72', '#428f49', '#297839', '#09622a'],
	ClassicRedWhiteBlack11 = ['#9c0824', '#b41f27', '#cc312b', '#e86753', '#fcb4a5', '#ffffff', '#bfbfbf', '#838383', '#575757', '#393939', '#1e1e1e'],
	ClassicOrangeWhiteBlue11 = ['#7b3014', '#a84415', '#d85a13', '#fb8547', '#ffc2a1', '#ffffff', '#b7cde2', '#6a9ec5', '#3679a8', '#2e5f8a', '#26456e'],
	ClassicRedWhiteBlackLight10 = ['#ffc2c5', '#ffd1d3', '#ffe0e1', '#fff0f0', '#ffffff', '#f3f3f3', '#e8e8e8', '#dddddd', '#d1d1d1', '#c6c6c6'],
	ClassicOrangeWhiteBlueLight11 = ['#ffcc9e', '#ffd6b1', '#ffe0c5', '#ffead8', '#fff5eb', '#ffffff', '#f3f7fd', '#e8effa', '#dce8f8', '#d0e0f6', '#c4d8f3'],
	ClassicRedWhiteGreenLight11 = ['#ffb2b6', '#ffc2c5', '#ffd1d3', '#ffe0e1', '#fff0f0', '#ffffff', '#f1faed', '#e3f5db', '#d5f0ca', '#c6ebb8', '#b7e6a7'],
	ClassicRedGreenLight11 = ['#ffb2b6', '#fcbdc0', '#f8c7c9', '#f2d1d2', '#ecdbdc', '#e5e5e5', '#dde6d9', '#d4e6cc', '#cae6c0', '#c1e6b4', '#b7e6a7'];

var tableau = /*#__PURE__*/Object.freeze({
__proto__: null,
Tableau10: Tableau10,
Tableau20: Tableau20,
ColorBlind10: ColorBlind10,
SeattleGrays5: SeattleGrays5,
Traffic9: Traffic9,
MillerStone11: MillerStone11,
SuperfishelStone10: SuperfishelStone10,
NurielStone9: NurielStone9,
JewelBright9: JewelBright9,
Summer8: Summer8,
Winter10: Winter10,
GreenOrangeTeal12: GreenOrangeTeal12,
RedBlueBrown12: RedBlueBrown12,
PurplePinkGray12: PurplePinkGray12,
HueCircle19: HueCircle19,
OrangeBlue7: OrangeBlue7,
RedGreen7: RedGreen7,
GreenBlue7: GreenBlue7,
RedBlue7: RedBlue7,
RedBlack7: RedBlack7,
GoldPurple7: GoldPurple7,
RedGreenGold7: RedGreenGold7,
SunsetSunrise7: SunsetSunrise7,
OrangeBlueWhite7: OrangeBlueWhite7,
RedGreenWhite7: RedGreenWhite7,
GreenBlueWhite7: GreenBlueWhite7,
RedBlueWhite7: RedBlueWhite7,
RedBlackWhite7: RedBlackWhite7,
OrangeBlueLight7: OrangeBlueLight7,
Temperature7: Temperature7,
BlueGreen7: BlueGreen7,
BlueLight7: BlueLight7,
OrangeLight7: OrangeLight7,
Blue20: Blue20,
Orange20: Orange20,
Green20: Green20,
Red20: Red20,
Purple20: Purple20,
Brown20: Brown20,
Gray20: Gray20,
GrayWarm20: GrayWarm20,
BlueTeal20: BlueTeal20,
OrangeGold20: OrangeGold20,
GreenGold20: GreenGold20,
RedGold21: RedGold21,
Classic10: Classic10,
ClassicMedium10: ClassicMedium10,
ClassicLight10: ClassicLight10,
Classic20: Classic20,
ClassicGray5: ClassicGray5,
ClassicColorBlind10: ClassicColorBlind10,
ClassicTrafficLight9: ClassicTrafficLight9,
ClassicPurpleGray6: ClassicPurpleGray6,
ClassicPurpleGray12: ClassicPurpleGray12,
ClassicGreenOrange6: ClassicGreenOrange6,
ClassicGreenOrange12: ClassicGreenOrange12,
ClassicBlueRed6: ClassicBlueRed6,
ClassicBlueRed12: ClassicBlueRed12,
ClassicCyclic13: ClassicCyclic13,
ClassicGreen7: ClassicGreen7,
ClassicGray13: ClassicGray13,
ClassicBlue7: ClassicBlue7,
ClassicRed9: ClassicRed9,
ClassicOrange7: ClassicOrange7,
ClassicAreaRed11: ClassicAreaRed11,
ClassicAreaGreen11: ClassicAreaGreen11,
ClassicAreaBrown11: ClassicAreaBrown11,
ClassicRedGreen11: ClassicRedGreen11,
ClassicRedBlue11: ClassicRedBlue11,
ClassicRedBlack11: ClassicRedBlack11,
ClassicAreaRedGreen21: ClassicAreaRedGreen21,
ClassicOrangeBlue13: ClassicOrangeBlue13,
ClassicGreenBlue11: ClassicGreenBlue11,
ClassicRedWhiteGreen11: ClassicRedWhiteGreen11,
ClassicRedWhiteBlack11: ClassicRedWhiteBlack11,
ClassicOrangeWhiteBlue11: ClassicOrangeWhiteBlue11,
ClassicRedWhiteBlackLight10: ClassicRedWhiteBlackLight10,
ClassicOrangeWhiteBlueLight11: ClassicOrangeWhiteBlueLight11,
ClassicRedWhiteGreenLight11: ClassicRedWhiteGreenLight11,
ClassicRedGreenLight11: ClassicRedGreenLight11
});

var colorschemes = {
	brewer: brewer,
	office: office,
	tableau: tableau
};

var EXPANDO_KEY = '$colorschemes';

// pluginBase snippet fixes the chartjs 3 incompatibility, and is backwards-compatible
// by Github user gebrits (https://github.com/gebrits/chartjs-plugin-colorschemes)
//
// Chartjs 2 => Chart.defaults.global
// Chartjs 3 => Chart.defaults
const pluginBase = chart_js.Chart.defaults.global || chart_js.Chart.defaults;
pluginBase.plugins.colorschemes = {
	scheme: 'brewer.Paired12',
	fillAlpha: 0.5,
	reverse: false,
	overrideExisting: false
};

function getScheme(scheme) {
	var colorschemes, matches, arr, category;

	if (Array.isArray(scheme)) {
		return scheme;
	} else if (typeof scheme === 'string') {
		colorschemes = chart_js.Chart.colorschemes || {};

		// For backward compatibility
		matches = scheme.match(/^(brewer\.\w+)([1-3])-(\d+)$/);
		if (matches) {
			scheme = matches[1] + ['One', 'Two', 'Three'][matches[2] - 1] + matches[3];
		} else if (scheme === 'office.Office2007-2010-6') {
			scheme = 'office.OfficeClassic6';
		}

		arr = scheme.split('.');
		category = colorschemes[arr[0]];
		if (category) {
			return category[arr[1]];
		}
	}
}

var ColorSchemesPlugin = {
	id: 'colorschemes',

	beforeUpdate: function(chart, args, options) {
		// Please note that in v3, the args argument was added. It was not used before it was added,
		// so we just check if it is not actually our options object
		if (options === undefined) {
			options = args;
		}

		var scheme = getScheme(options.scheme);
		var fillAlpha = options.fillAlpha;
		var reverse = options.reverse;
		var override = options.overrideExisting;
		var custom = options.custom;
		var schemeClone, customResult, length, colorIndex, newColor;

		if (scheme) {

			if (typeof custom === 'function') {
				// clone the original scheme
				schemeClone = scheme.slice();

				// Execute own custom color function
				customResult = custom(schemeClone);

				// check if we really received a filled array; otherwise we keep and use the original scheme
				if (Array.isArray(customResult) && customResult.length) {
					scheme = customResult;
				} else if (Array.isArray(schemeClone) && schemeClone.length) {
					scheme = schemeClone;
				}
			}

			length = scheme.length;

			// Set scheme colors
			chart.config.data.datasets.forEach(function(dataset, datasetIndex) {
				colorIndex = datasetIndex % length;
				newColor = scheme[reverse ? length - colorIndex - 1 : colorIndex];

				// Object to store which color option is set
				dataset[EXPANDO_KEY] = {};

				switch (dataset.type || chart.config.type) {
				// For line, radar and scatter chart, borderColor and backgroundColor (50% transparent) are set
				case 'line':
				case 'radar':
				case 'scatter':
					if (typeof dataset.backgroundColor === 'undefined' || override) {
						dataset[EXPANDO_KEY].backgroundColor = dataset.backgroundColor;
						dataset.backgroundColor = helpers.color(newColor).alpha(fillAlpha).rgbString();
					}
					if (typeof dataset.borderColor === 'undefined' || override) {
						dataset[EXPANDO_KEY].borderColor = dataset.borderColor;
						dataset.borderColor = newColor;
					}
					if (typeof dataset.pointBackgroundColor === 'undefined' || override) {
						dataset[EXPANDO_KEY].pointBackgroundColor = dataset.pointBackgroundColor;
						dataset.pointBackgroundColor = helpers.color(newColor).alpha(fillAlpha).rgbString();
					}
					if (typeof dataset.pointBorderColor === 'undefined' || override) {
						dataset[EXPANDO_KEY].pointBorderColor = dataset.pointBorderColor;
						dataset.pointBorderColor = newColor;
					}
					break;
				// For doughnut and pie chart, backgroundColor is set to an array of colors
				case 'doughnut':
				case 'pie':
				case 'polarArea':
					if (typeof dataset.backgroundColor === 'undefined' || override) {
						dataset[EXPANDO_KEY].backgroundColor = dataset.backgroundColor;
						dataset.backgroundColor = dataset.data.map(function(data, dataIndex) {
							colorIndex = dataIndex % length;
							return scheme[reverse ? length - colorIndex - 1 : colorIndex];
						});
					}
					break;
				// For bar chart backgroundColor (including fillAlpha) and borderColor are set
				case 'bar':
					if (typeof dataset.backgroundColor === 'undefined' || override) {
						dataset[EXPANDO_KEY].backgroundColor = dataset.backgroundColor;
						dataset.backgroundColor = helpers.color(newColor).alpha(fillAlpha).rgbString();
					}
					if (typeof dataset.borderColor === 'undefined' || override) {
						dataset[EXPANDO_KEY].borderColor = dataset.borderColor;
						dataset.borderColor = newColor;
					}
					break;
				// For the other chart, only backgroundColor is set
				default:
					if (typeof dataset.backgroundColor === 'undefined' || override) {
						dataset[EXPANDO_KEY].backgroundColor = dataset.backgroundColor;
						dataset.backgroundColor = newColor;
					}
					break;
				}
			});
		}
	},

	afterUpdate: function(chart) {
		// Unset colors
		chart.config.data.datasets.forEach(function(dataset) {
			if (dataset[EXPANDO_KEY]) {
				if (dataset[EXPANDO_KEY].hasOwnProperty('backgroundColor')) {
					dataset.backgroundColor = dataset[EXPANDO_KEY].backgroundColor;
				}
				if (dataset[EXPANDO_KEY].hasOwnProperty('borderColor')) {
					dataset.borderColor = dataset[EXPANDO_KEY].borderColor;
				}
				if (dataset[EXPANDO_KEY].hasOwnProperty('pointBackgroundColor')) {
					dataset.pointBackgroundColor = dataset[EXPANDO_KEY].pointBackgroundColor;
				}
				if (dataset[EXPANDO_KEY].hasOwnProperty('pointBorderColor')) {
					dataset.pointBorderColor = dataset[EXPANDO_KEY].pointBorderColor;
				}
				delete dataset[EXPANDO_KEY];
			}
		});
	},

	beforeEvent: function(chart, event, options) {
	},

	afterEvent: function(chart) {
	}
};

if (chart_js.Chart.registry) {
  // Chartjs 3
  chart_js.Chart.register(ColorSchemesPlugin);
} else {
  // Chartjs 2
  chart_js.Chart.plugins.register(ColorSchemesPlugin);
}

chart_js.Chart.colorschemes = colorschemes;

return ColorSchemesPlugin;

})));
