## -------------------------------------
# Require

puts "Please input site_name: site=[site_host]" or exit if ENV['site'].blank?

@site = Cms::Site.where(host: ENV['site']).first
puts "Site not found: #{ENV['site']}" or exit unless @site
link_url = "/"

require "#{Rails.root}/db/seeds/cms/users"
require "#{Rails.root}/db/seeds/cms/workflow"
require "#{Rails.root}/db/seeds/cms/members"

@site.map_api = "openlayers"
@site.update

Dir.chdir @root = File.dirname(__FILE__)

## -------------------------------------
puts "# roles"

def add_permissions(name, permissions)
  puts name
  cond = { name: name, site_id: @site.id }

  item = Cms::Role.find_by cond rescue nil
  return unless item

  item.permissions = (item.permissions.dup + permissions).uniq.sort.select(&:present?)
  item.update
  item
end

add_permissions "記事編集権限", %w(
    read_other_opendata_datasets edit_other_opendata_datasets delete_other_opendata_datasets
    read_private_opendata_datasets edit_private_opendata_datasets delete_private_opendata_datasets
    read_other_opendata_apps edit_other_opendata_apps delete_other_opendata_apps
    read_private_opendata_apps edit_private_opendata_apps delete_private_opendata_apps
    read_other_opendata_ideas edit_other_opendata_ideas delete_other_opendata_ideas
    read_private_opendata_ideas edit_private_opendata_ideas delete_private_opendata_ideas
  )

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
  item.cur_user = @user
  item.save

  item
end

## -------------------------------------
puts "# layouts"

def save_layout(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }
  html = File.read("layouts/" + data[:filename]) rescue nil

  item = Cms::Layout.find_or_initialize_by(cond)
  item.attributes = data.merge html: html
  item.cur_user = @user
  item.save
  item.add_to_set group_ids: @site.group_ids

  item
end

save_layout filename: "app-bunya.layout.html", name: "アプリ：分野、アプリ検索"
save_layout filename: "app-page.layout.html", name: "アプリ：詳細ページ"
save_layout filename: "app-top.layout.html", name: "アプリ：トップ"
save_layout filename: "dataset-bunya.layout.html", name: "データ：分野、データ検索、グループ検索"
save_layout filename: "dataset-map.layout.html", name: "地図"
save_layout filename: "chiiki.layout.html", name: "地域"
save_layout filename: "dataset-page.layout.html", name: "データ：詳細ページ"
save_layout filename: "dataset-top.layout.html", name: "データ：トップ"
save_layout filename: "idea-bunya.layout.html", name: "アイデア：分野、アイデア検索"
save_layout filename: "idea-page.layout.html", name: "アイデア：詳細ページ"
save_layout filename: "idea-top.layout.html", name: "アイデア：トップ"
save_layout filename: "mypage-page.layout.html", name: "マイページ：詳細"
save_layout filename: "mypage-top.layout.html", name: "マイページ：トップ、メンバー、SPARQL"
save_layout filename: "portal-event.layout.html", name: "ポータル：イベント"
save_layout filename: "portal-general.layout.html", name: "ポータル：汎用"
save_layout filename: "portal-top.layout.html", name: "ポータル：トップ"

array   = Cms::Layout.where(site_id: @site._id).map { |m| [m.filename.sub(/\..*$/, '\1'), m] }
layouts = Hash[*array.flatten]

## -------------------------------------
puts "# nodes"

def save_node(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename], route: data[:route] }

  upper_html ||= File.read("nodes/" + data[:filename] + ".upper_html") rescue nil
  loop_html  ||= File.read("nodes/" + data[:filename] + ".loop_html") rescue nil
  lower_html ||= File.read("nodes/" + data[:filename] + ".lower_html") rescue nil
  summary_html ||= File.read("nodes/" + data[:filename] + ".summary_html") rescue nil

  item = data[:route].sub("/", "/node/").camelize.constantize.unscoped.find_or_initialize_by(cond)
  item.upper_html = upper_html if upper_html
  item.loop_html = loop_html if loop_html
  item.lower_html = lower_html if lower_html
  item.summary_html = summary_html if summary_html

  item.attributes = data
  item.cur_user = @user
  item.save
  item.add_to_set group_ids: @site.group_ids

  item
end

save_node filename: "css", name: "CSS", route: "uploader/file"
save_node filename: "js", name: "Javascript", route: "uploader/file"
save_node filename: "img", name: "画像", route: "uploader/file"
save_node filename: "materials", name: "資料", route: "uploader/file"
save_node filename: "ads", name: "広告", route: "ads/banner"

save_node filename: "docs", name: "お知らせ", route: "article/page", shortcut: "show",
  layout_id: layouts["portal-general"].id
save_node filename: "event", name: "イベント", route: "event/page",
  layout_id: layouts["portal-event"].id,
  page_layout_id: layouts["portal-event"].id

save_node filename: "dataset", name: "データカタログ", route: "opendata/dataset", shortcut: "show",
  layout_id: layouts["dataset-top"].id,
  page_layout_id: layouts["dataset-page"].id
save_node filename: "dataset/bunya", name: "分野", route: "opendata/dataset_category",
  layout_id: layouts["dataset-bunya"].id
save_node filename: "dataset/chiiki", name: "地域", route: "opendata/dataset_area",
  layout_id: layouts["chiiki"].id
save_node filename: "dataset/chiiki/shirasagi", name: "シラサギ市", route: "opendata/dataset_area",
  layout_id: layouts["chiiki"].id
save_node filename: "dataset/chiiki/shirasagi/higashi", name: "東区", route: "opendata/dataset_area",
  layout_id: layouts["chiiki"].id
save_node filename: "dataset/chiiki/shirasagi/kita", name: "北区", route: "opendata/dataset_area",
  layout_id: layouts["chiiki"].id
save_node filename: "dataset/chiiki/shirasagi/minami", name: "南区", route: "opendata/dataset_area",
  layout_id: layouts["chiiki"].id
save_node filename: "dataset/chiiki/shirasagi/nishi", name: "西区", route: "opendata/dataset_area",
  layout_id: layouts["chiiki"].id
save_node filename: "dataset/map", name: "地図", route: "opendata/dataset_map",
  layout_id: layouts["dataset-map"].id
save_node filename: "graph", name: "オープンデータグラフ", route: "opendata/dataset_graph",
  layout_id: layouts["dataset-map"].id
save_node filename: "dataset/search_group", name: "データセットグループ検索", route: "opendata/search_dataset_group",
  layout_id: layouts["dataset-bunya"].id
save_node filename: "dataset/search", name: "データセット検索", route: "opendata/search_dataset",
  layout_id: layouts["dataset-bunya"].id

save_node filename: "app", name: "アプリマーケット", route: "opendata/app", shortcut: "show",
  layout_id: layouts["app-top"].id,
  page_layout_id: layouts["app-page"].id
save_node filename: "app/bunya", name: "分野", route: "opendata/app_category",
  layout_id: layouts["app-bunya"].id
save_node filename: "app/search", name: "アプリ検索", route: "opendata/search_app",
  layout_id: layouts["app-bunya"].id

save_node filename: "idea", name: "アイデアボックス", route: "opendata/idea", shortcut: "show",
  layout_id: layouts["idea-top"].id,
  page_layout_id: layouts["idea-page"].id
save_node filename: "idea/bunya", name: "分野", route: "opendata/idea_category",
  layout_id: layouts["idea-bunya"].id
save_node filename: "idea/search", name: "アイデア検索", route: "opendata/search_idea",
  layout_id: layouts["idea-bunya"].id

