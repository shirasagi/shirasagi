## -------------------------------------
# Require

puts "Please input site_name: site=[site_host]" or exit if ENV['site'].blank?

@site = SS::Site.where(host: ENV['site']).first
puts "Site not found: #{ENV['site']}" or exit unless @site
link_url = "http://#{@site.domains.first}"

require "#{Rails.root}/db/seeds/cms/users"
require "#{Rails.root}/db/seeds/cms/workflow"
require "#{Rails.root}/db/seeds/cms/members"

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
  item.name = data[:name] if data[:name].present?
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
  if SS.config.cms.enable_lgwan
    html.gsub!('{{ part "mypage-login" }}', '')
    html.gsub!('{{ part "mypage-tabs" }}', '')
  end
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
if SS.config.cms.enable_lgwan.blank?
  save_layout filename: "mypage-page.layout.html", name: "マイページ：詳細"
end
save_layout filename: "mypage-top.layout.html", name: "マイページ：トップ、メンバー、SPARQL"
save_layout filename: "portal-event.layout.html", name: "ポータル：イベント"
save_layout filename: "portal-general.layout.html", name: "ポータル：汎用"
save_layout filename: "portal-top.layout.html", name: "ポータル：トップ"

array   = Cms::Layout.where(site_id: @site._id).map { |m| [m.filename.sub(/\..*$/, '\1'), m] }
layouts = Hash[*array.flatten]

## -------------------------------------
puts "# nodes"

def save_node(data)
  return if SS.config.cms.enable_lgwan && data[:route].start_with?('member/')
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

if SS.config.cms.enable_lgwan.blank?
  save_node filename: "auth", name: "ログイン", route: "member/login",
            layout_id: layouts["mypage-top"].id, redirect_url: "/mypage/", form_auth: "enabled",
            twitter_oauth: "enabled", facebook_oauth: "enabled", yahoojp_oauth: "enabled",
            google_oauth2_oauth: "enabled", github_oauth: "enabled"

  save_node filename: "mypage", name: "マイページ", route: "opendata/mypage",
            layout_id: layouts["mypage-top"].id
  save_node filename: "mypage/profile", name: "プロフィール", route: "opendata/my_profile",
            layout_id: layouts["mypage-page"].id
  save_node filename: "mypage/dataset", name: "データカタログ", route: "opendata/my_dataset",
            layout_id: layouts["mypage-page"].id
  save_node filename: "mypage/app", name: "アプリマーケット", route: "opendata/my_app",
            layout_id: layouts["mypage-page"].id
  save_node filename: "mypage/idea", name: "アイデアボックス", route: "opendata/my_idea",
            layout_id: layouts["mypage-page"].id
end

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
estat_categories = Opendata::Node::EstatCategory.site(@site).map { |m| [m.filename, m] }.to_h

save_node filename: "chiiki", name: "地域", route: "cms/node"
save_node filename: "chiiki/shirasagi", name: "シラサギ市", route: "opendata/area", order: 1

[ %w(東区 higashi),
  %w(北区 kita),
  %w(南区 minami),
  %w(西区 nishi),
].each_with_index do |data, idx|
  save_node filename: "chiiki/shirasagi/#{data[1]}", name: data[0], route: "opendata/area", order: idx + 1
end

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
  return if SS.config.cms.enable_lgwan && data[:route].start_with?('member/')
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }

  html = File.read("parts/" + data[:filename]) rescue nil
  upper_html = File.read("parts/" + data[:filename].sub(/\.html$/, ".upper_html")) rescue nil
  loop_html  = File.read("parts/" + data[:filename].sub(/\.html$/, ".loop_html")) rescue nil
  lower_html = File.read("parts/" + data[:filename].sub(/\.html$/, ".lower_html")) rescue nil

  item = data[:route].sub("/", "/part/").camelize.constantize.unscoped.find_or_initialize_by(cond)
  if html
    if SS.config.cms.enable_lgwan
      html.gsub!('<li><a class="entry" href="/mypage/app/">アプリ登録</a></li>', '')
      html.gsub!('<li><a class="entry" href="/mypage/app/">アプリを登録する</a></li>', '')
      html.gsub!('<li><a class="entry" href="/mypage/dataset/">データセット登録</a></li>', '')
      html.gsub!('<li><a class="entry" href="/mypage/dataset/">データセットを登録する</a></li>', '')
      html.gsub!('<li><a class="entry" href="/mypage/idea/">アイデア登録</a></li>', '')
      html.gsub!('<li><a class="entry" href="/mypage/idea/">アイデアを登録する</a></li>', '')
    end
    item.html = html
  end
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
if SS.config.cms.enable_lgwan.blank?
  save_part filename: "mypage-login.part.html", name: "ログイン", \
    route: "opendata/mypage_login", ajax_view: "enabled"
  save_part filename: "mypage-tabs.part.html", name: "マイページ：タブ", route: "cms/free"
