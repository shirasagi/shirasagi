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

puts "# weather-xml"