save_node filename: "sparql", name: "SPARQL", route: "opendata/sparql",
  layout_id: layouts["mypage-top"].id
save_node filename: "api", name: "API", route: "opendata/api"

save_node filename: "member", name: "ユーザー", route: "opendata/member",
  layout_id: layouts["mypage-top"].id

save_node filename: "auth", name: "ログイン", route: "member/login",
  layout_id: layouts["mypage-top"].id, redirect_url: "/mypage/", form_auth: "enabled",
  twitter_oauth: "enabled", facebook_oauth: "enabled", yahoojp_oauth: "enabled",
  google_oauth2_oauth: "enabled", github_oauth: "enabled"

save_node filename: "mypage", name: "マイページ", route: "opendata/mypage",
  layout_id: layouts["mypage-top"].id
save_node filename: "mypage/favorite", name: "マイリスト", route: "opendata/my_favorite_dataset",
  layout_id: layouts["mypage-page"].id, order: 10
save_node filename: "mypage/dataset", name: "データカタログ", route: "opendata/my_dataset",
  layout_id: layouts["mypage-page"].id, order: 20
save_node filename: "mypage/app", name: "アプリマーケット", route: "opendata/my_app",
  layout_id: layouts["mypage-page"].id, order: 30
save_node filename: "mypage/idea", name: "アイデアボックス", route: "opendata/my_idea",
  layout_id: layouts["mypage-page"].id, order: 40
save_node filename: "mypage/profile", name: "プロフィール", route: "opendata/my_profile",
  layout_id: layouts["mypage-page"].id, order: 50

save_node filename: "bunya", name: "分野", route: "cms/node"
save_node filename: "bunya/kanko", name: "観光・文化・スポーツ", route: "opendata/category", order: 1
save_node filename: "bunya/kenko", name: "健康・福祉", route: "opendata/category", order: 2
save_node filename: "bunya/kosodate", name: "子育て・教育", route: "opendata/category", order: 3
save_node filename: "bunya/kurashi", name: "くらし・手続き", route: "opendata/category", order: 4
save_node filename: "bunya/sangyo", name: "産業・仕事", route: "opendata/category", order: 5
save_node filename: "bunya/shisei", name: "市政情報", route: "opendata/category", order: 6

save_node filename: "estat-bunya", name: "eStat分野", route: "cms/node"
save_node filename: "estat-bunya/estat1", name: "国土・気象", route: "opendata/estat_category", order: 1
save_node filename: "estat-bunya/estat2", name: "人口・世帯", route: "opendata/estat_category", order: 2
save_node filename: "estat-bunya/estat3", name: "労働・賃金", route: "opendata/estat_category", order: 3
save_node filename: "estat-bunya/estat4", name: "農林水産業", route: "opendata/estat_category", order: 4
save_node filename: "estat-bunya/estat5", name: "鉱工業", route: "opendata/estat_category", order: 5
save_node filename: "estat-bunya/estat6", name: "商業・サービス業", route: "opendata/estat_category", order: 6
save_node filename: "estat-bunya/estat7", name: "企業・家計・経済", route: "opendata/estat_category", order: 7
save_node filename: "estat-bunya/estat8", name: "住宅・土地・建設", route: "opendata/estat_category", order: 8
save_node filename: "estat-bunya/estat9", name: "エネルギー・水", route: "opendata/estat_category", order: 9
save_node filename: "estat-bunya/estat10", name: "運輸・観光", route: "opendata/estat_category", order: 10
save_node filename: "estat-bunya/estat11", name: "情報通信・科学技術", route: "opendata/estat_category", order: 11
save_node filename: "estat-bunya/estat12", name: "教育・文化・スポーツ・生活", route: "opendata/estat_category", order: 12
save_node filename: "estat-bunya/estat13", name: "行財政", route: "opendata/estat_category", order: 13
save_node filename: "estat-bunya/estat14", name: "司法・安全・環境", route: "opendata/estat_category", order: 14
save_node filename: "estat-bunya/estat15", name: "社会保障・衛生", route: "opendata/estat_category", order: 15
save_node filename: "estat-bunya/estat16", name: "国際", route: "opendata/estat_category", order: 16
save_node filename: "estat-bunya/estat99", name: "その他", route: "opendata/estat_category", order: 17