end
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

contact_group = SS::Group.where(name: "シラサギ市/企画政策部/政策課").first
contact_group_id = contact_group.id rescue nil
contact_charge = contact_group_id ? "オープンデータ担当" : nil
contact_email = contact_group_id ? "admin@example.jp" : nil
contact_tel = contact_group_id ? "000-000-0000" : nil
contact_fax = contact_group_id ? "000-000-0000" : nil
contact_link_url = contact_group_id ? link_url : nil
contact_link_name = contact_group_id ? link_url : nil

save_page route: "cms/page", filename: "index.html", name: "トップページ", layout_id: layouts["portal-top"].id
save_page route: "cms/page", filename: "tutorial-data.html", name: "データ登録手順", layout_id: layouts["portal-general"].id
save_page route: "cms/page", filename: "tutorial-app.html", name: "アプリ登録手順", layout_id: layouts["portal-general"].id
save_page route: "cms/page", filename: "tutorial-idea.html", name: "アイデア登録手順", layout_id: layouts["portal-general"].id
page0 = save_page route: "article/page", filename: "docs/1.html", name: "○○が公開されました。", layout_id: layouts["portal-general"].id, \
  map_points: Map::Extensions::Points.new([{loc: Map::Extensions::Loc.mongoize([34.067022, 134.589982])}]), \
  contact_group_id: contact_group_id, contact_charge: contact_charge, contact_email: contact_email, \
  contact_tel: contact_tel, contact_fax: contact_fax, contact_link_url: contact_link_url, contact_link_name: contact_link_name
page1 = save_page route: "article/page", filename: "docs/2.html", name: "○○○○○○が公開されました。", \
  layout_id: layouts["portal-general"].id, contact_group_id: contact_group_id, contact_charge: contact_charge, \
  contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax,
  contact_link_url: contact_link_url, contact_link_name: contact_link_name
page2 = save_page route: "article/page", filename: "docs/3.html", name: "○○○○○○○○が公開されました。", \
  layout_id: layouts["portal-general"].id, contact_group_id: contact_group_id, contact_charge: contact_charge, \
  contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax,
  contact_link_url: contact_link_url, contact_link_name: contact_link_name
event0 = save_page route: "event/page", filename: "event/4.html", name: "オープンデータイベント", \
  layout_id: layouts["portal-event"].id,
  schedule: "#{7.days.since.strftime("%m").sub(/^0+/, '')}月#{7.days.since.strftime("%d").sub(/^0+/, '')}日", \
  venue: "シラサギ市図書館", related_url: link_url, \
  event_dates: 7.upto(18).map { |d| d.days.since.strftime("%Y/%m/%d") }.join("\r\n")
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
                             default_state: 'default', uid: "cc-by"
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
  data.delete :filename
  Fs::UploadedFile.create_from_file(path) do |file|
    item = dataset.resources.where(cond).first || dataset.resources.new
    item.in_file = file
    item.update! data
    puts item.errors.full_messages unless item.save
  end
end

datasets = []
1.step(5) do |i|
  dataset = save_data filename: "dataset/#{i}.html", name: "サンプルデータ【#{i}】", route: "opendata/dataset",
    layout_id: layouts["dataset-page"].id, text: "サンプルデータ【#{i}】", member_id: @member_1.id, tags: %w(タグ),
    category_ids: Opendata::Node::Category.site(@site).pluck(:_id).sample(1),
    dataset_group_ids: Opendata::DatasetGroup.site(@site).pluck(:_id).sample(1),
    area_ids: Opendata::Node::Area.site(@site).pluck(:_id).sample(1)
  if i == 1
    save_resource(dataset, name: "サンプルリソース", filename: "sample.txt", license_id: license_cc_by.id)
  elsif i == 5
    save_resource(dataset, name: "sample.csv", filename: "sample.csv", license_id: license_cc_by.id)
    save_resource(dataset, name: "sample2.xlsx", filename: "sample2.xlsx", license_id: license_cc_by.id)
  end
  datasets << dataset
end

dataset5 = datasets[4]
dataset5.add_to_set(
  estat_category_ids: [
    estat_categories["estat-bunya/estat1/estat101"].id, estat_categories["estat-bunya/estat5/estat501"].id
  ]
)

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
  data.delete :filename
  Fs::UploadedFile.create_from_file(path) do |file|
    item = app.appfiles.where(cond).first || app.appfiles.new
    item.in_file = file
    item.update! data
    puts item.errors.full_messages unless item.save
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
