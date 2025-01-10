puts "# LINE連携"

# 配信カテゴリー
def create_delivery_category(data)
  puts data[:name]

  cond = { site_id: @site.id, filename: data[:filename] }
  item = Cms::Line::DeliverCategory::Category.find_or_initialize_by(cond)
  item.attributes = data
  item.save!
  item
end

category1 = create_delivery_category name: "年代", filename: "age", order: 10,
  required: "optional", condition_state: "enabled", select_type: "select"
category2 = create_delivery_category name: "性別", filename: "gender", order: 20,
  required: "optional", condition_state: "enabled", select_type: "select"
category3 = create_delivery_category name: "住居地域", filename: "area", order: 30,
  required: "optional", condition_state: "enabled", select_type: "select"

# 配信カテゴリー 選択肢
def create_delivery_category_selection(data)
  puts data[:name]

  cond = { site_id: @site.id, filename: data[:filename] }
  item = Cms::Line::DeliverCategory::Selection.find_or_initialize_by(cond)
  item.attributes = data
  item.save!
  item
end

selections = []
%w(20代未満 30代 40代 50代 60代 70代 80代以上).each_with_index do |name, i|
  selections << create_delivery_category_selection(name: name, filename: "age/age#{i + 1}",
    parent: category1, order: (i + 1) * 10)
end
%w(男性 女性).each_with_index do |name, i|
  selections << create_delivery_category_selection(name: name, filename: "gender/gender#{i + 1}",
    parent: category2, order: (i + 1) * 10)
end
%w(シラサギ町 クロサギ町 アオサギ町).each_with_index do |name, i|
  selections << create_delivery_category_selection(name: name, filename: "area/area#{i + 1}",
    parent: category3, order: (i + 1) * 10)
end

# 配信条件
def create_deliver_condition(data)
  puts data[:name]

  cond = { site_id: @site.id, name: data[:name] }
  item = Cms::Line::DeliverCondition.find_or_initialize_by(cond)
  item.attributes = data
  item.save!
  item
end

deliver_category_ids1 = selections.select { |item| %w(30代 女性 シラサギ町).include?(item.name) }.map(&:id)
deliver_category_ids2 = selections.select { |item| %w(40代 男性 アオサギ町).include?(item.name) }.map(&:id)
deliver_category_ids3 = selections.select { |item| %w(50代 女性 クロサギ町).include?(item.name) }.map(&:id)
develiver_condition1 = create_deliver_condition name: "配信条件１", deliver_category_ids: deliver_category_ids1, order: 10
develiver_condition2 = create_deliver_condition name: "配信条件２", deliver_category_ids: deliver_category_ids2, order: 20

# メッセージ
def create_line_message(data)
  puts data[:name]

  cond = { site_id: @site.id, name: data[:name] }
  item = Cms::Line::Message.find_or_initialize_by(cond)
  item.attributes = data
  item.save!
  item
end

message7 = create_line_message name: "【削除禁止】JSONテンプレート_バブル",
  deliver_condition_state: "multicast_with_no_condition"
message6 = create_line_message name: "【削除禁止】JSONテンプレート_画像カルーセル_画像リンク1枚のみ",
  deliver_condition_state: "multicast_with_no_condition"
message5 = create_line_message name: "【削除禁止】JSONテンプレート_画像カルーセル",
  deliver_condition_state: "multicast_with_no_condition"
message4 = create_line_message name: "【削除禁止】JSONテンプレート_画像リンク1枚のみ",
  deliver_condition_state: "multicast_with_no_condition"
message3 = create_line_message name: "メッセージ３", deliver_condition_state: "multicast_with_input_condition",
  deliver_category_ids: deliver_category_ids3
message2 = create_line_message name: "メッセージ２", deliver_condition_state: "multicast_with_registered_condition",
  deliver_condition_id: develiver_condition1.id
message1 = create_line_message name: "メッセージ１", deliver_condition_state: "multicast_with_no_condition"

