puts "# member_photo"

photo_page1 = save_page route: "member/photo", filename: "kanko-info/photo/page1.html", name: "観光地1",
  member_id: @member_1.id,
  layout_id: @layouts["kanko-info"].id,
  listable_state: "public",
  slideable_state: "public",
  slide_order: 10,
  license_name: "free",
  photo_category_ids: [@photo_c1.id],
  photo_location_ids: [@photo_l1.id, @photo_l3.id],
  in_image: Fs::UploadedFile.create_from_file("ss_files/key-visual/small/keyvisual01.jpg")

photo_page2 = save_page route: "member/photo", filename: "kanko-info/photo/page2.html", name: "観光地2",
  member_id: @member_1.id,
  layout_id: @layouts["kanko-info"].id,
  listable_state: "public",
  slideable_state: "public",
  slide_order: 20,
  license_name: "free",
  photo_category_ids: [@photo_c1.id, @photo_c2.id, @photo_c3.id, @photo_c4.id],
  photo_location_ids: [@photo_l1.id, @photo_l2.id, @photo_l3.id, @photo_l4.id],
  in_image: Fs::UploadedFile.create_from_file("ss_files/key-visual/small/keyvisual02.jpg")

photo_page3 = save_page route: "member/photo", filename: "kanko-info/photo/page3.html", name: "観光地3",
  member_id: @member_1.id,
  layout_id: @layouts["kanko-info"].id,
  listable_state: "public",
  slideable_state: "public",
  slide_order: 30,
  license_name: "free",
  photo_category_ids: [@photo_c2.id, @photo_c3.id],
  photo_location_ids: [@photo_l2.id, @photo_l3.id],
  in_image: Fs::UploadedFile.create_from_file("ss_files/key-visual/small/keyvisual03.jpg")

photo_page4 = save_page route: "member/photo", filename: "kanko-info/photo/page4.html", name: "観光地4",
  member_id: @member_1.id,
  layout_id: @layouts["kanko-info"].id,
  listable_state: "public",
  slideable_state: "public",
  slide_order: 40,
  license_name: "free",
  photo_category_ids: [@photo_c1.id, @photo_c2.id, @photo_c4.id],
  photo_location_ids: [@photo_l1.id, @photo_l4.id],
  in_image: Fs::UploadedFile.create_from_file("ss_files/key-visual/small/keyvisual04.jpg")

photo_page5 = save_page route: "member/photo", filename: "kanko-info/photo/page5.html", name: "観光地5",
  member_id: @member_1.id,
  layout_id: @layouts["kanko-info"].id,
  listable_state: "public",
  slideable_state: "public",
  slide_order: 50,
  license_name: "free",
  photo_category_ids: [@photo_c1.id, @photo_c2.id, @photo_c4.id],
  photo_location_ids: [@photo_l3.id, @photo_l4.id],
  in_image: Fs::UploadedFile.create_from_file("ss_files/key-visual/small/keyvisual05.jpg")

photo_page6 = save_page route: "member/photo", filename: "kanko-info/photo/page6.html", name: "観光地６",
  member_id: @member_1.id,
  layout_id: @layouts["kanko-info"].id,
  map_points: [{ loc: [134.566899, 34.074214] }],
  listable_state: "public",
  slideable_state: "closed",
  caption: 'シラサギ市民公園のあじさい',
  license_name: "not_free",
  photo_category_ids: [@photo_c2.id],
  photo_location_ids: [@photo_l2.id],
  in_image: Fs::UploadedFile.create_from_file("ss_files/key-visual/keyvisual01.jpg")

save_page route: "member/photo_spot", filename: "kanko-info/photo/spot/index.html", name: "スポット",
  layout_id: @layouts["kanko-info"].id,
  member_photo_ids: [photo_page1.id, photo_page2.id, photo_page3.id]
