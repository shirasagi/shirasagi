puts "# LINE連携"

def create_delivery_category_selection(data)
  Cms::Line::DeliverCategory::Selection.create!(
    site_id: @site.id, name: data[:name], filename: data[:filename], order: data[:order], state: "public",
    _type: "Cms::Line::DeliverCategory::Selection", depth: 2, parent_id: data[:parent_id])
end

def create_deliver_condition(data)
  Cms::Line::DeliverCondition.create!(
    deliver_category_ids: data[:deliver_category_ids], name: data[:name],
    order: data[:order], site_id: @site.id, permission_level: 1
  )
end

def create_service_group(data)
  Cms::Line::Service::Group.create!(site_id: @site.id, name: "アクション", order: 0, state: "public")
end

def create_richmenu_menu(data)
  Cms::Line::Richmenu::Menu.create!(site_id: @site.id, name: data[:name], target: data[:target],
    area_size: data[:area_size], width: data[:width], height: data[:height], chat_bar_text: data[:chat_bar_text],
    group_id: data[:group_id], image_id: data[:image_id], in_areas: data[:in_areas])
end

def create_delivery_category(data)
  Cms::Line::DeliverCategory::Category.create!(site_id: @site.id, name: data[:name], filename: data[:filename],
    order: data[:order], state: "public", _type: "Cms::Line::DeliverCategory::Category", required: "optional",
    condition_state: "enabled", select_type: "select")
end

def create_message(data)
  Cms::Line::Message.create!(site_id: @site.id, group_ids: [3], name: data[:name],
    deliver_state: data[:deliver_state], state: "public", deliver_condition_state: data[:deliver_condition_state],
    deliver_condition_id: data[:deliver_condition_id], deliver_category_ids: data[:deliver_category_ids])
end

def create_page_template(data)
  Cms::Line::Template::Page.create!(site_id: @site.id, message_id: data[:message_id], name: data[:name],
    page_id: data[:page].id, _type: "Cms::Line::Template::Page", title: data[:page].name,
    summary: "#{data[:page].name}の記事になります。", thumb_state: data[:thumb_state])
end

def create_text_template(data)
  Cms::Line::Template::Text.create!(site_id: @site.id, message_id: data[:message_id], name: data[:name],
    text: data[:text], _type: "Cms::Line::Template::Text")
end

def init_image_template(data)
  Cms::Line::Template::Image.new(
    site_id: @site.id, message_id: data[:message_id], name: data[:name], _type: "Cms::Line::Template::Image"
  )
end

def create_deliver_plan(data)
  Cms::Line::DeliverPlan.create!(
    site_id: @site.id, name: data[:nmae],
    deliver_date: data[:deliver_date], state: data[:state], message_id: data[:message_id]
  )
end

def create_servive_chat(data)
  Cms::Line::Service::Hook::Chat.create!(
    site_id: @site.id, name: data[:name], action_type: data[:action_type], group_id: data[:group_id],
    action_data: data[:action_data], _type: data[:type], node_id: data[:node_id]
  )
end

def save_line_files(path, data)
  cond = {
    site_id: @site.id, filename: data[:filename], owner_item_id: data[:owner_item_id],
    owner_item_type: data[:owner_item_type], model: data[:model]
  }

  file = Fs::UploadedFile.create_from_file(path)
  item = SS::File.find_or_initialize_by(cond)
  return item if item.persisted?

  item.in_file = file
  if data[:name].present?
    name = data[:name]
    if !name.include?(".") && data[:filename].include?(".")
      name = "#{name}#{::File.extname(data[:filename])}"
    end
    item.name = name
  end
  item.save

  item
end

# LINE HUB
Cms::Node::LineHub.create!(
  site_id: @site.id, state: "public", name: "LINE HUB", filename: "receiver", depth: 1,
  released_type: "fixed", layout_id: 12, route: "cms/line_hub", view_route: "cms/line_hub"
)

# 配信カテゴリー
category1 = create_delivery_category(name: "年代", filename: "age", order: 10)
category2 = create_delivery_category(name: "性別", filename: "gender", order: 20)
category3 = create_delivery_category(name: "住居地域", filename: "area", order: 30)

# 配信カテゴリー セレクション
8.times do |n|
  n += 1
  case n
  when 1
    name = "20代未満"
  when 8
    name = "80代以上"
  else
    name = "#{n}0代"
  end

  create_delivery_category_selection(name: name, filename: "age/age#{n}", parent_id: category1.id, order: "#{n}0".to_i)
end

%w(男性 女性).each_with_index do |v, i|
  create_delivery_category_selection(name: v, filename: "age/age#{i + 1}", parent_id: category2.id, order: "#{i + 1}0".to_i)
end

%w(シラサギ町 クロサギ町 アオサギ町).each_with_index do |v, i|
  create_delivery_category_selection(name: v, filename: "area/area#{i + 1}", parent_id: category3.id, order: "#{i + 1}0".to_i)
end

