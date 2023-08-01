puts "# anpi"

def save_board_anpi_post(data)
  puts data[:name]
  cond = { site_id: @site._id, member_id: data[:member_id] }
  item = Board::AnpiPost.find_or_create_by(cond)
  item.attributes = data
  item.save

  item
end

save_board_anpi_post member_id: @member_1.id, name: @member_1.name, kana: @member_1.kana, tel: @member_1.tel,
  addr: @member_1.addr, sex: @member_1.sex, age: @member_1.age, email: @member_1.email,
  text: "立川の避難所に花子と一緒に居ます。\r\n私も花子も無事です。", public_scope: "public",
  point: { "loc" => [35.712948784, 139.399852752], "zoom_level" => 11 }
save_board_anpi_post member_id: @member_2.id, name: @member_2.name, kana: @member_2.kana, tel: @member_2.tel,
  addr: @member_2.addr, sex: @member_2.sex, age: @member_2.age, email: @member_2.email,
  text: "主人と一緒に必死で立川の避難所まで避難してきました。", public_scope: "public",
  point: { "loc" => [35.713576996, 139.407887933], "zoom_level" => 11 }

puts "# cms pages"
save_page route: "cms/page", filename: "index.html", name: "自治体サンプル", layout_id: @layouts["top"].id
save_page route: "cms/page", filename: "mobile.html", name: "スマートフォン・携帯サイト", layout_id: @layouts["pages"].id
save_page route: "cms/page", filename: "use/index.html", name: "ご利用案内", layout_id: @layouts["general"].id
save_page route: "cms/page", filename: "404.html", name: "お探しのページは見つかりません。 404 Not Found", layout_id: @layouts["general"].id
save_page route: "cms/page", filename: "shisei/soshiki/index.html", name: "組織案内", layout_id: @layouts["category-middle"].id