save_node filename: "estat-bunya/estat1/estat101", name: "国土", route: "opendata/estat_category", order: 101
save_node filename: "estat-bunya/estat1/estat102", name: "気象", route: "opendata/estat_category", order: 102
save_node filename: "estat-bunya/estat2/estat201", name: "人口", route: "opendata/estat_category", order: 201
save_node filename: "estat-bunya/estat2/estat202", name: "世帯", route: "opendata/estat_category", order: 202
save_node filename: "estat-bunya/estat2/estat203", name: "人口動態", route: "opendata/estat_category", order: 203
save_node filename: "estat-bunya/estat2/estat204", name: "人口移動", route: "opendata/estat_category", order: 204
save_node filename: "estat-bunya/estat3/estat301", name: "労働力", route: "opendata/estat_category", order: 301
save_node filename: "estat-bunya/estat3/estat302", name: "賃金・労働条件", route: "opendata/estat_category", order: 302
save_node filename: "estat-bunya/estat3/estat303", name: "雇用", route: "opendata/estat_category", order: 303
save_node filename: "estat-bunya/estat3/estat304", name: "労使関係", route: "opendata/estat_category", order: 304
save_node filename: "estat-bunya/estat3/estat305", name: "労働災害", route: "opendata/estat_category", order: 305
save_node filename: "estat-bunya/estat4/estat401", name: "農業", route: "opendata/estat_category", order: 401
save_node filename: "estat-bunya/estat4/estat402", name: "畜産業", route: "opendata/estat_category", order: 402
save_node filename: "estat-bunya/estat4/estat403", name: "林業", route: "opendata/estat_category", order: 403
save_node filename: "estat-bunya/estat4/estat404", name: "水産業", route: "opendata/estat_category", order: 404
save_node filename: "estat-bunya/estat5/estat501", name: "鉱業", route: "opendata/estat_category", order: 501
save_node filename: "estat-bunya/estat5/estat502", name: "製造業", route: "opendata/estat_category", order: 502
save_node filename: "estat-bunya/estat6/estat601", name: "商業", route: "opendata/estat_category", order: 601
save_node filename: "estat-bunya/estat6/estat602", name: "需給流通", route: "opendata/estat_category", order: 602
save_node filename: "estat-bunya/estat6/estat603", name: "サービス業", route: "opendata/estat_category", order: 603
save_node filename: "estat-bunya/estat7/estat701", name: "企業活動", route: "opendata/estat_category", order: 701
save_node filename: "estat-bunya/estat7/estat702", name: "金融・保険・通貨", route: "opendata/estat_category", order: 702
save_node filename: "estat-bunya/estat7/estat703", name: "物価", route: "opendata/estat_category", order: 703
save_node filename: "estat-bunya/estat7/estat704", name: "家計", route: "opendata/estat_category", order: 704
save_node filename: "estat-bunya/estat7/estat705", name: "国民経済計算", route: "opendata/estat_category", order: 705
save_node filename: "estat-bunya/estat7/estat706", name: "景気", route: "opendata/estat_category", order: 706
save_node filename: "estat-bunya/estat8/estat801", name: "住宅・土地", route: "opendata/estat_category", order: 801
save_node filename: "estat-bunya/estat8/estat802", name: "建設", route: "opendata/estat_category", order: 802
save_node filename: "estat-bunya/estat9/estat901", name: "電気", route: "opendata/estat_category", order: 901
save_node filename: "estat-bunya/estat9/estat902", name: "ガス", route: "opendata/estat_category", order: 902
save_node filename: "estat-bunya/estat9/estat903", name: "エネルギー需給", route: "opendata/estat_category", order: 903
save_node filename: "estat-bunya/estat9/estat904", name: "水", route: "opendata/estat_category", order: 904
save_node filename: "estat-bunya/estat10/estat1001", name: "運輸", route: "opendata/estat_category", order: 1001
save_node filename: "estat-bunya/estat10/estat1002", name: "倉庫", route: "opendata/estat_category", order: 1002
save_node filename: "estat-bunya/estat10/estat1003", name: "観光", route: "opendata/estat_category", order: 1003
save_node filename: "estat-bunya/estat11/estat1101", name: "情報通信・放送", route: "opendata/estat_category", order: 1101
save_node filename: "estat-bunya/estat11/estat1102", name: "科学技術", route: "opendata/estat_category", order: 1102
save_node filename: "estat-bunya/estat11/estat1103", name: "知的財産", route: "opendata/estat_category", order: 1103
save_node filename: "estat-bunya/estat12/estat1201", name: "学校教育", route: "opendata/estat_category", order: 1201
save_node filename: "estat-bunya/estat12/estat1202", name: "社会教育", route: "opendata/estat_category", order: 1202
save_node filename: "estat-bunya/estat12/estat1203", name: "文化・スポーツ・生活", route: "opendata/estat_category", order: 1203
save_node filename: "estat-bunya/estat13/estat1301", name: "行政", route: "opendata/estat_category", order: 1301
save_node filename: "estat-bunya/estat13/estat1302", name: "財政", route: "opendata/estat_category", order: 1302
save_node filename: "estat-bunya/estat13/estat1303", name: "公務員", route: "opendata/estat_category", order: 1303
save_node filename: "estat-bunya/estat13/estat1304", name: "選挙", route: "opendata/estat_category", order: 1304
save_node filename: "estat-bunya/estat14/estat1401", name: "司法", route: "opendata/estat_category", order: 1401
save_node filename: "estat-bunya/estat14/estat1402", name: "犯罪", route: "opendata/estat_category", order: 1402
save_node filename: "estat-bunya/estat14/estat1403", name: "災害", route: "opendata/estat_category", order: 1403
save_node filename: "estat-bunya/estat14/estat1404", name: "事故", route: "opendata/estat_category", order: 1404
save_node filename: "estat-bunya/estat14/estat1405", name: "環境", route: "opendata/estat_category", order: 1405
save_node filename: "estat-bunya/estat15/estat1501", name: "社会保障", route: "opendata/estat_category", order: 1501
save_node filename: "estat-bunya/estat15/estat1502", name: "社会保険", route: "opendata/estat_category", order: 1502
save_node filename: "estat-bunya/estat15/estat1503", name: "社会福祉", route: "opendata/estat_category", order: 1503
save_node filename: "estat-bunya/estat15/estat1504", name: "保険衛生", route: "opendata/estat_category", order: 1504
save_node filename: "estat-bunya/estat15/estat1505", name: "医療", route: "opendata/estat_category", order: 1505
save_node filename: "estat-bunya/estat16/estat1601", name: "貿易・国際収支", route: "opendata/estat_category", order: 1601
save_node filename: "estat-bunya/estat16/estat1602", name: "国際協力", route: "opendata/estat_category", order: 1602
save_node filename: "estat-bunya/estat99/estat9999", name: "その他", route: "opendata/estat_category", order: 9999
estat_categories = Opendata::Node::EstatCategory.site(@site).index_by { |m| m.filename }

save_node filename: "chiiki", name: "地域", route: "cms/node"
save_node filename: "chiiki/shirasagi", name: "シラサギ市", route: "opendata/area", order: 1

[ %w(東区 higashi),
  %w(北区 kita),
  %w(南区 minami),
  %w(西区 nishi),
].each_with_index do |data, idx|
  save_node filename: "chiiki/shirasagi/#{data[1]}", name: data[0], route: "opendata/area", order: idx + 1
end

array   = Cms::Node.where(site_id: @site._id).map { |m| [m.filename.sub(/\..*$/, '\1'), m] }
nodes = Hash[*array.flatten]

# inquiry

def save_inquiry_column(data)
  puts data[:name]
  cond = { node_id: data[:node_id], name: data[:name] }

  item = Inquiry::Column.find_or_create_by(cond)
  item.attributes = data
  item.update

  item
end

puts "# inquiry"

inquiry_node = save_node route: "inquiry/form", filename: "inquiry", name: "お問い合わせ",
  layout_id: layouts["portal-general"].id,
  inquiry_html: "<p>下記事項を入力の上、確認画面へのボタンを押してください。</p>\n",
  inquiry_sent_html: "<p>お問い合わせを受け付けました。</p>\n",
  inquiry_captcha: "enabled",
  notice_state: "disabled",
  reply_state: "disabled"
save_inquiry_column node_id: inquiry_node.id, name: "お名前", order: 10, input_type: "text_field",
  html: "", select_options: [], required: "required", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "企業・団体名", order: 20, input_type: "text_field",
  html: "", select_options: [], required: "optional", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "メールアドレス", order: 30, input_type: "email_field",
  html: "", select_options: [], required: "required", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "お問い合わせ内容", order: 40, input_type: "text_area",
  html: "", select_options: [], required: "required", site_id: @site._id

## -------------------------------------
puts "# parts"

def save_part(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }

  html = File.read("parts/" + data[:filename]) rescue nil
  upper_html = File.read("parts/" + data[:filename].sub(/\.html$/, ".upper_html")) rescue nil
  loop_html  = File.read("parts/" + data[:filename].sub(/\.html$/, ".loop_html")) rescue nil
  lower_html = File.read("parts/" + data[:filename].sub(/\.html$/, ".lower_html")) rescue nil

  item = data[:route].sub("/", "/part/").camelize.constantize.unscoped.find_or_initialize_by(cond)
  item.html = html if html
  item.upper_html = upper_html if upper_html
  item.loop_html = loop_html if loop_html
  item.lower_html = lower_html if lower_html

  item.attributes = data
  item.cur_user = @user
  item.save
  item.add_to_set group_ids: @site.group_ids

  item
end

save_part filename: "ads/banner.part.html", name: "広告", route: "ads/banner"
save_part filename: "app-attention.part.html", name: "アプリ：注目順", \
  route: "opendata/app", limit: 10, sort: "attention"
save_part filename: "app-head.part.html", name: "アプリ：ヘッダー", route: "cms/free"
save_part filename: "app-kv.part.html", name: "アプリ：キービジュアル", route: "cms/free"
save_part filename: "crumbs.part.html", name: "パンくず", route: "cms/crumb"
save_part filename: "dataset-attention.part.html", name: "データ：注目順", \
  route: "opendata/dataset", limit: 10, sort: "attention"
save_part filename: "dataset-group.part.html", name: "データ：グループ", route: "opendata/dataset_group"
save_part filename: "dataset-head.part.html", name: "データ：ヘッダー", route: "cms/free"
save_part filename: "dataset-kv.part.html", name: "データ：キービジュアル", route: "cms/free"
save_part filename: "event/calendar.part.html", name: "イベントカレンダー", route: "event/calendar"
save_part filename: "foot.part.html", name: "フッター", route: "cms/free"
save_part filename: "idea-attention.part.html", name: "アイデア：注目順", \
  route: "opendata/idea", limit: 10, sort: "attention"