# 配信条件
deliver_category_ids1 = []
deliver_category_ids2 = []
deliver_category_ids3 = []
deliver_category_ids1 << Cms::Line::DeliverCategory::Selection.find_by(name: "30代").id
deliver_category_ids2 << Cms::Line::DeliverCategory::Selection.find_by(name: "40代").id
deliver_category_ids3 << Cms::Line::DeliverCategory::Selection.find_by(name: "50代").id
deliver_category_ids1 << Cms::Line::DeliverCategory::Selection.find_by(name: "女性").id
deliver_category_ids2 << Cms::Line::DeliverCategory::Selection.find_by(name: "男性").id
deliver_category_ids3 << Cms::Line::DeliverCategory::Selection.find_by(name: "女性").id
deliver_category_ids1 << Cms::Line::DeliverCategory::Selection.find_by(name: "シラサギ町").id
deliver_category_ids2 << Cms::Line::DeliverCategory::Selection.find_by(name: "アオサギ町").id
deliver_category_ids3 << Cms::Line::DeliverCategory::Selection.find_by(name: "クロサギ町").id
develiver_condition1 = create_deliver_condition(deliver_category_ids: deliver_category_ids1, name: "配信条件１", order: 10)
develiver_condition2 = create_deliver_condition(deliver_category_ids: deliver_category_ids2, name: "配信条件２", order: 20)

# メッセージ
msg3 = create_message(
  deliver_state: "draft", deliver_category_ids: deliver_category_ids3,
  name: "メッセージ３", deliver_condition_state: "multicast_with_input_condition"
)
msg2 = create_message(
  name: "メッセージ２", deliver_condition_state: "multicast_with_registered_condition",
  deliver_condition_id: develiver_condition1.id, deliver_state: "draft"
)
msg1 = create_message(
  name: "メッセージ１", deliver_state: "draft", deliver_condition_state: "multicast_with_no_condition"
)

image_template = init_image_template(name: "画像テンプレート", message_id: msg3.id)
create_text_template(name: "画像・テキストテンプレート", message_id: msg3.id, text: "シラサギからのお知らせです。\r\nメッセージを入力します。")
create_text_template(name: "テキストテンプレート", message_id: msg2.id, text: "シラサギからのお知らせです。\r\nメッセージを入力します。")
create_page_template(name: "記事テンプレート", message_id: msg1.id, page: Article::Page.last, thumb_state: "none")

image = save_line_files(
  "ss_files/key_visual/small/keyvisual01.jpg", model: "cms/line/template/image", owner_item_id: image_template.id,
  name: "keyvisual01.jpg", filename: "keyvisual01.jpg", owner_item_type: "Cms::Line::Template::Image"
)
image_template.image_id = image.id
image_template.save!

date_time3 = DateTime.now + 10
date_time_japan3 = "#{date_time3.strftime("%Y/%m/%d %H:%M")} (#{I18n.t("date.abbr_day_names")[date_time3.wday]})"
create_deliver_plan(name: date_time_japan3, deliver_date: date_time3, state: "ready", message_id: msg3.id)

date_time1 = DateTime.now + 5
date_time_japan1 = "#{date_time1.strftime("%Y/%m/%d %H:%M")} (#{I18n.t("date.abbr_day_names")[date_time1.wday]})"
create_deliver_plan(name: date_time_japan1, deliver_date: date_time1, state: "ready", message_id: msg1.id)

# リッチメニュー グループ
richmenu_group = Cms::Line::Richmenu::Group.create(site_id: @site.id, name: "リッチメニュー ", state: "public")

# リッチメニュー画像
file = save_line_files(
  "ss_files/line/richmenu.png", filename: "richmenu.png",
  owner_item_type: "Cms::Line::Richmenu::Menu", model: "cms/line/richmenu/menu"
)

# リッチメニュー メニュー
richmenu_in_areas = [
  {"x"=>"16", "y"=>"15", "width"=>"252", "height"=>"219", "type"=>"uri", "uri"=>"https://#{@site.domain}"},
  {"x"=>"276", "y"=>"14", "width"=>"248", "height"=>"222", "type"=>"postback", "data"=>"チャットボット"},
  {"x"=>"533", "y"=>"14", "width"=>"251", "height"=>"221", "type"=>"uri", "uri"=>"https://#{@site.domain}/calendar"}
]
richmenu = create_richmenu_menu(
  site_id: @site.id, name: "シラサギリッチメニュー ", target: "default", area_size: 3, width: 800, height: 250,
  chat_bar_text: "shirasagi", group_id: richmenu_group.id, image_id: file.id, in_areas: richmenu_in_areas
)
file.owner_item_id = richmenu.id
file.save

# サービス
service_group = create_service_group(name: "アクション", order: 0, state: "public")
chat_node = Chat::Node::Bot.first
create_servive_chat(
  name: "チャットボット", order: 0, action_type: "postback", group_id: service_group.id,
  action_data: "チャットボット", type: "Cms::Line::Service::Hook::Chat", node_id: chat_node.id
)
