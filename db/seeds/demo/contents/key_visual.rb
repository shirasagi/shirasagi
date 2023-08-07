puts "# key_visual"
keyvisual1 = save_ss_files "ss_files/key_visual/keyvisual01.jpg", filename: "keyvisual01.jpg",
  model: "key_visual/image"
keyvisual2 = save_ss_files "ss_files/key_visual/keyvisual02.jpg", filename: "keyvisual02.jpg",
  model: "key_visual/image"
keyvisual3 = save_ss_files "ss_files/key_visual/keyvisual03.jpg", filename: "keyvisual03.jpg",
  model: "key_visual/image"
keyvisual4 = save_ss_files "ss_files/key_visual/keyvisual04.jpg", filename: "keyvisual04.jpg",
  model: "key_visual/image"
keyvisual5 = save_ss_files "ss_files/key_visual/keyvisual05.jpg", filename: "keyvisual05.jpg",
  model: "key_visual/image"
keyvisual1.set(state: "public")
keyvisual2.set(state: "public")
keyvisual3.set(state: "public")
keyvisual4.set(state: "public")
keyvisual5.set(state: "public")
save_page route: "key_visual/image", filename: "key_visual/page37.html", name: "キービジュアル1", order: 10,
  file_id: keyvisual1.id, released_type: 'same_as_updated'
save_page route: "key_visual/image", filename: "key_visual/page38.html", name: "キービジュアル2", order: 20,
  file_id: keyvisual2.id, released_type: 'same_as_updated'
save_page route: "key_visual/image", filename: "key_visual/page39.html", name: "キービジュアル3", order: 30,
  file_id: keyvisual3.id, released_type: 'same_as_updated'
save_page route: "key_visual/image", filename: "key_visual/page40.html", name: "キービジュアル4", order: 40,
  file_id: keyvisual4.id, released_type: 'same_as_updated'
save_page route: "key_visual/image", filename: "key_visual/page50.html", name: "キービジュアル5", order: 50,
  file_id: keyvisual5.id, released_type: 'same_as_updated'
