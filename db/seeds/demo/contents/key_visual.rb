puts "# key-visual"
keyvisual1 = save_ss_files "ss_files/key-visual/keyvisual01.jpg", filename: "keyvisual01.jpg",
  model: "key_visual/image"
keyvisual2 = save_ss_files "ss_files/key-visual/keyvisual02.jpg", filename: "keyvisual02.jpg",
  model: "key_visual/image"
keyvisual3 = save_ss_files "ss_files/key-visual/keyvisual03.jpg", filename: "keyvisual03.jpg",
  model: "key_visual/image"
keyvisual4 = save_ss_files "ss_files/key-visual/keyvisual04.jpg", filename: "keyvisual04.jpg",
  model: "key_visual/image"
keyvisual5 = save_ss_files "ss_files/key-visual/keyvisual05.jpg", filename: "keyvisual05.jpg",
  model: "key_visual/image"
keyvisual6 = save_ss_files "ss_files/key-visual/keyvisual06.png", filename: "keyvisual06.png",
  model: "key_visual/image"
keyvisual7 = save_ss_files "ss_files/key-visual/keyvisual07.png", filename: "keyvisual07.png",
  model: "key_visual/image"
keyvisual8 = save_ss_files "ss_files/key-visual/keyvisual08.png", filename: "keyvisual08.png",
  model: "key_visual/image"
save_page route: "key_visual/image", filename: "key-visual/page51.html", name: "しらさぎマラソン", order: 10,
  display_remarks: %w(title remark_html), remark_html: '<div class="remark">イベント</div>',
  file_id: keyvisual6.id, released_type: 'same_as_updated'
save_page route: "key_visual/image", filename: "key-visual/page52.html", name: "スマート窓口申請", order: 20,
  display_remarks: %w(title remark_html), remark_html: '<div class="remark">お知らせ</div>',
  file_id: keyvisual7.id, released_type: 'same_as_updated'
save_page route: "key_visual/image", filename: "key-visual/page53.html", name: "しらさぎ市公式LINE", order: 30,
  display_remarks: %w(title remark_html), remark_html: '<div class="remark">お知らせ</div>',
  file_id: keyvisual8.id, released_type: 'same_as_updated'
save_page route: "key_visual/image", filename: "key-visual/page37.html", name: "しらさぎ市のアジサイ", order: 40,
  display_remarks: %w(title remark_html), remark_html: '<div class="remark">観光</div>',
  file_id: keyvisual1.id, released_type: 'same_as_updated', state: "closed"
save_page route: "key_visual/image", filename: "key-visual/page38.html", name: "しらさぎ橋", order: 50,
  display_remarks: %w(title remark_html), remark_html: '<div class="remark">観光</div>',
  file_id: keyvisual2.id, released_type: 'same_as_updated', state: "closed"
save_page route: "key_visual/image", filename: "key-visual/page39.html", name: "梅雨のイベント", order: 60,
  display_remarks: %w(title remark_html), remark_html: '<div class="remark">お知らせ</div>',
  file_id: keyvisual3.id, released_type: 'same_as_updated', state: "closed"
save_page route: "key_visual/image", filename: "key-visual/page40.html", name: "しらさぎ神社", order: 70,
  display_remarks: %w(title remark_html), remark_html: '<div class="remark">観光</div>',
  file_id: keyvisual4.id, released_type: 'same_as_updated', state: "closed"
save_page route: "key_visual/image", filename: "key-visual/page50.html", name: "しらさぎ公園", order: 80,
  display_remarks: %w(title remark_html), remark_html: '<div class="remark">観光</div>',
  file_id: keyvisual5.id, released_type: 'same_as_updated', state: "closed"