save_part filename: "idea-head.part.html", name: "アイデア：ヘッダー", route: "cms/free"
save_part filename: "idea-kv.part.html", name: "アイデア：キービジュアル", route: "cms/free"
save_part filename: "mypage-login.part.html", name: "ログイン", \
  route: "opendata/mypage_login", ajax_view: "enabled"
save_part filename: "mypage-tabs.part.html", name: "マイページ：タブ", route: "cms/free"
save_part filename: "portal-about.part.html", name: "ポータル：Our Open Dateとは", route: "cms/free"
save_part filename: "portal-app.part.html", name: "ポータル：オープンアプリマーケット", \
  route: "opendata/app", limit: 5, sort: "released"
save_part filename: "portal-dataset.part.html", name: "ポータル：オープンデータカタログ", \
  route: "opendata/dataset", limit: 5, sort: "released"
save_part filename: "portal-idea.part.html", name: "ポータル：オープンアイデアボックス", \
  route: "opendata/idea", limit: 5, sort: "released"
save_part filename: "portal-kv.part.html", name: "ポータル：キービジュアル", route: "cms/free"
save_part filename: "portal-tab.part.html", name: "ポータル：新着タブ", \
  route: "cms/tabs", conditions: %w(docs event), limit: 5
save_part filename: "sns-share.part.html", name: "SNSシェアボタン", route: "cms/sns_share"
save_part filename: "tab.part.html", name: "サイト切り替えタブ", route: "cms/free"
save_part filename: "opendatamap.part.html", name: "ポータル：オープンデータマップ", route: "cms/free"
save_part filename: "portal-area.part.html", name: "ポータル：地域", route: "cms/free"

## -------------------------------------
puts "# pages"

def save_page(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }

  html ||= File.read("pages/" + data[:filename]) rescue nil
  summary_html ||= File.read("pages/" + data[:filename].sub(/\.html$/, "") + ".summary_html") rescue nil

  route = data[:route].presence || 'cms/page'
  item = route.camelize.constantize.find_or_initialize_by(cond)
  item.html = html if html
  item.summary_html = summary_html if summary_html

  item.attributes = data
  item.cur_user = @user
  item.save
  item.add_to_set group_ids: @site.group_ids

  item
end

contact_group = Cms::Group.where(name: "シラサギ市/企画政策部/政策課").first
contact_group_id = contact_group.id rescue nil
contact = contact_group.contact_groups.first

save_page route: "cms/page", filename: "index.html", name: "トップページ", layout_id: layouts["portal-top"].id
save_page route: "cms/page", filename: "tutorial-data.html", name: "データ登録手順", layout_id: layouts["portal-general"].id
save_page route: "cms/page", filename: "tutorial-app.html", name: "アプリ登録手順", layout_id: layouts["portal-general"].id
save_page route: "cms/page", filename: "tutorial-idea.html", name: "アイデア登録手順", layout_id: layouts["portal-general"].id
page0 = save_page route: "article/page", filename: "docs/1.html", name: "○○が公開されました。", layout_id: layouts["portal-general"].id,
  map_points: Map::Extensions::Points.new([{loc: Map::Extensions::Loc.mongoize([134.589982, 34.067022])}]),
  contact_group_id: contact_group_id, contact_group_contact_id: contact.id, contact_group_relation: "related",
  contact_group_name: contact.contact_group_name, contact_charge: contact.contact_charge,
  contact_tel: contact.contact_tel, contact_fax: contact.contact_fax,
  contact_email: contact.contact_email, contact_postal_code: contact.contact_postal_code,
  contact_address: contact.contact_address, contact_link_url: contact.contact_link_url,
  contact_link_name: contact.contact_link_name
page1 = save_page route: "article/page", filename: "docs/2.html", name: "○○○○○○が公開されました。",
  layout_id: layouts["portal-general"].id,
  contact_group_id: contact_group_id, contact_group_contact_id: contact.id, contact_group_relation: "related",
  contact_group_name: contact.contact_group_name, contact_charge: contact.contact_charge,
  contact_tel: contact.contact_tel, contact_fax: contact.contact_fax,
  contact_email: contact.contact_email, contact_postal_code: contact.contact_postal_code,
  contact_address: contact.contact_address, contact_link_url: contact.contact_link_url,
  contact_link_name: contact.contact_link_name
page2 = save_page route: "article/page", filename: "docs/3.html", name: "○○○○○○○○が公開されました。",
  layout_id: layouts["portal-general"].id,
  contact_group_id: contact_group_id, contact_group_contact_id: contact.id, contact_group_relation: "related",
  contact_group_name: contact.contact_group_name, contact_charge: contact.contact_charge,
  contact_tel: contact.contact_tel, contact_fax: contact.contact_fax,
  contact_email: contact.contact_email, contact_postal_code: contact.contact_postal_code,
  contact_address: contact.contact_address, contact_link_url: contact.contact_link_url,
  contact_link_name: contact.contact_link_name
recurrence = { kind: "date", start_at: Time.zone.today + 7, frequency: "daily", until_on: Time.zone.today + 18 }
event0 = save_page route: "event/page", filename: "event/4.html", name: "オープンデータイベント", \
  layout_id: layouts["portal-event"].id,
  schedule: "#{7.days.since.strftime("%m").sub(/^0+/, '')}月#{7.days.since.strftime("%d").sub(/^0+/, '')}日", \
  venue: "シラサギ市図書館", related_url: link_url, \
  event_recurrences: [ recurrence ]
page0.related_page_ids = [ page2.id, event0.id ]
page0.save!

save_page route: "cms/page", name: "お探しのページは見つかりません。 404 Not Found", filename: "404.html",
  layout_id: layouts["portal-general"].id

## -------------------------------------
puts "# ads"

banner1 = save_ss_files "ss_files/ads/banner1.gif", filename: "banner1.gif", model: "ads/banner"
banner2 = save_ss_files "ss_files/ads/banner2.gif", filename: "banner2.gif", model: "ads/banner"
banner3 = save_ss_files "ss_files/ads/banner3.gif", filename: "banner3.gif", model: "ads/banner"
banner4 = save_ss_files "ss_files/ads/banner4.gif", filename: "banner4.gif", model: "ads/banner"
banner5 = save_ss_files "ss_files/ads/banner5.gif", filename: "banner5.gif", model: "ads/banner"
banner6 = save_ss_files "ss_files/ads/banner6.gif", filename: "banner6.gif", model: "ads/banner"
banner1.set(state: "public")
banner2.set(state: "public")
banner3.set(state: "public")
banner4.set(state: "public")
banner5.set(state: "public")
banner6.set(state: "public")

save_page route: "ads/banner", filename: "ads/page600.html", name: "シラサギ",
  link_url: link_url, file_id: banner1.id
save_page route: "ads/banner", filename: "ads/page601.html", name: "シラサギ",
  link_url: link_url, file_id: banner2.id
save_page route: "ads/banner", filename: "ads/page602.html", name: "シラサギ",
  link_url: link_url, file_id: banner3.id
save_page route: "ads/banner", filename: "ads/page603.html", name: "シラサギ",
  link_url: link_url, file_id: banner4.id
save_page route: "ads/banner", filename: "ads/page604.html", name: "シラサギ",
  link_url: link_url, file_id: banner5.id
save_page route: "ads/banner", filename: "ads/page605.html", name: "シラサギ",
  link_url: link_url, file_id: banner6.id

