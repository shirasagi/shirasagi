Dir.chdir @root = File.dirname(__FILE__)
@site = SS::Site.find_by host: ENV["site"]

## -------------------------------------
puts "# files"

Dir.glob "files/**/*.*" do |file|
  puts name = file.sub(/^files\//, "")
  Fs.binwrite "#{@site.path}/#{name}", File.binread(file)
end

def save_ss_files(path, data)
  puts path
  cond = { filename: data[:filename], model: data[:model] }

  file = Fs::UploadedFile.create_from_file(path)
  file.original_filename = data[:filename] if data[:filename].present?

  item = SS::File.find_or_create_by(cond)
  item.in_file = file
  item.update

  item
end

## -------------------------------------
puts "# members"

def save_member(data)
  puts data[:name]
  cond = { site_id: @site._id, email: data[:email] }

  item = Cms::Member.find_or_create_by(cond)
  item.attributes = data
  item.update

  item
end

member = save_member email: "admin@example.jp", name: "admin", in_password: "pass"

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

save_layout filename: "app-bunya.layout.html", name: "アプリ：分野、アプリ検索"
save_layout filename: "app-page.layout.html", name: "アプリ：詳細ページ"
save_layout filename: "app-top.layout.html", name: "アプリ：トップ"
save_layout filename: "dataset-bunya.layout.html", name: "データ：分野、データ検索、グループ検索"
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

array   = Cms::Layout.where(site_id: @site._id).map {|m| [m.filename.sub(/\..*$/, '\1'), m] }
layouts = Hash[*array.flatten]

## -------------------------------------
puts "# nodes"

def save_node(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }

  upper_html ||= File.read("nodes/" + data[:filename] + ".upper_html") rescue nil
  loop_html  ||= File.read("nodes/" + data[:filename] + ".loop_html") rescue nil
  lower_html ||= File.read("nodes/" + data[:filename] + ".lower_html") rescue nil
  summary_html ||= File.read("nodes/" + data[:filename] + ".summary_html") rescue nil

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
save_node filename: "mypage/profile", name: "プロフィール", route: "opendata/my_profile",
  layout_id: layouts["mypage-page"].id
save_node filename: "mypage/dataset", name: "データカタログ", route: "opendata/my_dataset",
  layout_id: layouts["mypage-page"].id
save_node filename: "mypage/app", name: "アプリマーケット", route: "opendata/my_app",
  layout_id: layouts["mypage-page"].id
save_node filename: "mypage/idea", name: "アイデアボックス", route: "opendata/my_idea",
  layout_id: layouts["mypage-page"].id

save_node filename: "bunya", name: "分野", route: "cms/node"
save_node filename: "bunya/kanko", name: "観光・文化・スポーツ", route: "opendata/category", order: 1
save_node filename: "bunya/kenko", name: "健康・福祉", route: "opendata/category", order: 2
save_node filename: "bunya/kosodate", name: "子育て・教育", route: "opendata/category", order: 3
save_node filename: "bunya/kurashi", name: "くらし・手続き", route: "opendata/category", order: 4
save_node filename: "bunya/sangyo", name: "産業・仕事", route: "opendata/category", order: 5
save_node filename: "bunya/shisei", name: "市政情報", route: "opendata/category", order: 6

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

## -------------------------------------
puts "# pages"

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

contact_group = SS::Group.where(name: "シラサギ市/企画政策部/政策課").first
contact_group_id = contact_group.id rescue nil
contact_charge = contact_group_id ? "オープンデータ担当" : nil
contact_email = contact_group_id ? "admin@example.jp" : nil
contact_tel = contact_group_id ? "000-000-0000" : nil
contact_fax = contact_group_id ? "000-000-0000" : nil

save_page route: "cms/page", filename: "index.html", name: "トップページ", layout_id: layouts["portal-top"].id
save_page route: "cms/page", filename: "tutorial-data.html", name: "データ登録手順", layout_id: layouts["portal-general"].id
save_page route: "cms/page", filename: "tutorial-app.html", name: "アプリ登録手順", layout_id: layouts["portal-general"].id
save_page route: "cms/page", filename: "tutorial-idea.html", name: "アイデア登録手順", layout_id: layouts["portal-general"].id
page0 = save_page route: "article/page", filename: "docs/1.html", name: "○○が公開されました。", layout_id: layouts["portal-general"].id, \
  map_points: Map::Extensions::Points.new([{loc: Map::Extensions::Loc.mongoize([34.067022, 134.589982])}]), \
  contact_group_id: contact_group_id, contact_charge: contact_charge, contact_email: contact_email, \
  contact_tel: contact_tel, contact_fax: contact_fax
page1 = save_page route: "article/page", filename: "docs/2.html", name: "○○○○○○が公開されました。", \
  layout_id: layouts["portal-general"].id, contact_group_id: contact_group_id, contact_charge: contact_charge, \
  contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
page2 = save_page route: "article/page", filename: "docs/3.html", name: "○○○○○○○○が公開されました。", \
  layout_id: layouts["portal-general"].id, contact_group_id: contact_group_id, contact_charge: contact_charge, \
  contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
event0 = save_page route: "event/page", filename: "event/4.html", name: "オープンデータイベント", \
  layout_id: layouts["portal-event"].id,
  schedule: "#{7.days.since.strftime("%m").sub(/^0+/, '')}月#{7.days.since.strftime("%d").sub(/^0+/, '')}日", \
  venue: "シラサギ市図書館", related_url: "http://demo.ss-proj.org/", \
  event_dates: 7.upto(18).map { |d| "#{d.days.since.strftime("%Y/%m/%d")}" }.join("\r\n")
page0.related_page_ids = [ page2.id, event0.id ]
page0.save!

## -------------------------------------
puts "# ads"

banner1 = save_ss_files "ss_files/ads/banner.gif", filename: "banner.gif", model: "ads/banner"
banner2 = save_ss_files "ss_files/ads/banner.gif", filename: "banner.gif", model: "ads/banner"
banner3 = save_ss_files "ss_files/ads/banner.gif", filename: "banner.gif", model: "ads/banner"
banner4 = save_ss_files "ss_files/ads/banner.gif", filename: "banner.gif", model: "ads/banner"
banner5 = save_ss_files "ss_files/ads/banner.gif", filename: "banner.gif", model: "ads/banner"
banner6 = save_ss_files "ss_files/ads/banner.gif", filename: "banner.gif", model: "ads/banner"

save_page route: "ads/banner", filename: "ads/600.html", name: "シラサギ", link_url: "http://www.ss-proj.org/", file_id: banner1.id
save_page route: "ads/banner", filename: "ads/601.html", name: "シラサギ", link_url: "http://www.ss-proj.org/", file_id: banner2.id
save_page route: "ads/banner", filename: "ads/602.html", name: "シラサギ", link_url: "http://www.ss-proj.org/", file_id: banner3.id
save_page route: "ads/banner", filename: "ads/603.html", name: "シラサギ", link_url: "http://www.ss-proj.org/", file_id: banner4.id
save_page route: "ads/banner", filename: "ads/604.html", name: "シラサギ", link_url: "http://www.ss-proj.org/", file_id: banner5.id
save_page route: "ads/banner", filename: "ads/605.html", name: "シラサギ", link_url: "http://www.ss-proj.org/", file_id: banner6.id

## -------------------------------------
puts "# licenses"

def license_file(filename)
  file = Fs::UploadedFile.new("fixtures")
  file.binmode
  file.write File.read("fixtures/#{filename}")
  file.rewind
  file.original_filename = filename
  file.content_type = "image/png"
  file
end

def save_license(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Opendata::License.find_or_create_by cond
  item.update data
  item
end

license_cc_by = save_license name: "表示（CC BY）", in_file: license_file("cc-by.png"), order: 1
save_license name: "表示-継承（CC BY-SA）", in_file: license_file("cc-by-sa.png"), order: 2
save_license name: "表示-改変禁止（CC BY-ND）", in_file: license_file("cc-by-nd.png"), order: 3
save_license name: "表示-非営利（CC BY-NC）", in_file: license_file("cc-by-nc.png"), order: 4
save_license name: "表示-非営利-継承（CC BY-NC-SA）", in_file: license_file("cc-by-nc-sa.png"), order: 5
save_license name: "表示-非営利-改変禁止（CC BY-NC-ND）", in_file: license_file("cc-by-nc-nd.png"), order: 6
save_license name: "いかなる権利も保有しない（CC 0）", in_file: license_file("cc-zero.png"), order: 7

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
    item.update_attributes! data
    puts item.errors.full_messages unless item.save
  end
end

1.step(5) do |i|
  dataset = save_data filename: "dataset/#{i}.html", name: "サンプルデータ【#{i}】", text: "サンプルデータ【#{i}】",
    route: "opendata/dataset", layout_id: layouts["dataset-page"].id, member_id: member.id, tags: %w(タグ),
    category_ids: Opendata::Node::Category.site(@site).pluck(:_id).sample(1),
    dataset_group_ids: Opendata::DatasetGroup.site(@site).pluck(:_id).sample(1),
    area_ids: Opendata::Node::Area.site(@site).pluck(:_id).sample(1)
  if i == 1
    save_resource(dataset, name: "サンプルリソース", filename: "sample.txt", license_id: license_cc_by.id)
  end
end

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
    item.update_attributes! data
    puts item.errors.full_messages unless item.save
  end
end

1.step(5) do |i|
  app = save_app filename: "app/#{i}.html", name: "サンプルアプリ【#{i}】", text: "サンプルアプリ【#{i}】",
    license: %w(MIT BSD Apache).sample, route: "opendata/app", layout_id: layouts["app-page"].id,
    member_id: member.id, tags: %w(タグ),
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
    route: "opendata/idea", layout_id: layouts["idea-page"].id, member_id: member.id, tags: %w(タグ),
    category_ids: Opendata::Node::Category.site(@site).pluck(:_id).sample(1),
    dataset_ids: Opendata::Dataset.site(@site).pluck(:_id).sample(1),
    app_ids: Opendata::App.site(@site).pluck(:_id).sample(1),
    area_ids: Opendata::Node::Area.site(@site).pluck(:_id).sample(1)
end

## -------------------------------------
puts "# rdf vocabs"

def import_vocab(data)
  puts data[:prefix]
  Rdf::VocabImportJob.new.call(@site.host, data[:prefix], data[:file], data[:owner] || Rdf::Vocab::OWNER_SYSTEM, data[:order])
end

import_vocab prefix: "xsd", file: "rdf/xsd.ttl", order: 2000
import_vocab prefix: "dcmitype", file: "rdf/dctype.ttl", order: 2000
import_vocab prefix: "dc11", file: "rdf/dcelements.ttl", order: 2000
import_vocab prefix: "dc", file: "rdf/dcterms.ttl", order: 2000
import_vocab prefix: "ic", file: "rdf/ipa-core.ttl", order: 1000
