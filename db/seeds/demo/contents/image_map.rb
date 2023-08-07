puts "# image map"

file = save_ss_files "ss_files/image_map/shirasagi_clickable.png", filename: "shirasagi_clickable.png",
  name: "shirasagi_clickable.png", model: "ss/temp_file"
save_node route: "image_map/page", filename: "map_clickable", name: "シラサギ市説明マップ",
  layout_id: @layouts["category-middle"].id, image_id: file.id,
  area_states: [
    {"name"=>"西部", "value"=>"seibu"}, {"name"=>"北部", "value"=>"hokubu"}, {"name"=>"南部", "value"=>"toubu"}
  ], supplement_state: 'enabled'

save_page route: "image_map/page", filename: "map_clickable/page1.html", name: "西部",
  layout_id: @layouts["category-middle"].id, coords: [60, 228, 211, 302],
  link_url: '/shisei/gaiyo/seibu.html', area_state: 'seibu',
  group_ids: [@g_seisaku.id]

save_page route: "image_map/page", filename: "map_clickable/page2.html", name: "北部",
  layout_id: @layouts["category-middle"].id, coords: [310, 292, 463, 370],
  link_url: '/shisei/gaiyo/hokubu.html', area_state: 'hokubu',
  group_ids: [@g_seisaku.id]

save_page route: "image_map/page", filename: "map_clickable/page3.html", name: "南部",
  layout_id: @layouts["category-middle"].id, coords: [139, 449, 292, 526],
  link_url: '/shisei/gaiyo/naubu.html ', area_state: 'naubu',
  group_ids: [@g_seisaku.id]
