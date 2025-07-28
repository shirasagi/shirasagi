puts "# cms pages"
save_page route: "cms/page", filename: "index.html", name: "自治体サンプル", layout_id: @layouts["top"].id,
  released_type: 'same_as_updated'
save_page route: "cms/page", filename: "index2.html", name: "自治体サンプル（緊急レイアウト用）",
  layout_id: @layouts["top"].id
save_page route: "cms/page", filename: "mobile.html", name: "スマートフォン・携帯サイト", layout_id: @layouts["pages"].id,
  released_type: 'same_as_updated'
save_page route: "cms/page", filename: "use/index.html", name: "ご利用案内", layout_id: @layouts["general"].id,
  released_type: 'same_as_updated'
save_page route: "cms/page", filename: "404.html", name: "お探しのページは見つかりません。 404 Not Found", layout_id: @layouts["general"].id
save_page route: "cms/page", filename: "shisei/soshiki/index.html", name: "組織案内", layout_id: @layouts["category-middle"].id,
  released_type: 'same_as_updated'
save_page route: "cms/page", filename: "shisei/gaiyo/seibu.html", name: "西部", layout_id: @layouts["category-middle"].id
save_page route: "cms/page", filename: "shisei/gaiyo/hokubu.html", name: "北部",
  layout_id: @layouts["category-middle"].id
save_page route: "cms/page", filename: "shisei/gaiyo/naubu.html", name: "南部", layout_id: @layouts["category-middle"].id
save_page route: "cms/page", filename: "list/one.html", name: "ページ１", layout_id: @layouts["pages"].id,
  released_type: 'same_as_updated'
save_page route: "cms/page", filename: "list/two.html", name: "ページ２", layout_id: @layouts["pages"].id,
  released_type: 'same_as_updated'
save_page route: "cms/page", filename: "list/three.html", name: "ページ３", layout_id: @layouts["pages"].id,
  released_type: 'same_as_updated'
