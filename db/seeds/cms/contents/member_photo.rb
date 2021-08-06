return if SS.config.cms.enable_lgwan
puts "# member_photo"

photo_page1 = save_page route: "member/photo", filename: "kanko-info/photo/page1.html", name: "観光地1",
                        member_id: @member_1.id,
                        layout_id: @layouts["kanko-info"].id,
                        map_points: [{ loc: [33.902679, 134.526215] }],
                        listable_state: "public",
                        slideable_state: "hide",
                        license_name: "not_free",
                        photo_category_ids: [@photo_c1.id],
                        photo_location_ids: [@photo_l3.id],
                        in_image: Fs::UploadedFile.create_from_file("ss_files/key_visual/keyvisual01.jpg")

photo_page2 = save_page route: "member/photo", filename: "kanko-info/photo/page2.html", name: "観光地2",
                        member_id: @member_1.id,
                        layout_id: @layouts["kanko-info"].id,
                        map_points: [{ loc: [33.729822, 134.538575] }],
                        listable_state: "public",
                        slideable_state: "public",
                        license_name: "not_free",
                        photo_category_ids: [@photo_c1.id, @photo_c2.id, @photo_c3.id, @photo_c4.id],
                        photo_location_ids: [@photo_l1.id, @photo_l2.id, @photo_l3.id, @photo_l4.id],
                        in_image: Fs::UploadedFile.create_from_file("ss_files/key_visual/keyvisual02.jpg")

photo_page3 = save_page route: "member/photo", filename: "kanko-info/photo/page3.html", name: "観光地3",
                        member_id: @member_1.id,
                        layout_id: @layouts["kanko-info"].id,
                        map_points: [{ loc: [33.839396, 134.450684] }],
                        listable_state: "public",
                        slideable_state: "public",
                        license_name: "not_free",
                        photo_category_ids: [@photo_c2.id, @photo_c3.id],
                        photo_location_ids: [@photo_l2.id, @photo_l3.id],
                        in_image: Fs::UploadedFile.create_from_file("ss_files/key_visual/keyvisual03.jpg")

photo_page4 = save_page route: "member/photo", filename: "kanko-info/photo/page4.html", name: "観光地4",
                        member_id: @member_1.id,
                        layout_id: @layouts["kanko-info"].id,
                        map_points: [{ loc: [33.946095, 134.088135] }],
                        listable_state: "public",
                        slideable_state: "public",
                        license_name: "not_free",
                        photo_category_ids: [@photo_c1.id, @photo_c2.id, @photo_c4.id],
                        photo_location_ids: [@photo_l1.id, @photo_l4.id],
                        in_image: Fs::UploadedFile.create_from_file("ss_files/key_visual/keyvisual04.jpg")

photo_page5 = save_page route: "member/photo", filename: "kanko-info/photo/page5.html", name: "観光地5",
                        member_id: @member_1.id,
                        layout_id: @layouts["kanko-info"].id,
                        map_points: [{ loc: [33.793757, 134.538575] }],
                        listable_state: "public",
                        slideable_state: "hide",
                        license_name: "not_free",
                        photo_category_ids: [@photo_c1.id, @photo_c2.id, @photo_c4.id],
                        photo_location_ids: [@photo_l3.id, @photo_l4.id],
                        in_image: Fs::UploadedFile.create_from_file("ss_files/key_visual/keyvisual05.jpg")

save_page route: "member/photo_spot", filename: "kanko-info/photo/spot/index.html", name: "スポット",
          layout_id: @layouts["kanko-info"].id,
          member_photo_ids: [photo_page1.id, photo_page2.id, photo_page3.id]
