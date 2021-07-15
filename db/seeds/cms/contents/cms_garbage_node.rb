puts "# cms_garbage_node"

garbage_search = save_node(route: "garbage/search", filename: "garbage", name: "ゴミ品目検索", layout_id: @layouts["garbage"].id)
garbage_list = save_node(route: "garbage/node", filename: "garbage/list", name: "ゴミ品目一覧", layout_id: @layouts["garbage"].id)

save_node route: "garbage/category_list", filename: "garbage/category", name: "品目カテゴリー", layout_id: @layouts["garbage"].id
garbage_categories = [
  save_node(
    route: "garbage/category", filename: "garbage/category/c1", name: "燃えないゴミ",
    order: 10, layout_id: @layouts["garbage"].id
  ),
  save_node(
    route: "garbage/category", filename: "garbage/category/c2", name: "燃えるゴミ",
    order: 20, layout_id: @layouts["garbage"].id
  ),
  save_node(
    route: "garbage/category", filename: "garbage/category/c3", name: "小型家電",
    order: 30, layout_id: @layouts["garbage"].id
  ),
  save_node(
    route: "garbage/category", filename: "garbage/category/c4", name: "金属類",
    order: 40, layout_id: @layouts["garbage"].id
  ),
  save_node(
    route: "garbage/category", filename: "garbage/category/c5", name: "缶類",
    order: 50, layout_id: @layouts["garbage"].id
  ),
  save_node(
    route: "garbage/category", filename: "garbage/category/c6", name: "びん類",
    order: 60, layout_id: @layouts["garbage"].id
  ),
  save_node(
    route: "garbage/category", filename: "garbage/category/c7", name: "プラスチック",
    order: 70, layout_id: @layouts["garbage"].id
  ),
  save_node(
    route: "garbage/category", filename: "garbage/category/c8", name: "古着",
    order: 80, layout_id: @layouts["garbage"].id
  ),
  save_node(
    route: "garbage/category", filename: "garbage/category/c9", name: "ダンボール",
    order: 90, layout_id: @layouts["garbage"].id
  ),
  save_node(
    route: "garbage/category", filename: "garbage/category/c10", name: "回収不可",
    order: 100, layout_id: @layouts["garbage"].id
  )
]

garbage_search.st_category_ids = garbage_categories.map(&:id)
garbage_search.update
garbage_list.st_category_ids = garbage_categories.map(&:id)
garbage_list.update

save_node(
  route: "garbage/page", filename: "garbage/list/item1", name: "紙コップ",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[1].id]
)
save_node(
  route: "garbage/page", filename: "garbage/list/item2", name: "傘",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[0].id]
)
save_node(
  route: "garbage/page", filename: "garbage/list/item3", name: "カタログ",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[1].id]
)
save_node(
  route: "garbage/page", filename: "garbage/list/item4", name: "延長コード",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[0].id]
)
save_node(
  route: "garbage/page", filename: "garbage/list/item5", name: "油", remark: "固化するか紙、布などに染み込ませて出す",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[1].id]
)
save_node(
  route: "garbage/page", filename: "garbage/list/item7", name: "植木鉢（プラスチック製）", remark: "土を洗い落とす",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[6].id]
)
save_node(
  route: "garbage/page", filename: "garbage/list/item8", name: "網戸",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[3].id]
)
save_node(
  route: "garbage/page", filename: "garbage/list/item9", name: "飲料用紙パック", remark: "中を洗って開き乾かしてしばって出す",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[1].id]
)
save_node(
  route: "garbage/page", filename: "garbage/list/item10", name: "ガムテープ",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[1].id]
)
save_node(
  route: "garbage/page", filename: "garbage/list/item11", name: "カッパ（雨具）",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[7].id]
)
save_node(
  route: "garbage/page", filename: "garbage/list/item12", name: "アイロン",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[2].id]
)
save_node(
  route: "garbage/page", filename: "garbage/list/item13", name: "化粧品の容器", remark: "外側のプラスチック、中ふた等取り外し中身を洗浄し、色分けして出す",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[5].id]
)
save_node(
  route: "garbage/page", filename: "garbage/list/item14", name: "消火器", remark: "販売店か処理業者へ依頼する",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[9].id]
)
save_node(
  route: "garbage/page", filename: "garbage/list/item15", name: "アルミ缶", remark: "中身を洗浄する",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[4].id]
)
save_node(
  route: "garbage/page", filename: "garbage/list/item16", name: "軍手",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[1].id]
)
save_node(
  route: "garbage/page", filename: "garbage/list/item17", name: "セーター",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[7].id]
)
save_node(
  route: "garbage/page", filename: "garbage/list/item18", name: "充電式電池", remark: "電極部分をテープで覆い指定箱に入れる　できるだけ回収協力販売店の回収ボックスへ",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[3].id]
)
save_node(
  route: "garbage/page", filename: "garbage/list/item19", name: "ダンボール", remark: "ダンボール箱はたたんで十字にしばって出す",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[8].id]
)
save_node(
  route: "garbage/page", filename: "garbage/list/item20", name: "レジ袋", remark: "プラマークを確認する",
  layout_id: @layouts["garbage"].id, category_ids: [garbage_categories[6].id]
)
