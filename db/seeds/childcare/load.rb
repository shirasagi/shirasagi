## -------------------------------------
# Require

puts "Please input site_name: site=[site_host]" or exit if ENV['site'].blank?

@site = SS::Site.where(host: ENV['site']).first
puts "Site not found: #{ENV['site']}" or exit unless @site

require "#{Rails.root}/db/seeds/cms/users"
require "#{Rails.root}/db/seeds/cms/workflow"

Dir.chdir @root = File.dirname(__FILE__)

## -------------------------------------
puts "# files"

Dir.glob "files/**/*.*" do |file|
  puts name = file.sub(/^files\//, "")
  Fs.binwrite "#{@site.path}/#{name}", File.binread(file)
end

def save_ss_files(path, data)
  puts path
  cond = { site_id: @site._id, filename: data[:filename], model: data[:model] }

  file = Fs::UploadedFile.create_from_file(path)
  file.original_filename = data[:filename] if data[:filename].present?

  item = SS::File.find_or_create_by(cond)
  item.in_file = file
  item.update

  item
end

## -------------------------------------
puts "# layouts"

def save_layout(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }
  html = File.read("layouts/" + data[:filename]) rescue nil

  item = Cms::Layout.find_or_create_by(cond)
  item.attributes = data.merge html: html
  item.update
  item.add_to_set group_ids: @site.group_ids

  item
end

save_layout filename: "docs.layout.html", name: "記事ページ",
  css_paths: %w(/css/style.css),
  js_paths: %w(/js/common.js /js/flexibility.js /js/heightLine.js /js/selectivizr.js /js/html5shiv.js),
  part_paths: %w(
    tool.part.html head.part.html navi.part.html
    breadcrumbs.part.html sns.part.html news/recent.part.html
    purpose/birth/folder.html age/zero/folder.part.html sub-menu/banner.part.html
    pagetop.part.html foot.part.html
    )
save_layout filename: "event-page.layout.html", name: "イベントページ",
  css_paths: %w(/css/style.css),
  js_paths: %w(/js/common.js /js/flexibility.js /js/heightLine.js /js/selectivizr.js /js/html5shiv.js),
  part_paths: %w(
    tool.part.html head.part.html navi.part.html
    breadcrumbs.part.html event/calendar.part.html purpose/birth/folder.html
    age/zero/folder.part.html sub-menu/banner.part.html pagetop.part.html foot.part.html
    )
save_layout filename: "event.layout.html", name: "イベントカレンダー",
  css_paths: %w(/css/style.css),
  js_paths: %w(/js/common.js /js/flexibility.js /js/heightLine.js /js/selectivizr.js /js/html5shiv.js),
  part_paths: %w(
    tool.part.html head.part.html navi.part.html
    breadcrumbs.part.html event/calendar.part.html purpose/birth/folder.html
    age/zero/folder.part.html sub-menu/banner.part.html pagetop.part.html foot.part.html
    )
save_layout filename: "faq-top.layout.html", name: "よくある質問：トップ",
  css_paths: %w(/css/style.css),
  js_paths: %w(/js/common.js /js/flexibility.js /js/heightLine.js /js/selectivizr.js /js/html5shiv.js),
  part_paths: %w(
    tool.part.html head.part.html navi.part.html
    breadcrumbs.part.html faq/search/search.part.html faq/docs/recent.part.html
    purpose/birth/folder.html age/zero/folder.part.html sub-menu/banner.part.html
    pagetop.part.html foot.part.html
    )
save_layout filename: "faq.layout.html", name: "よくある質問",
  css_paths: %w(/css/style.css),
  js_paths: %w(/js/common.js /js/flexibility.js /js/heightLine.js /js/selectivizr.js /js/html5shiv.js),
  part_paths: %w(
    tool.part.html head.part.html navi.part.html
    breadcrumbs.part.html sns.part.html faq/docs/recent.part.html
    purpose/birth/folder.html age/zero/folder.part.html sub-menu/banner.part.html
    pagetop.part.html foot.part.html
    )
save_layout filename: "folder.layout.html", name: "フォルダーリスト",
  css_paths: %w(/css/style.css),
  js_paths: %w(/js/common.js /js/flexibility.js /js/heightLine.js /js/selectivizr.js /js/html5shiv.js),
  part_paths: %w(
    tool.part.html head.part.html navi.part.html
    breadcrumbs.part.html purpose/birth/folder.html age/zero/folder.part.html
    sub-menu/banner.part.html pagetop.part.html foot.part.html
    )
save_layout filename: "general.layout.html", name: "汎用ページ",
  css_paths: %w(/css/style.css),
  js_paths: %w(/js/common.js /js/flexibility.js /js/heightLine.js /js/selectivizr.js /js/html5shiv.js),
  part_paths: %w(
    tool.part.html head.part.html navi.part.html
    breadcrumbs.part.html sns.part.html purpose/birth/folder.html
    age/zero/folder.part.html sub-menu/banner.part.html pagetop.part.html
    foot.part.html
    )
save_layout filename: "institution-page.layout.html", name: "施設情報：施設",
  css_paths: %w(/css/style.css),
  js_paths: %w(/js/common.js /js/flexibility.js /js/heightLine.js /js/selectivizr.js /js/html5shiv.js),
  part_paths: %w(
    tool.part.html head.part.html navi.part.html
    breadcrumbs.part.html institution/type/nursery/folder.part.html purpose/birth/folder.part.html
    age/zero/folder.part.html sub-menu/banner.part.html pagetop.part.html
    foot.part.html
    )
save_layout filename: "institution.layout.html", name: "施設情報",
  css_paths: %w(/css/style.css),
  js_paths: %w(/js/common.js /js/flexibility.js /js/heightLine.js /js/selectivizr.js /js/html5shiv.js),
  part_paths: %w(
    tool.part.html head.part.html navi.part.html
    breadcrumbs.part.html institution/type/nursery/folder.part.html purpose/birth/folder.part.html
    age/zero/folder.part.html sub-menu/banner.part.html pagetop.part.html
    foot.part.html
    )
save_layout filename: "page.layout.html", name: "固定ページ",
  css_paths: %w(/css/style.css),
  js_paths: %w(/js/common.js /js/flexibility.js /js/heightLine.js /js/selectivizr.js /js/html5shiv.js),
  part_paths: %w(
    tool.part.html head.part.html navi.part.html
    breadcrumbs.part.html sns.part.html pages.part.html
    purpose/birth/folder.part.html age/zero/folder.part.html sub-menu/banner.part.html
    pagetop.part.html foot.part.html
    )
save_layout filename: "pages.layout.html", name: "ページリスト",
  css_paths: %w(/css/style.css),
  js_paths: %w(/js/common.js /js/flexibility.js /js/heightLine.js /js/selectivizr.js /js/html5shiv.js),
  part_paths: %w(
    tool.part.html head.part.html navi.part.html
    breadcrumbs.part.html category.part.html purpose/birth/folder.part.html
    age/zero/folder.part.html sub-menu/banner.part.html pagetop.part.html
    foot.part.html
    )
save_layout filename: "top.layout.html", name: "トップページ",
  css_paths: %w(/css/style.css),
  js_paths: %w(/js/common.js /js/flexibility.js /js/heightLine.js /js/selectivizr.js /js/html5shiv.js),
  part_paths: %w(
    tool.part.html head.part.html navi.part.html
    slide/slide.part.html purpose/birth/folder.part age/zero/folder.part.html
    news/recent.part.html sub-menu/banner.part.html topics/recent.part.html
    event/calendar.part.html relation/banner.part.html add/banner.part.html
    pagetop.part.html foot.part.html
    )

array   = Cms::Layout.where(site_id: @site._id).map { |m| [m.filename.sub(/\..*/, ""), m] }
layouts = Hash[*array.flatten]

## -------------------------------------
puts "# parts"

def save_part(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }

  html = File.read("parts/" + data[:filename]) rescue nil
  upper_html = File.read("parts/" + data[:filename].sub(/\.html$/, ".upper_html")) rescue nil
  loop_html  = File.read("parts/" + data[:filename].sub(/\.html$/, ".loop_html")) rescue nil
  lower_html = File.read("parts/" + data[:filename].sub(/\.html$/, ".lower_html")) rescue nil

  item = Cms::Part.unscoped.find_or_create_by(cond).becomes_with_route(data[:route])
  item.html = html if html
  item.upper_html = upper_html if upper_html
  item.loop_html = loop_html if loop_html
  item.lower_html = lower_html if lower_html

  item.attributes = data
  item.update
  item.add_to_set group_ids: @site.group_ids

  item
end

save_part route: "cms/crumb", filename: "breadcrumbs.part.html", name: "パンくず",
  home_label: "トップ", mobile_view: "hide"
save_part route: "category/node", filename: "category.part.html", name: "カテゴリーリスト",
  sort: "order", mobile_view: "hide"
save_part route: "cms/free", filename: "foot.part.html", name: "フッター"
save_part route: "cms/free", filename: "head.part.html", name: "ヘッダー"
save_part route: "cms/free", filename: "head-top.part.html", name: "ヘッダー：トップ"
save_part route: "cms/free", filename: "navi.part.html", name: "グローバルメニュー"
save_part route: "cms/free", filename: "normal.part.html", name: "標準機能"
save_part route: "cms/page", filename: "pages.part.html", name: "ページリスト",
  conditions: %w(#{request_dir})
save_part route: "cms/free", filename: "pagetop.part.html", name: "ページトップ"
save_part route: "cms/sns_share", filename: "sns.part.html", name: "SNS",
  mobile_view: "hide"
save_part route: "cms/tabs", filename: "tabs.part.html", name: "新着タブ",
  conditions: %w(news topics know), limit: 10
save_part route: "cms/free", filename: "tool.part.html", name: "アクセシビリティツール",
  mobile_view: "hide"
save_part route: "ads/banner", filename: "add/banner.part.html", name: "バナー",
  link_action: "direct", sort: "order", mobile_view: "hide"
save_part route: "cms/node", filename: "age/zero/folder.part.html", name: "フォルダーリスト",
  sort: "order", limit: 100
save_part route: "event/calendar", filename: "event/calendar.part.html", name: "カレンダー",
  mobile_view: "hide"
save_part route: "cms/page", filename: "faq/docs/recent.part.html", name: "ページリスト"
save_part route: "faq/search", filename: "faq/search/search.part.html", name: "よくある質問検索",
  mobile_view: "hide"
save_part route: "cms/node", filename: "institution/type/nursery/folder.part.html", name: "フォルダーリスト",
  sort: "order", limit: 100
save_part route: "article/page", filename: "news/recent.part.html", name: "記事リスト",
  sort: "order", limit: 5
save_part route: "cms/node", filename: "purpose/birth/folder.part.html", name: "フォルダーリスト",
  sort: "order", limit: 100
save_part route: "ads/banner", filename: "relation/banner.part.html", name: "バナー",
  link_action: "direct", sort: "order", mobile_view: "hide"
save_part route: "key_visual/slide", filename: "slide/slide.part.html", name: "スライドショー",
  mobile_view: "hide"
save_part route: "ads/banner", filename: "sub-menu/banner.part.html", name: "バナー",
  link_action: "direct", sort: "order", mobile_view: "hide"
save_part route: "cms/page", filename: "topics/recent.part.html", name: "ページリスト", limit: 1

## -------------------------------------
puts "# nodes"

def save_node(data)
  puts data[:name]
  klass = data[:route].sub("/", "/node/").singularize.camelize.constantize
  cond = { site_id: @site._id, filename: data[:filename] }

  upper_html = File.read("nodes/" + data[:filename] + ".upper_html") rescue nil
  loop_html  = File.read("nodes/" + data[:filename] + ".loop_html") rescue nil
  lower_html = File.read("nodes/" + data[:filename] + ".lower_html") rescue nil
  summary_html = File.read("nodes/" + data[:filename] + ".summary_html") rescue nil

  item = Cms::Node.unscoped.find_or_create_by(cond).becomes_with_route(data[:route])
  item.upper_html = upper_html if upper_html
  item.loop_html = loop_html if loop_html
  item.lower_html = lower_html if lower_html
  item.summary_html = summary_html if summary_html

  item.attributes = data
  item.update
  item.add_to_set group_ids: @site.group_ids

  item
end

## uploader
save_node route: "uploader/file", name: "CSS", filename: "css"
save_node route: "uploader/file", name: "画像", filename: "img"
save_node route: "uploader/file", name: "JavaScript", filename: "js"

## category
save_node route: "category/node", name: "知りたい", filename: "know",
  layout_id: layouts["folder"].id, sort: "order", limit: 100, order: 10
save_node route: "category/page", name: "相談したい", filename: "consultation",
 layout_id: layouts["folder"].id, sort: "order", limit: 100, order: 20
save_node route: "category/page", name: "つながりたい", filename: "lead",
  layout_id: layouts["folder"].id, sort: "order", limit: 100, order: 30
save_node route: "category/node", name: "目的で探す", filename: "purpose",
  layout_id: layouts["folder"].id, sort: "order", limit: 100, order: 40
save_node route: "category/node", name: "年齢で探す", filename: "age",
  layout_id: layouts["folder"].id, sort: "order", limit: 50, order: 50
save_node route: "category/page", name: "新着情報", filename: "news",
  layout_id: layouts["folder"].id, sort: "order", limit: 50, order: 70
save_node route: "category/page", name: "トピックス", filename: "topics",
  layout_id: layouts["folder"].id, sort: "order", limit: 50, order: 80
save_node route: "category/node", name: "よくある質問", filename: "faq",
  layout_id: layouts["faq-top"].id, sort: "order", limit: 100, order: 110

save_node route: "category/page", name: "妊娠・出産", filename: "know/pregnancy",
  layout_id: layouts["pages"].id, sort: "order", limit: 50, order: 10
save_node route: "category/node", name: "健康・医療", filename: "know/health",
  layout_id: layouts["pages"].id, sort: "order", limit: 50, order: 20
save_node route: "category/page", name: "手当・助成", filename: "know/grant",
  layout_id: layouts["pages"].id, sort: "order", limit: 50, order: 30
save_node route: "category/page", name: "保育園・幼稚園", filename: "know/nursery",
  layout_id: layouts["pages"].id, sort: "order", limit: 50, order: 40
save_node route: "category/page", name: "一時保育・託児サービス", filename: "know/child",
  layout_id: layouts["pages"].id, sort: "order", limit: 50, order: 50
save_node route: "category/page", name: "小学校・中学校", filename: "know/primary",
  layout_id: layouts["pages"].id, sort: "order", limit: 50, order: 60
save_node route: "category/page", name: "子どもの安全", filename: "know/saftey",
  layout_id: layouts["pages"].id, sort: "order", limit: 50, order: 70
save_node route: "category/page", name: "引っ越し", filename: "know/moving",
  layout_id: layouts["pages"].id, sort: "order", limit: 50, order: 80

save_node route: "category/page", name: "妊娠中", filename: "age/pregnancy",
  layout_id: layouts["folder"].id, sort: "order", limit: 50, order: 10
save_node route: "category/page", name: "0歳児(赤ちゃん)", filename: "age/zero",
  layout_id: layouts["folder"].id, sort: "order", limit: 50, order: 20
save_node route: "category/page", name: "1～2歳児", filename: "age/one",
  layout_id: layouts["folder"].id, sort: "order", limit: 50, order: 30
save_node route: "category/page", name: "3～5歳児", filename: "age/three",
  layout_id: layouts["folder"].id, sort: "order", limit: 50, order: 40
save_node route: "category/page", name: "小学生から", filename: "age/primary",
  layout_id: layouts["folder"].id, sort: "order", limit: 50, order: 50

save_node route: "category/page", name: "妊娠・出産", filename: "purpose/birth",
  layout_id: layouts["folder"].id, sort: "order", limit: 50, order: 10
save_node route: "category/page", name: "子育てサークル", filename: "purpose/circle",
  layout_id: layouts["folder"].id, sort: "order", limit: 50, order: 50
save_node route: "category/page", name: "子どもの健康", filename: "purpose/health",
  layout_id: layouts["folder"].id, sort: "order", limit: 50, order: 20
save_node route: "category/page", name: "子どもを預ける", filename: "purpose/leave",
  layout_id: layouts["folder"].id, sort: "order", limit: 50, order: 30
save_node route: "category/page", name: "仕事と子育て", filename: "purpose/work",
  layout_id: layouts["folder"].id, sort: "order", limit: 50, order: 40

save_node route: "category/page", name: "子どもを預ける", filename: "faq/leave",
  layout_id: layouts["pages"].id, sort: "order", limit: 50
save_node route: "category/page", name: "子育ての悩み", filename: "faq/trouble",
  layout_id: layouts["pages"].id, sort: "order", limit: 50
save_node route: "category/page", name: "出産", filename: "faq/birth",
  layout_id: layouts["pages"].id, sort: "order", limit: 50

save_node route: "category/page", name: "遊ぶ", filename: "event/play",
  layout_id: layouts["event"].id, sort: "order", limit: 50, order: 10
save_node route: "category/page", name: "学ぶ", filename: "event/study",
  layout_id: layouts["event"].id, sort: "order", limit: 50, order: 20
save_node route: "category/page", name: "相談", filename: "event/info",
  layout_id: layouts["event"].id, sort: "order", limit: 50, order: 30

array = Category::Node::Base.where(site_id: @site._id).map { |m| [m.filename, m] }
categories = Hash[*array.flatten]

## article
save_node route: "article/page", filename: "docs", name: "記事", shortcut: "show",
  layout_id: layouts["folder"].id, sort: "order", limit: 50, order: 60

## faq
save_node route: "faq/page", filename: "faq/docs", name: "よくある質問記事", shortcut: "show",
  st_category_ids: [categories["faq"].id], layout_id: layouts["folder"].id, limit: 50, order: 110
save_node route: "faq/search", filename: "faq/search", name: "よくある質問検索",
  st_category_ids: [categories["faq"].id], layout_id: layouts["folder"].id, limit: 100

## event
save_node route: "event/page", filename: "event", name: "イベント情報",
  layout_id: layouts["event"].id, page_layout_id: layouts["event-page"].id, order: 35,
  st_category_ids: [categories["event/info"].id, categories["event/play"].id, categories["event/study"].id]

## ads
save_node route: "ads/banner", filename: "add", name: "広告バナー"
save_node route: "ads/banner", filename: "relation", name: "関連サイト"
save_node route: "ads/banner", filename: "sub-menu", name: "サブメニュー"

## sitemap
save_node route: "sitemap/page", filename: "sitemap", name: "サイトマップ",
  layout_id: layouts["folder"].id, order: 1000

## key_visual
save_node route: "key_visual/image", filename: "slide", name: "スライドショー管理"

## facility
facility_locations  = []
facility_categories = []
facility_services   = []

save_node route: "cms/node", filename: "institution/area", name: "施設のある地域",
  layout_id: layouts["institution"].id, sort: "order", order: 100
save_node route: "cms/node", filename: "institution/type", name: "施設の種類",
  layout_id: layouts["institution"].id, sort: "order", order: 100
save_node route: "cms/node", filename: "institution/use", name: "施設の用途",
  layout_id: layouts["institution"].id, sort: "order", order: 100

center_point_1 = Map::Extensions::Point.mongoize(loc: [34.075593, 134.550614], zoom_level: 10)
center_point_2 = Map::Extensions::Point.mongoize(loc: [34.034417, 133.808902], zoom_level: 10)
center_point_3 = Map::Extensions::Point.mongoize(loc: [33.609123, 134.352387], zoom_level: 10)
center_point_4 = Map::Extensions::Point.mongoize(loc: [34.179472, 134.608579], zoom_level: 10)

node = save_node route: "facility/location", filename: "institution/area/east",
  name: "東区", layout_id: layouts["institution"].id, order: 10, center_point: center_point_1
facility_locations << node
node = save_node route: "facility/location", filename: "institution/area/south",
  name: "西区", layout_id: layouts["institution"].id, order: 20, center_point: center_point_2
facility_locations << node
node = save_node route: "facility/location", filename: "institution/area/west",
  name: "南区", layout_id: layouts["institution"].id, order: 30, center_point: center_point_3
facility_locations << node
node = save_node route: "facility/location", filename: "institution/area/north",
  name: "北区", layout_id: layouts["institution"].id, order: 40, center_point: center_point_4
facility_locations << node

node = save_node route: "facility/category", filename: "institution/type/kindergarten",
  name: "幼稚園", layout_id: layouts["institution"].id, order: 10
facility_categories << node
node = save_node route: "facility/category", filename: "institution/type/nursery",
  name: "保育所", layout_id: layouts["institution"].id, order: 20
facility_categories << node
node = save_node route: "facility/category", filename: "institution/type/primary",
  name: "小学校", layout_id: layouts["institution"].id, order: 30
facility_categories << node

node = save_node route: "facility/service", filename: "institution/use/leave",
  name: "預ける", layout_id: layouts["institution"].id, order: 10
facility_services << node
node = save_node route: "facility/service", filename: "institution/use/leave",
  name: "預ける", layout_id: layouts["institution"].id, order: 10
facility_services << node
node = save_node route: "facility/service", filename: "institution/use/play",
  name: "遊ぶ", layout_id: layouts["institution"].id, order: 20
facility_services << node
node = save_node route: "facility/service", filename: "institution/use/study",
  name: "学ぶ", layout_id: layouts["institution"].id, order: 30
facility_services << node

save_node route: "facility/search", filename: "institution", name: "施設情報", order: 37,
  layout_id: layouts["institution"].id,
  st_category_ids: facility_categories.map(&:id),
  st_location_ids: facility_locations.map(&:id),
  st_service_ids: facility_services.map(&:id)

save_node route: "facility/node", filename: "institution/list", name: "施設一覧",
  layout_id: layouts["institution"].id,
  st_category_ids: facility_categories.map(&:id),
  st_location_ids: facility_locations.map(&:id),
  st_service_ids: facility_services.map(&:id),
  shortcut: "show"

save_node route: "facility/page", filename: "institution/list/shirsagi", name: "シラサギ学園",
  layout_id: layouts["institution-page"].id,
  kana: "しらさぎがくえん",
  postcode: "000-0000",
  address: "大鷺県シラサギ市小鷺町1丁目1番地1号",
  tel: "00-0000-0000",
  fax: "00-0000-0000",
  related_url: "http://demo.ss-proj.org/",
  category_ids: facility_categories.map(&:id),
  location_ids: facility_locations.map(&:id),
  service_ids: facility_services.map(&:id)

inquiry_html = File.read("nodes/inquiry.inquiry_html") rescue nil
inquiry_sent_html = File.read("nodes/inquiry.inquiry_sent_html") rescue nil
inquiry_node = save_node route: "inquiry/form", filename: "inquiry", name: "お問い合わせ",
  layout_id: layouts["folder"].id,
  inquiry_captcha: "enabled",
  notice_state: "disabled",
  notice_content: "link_only",
  inquiry_html: inquiry_html,
  inquiry_sent_html: inquiry_sent_html,
  reply_state: "disabled",
  reply_subject: "子育て支援サイトへのお問い合わせを受け付けました。",
  reply_upper_text: "お問い合わせを受け付けました。",
  aggregation_state: "disabled",
  shortcut: "show", order: 90

def save_inquiry_column(data)
  puts data[:name]
  cond = { site_id: data[:site_id], node_id: data[:node_id], name: data[:name] }

  item = Inquiry::Column.find_or_create_by(cond)
  item.attributes = data
  item.update

  item
end

def save_inquiry_answer(data)
  item = Inquiry::Answer.new
  item.set_data(data[:data])
  data.delete(:data)

  item.attributes = data
  raise item.errors.full_messages.to_s unless item.save

  item
end

puts "# inquiry"
save_inquiry_column node_id: inquiry_node.id, name: "企業・団体名", order: 10, input_type: "text_field",
  html: '<p>企業・団体名を入力してください。</p>', select_options: [], required: "optional", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "部署名", order: 20, input_type: "text_field",
  html: nil, select_options: [], required: "optional", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "お名前", order: 30, input_type: "text_field",
  html: '<p>お名前を入力してください。</p>', select_options: [], required: "required", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "ふりがな", order: 40, input_type: "text_field",
  html: nil, select_options: [], required: "optional", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "性別", order: 50, input_type: "radio_button",
  html: nil, select_options: %w(男性 女性), required: "required", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "メールアドレス", order: 60, input_type: "email_field",
  html: '<p>半角英数字記号で入力してください。</p><p>お問い合わせへの返信に利用させていただきます。</p>',
  select_options: [], required: "required", input_confirm: "enabled", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "電話番号", order: 70, input_type: "text_field",
  html: nil, select_options: [], required: "optional", additional_attr: 'pattern="[0-9]*"', site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "郵便番号", order: 80, input_type: "text_field",
  html: nil, select_options: [], required: "optional", additional_attr: 'pattern="[0-9]*"', site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "都道府県", order: 90, input_type: "select",
  html: nil, required: "optional", additional_attr: 'pattern="[0-9]*"', site_id: @site._id,
  select_options: %w(
    北海道 青森県 岩手県 宮城県 秋田県 山形県 福島県 茨城県 栃木県 群馬県 埼玉県 千葉県 東京都 神奈川県 新潟県 富山県 石川県
    福井県 山梨県 長野県 岐阜県 静岡県 愛知県 三重県 滋賀県 京都府 大阪府 兵庫県 奈良県 和歌山県 鳥取県 島根県 岡山県 広島県
    山口県 徳島県 香川県 愛媛県 高知県 福岡県 佐賀県 長崎県 熊本県 大分県 宮崎県 鹿児島県 沖縄県
    )
save_inquiry_column node_id: inquiry_node.id, name: "住所", order: 100, input_type: "text_field",
  html: nil, select_options: [], required: "optional", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "お問い合わせ種別", order: 110, input_type: "check_box",
  html: nil, select_options: %w(資料請求 お問い合わせ), required: "optional", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "お問い合わせ内容", order: 120, input_type: "text_area",
  html: '<p>お問い合わせ内容を入力してください。</p>', select_options: [], required: "required", site_id: @site._id

## -------------------------------------
def save_page(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }

  html ||= File.read("pages/" + data[:filename]) rescue nil
  summary_html ||= File.read("pages/" + data[:filename].sub(/\.html$/, "") + ".summary_html") rescue nil

  item = Cms::Page.find_or_create_by(cond).becomes_with_route(data[:route])
  item.html = html if html
  item.summary_html = summary_html if summary_html

  item.attributes = data
  item.update
  item.add_to_set group_ids: @site.group_ids

  item
end

## -------------------------------------
puts "# article"
contact_group = SS::Group.where(name: "シラサギ市/企画政策部/政策課").first
contact_group_id = contact_group.id rescue nil
contact_email = contact_group_id ? "kikakuseisaku@example.jp" : nil
contact_tel = contact_group_id ? "000-000-0000" : nil
contact_fax = contact_group_id ? "000-000-0000" : nil

article1 = save_page route: "article/page", filename: "docs/page1.html", name: "お知らせ情報が入ります。",
  layout_id: layouts["docs"].id, category_ids: [categories["news"].id]

article2 = save_page route: "article/page", filename: "docs/page2.html", name: "お知らせ情報が入ります。お知らせ情報が入ります。",
  layout_id: layouts["docs"].id, category_ids: [categories["news"].id]

file = save_ss_files "ss_files/article/dummy.jpg", filename: "dummy.jpg", model: "article/page"
article3 = save_page route: "article/page", filename: "docs/page3.html", name: "お知らせ情報が入ります。",
  layout_id: layouts["docs"].id, category_ids: [categories["news"].id], file_ids: [file.id],
  map_points: [ { name: "徳島駅", loc: [34.074722, 134.5516], text: "徳島駅です。" } ], related_page_ids: [article1.id, article2.id],
  contact_charge: "担当者", contact_email: "admin@example.jp", contact_tel: "000-000-0000", contact_fax: "000-000-0000"
article3.html = article3.html.gsub("src=\"#\"", "src=\"#{file.url}\"")
article3.update

file = save_ss_files "ss_files/article/dummy.jpg", filename: "dummy.jpg", model: "article/page"
article4 = save_page route: "article/page", filename: "docs/page4.html", name: "子育てサークルにさんかしませんか？",
  layout_id: layouts["docs"].id, category_ids: [categories["topics"].id], file_ids: [file.id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
article4.html = article4.html.gsub("src=\"#\"", "src=\"#{file.url}\"")
article4.update

puts "# event"
dates = (Time.zone.today..(Time.zone.today + 20)).map { |d| d.mongoize }
save_page route: "event/page", filename: "event/page1.html", name: "イベントタイトルが入ります。",
  layout_id: layouts["event-page"].id, event_dates: dates,
  category_ids: [categories["event/info"].id, categories["event/play"].id, categories["event/study"].id],
  map_points: [ { name: "徳島駅", loc: [34.074722, 134.5516], text: "徳島駅です。" } ],
  related_page_ids: [article1.id, article2.id, article3.id],
  schedule: "○月○日○時から○時", venue: "某所", cost: "○○○○円", contact: "シラサギ市",
  content: "イベントを開催します。", related_url: "http://demo.ss-proj.org/"

save_page route: "event/page", filename: "event/2.html", name: "イベントタイトルが入ります。",
  layout_id: layouts["event-page"].id, event_dates: dates,
  category_ids: [categories["event/info"].id, categories["event/play"].id, categories["event/study"].id],
  map_points: [ { name: "徳島駅", loc: [34.074722, 134.5516], text: "徳島駅です。" } ],
  related_page_ids: [article1.id, article2.id, article3.id],
  schedule: "○月○日○時から○時", venue: "某所", cost: "○○○○円", contact: "シラサギ市",
  content: "イベントを開催します。", related_url: "http://demo.ss-proj.org/"

puts "#faq"
save_page route: "faq/page", filename: "faq/docs/page1.html", name: "よくある質問のタイトル",
  layout_id: layouts["faq"].id,
  question: "<p>質問が入ります。質問が入ります。質問が入ります。</p>",
  category_ids: [categories["faq/birth"].id, categories["faq/leave"].id, categories["faq/trouble"].id]

puts "# facility"
file = save_ss_files "ss_files/facility/dummy.jpg", filename: "dummy.jpg", model: "facility/image"
save_page route: "facility/image", filename: "institution/list/shirsagi/page1.html", name: "写真1",
  layout_id: layouts["institution-page"].id, image_id: file.id, order: 0,
  image_alt: "写真1", image_comment: "写真です。"

file = save_ss_files "ss_files/facility/kv01.jpg", filename: "kv01.jpg", model: "facility/image"
save_page route: "facility/image", filename: "institution/list/shirsagi/page2.html", name: "写真2",
  layout_id: layouts["institution-page"].id, image_id: file.id, order: 10,
  image_alt: "写真1", image_comment: "写真です。"

file = save_ss_files "ss_files/facility/kv02.jpg", filename: "kv02.jpg", model: "facility/image"
save_page route: "facility/image", filename: "institution/list/shirsagi/page3.html", name: "写真3",
  layout_id: layouts["institution-page"].id, image_id: file.id, order: 20,
  image_alt: "写真1", image_comment: "写真です。"

file = save_ss_files "ss_files/facility/kv03.jpg", filename: "kv03.jpg", model: "facility/image"
save_page route: "facility/image", filename: "institution/list/shirsagi/page4.html", name: "写真4",
  layout_id: layouts["institution-page"].id, image_id: file.id, order: 30,
  image_alt: "写真1", image_comment: "写真です。"

save_page route: "facility/map", filename: "institution/list/shirsagi/map.html", name: "地図",
  layout_id: layouts["institution-page"].id, map_points: [ { loc: [34.074722, 134.5516] } ]

puts "# key visual"
keyvisual1 = save_ss_files "ss_files/key_visual/keyvisual01.jpg", filename: "keyvisual01.jpg", model: "key_visual/image"
keyvisual2 = save_ss_files "ss_files/key_visual/keyvisual02.jpg", filename: "keyvisual02.jpg", model: "key_visual/image"
keyvisual3 = save_ss_files "ss_files/key_visual/keyvisual03.jpg", filename: "keyvisual03.jpg", model: "key_visual/image"
keyvisual1.set(state: "public")
keyvisual2.set(state: "public")
keyvisual3.set(state: "public")

save_page route: "key_visual/image", filename: "slide/page37.html", name: "キービジュアル1", order: 10, file_id: keyvisual1.id
save_page route: "key_visual/image", filename: "slide/page38.html", name: "キービジュアル2", order: 20, file_id: keyvisual2.id
save_page route: "key_visual/image", filename: "slide/page39.html", name: "キービジュアル3", order: 30, file_id: keyvisual3.id

puts "# ads"
banner1 = save_ss_files "ss_files/ads/banner01.png", filename: "banner01.png", model: "ads/banner"
banner2 = save_ss_files "ss_files/ads/banner02.png", filename: "banner02.png", model: "ads/banner"
banner3 = save_ss_files "ss_files/ads/banner03.png", filename: "banner03.png", model: "ads/banner"
banner4 = save_ss_files "ss_files/ads/banner04.png", filename: "banner04.png", model: "ads/banner"
banner5 = save_ss_files "ss_files/ads/banner05.png", filename: "banner05.png", model: "ads/banner"
banner1.set(state: "public")
banner2.set(state: "public")
banner3.set(state: "public")
banner4.set(state: "public")
banner5.set(state: "public")

save_page route: "ads/banner", filename: "add/page1.html", name: "バナー画像",
  link_url: "#", file_id: banner1.id, order: 10
save_page route: "ads/banner", filename: "add/page2.html", name: "バナー画像",
  link_url: "#", file_id: banner2.id, order: 20
save_page route: "ads/banner", filename: "add/page3.html", name: "バナー画像",
  link_url: "#", file_id: banner3.id, order: 30
save_page route: "ads/banner", filename: "add/page4.html", name: "バナー画像",
  link_url: "#", file_id: banner4.id, order: 40
save_page route: "ads/banner", filename: "add/page5.html", name: "バナー画像",
  link_url: "#", file_id: banner5.id, order: 50

bn_relation1 = save_ss_files "ss_files/ads/bn-relation01.png", filename: "bn-relation01.png", model: "ads/banner"
bn_relation2 = save_ss_files "ss_files/ads/bn-relation02.png", filename: "bn-relation02.png", model: "ads/banner"
bn_relation1.set(state: "public")
bn_relation2.set(state: "public")
save_page route: "ads/banner", filename: "relation/page1.html", name: "関連サイト",
  link_url: "#", file_id: bn_relation1.id, order: 10
save_page route: "ads/banner", filename: "relation/page2.html", name: "関連サイト",
  link_url: "#", file_id: bn_relation2.id, order: 20

bn_institution = save_ss_files "ss_files/ads/bn-institution.png", filename: "bn-institution.png", model: "ads/banner"
bn_faq = save_ss_files "ss_files/ads/bn-faq.png", filename: "bn-faq.png", model: "ads/banner"
bn_institution.set(state: "public")
bn_faq.set(state: "public")
save_page route: "ads/banner", filename: "sub-menu/page1.html", name: "子育て施設情報",
  link_url: "/institution/", file_id: bn_institution.id, order: 10
save_page route: "ads/banner", filename: "sub-menu/page2.html", name: "よくある質問",
  link_url: "/faq/", file_id: bn_faq.id, order: 20

puts "# sitemap"
save_page route: "sitemap/page", filename: "sitemap/index.html", name: "サイトマップ",
  layout_id: layouts["folder"].id, sitemap_page_state: "hide", sitemap_depth: 3,
  sitemap_deny_urls: %w(add css img js relation slide sub-menu)

puts "# cms pages"
file = save_ss_files "ss_files/facility/dummy.jpg", filename: "dummy.jpg", model: "facility/image"
page1 = save_page route: "cms/page", filename: "know/pregnancy/procedure.html", name: "妊娠した時の手続き",
  layout_id: layouts["page"].id, file_ids: [file.id],
  category_ids: [categories["age/pregnancy"].id, categories["purpose/birth"].id],
  related_page_ids: [article1.id, article2.id, article3.id],
  map_points: [ { name: "徳島駅", loc: [34.074722, 134.5516], text: "徳島駅です。" } ],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax,
  order: 10
page1.html = page1.html.gsub("src=\"#\"", "src=\"#{file.url}\"")
page1.update

file = save_ss_files "ss_files/facility/dummy.jpg", filename: "dummy.jpg", model: "facility/image"
page2 = save_page route: "cms/page", filename: "know/pregnancy/exploration.html", name: "妊婦健康診査",
  layout_id: layouts["page"].id, file_ids: [file.id],
  category_ids: [categories["age/pregnancy"].id, categories["purpose/birth"].id],
  related_page_ids: [article1.id, article2.id, article3.id],
  map_points: [ { name: "徳島駅", loc: [34.074722, 134.5516], text: "徳島駅です。" } ],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax,
  order: 20
page2.html = page2.html.gsub("src=\"#\"", "src=\"#{file.url}\"")
page2.update

file = save_ss_files "ss_files/facility/dummy.jpg", filename: "dummy.jpg", model: "facility/image"
page3 = save_page route: "cms/page", filename: "know/pregnancy/born.html", name: "赤ちゃんが生まれたら",
  layout_id: layouts["page"].id, file_ids: [file.id],
  category_ids: [categories["age/pregnancy"].id, categories["purpose/birth"].id],
  map_points: [ { name: "徳島駅", loc: [34.074722, 134.5516], text: "徳島駅です。" } ],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax,
  order: 30
page3.html = page3.html.gsub("src=\"#\"", "src=\"#{file.url}\"")
page3.update

file = save_ss_files "ss_files/facility/dummy.jpg", filename: "dummy.jpg", model: "facility/image"
page4 = save_page route: "cms/page", filename: "know/pregnancy/birth.html", name: "出生届",
  layout_id: layouts["page"].id, file_ids: [file.id],
  category_ids: [categories["age/pregnancy"].id, categories["purpose/birth"].id],
  related_page_ids: [article1.id, article2.id, article3.id],
  map_points: [ { name: "徳島駅", loc: [34.074722, 134.5516], text: "徳島駅です。" } ],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax,
  order: 40
page4.html = page4.html.gsub("src=\"#\"", "src=\"#{file.url}\"")
page4.update

file = save_ss_files "ss_files/facility/dummy.jpg", filename: "dummy.jpg", model: "facility/image"
page5 = save_page route: "cms/page", filename: "know/pregnancy/lump-sum.html", name: "出産育児一時金",
  layout_id: layouts["page"].id, file_ids: [file.id],
  category_ids: [categories["age/pregnancy"].id, categories["purpose/birth"].id],
  related_page_ids: [article1.id, article2.id, article3.id],
  map_points: [ { name: "徳島駅", loc: [34.074722, 134.5516], text: "徳島駅です。" } ],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax,
  order: 50
page5.html = page5.html.gsub("src=\"#\"", "src=\"#{file.url}\"")
page5.update

save_page route: "cms/page", filename: "404.html", name: "お探しのページは見つかりません。 404 Not Found", layout_id: layouts["general"].id
save_page route: "cms/page", filename: "index.html", name: "子育て支援サンプル", layout_id: layouts["top"].id

## -------------------------------------
def save_editor_template(data)
  puts data[:name]
  cond = { site_id: data[:site_id], name: data[:name] }

  item = Cms::EditorTemplate.find_or_create_by(cond)
  item.attributes = data
  item.update

  item
end

puts "# editor templates"
thumb_left  = save_ss_files("editor_templates/float-left.jpg", filename: "float-left.jpg", model: "cms/editor_template")
thumb_right = save_ss_files("editor_templates/float-right.jpg", filename: "float-right.jpg", model: "cms/editor_template")

editor_template_html = File.read("editor_templates/float-left.html") rescue nil
save_editor_template name: "画像左回り込み", description: "画像が左に回り込み右側がテキストになります",
  html: editor_template_html, thumb_id: thumb_left.id, order: 10, site_id: @site.id
thumb_left.set(state: "public")

editor_template_html = File.read("editor_templates/float-right.html") rescue nil
save_editor_template name: "画像右回り込み", description: "画像が右に回り込み左側がテキストになります",
  html: editor_template_html, thumb_id: thumb_right.id, order: 20, site_id: @site.id
thumb_right.set(state: "public")

editor_template_html = File.read("editor_templates/clear.html") rescue nil
save_editor_template name: "回り込み解除", description: "回り込みを解除します",
  html: editor_template_html, order: 30, site_id: @site.id
