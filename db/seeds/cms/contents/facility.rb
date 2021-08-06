puts "# facility"

Dir.glob "ss_files/facility/*.*" do |file|
  save_ss_files file, filename: File.basename(file), model: "facility/file"
end

array = SS::File.where(model: "facility/file").map { |m| [m.filename, m] }
facility_images = Hash[*array.flatten]

save_page route: "facility/image", filename: "institution/shisetsu/library/library.html", name: "シラサギ市立図書館",
          layout_id: @layouts["map"].id, image_id: facility_images["library.jpg"].id, order: 0
save_page route: "facility/image", filename: "institution/shisetsu/library/equipment.html", name: "設備",
          layout_id: @layouts["map"].id, image_id: facility_images["equipment.jpg"].id, order: 10
save_page route: "facility/map", filename: "institution/shisetsu/library/map.html", name: "地図",
          layout_id: @layouts["map"].id, map_points: [{ name: "シラサギ市立図書館", loc: [34.067035, 134.589971], text: "" }]

file1 = save_ss_files "ss_files/article/img.png", filename: "img1.jpg", name: "img.jpg", model: "ss/temp_file"
save_page route: "facility/notice", filename: "institution/shisetsu/library/page217.html", name: "シラサギ市立図書館の本の読み聞かせ",
          layout_id: @layouts["map"].id, form_id: @form.id,
          keywords: "シラサギ市立図書館", description: "サンプルサンプルサンプル",
          column_values: [
            @form_columns[0].value_type.new(column: @form_columns[0], file_id: file1.id, file_label: "メイン写真",
                                            image_html_type: "image"),
            @form_columns[1].value_type.new(column: @form_columns[1], value: "SHIRASAGIについての本の読み聞かせを実施します。"),
            @form_columns[2].value_type.new(column: @form_columns[2], value: "シラサギ市"),
            @form_columns[3].value_type.new(column: @form_columns[3], value: "シラサギ市立図書館メインホール"),
            @form_columns[4].value_type.new(column: @form_columns[4], value: "10:00~18:00"),
            @form_columns[5].value_type.new(column: @form_columns[5], value: "祝日"),
            @form_columns[6].value_type.new(column: @form_columns[6], value: "無料"),
            @form_columns[7].value_type.new(column: @form_columns[7], value: "000-0000-000"),
            @form_columns[8].value_type.new(column: @form_columns[8], value: "sample@example.jp"),
            @form_columns[9].value_type.new(column: @form_columns[9], link_url: "/institution/shisetsu/library/",
                                            link_label: "シラサギ")
          ],
          group_ids: [@g_seisaku.id]

values = [
  "本の借り方などについて",
  "本を借りる場合は、シラサギ私立図書館のパスポートカードを申請し、作成してください。\n本は自由に借りることができますが、１週間以内に返却をお願いいたします。\nまた、借りた本については、長く読めるよう、大事に扱うようお願いいたします",
  "館内での注意",
  "館内では、多くの方がご利用になられますので以下の点に注意し、施設をご利用ください。",
  [
    "館内では走らないようにお願いたします。",
    "大きな声で喋らないようにお願いたします。",
    "飲食は本が汚れてしまう可能性があるため、図書館内ではご遠慮ください、併設でフードコートがございますので、そちらをご利用ください。"
  ]
]
save_page route: "facility/notice", filename: "institution/shisetsu/library/page218.html", name: "当館のご利用について",
          layout_id: @layouts["map"].id, form_id: @form4.id,
          keywords: "シラサギ市立図書館", description: "サンプルサンプルサンプル",
          column_values: [
            @form_columns4[2].value_type.new(column: @form_columns4[2], head: "h2", text: values[0]),
            @form_columns4[1].value_type.new(column: @form_columns4[1], value: values[1]),
            @form_columns4[2].value_type.new(column: @form_columns4[2], head: "h2", text: values[2]),
            @form_columns4[0].value_type.new(column: @form_columns4[0], value: values[3]),
            @form_columns4[7].value_type.new(column: @form_columns4[7], lists: values[4])
          ],
          group_ids: [@g_seisaku.id]

puts "# ezine"
save_page route: "ezine/page", filename: "ezine/page36.html", name: "シラサギ市メールマガジン", completed: true,
          layout_id: @layouts["ezine"].id, html: "<p>シラサギ市メールマガジンを配信します。</p>\r\n",
          text: "シラサギ市メールマガジンを配信します。\r\n"

puts "# anpi-ezine"
anpi_text = File.read("pages/anpi-ezine/anpi/anpi37.text.txt") rescue nil
save_page route: "ezine/page", filename: "anpi-ezine/anpi/anpi37.html",
          name: "2011年03月11日 14時46分 ころ地震がありました", completed: true, layout_id: @layouts["ezine"].id,
          text: anpi_text
save_page route: "ezine/page", filename: "anpi-ezine/event/page38.html",
          name: "シラサギ市イベント情報 No.12", completed: true, layout_id: @layouts["ezine"].id,
          html: "<p>シラサギ市イベント情報を配信します。</p>\r\n",
          text: "シラサギ市イベント情報を配信します。\r\n"