## -------------------------------------
puts "# licenses"

def save_license(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Opendata::License.find_or_create_by cond
  item.update data
  item
end

license_file1 = save_ss_files "fixtures/cc-by.png", filename: "cc-by.png", model: "opendata/license"
license_file2 = save_ss_files "fixtures/cc-by-sa.png", filename: "cc-by-sa.png", model: "opendata/license"
license_file3 = save_ss_files "fixtures/cc-by-nd.png", filename: "cc-by-nd.png", model: "opendata/license"
license_file4 = save_ss_files "fixtures/cc-by-nc.png", filename: "cc-by-nc.png", model: "opendata/license"
license_file5 = save_ss_files "fixtures/cc-by-nc-sa.png", filename: "cc-by-nc-sa.png", model: "opendata/license"
license_file6 = save_ss_files "fixtures/cc-by-nc-nd.png", filename: "cc-by-nc-nd.png", model: "opendata/license"
license_file7 = save_ss_files "fixtures/cc-zero.png", filename: "cc-zero.png", model: "opendata/license"

license_cc_by = save_license name: "表示（CC BY）", file_id: license_file1.id, order: 1,
  default_state: 'default', uid: "cc-by", metadata_uid: 'CC BY 4.0'
save_license name: "表示-継承（CC BY-SA）", file_id: license_file2.id, order: 2, uid: "cc-by-sa"
save_license name: "表示-改変禁止（CC BY-ND）", file_id: license_file3.id, order: 3, uid: "cc-by-nd"
save_license name: "表示-非営利（CC BY-NC）", file_id: license_file4.id, order: 4, uid: "cc-by-nc"
save_license name: "表示-非営利-継承（CC BY-NC-SA）", file_id: license_file5.id, order: 5, uid: "cc-by-nc-sa"
save_license name: "表示-非営利-改変禁止（CC BY-NC-ND）", file_id: license_file6.id, order: 6, uid: "cc-by-nc-nd"
save_license name: "いかなる権利も保有しない（CC 0）", file_id: license_file7.id, order: 7, uid: "cc-zero"

## -------------------------------------
puts "# opendata dataset_groups"

def save_dataset_group(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Opendata::DatasetGroup.find_or_create_by cond
  item.update data
end

1.step(3) do |i|
  save_dataset_group name: "データセットグループ#{i}",
    category_ids: Opendata::Node::Category.site(@site).pluck(:_id).sample(1)
end

## -------------------------------------
puts "# opendata datasets"

def save_data(data)
  puts data[:name]
  cond = { site_id: @site.id, filename: data[:filename] }

  item = Opendata::Dataset.find_or_create_by cond
  puts item.errors.full_messages unless item.update data
  item
end

def save_resource(dataset, data)
  puts data[:name]
  cond = { name: data[:name] }

  path = "datasets/resources/#{data[:filename]}"
  Fs::UploadedFile.create_from_file(path) do |file|
    item = dataset.resources.where(cond).first || dataset.resources.new
    item.in_file = file
    puts item.errors.full_messages unless item.update data
  end
end

dataset1 = save_data filename: "dataset/1.html", name: "サンプルデータ【1】", route: "opendata/dataset",
  layout_id: layouts["dataset-page"].id, text: "サンプルデータ【1】", member_id: @member_1.id, tags: %w(タグ),
  category_ids: Opendata::Node::Category.site(@site).pluck(:id).sample(1),
  dataset_group_ids: Opendata::DatasetGroup.site(@site).pluck(:id).sample(1),
  area_ids: Opendata::Node::Area.site(@site).pluck(:id).sample(1)

dataset2 = save_data filename: "dataset/2.html", name: "サンプルデータ【2】", route: "opendata/dataset",
  layout_id: layouts["dataset-page"].id, text: "サンプルデータ【2】", member_id: @member_1.id, tags: %w(タグ),
  category_ids: Opendata::Node::Category.site(@site).pluck(:id).sample(1),
  dataset_group_ids: Opendata::DatasetGroup.site(@site).pluck(:id).sample(1),
  area_ids: Opendata::Node::Area.site(@site).pluck(:id).sample(1)

dataset3 = save_data filename: "dataset/3.html", name: "サンプルデータ【3】", route: "opendata/dataset",
  layout_id: layouts["dataset-page"].id, text: "サンプルデータ【3】", member_id: @member_1.id, tags: %w(タグ),
  category_ids: Opendata::Node::Category.site(@site).pluck(:id).sample(1),
  dataset_group_ids: Opendata::DatasetGroup.site(@site).pluck(:id).sample(1),
  area_ids: Opendata::Node::Area.site(@site).pluck(:id).sample(1)

dataset4 = save_data filename: "dataset/4.html", name: "サンプルデータ【4】", route: "opendata/dataset",
  layout_id: layouts["dataset-page"].id, text: "サンプルデータ【4】", member_id: @member_1.id, tags: %w(タグ),
  category_ids: Opendata::Node::Category.site(@site).pluck(:id).sample(1),
  dataset_group_ids: Opendata::DatasetGroup.site(@site).pluck(:id).sample(1),
  area_ids: Opendata::Node::Area.site(@site).pluck(:id).sample(1)

dataset5 = save_data filename: "dataset/5.html", name: "サンプルデータ【5】", route: "opendata/dataset",
  layout_id: layouts["dataset-page"].id, text: "サンプルデータ【5】", member_id: @member_1.id, tags: %w(タグ),
  category_ids: Opendata::Node::Category.site(@site).pluck(:id).sample(1),
  estat_category_ids: [
    estat_categories["estat-bunya/estat1/estat101"].id,
    estat_categories["estat-bunya/estat5/estat501"].id
  ],
  dataset_group_ids: Opendata::DatasetGroup.site(@site).pluck(:id).sample(1),
  area_ids: Opendata::Node::Area.site(@site).pluck(:id).sample(1)

save_resource(dataset1, name: "サンプルリソース", filename: "sample.txt", license_id: license_cc_by.id)
save_resource(dataset2, name: "年齢別人口", filename: "population.csv", license_id: license_cc_by.id,
              preview_graph_state: "enabled", preview_graph_types: %w(bar line pie))
save_resource(dataset3, name: "shirasagibridge.kml", filename: "shirasagibridge.kml", license_id: license_cc_by.id)
save_resource(dataset5, name: "sample.csv", filename: "sample.csv", license_id: license_cc_by.id)
save_resource(dataset5, name: "sample2.xlsx", filename: "sample2.xlsx", license_id: license_cc_by.id)

## -------------------------------------
puts "# opendata apps"

def save_app(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }

  item = Opendata::App.find_or_create_by cond
  puts item.errors.full_messages unless item.update data
  item
end

def save_appfile(app, data)
  puts data[:filename]
  cond = { filename: data[:filename] }

  path = "apps/appfiles/#{data[:filename]}"
  Fs::UploadedFile.create_from_file(path) do |file|
    item = app.appfiles.where(cond).first || app.appfiles.new
    item.in_file = file
    puts item.errors.full_messages unless item.update data
  end
end

1.step(5) do |i|
  app = save_app filename: "app/#{i}.html", name: "サンプルアプリ【#{i}】", text: "サンプルアプリ【#{i}】",
    license: %w(MIT BSD Apache).sample, route: "opendata/app", layout_id: layouts["app-page"].id,
    member_id: @member_1.id, tags: %w(タグ),
    category_ids: Opendata::Node::Category.site(@site).pluck(:_id).sample(1),
    dataset_ids: Opendata::Dataset.site(@site).pluck(:_id).sample(1),
    area_ids: Opendata::Node::Area.site(@site).pluck(:_id).sample(1)
  if i == 1
    save_appfile(app, filename: "index.html")
  end
end

## -------------------------------------
puts "# opendata ideas"

def save_idea(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }

  item = Opendata::Idea.find_or_create_by cond
  puts item.errors.full_messages unless item.update data
  item
end

1.step(5) do |i|
  idea = save_idea filename: "idea/#{i}.html", name: "サンプルアイデア【#{i}】", text: "サンプルコメント",
    route: "opendata/idea", layout_id: layouts["idea-page"].id, member_id: @member_1.id, tags: %w(タグ),
    category_ids: Opendata::Node::Category.site(@site).pluck(:_id).sample(1),
    dataset_ids: Opendata::Dataset.site(@site).pluck(:_id).sample(1),
    app_ids: Opendata::App.site(@site).pluck(:_id).sample(1),
    area_ids: Opendata::Node::Area.site(@site).pluck(:_id).sample(1)
end

## -------------------------------------
puts "# opendata metadata"

def save_metadata_importer(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }

  item = Opendata::Metadata::Importer.find_or_create_by cond
  puts item.errors.full_messages unless item.update data
  item
end

@metadata_importer = save_metadata_importer cur_node: nodes['dataset'], cur_user: @user, name: 'シラサギ市',
  source_url: ::Addressable::URI.join(@site.full_url, 'materials/shirasagi_test_date.csv'),
  default_area_ids: [nodes['chiiki/shirasagi'].id], notice_user_ids: [@user.id]

def save_estat_category_setting(data)
  puts data[:category].name
  cond = { site_id: @site._id, importer_id: data[:importer].id, category_id: data[:category].id }

  item = Opendata::Metadata::Importer::EstatCategorySetting.find_or_create_by cond
  puts item.errors.full_messages unless item.update data
  item
end

Opendata::Node::EstatCategory.site(@site).each do |node|
  save_estat_category_setting cur_user: @user, importer: @metadata_importer,
    category: node, order: 0,
    conditions: [{ type: 'metadata_estat_category', value: node.name, operator: 'match' }.with_indifferent_access]
end

def save_metadata_report(data)
  puts data[:name]
  cond = { site_id: @site._id, importer_id: data[:importer_id] }

  item = Opendata::Metadata::Importer::Report.find_or_create_by cond
  puts item.errors.full_messages unless item.update data
  item
end

@metadata_report = save_metadata_report importer: @metadata_importer

def save_metadata_dataset(idx, data)
  dataset_report = @metadata_report.new_dataset
  cond = { site_id: @site.id, filename: data[:filename] }

  item = Opendata::Dataset.find_or_create_by cond
  attributes = data[:metadata_imported_attributes]
  data.merge!(
    {
      created: Time.zone.parse(attributes['データセット_公開日']),
      updated: Time.zone.parse(attributes['データセット_最終更新日']),
      released: Time.zone.parse(attributes['データセット_公開日']),
      name: attributes['データセット_タイトル'],
      text: attributes['データセット_概要'],
      estat_category_ids: Opendata::Node::EstatCategory.site(@site).where(name: attributes['データセット_分類']).pluck(:id),
      area_ids: @metadata_importer.default_area_ids,
      metadata_importer_id: @metadata_importer.id,
      metadata_imported: Time.zone.now,
      metadata_source_url: attributes['データセット_URL'],
      metadata_host: @metadata_importer.source_host,
      metadata_dataset_id: attributes['データセット_ID'].to_s.gsub(/\R|\s|\u00A0|　/, ''),
      metadata_japanese_local_goverment_code: attributes['全国地方公共団体コード'],
      metadata_local_goverment_name: attributes['地方公共団体名'],
      metadata_dataset_keyword: attributes['データセット_キーワード'],
      metadata_dataset_released: Time.zone.parse(attributes['データセット_公開日']),
      metadata_dataset_updated: Time.zone.parse(attributes['データセット_最終更新日']),
      metadata_dataset_url: attributes['データセット_URL'],
      metadata_dataset_update_frequency: attributes['データセット_更新頻度'],
      metadata_dataset_follow_standards: attributes['データセット_準拠する標準'],
      metadata_dataset_related_document: attributes['データセット_関連ドキュメント'],
      metadata_dataset_target_period: attributes['データセット_対象期間'],
      metadata_dataset_creator: attributes['データセット_作成者'],
      metadata_dataset_contact_name: attributes['データセット_連絡先名称'],
      metadata_dataset_contact_email: attributes['データセット_連絡先メールアドレス'],
      metadata_dataset_contact_tel: attributes['データセット_連絡先電話番号'],
      metadata_dataset_contact_ext: attributes['データセット_連絡先内線番号'],
      metadata_dataset_contact_form_url: attributes['データセット_連絡先FormURL'],
      metadata_dataset_contact_remark: attributes['データセット_連絡先備考（その他、SNSなど）'],
      metadata_dataset_remark: attributes['データセット_備考']
    }
  )
  def item.set_updated; end
  puts item.errors.full_messages unless item.update data
  save_metadata_resource(idx, item, dataset_report, data)
  puts item.errors.full_messages unless item.save
  dataset_report.set_reports(
    item, item.metadata_imported_attributes, @metadata_importer.source_url, idx
  )
  dataset_report.save
end

def save_metadata_resource(idx, dataset, report, data)
  url = data[:metadata_imported_attributes]['ファイル_ダウンロードURL']
  license = @metadata_importer.send(
    :get_license_from_metadata_uid, data[:metadata_imported_attributes]['ファイル_ライセンス']
  )
  report_resource = report.new_resource
  resource = dataset.resources.select { |r| r.source_url == url }.first
  if resource.nil?
    resource = Opendata::Resource.new
    dataset.resources << resource
  end
  filename = data[:metadata_imported_attributes]['ファイル_タイトル'].to_s + ::File.extname(url.to_s)
  resource_data = {
    source_url: url,
    name: data[:metadata_imported_attributes]['ファイル_タイトル'].presence || filename,
    text: data[:metadata_imported_attributes]['ファイル_説明'],
    filename: filename,
    format: data[:metadata_imported_attributes]['ファイル形式'],
    license: license,
    updated: Time.zone.parse(data[:metadata_imported_attributes]['ファイル_最終更新日']),
    created: Time.zone.parse(data[:metadata_imported_attributes]['ファイル_公開日']),
    metadata_importer: @metadata_importer,
    metadata_host: @metadata_importer.source_host,
    metadata_imported: Time.zone.now,
    metadata_imported_url: @metadata_importer.source_url,
    metadata_imported_attributes: data[:metadata_imported_attributes],
    metadata_file_access_url: data[:metadata_imported_attributes]['ファイル_アクセスURL'],
    metadata_file_download_url: data[:metadata_imported_attributes]['ファイル_ダウンロードURL'],
    metadata_file_released: Time.zone.parse(data[:metadata_imported_attributes]['ファイル_公開日']),
    metadata_file_updated: Time.zone.parse(data[:metadata_imported_attributes]['ファイル_最終更新日']),
    metadata_file_terms_of_service: data[:metadata_imported_attributes]['ファイル_利用規約'],
    metadata_file_related_document: data[:metadata_imported_attributes]['ファイル_関連ドキュメント'],
    metadata_file_follow_standards: data[:metadata_imported_attributes]['ファイル_準拠する標準'],
    metadata_file_copyright: data[:metadata_imported_attributes]['ファイル_著作権表記']
  }
  def resource.set_updated; end
  puts resource.errors.full_messages unless resource.update resource_data
  report_resource.set_reports(resource, dataset.metadata_imported_attributes, idx)
end

save_metadata_dataset 0, filename: "dataset/metadata_dataset1.html", route: "opendata/dataset",
  layout_id: layouts["dataset-page"].id,
  metadata_imported_attributes: {
    'データセット_ID': "1111111111",
    '全国地方公共団体コード': "111111",
    '地方公共団体名': "オオワシ県シラサギ市",
    'データセット_タイトル': "指定管理者制度導入施設一覧",
    'データセット_サブタイトル': "指定管理者制度導入施設一覧",
    'データセット_概要': "シラサギ市の指定管理者制度導入施設一覧",
    'データセット_キーワード': "指定管理",
    'データセット_分類': "行財政",
    'データセット_ユニバーサルメニュー': "観光情報;観光名所;自然;レジャー",
    'データセット_公開日': "2024/2/1",
    'データセット_最終更新日': "2024/7/1",
    'データセット_バージョン': "A1.0",
    'データセット_言語': "ja",
    'データセット_URL': "https://opendata.demo.ss-proj.org/",
    'データセット_更新頻度': "1年に1回",
    'データセット_準拠する標準': "自治体標準オープンデータセット",
    'データセット_関連ドキュメント': "http://www.test.jp/doc.html",
    'データセット_来歴情報': "2024年2月11日：3件新規追加",
    'データセット_対象地域': "オオワシ県シラサギ市",
    'データセット_対象期間': "開始年月日/終了年月日 : 2024年2月1日/2024年7月1日",
    'データセット_作成者': "○○課○○係○○担当",
    'データセット_連絡先名称': "シラサギ市 企画制作部 広報課",
    'データセット_連絡先メールアドレス': "koho@example.jp",
    'データセット_連絡先電話番号': "111-111-1111",
    'データセット_連絡先内線番号': "111-111-1111",
    'データセット_連絡先FormURL': "http://www.test.jp/doc.html",
    'データセット_連絡先備考（その他、SNSなど）': "http://www.test.jp/doc.html",
    'データセット_備考': "特になし",
    'ファイル_タイトル': "manager-system.csv",
    'ファイル_アクセスURL': "https://opendata.demo.ss-proj.org/",
    'ファイル_ダウンロードURL': "https://opendata.demo.ss-proj.org/",
    'ファイル_説明': "シラサギ市の指定管理者制度導入施設一覧",
    'ファイル形式': "csv",
    'ファイル_ライセンス': "CC BY 4.0",
    'ファイル_ステータス': "配信中",
    'ファイル_サイズ': "8053",
    'ファイル_公開日': "2024/2/1",
    'ファイル_最終更新日': "2024/7/1",
    'ファイル_利用規約': "https://opendata.demo.ss-proj.org/",
    'ファイル_関連ドキュメント': "http://www.test.jp/doc.html",
    'ファイル_言語': "ja",
    'ファイル_準拠する標準': "自治体標準オープンデータセット",
    'ファイル_API対応有無': "有",
    'ファイル_著作権表記': "株式会社〇〇"
  }.with_indifferent_access
save_metadata_dataset 1, filename: "dataset/metadata_dataset1.html", route: "opendata/dataset",
  layout_id: layouts["dataset-page"].id,
  metadata_imported_attributes: {
    'データセット_ID': "1111111111",
    '全国地方公共団体コード': "111111",
    '地方公共団体名': "オオワシ県シラサギ市",
    'データセット_タイトル': "指定管理者制度導入施設一覧",
    'データセット_サブタイトル': "指定管理者制度導入施設一覧",
    'データセット_概要': "シラサギ市の指定管理者制度導入施設一覧",
    'データセット_キーワード': "指定管理",
    'データセット_分類': "行財政",
    'データセット_ユニバーサルメニュー': "観光情報;観光名所;自然;レジャー",
    'データセット_公開日': "2024/2/1",
    'データセット_最終更新日': "2024/7/1",
    'データセット_バージョン': "A1.0",
    'データセット_言語': "ja",
    'データセット_URL': "https://opendata.demo.ss-proj.org/",
    'データセット_更新頻度': "1年に1回",
    'データセット_準拠する標準': "自治体標準オープンデータセット",
    'データセット_関連ドキュメント': "http://www.test.jp/doc.html",
    'データセット_来歴情報': "2024年2月11日：3件新規追加",
    'データセット_対象地域': "オオワシ県シラサギ市",
    'データセット_対象期間': "開始年月日/終了年月日 : 2024年2月1日/2024年7月1日",
    'データセット_作成者': "○○課○○係○○担当",
    'データセット_連絡先名称': "シラサギ市 企画制作部 広報課",
    'データセット_連絡先メールアドレス': "koho@example.jp",
    'データセット_連絡先電話番号': "111-111-1111",
    'データセット_連絡先内線番号': "111-111-1111",
    'データセット_連絡先FormURL': "http://www.test.jp/doc.html",
    'データセット_連絡先備考（その他、SNSなど）': "http://www.test.jp/doc.html",
    'データセット_備考': "特になし",
    'ファイル_タイトル': "manager-system2.csv",
    'ファイル_アクセスURL': "https://opendata.demo.ss-proj.org/dataset/",
    'ファイル_ダウンロードURL': "https://opendata.demo.ss-proj.org/dataset/",
    'ファイル_説明': "シラサギ市の指定管理者制度導入施設一覧2",
    'ファイル形式': "csv",
    'ファイル_ライセンス': "CC BY 4.0",
    'ファイル_ステータス': "配信中",
    'ファイル_サイズ': "8053",
    'ファイル_公開日': "2024/2/1",
    'ファイル_最終更新日': "2024/7/1",
    'ファイル_利用規約': "https://opendata.demo.ss-proj.org/",
    'ファイル_関連ドキュメント': "http://www.test.jp/doc.html",
    'ファイル_言語': "ja",
    'ファイル_準拠する標準': "自治体標準オープンデータセット",
    'ファイル_API対応有無': "有",
    'ファイル_著作権表記': "株式会社〇〇"
  }.with_indifferent_access
save_metadata_dataset 2, filename: "dataset/metadata_dataset2.html", route: "opendata/dataset",
  layout_id: layouts["dataset-page"].id,
  metadata_imported_attributes: {
    'データセット_ID': "2222222222",
    '全国地方公共団体コード': "222222",
    '地方公共団体名': "オオワシ県シラサギ市",
    'データセット_タイトル': "観光施設",
    'データセット_サブタイトル': "観光施設",
    'データセット_概要': "シラサギ市の観光施設一覧",
    'データセット_キーワード': "観光",
    'データセット_分類': "運輸・観光",
    'データセット_ユニバーサルメニュー': "観光情報;観光名所;自然;レジャー",
    'データセット_公開日': "2024/7/1",
    'データセット_最終更新日': "2024/8/1",
    'データセット_バージョン': "A1.0",
    'データセット_言語': "ja",
    'データセット_URL': "https://opendata.demo.ss-proj.org/",
    'データセット_更新頻度': "1年に1回",
    'データセット_準拠する標準': "自治体標準オープンデータセット",
    'データセット_関連ドキュメント': "http://www.test.jp/doc.html",
    'データセット_来歴情報': "2024年7月11日：3件新規追加",
    'データセット_対象地域': "オオワシ県シラサギ市",
    'データセット_対象期間': "開始年月日/終了年月日 : 2024年7月1日/2024年8月1日",
    'データセット_作成者': "○○課○○係○○担当",
    'データセット_連絡先名称': "シラサギ市 企画政策部 政策課",
    'データセット_連絡先メールアドレス': "seisaku@example.jp",
    'データセット_連絡先電話番号': "111-111-1111",
    'データセット_連絡先内線番号': "111-111-1111",
    'データセット_連絡先FormURL': "http://www.test.jp/doc.html",
    'データセット_連絡先備考（その他、SNSなど）': "http://www.test.jp/doc.html",
    'データセット_備考': "特になし",
    'ファイル_タイトル': "tourist-facilities.csv",
    'ファイル_アクセスURL': "https://opendata.demo.ss-proj.org/",
    'ファイル_ダウンロードURL': "https://opendata.demo.ss-proj.org/",
    'ファイル_説明': "シラサギ市観光施設一覧",
    'ファイル形式': "csv",
    'ファイル_ライセンス': "CC BY 4.0",
    'ファイル_ステータス': "配信中",
    'ファイル_サイズ': "8053",
    'ファイル_公開日': "2024/7/1",
    'ファイル_最終更新日': "2024/8/1",
    'ファイル_利用規約': "https://opendata.demo.ss-proj.org/",
    'ファイル_関連ドキュメント': "http://www.test.jp/doc.html",
    'ファイル_言語': "ja",
    'ファイル_準拠する標準': "自治体標準オープンデータセット",
    'ファイル_API対応有無': "無",
    'ファイル_著作権表記': "株式会社〇〇"
  }.with_indifferent_access
save_metadata_dataset 3, filename: "dataset/metadata_dataset3.html", route: "opendata/dataset",
  layout_id: layouts["dataset-page"].id,
  metadata_imported_attributes: {
    'データセット_ID': "3333333333",
    '全国地方公共団体コード': "333333",
    '地方公共団体名': "オオワシ県シラサギ市",
    'データセット_タイトル': "地域・年齢別人口",
    'データセット_サブタイトル': "地域・年齢別人口",
    'データセット_概要': "シラサギ市の観光施設一覧",
    'データセット_キーワード': "人口",
    'データセット_分類': "人口・世帯",
    'データセット_ユニバーサルメニュー': "観光情報;観光名所;自然;レジャー",
    'データセット_公開日': "2024/8/1",
    'データセット_最終更新日': "2024/9/1",
    'データセット_バージョン': "A1.0",
    'データセット_言語': "ja",
    'データセット_URL': "https://opendata.demo.ss-proj.org/",
    'データセット_更新頻度': "1年に1回",
    'データセット_準拠する標準': "自治体標準オープンデータセット",
    'データセット_関連ドキュメント': "http://www.test.jp/doc.html",
    'データセット_来歴情報': "2024年8月11日：3件新規追加",
    'データセット_対象地域': "オオワシ県シラサギ市",
    'データセット_対象期間': "開始年月日/終了年月日 : 2024年9月1日/2024年9月1日",
    'データセット_作成者': "○○課○○係○○担当",
    'データセット_連絡先名称': "シラサギ市 企画政策部 政策課",
    'データセット_連絡先メールアドレス': "seisaku@example.jp",
    'データセット_連絡先電話番号': "111-111-1111",
    'データセット_連絡先内線番号': "111-111-1111",
    'データセット_連絡先FormURL': "http://www.test.jp/doc.html",
    'データセット_連絡先備考（その他、SNSなど）': "http://www.test.jp/doc.html",
    'データセット_備考': "特になし",
    'ファイル_タイトル': "population.csv",
    'ファイル_アクセスURL': "https://opendata.demo.ss-proj.org/",
    'ファイル_ダウンロードURL': "https://opendata.demo.ss-proj.org/",
    'ファイル_説明': "シラサギ市地域・年齢別人口",
    'ファイル形式': "csv",
    'ファイル_ライセンス': "CC BY 4.0",
    'ファイル_ステータス': "配信中",
    'ファイル_サイズ': "8053",
    'ファイル_公開日': "2024/7/1",
    'ファイル_最終更新日': "2024/9/1",
    'ファイル_利用規約': "https://opendata.demo.ss-proj.org/",
    'ファイル_関連ドキュメント': "http://www.test.jp/doc.html",
    'ファイル_言語': "ja",
    'ファイル_準拠する標準': "自治体標準オープンデータセット",
    'ファイル_API対応有無': "有",
    'ファイル_著作権表記': "株式会社〇〇"
  }.with_indifferent_access

## -------------------------------------
puts "# rdf vocabs"

def import_vocab(data)
  puts data[:prefix]
  Rdf::VocabImportJob.bind(site_id: @site).
    perform_now(data[:prefix], data[:file], data[:owner] || Rdf::Vocab::OWNER_SYSTEM, data[:order])
end

import_vocab prefix: "xsd", file: "rdf/xsd.ttl", order: 2000
import_vocab prefix: "dcmitype", file: "rdf/dctype.ttl", order: 2000
import_vocab prefix: "dc11", file: "rdf/dcelements.ttl", order: 2000
import_vocab prefix: "dc", file: "rdf/dcterms.ttl", order: 2000
import_vocab prefix: "ic", file: "rdf/imicore242.ttl", order: 1000

## -------------------------------------
puts "# max file size"

def save_max_file_size(data)
  # 100 MiB
  data = {size: 100 * 1_024 * 1_024}.merge(data)

  puts data[:name]
  cond = { name: data[:name] }

  item = SS::MaxFileSize.find_or_create_by cond
  puts item.errors.full_messages unless item.update data
  item
end

save_max_file_size name: '画像ファイル', extensions: %w(gif png jpg jpeg bmp), order: 1, state: 'enabled'
save_max_file_size name: '音声ファイル', extensions: %w(wav wma mp3 ogg), order: 2, state: 'enabled'
save_max_file_size name: '動画ファイル', extensions: %w(wmv avi mpeg mpg flv mp4), order: 3, state: 'enabled'
save_max_file_size name: 'マクロソフト・オフィース', extensions: %w(doc docx ppt pptx xls xlsx), order: 4, state: 'enabled'
save_max_file_size name: 'PDF', extensions: %w(pdf), order: 5, state: 'enabled'
save_max_file_size name: 'その他', extensions: %w(*), order: 9999, state: 'enabled'

## -------------------------------------
puts "# word dictionary"

def save_word_dictionary(data)
  puts data[:name]
  cond = { site_id: @site.id, name: data[:name] }

  body_file = data.delete(:body_file)
  data[:body] = ::File.read(body_file)

  item = Cms::WordDictionary.find_or_initialize_by cond
  puts item.errors.full_messages unless item.update data
  item
end

save_word_dictionary name: "機種依存文字", body_file: "#{Rails.root}/db/seeds/cms/word_dictionary/dependent_characters.txt"

##
puts "# site settings"

@site.editor_css_path = '/css/ckeditor_contents.css'
@site.anti_bot_methods = %w(set_nofollow use_button_for_bulk_download)
@site.update!

if @site.subdir.present?
  # rake cms:set_subdir_url site=@site.host
  require 'rake'
  Rails.application.load_tasks
  ENV["site"]=@site.host
  Rake::Task['cms:set_subdir_url'].invoke
end

## -------------------------------------
puts "# translate_lang"
item = Translate::Lang.new
item.cur_site = @site
item.in_file = Fs::UploadedFile.create_from_file("#{Rails.root}/db/seeds/demo/translate/lang.csv")
item.import_csv
