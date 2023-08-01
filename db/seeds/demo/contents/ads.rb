puts "# ads"

banner1 = save_ss_files "ss_files/ads/dummy_banner_1.gif", filename: "dummy_banner_1.gif", model: "ads/banner"
banner2 = save_ss_files "ss_files/ads/dummy_banner_2.gif", filename: "dummy_banner_2.gif", model: "ads/banner"
banner3 = save_ss_files "ss_files/ads/dummy_banner_3.gif", filename: "dummy_banner_3.gif", model: "ads/banner"
banner4 = save_ss_files "ss_files/ads/dummy_banner_4.gif", filename: "dummy_banner_4.gif", model: "ads/banner"
banner5 = save_ss_files "ss_files/ads/dummy_banner_5.gif", filename: "dummy_banner_5.gif", model: "ads/banner"
banner6 = save_ss_files "ss_files/ads/dummy_banner_6.gif", filename: "dummy_banner_6.gif", model: "ads/banner"
banner1.set(state: "public")
banner2.set(state: "public")
banner3.set(state: "public")
banner4.set(state: "public")
banner5.set(state: "public")
banner6.set(state: "public")

save_page route: "ads/banner", filename: "ad/page30.html", name: "くらし・手続き",
  link_url: "/kurashi/", file_id: banner1.id, ads_category_ids: [@categories["kurashi"].id], order: 10
save_page route: "ads/banner", filename: "ad/page31.html", name: "子育て・教育",
  link_url: "/kosodate/", file_id: banner2.id, ads_category_ids: [@categories["kosodate"].id], order: 20
save_page route: "ads/banner", filename: "ad/page32.html", name: "健康・福祉",
  link_url: "/kenko/", file_id: banner3.id, ads_category_ids: [@categories["kenko"].id], order: 30
save_page route: "ads/banner", filename: "ad/page33.html", name: "観光・文化・スポーツ",
  link_url: "/kanko/", file_id: banner4.id, ads_category_ids: [@categories["kanko"].id], order: 40
save_page route: "ads/banner", filename: "ad/page34.html", name: "産業・仕事",
  link_url: "/sangyo/", file_id: banner5.id, ads_category_ids: [@categories["sangyo"].id], order: 50
save_page route: "ads/banner", filename: "ad/page35.html", name: "市政情報",
  link_url: "/shisei/", file_id: banner6.id, ads_category_ids: [@categories["shisei"].id], order: 60