message1.templates.destroy_all
message2.templates.destroy_all
message3.templates.destroy_all
message4.templates.destroy_all
message5.templates.destroy_all
message6.templates.destroy_all
message7.templates.destroy_all

# テンプレート
def create_line_template_image(message, data)
  item = Cms::Line::Template::Image.new
  item.cur_site = @site
  item.message = message
  item.attributes = data
  item.save!
  item
end

def create_line_template_text(message, data)
  item = Cms::Line::Template::Text.new
  item.cur_site = @site
  item.message = message
  item.attributes = data
  item.save!
  item
end

def create_line_template_page(message, page, data)
  item = Cms::Line::Template::Page.new
  item.cur_site = @site
  item.message = message
  item.page = page
  item.attributes = data
  item.save!
  item
end

def create_line_template_json(message, json_path)
  item = Cms::Line::Template::JsonBody.new
  item.cur_site = @site
  item.message = message
  item.json_body = ::File.read(::File.join("line_template_json", json_path))
  item.save!
  item
end

page = Article::Page.site(@site).last
image = save_ss_files "ss_files/key-visual/keyvisual05.jpg", filename: "keyvisual05.jpg", model: "cms/line/template/image"
create_line_template_page message1, page, title: page.try(:name), summary: "メッセージを入力します。", thumb_state: "none"
create_line_template_text message2, text: "シラサギからのお知らせです。\r\nメッセージを入力します。"
create_line_template_image message3, name: "画像テンプレート", image: image
create_line_template_text message3, name: "テキストテンプレート", text: "シラサギからのお知らせです。\r\nメッセージを入力します。"
create_line_template_json message4, "image.json"
create_line_template_json message5, "carousel1.json"
create_line_template_json message6, "carousel2.json"
create_line_template_json message7, "bubble.json"

# リッチメニュー
def create_richmenu_group(data)
  puts data[:name]

  cond = { site_id: @site.id, name: data[:name] }
  item = Cms::Line::Richmenu::Group.find_or_initialize_by(cond)
  item.attributes = data
  item.save!
  item
end

def create_richmenu_menu(richmenu_group, data)
  puts data[:name]

  item = Cms::Line::Richmenu::Menu.new
  item.cur_site = @site
  item.group = richmenu_group
  item.attributes = data
  item.save!
  item
end

richmenu_group = create_richmenu_group name: "リッチメニュー", state: "public"
richmenu_group.menus.destroy_all

image = Fs::UploadedFile.create_from_file("ss_files/line/richmenu.png")
richmenu_in_areas = [
  { x: "16", y: "15", width: "252", height: "219", type: "uri", uri: @site.full_url },
  { x: "276", y: "14", width: "248", height: "222", type: "postback", data: "チャットボット"},
  { x: "533", y: "14", width: "251", height: "221", type: "uri", uri: ::File.join(@site.full_url, "calendar") }
]
richmenu = create_richmenu_menu richmenu_group,
  name: "シラサギリッチメニュー ", target: "default",
  area_size: 3, width: 800, height: 250, chat_bar_text: "shirasagi",
  in_image: image, in_areas: richmenu_in_areas

# サービス
def create_service_group(data)
  puts data[:name]

  cond = { site_id: @site.id, name: data[:name] }
  item = Cms::Line::Service::Group.find_or_initialize_by(cond)
  item.attributes = data
  item.save!
  item
end

def create_servive_chat(service_group, chat_node, data)
  puts data[:name]

  item = Cms::Line::Service::Hook::Chat.new
  item.cur_site = @site
  item.group = service_group
  item.node = chat_node
  item.attributes = data
  item.save!
  item
end

service_group = create_service_group name: "アクション", state: "public"
service_group.hooks.destroy_all

chat_node = Chat::Node::Bot.site(@site).first
create_servive_chat service_group, chat_node, name: "チャットボット",
  action_type: "postback", action_data: "チャットボット"
