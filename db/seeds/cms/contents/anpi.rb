puts "# cms pages"
save_page route: "cms/page", filename: "index.html", name: "自治体サンプル", layout_id: @layouts["top"].id
save_page route: "cms/page", filename: "mobile.html", name: "スマートフォン・携帯サイト", layout_id: @layouts["pages"].id
save_page route: "cms/page", filename: "use/index.html", name: "ご利用案内", layout_id: @layouts["one"].id
save_page route: "cms/page", filename: "404.html", name: "お探しのページは見つかりません。 404 Not Found", layout_id: @layouts["one"].id
save_page route: "cms/page", filename: "shisei/soshiki/index.html", name: "組織案内", layout_id: @layouts["category-middle"].id
