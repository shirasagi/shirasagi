Dir.chdir @root = File.dirname(__FILE__)
@site = SS::Site.find_by host: ENV["site"]

## -------------------------------------
puts "# files"

Dir.glob "files/**/*.*" do |file|
  puts name = file.sub(/^files\//, "")
  Fs.binwrite "#{@site.path}/#{name}", File.binread(file)

  { scss: "css", coffee: "js" }.each_pair do |src, dst|
    if file =~ /\.#{src}$/
      site_file = "#{@site.path}/" + name.sub(/\.#{src}$/, ".#{dst}")
      Fs.rm_rf site_file
    end
  end
end

## -------------------------------------
puts "# layouts"

def save_layout(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }
  html = File.read("layouts/" + data[:filename]) rescue nil

  item = Cms::Layout.find_or_create_by(cond)
  item.update data.merge html: html
end

save_layout filename: "portal-top.layout.html", name: "ポータル：トップ"
save_layout filename: "portal-info.layout.html", name: "ポータル：お知らせ"
save_layout filename: "dataset-top.layout.html", name: "データ：トップ"
save_layout filename: "dataset-bunya.layout.html", name: "データ：分野、データ検索"
save_layout filename: "dataset-group.layout.html", name: "データ：グループ検索"
save_layout filename: "dataset-page.layout.html", name: "データ：詳細ページ"
save_layout filename: "dataset-general.layout.html", name: "データ：汎用"
save_layout filename: "idea-top.layout.html", name: "アイデア：トップ"
save_layout filename: "idea-bunya.layout.html", name: "アイデア：分野、アイデア検索"
save_layout filename: "idea-page.layout.html", name: "アイデア：詳細ページ"
save_layout filename: "idea-general.layout.html", name: "アイデア：汎用"
save_layout filename: "sparql.layout.html", name: "SPARQL"
save_layout filename: "member-general.layout.html", name: "メンバー：汎用"
save_layout filename: "mypage-login.layout.html", name: "マイページ：トップ"
save_layout filename: "mypage-general.layout.html", name: "マイページ：トップ汎用"

array   = Cms::Layout.where(site_id: @site._id).map {|m| [m.filename.sub(/\..*$/, '\1'), m] }
layouts = Hash[*array.flatten]

## -------------------------------------
puts "# nodes"

def save_node(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }

  item = Cms::Node.unscoped.find_or_create_by(cond).becomes_with_route(data[:route])
  item.update data
end

save_node filename: "css", name: "CSS", route: "uploader/file"
save_node filename: "js", name: "Javascript", route: "uploader/file"
save_node filename: "img", name: "画像", route: "uploader/file"
save_node filename: "ads", name: "広告", route: "ads/banner"

save_node filename: "info", name: "お知らせ", route: "article/page", shortcut: "show",
  layout_id: layouts["portal-info"].id
save_node filename: "event", name: "イベント", route: "event/page", shortcut: "show",
  layout_id: layouts["portal-info"].id

save_node filename: "dataset", name: "データセット", route: "opendata/dataset", shortcut: "show",
  layout_id: layouts["dataset-top"].id,
  page_layout_id: layouts["dataset-page"].id
save_node filename: "dataset/bunya", name: "分野", route: "opendata/dataset_category",
  layout_id: layouts["dataset-bunya"].id
save_node filename: "dataset/search_group", name: "データセットグループ検索", route: "opendata/search_dataset_group",
  layout_id: layouts["dataset-group"].id
save_node filename: "dataset/search", name: "データセット検索", route: "opendata/search_dataset",
  layout_id: layouts["dataset-bunya"].id

save_node filename: "app", name: "アプリ", route: "opendata/app", shortcut: "show"

save_node filename: "idea", name: "アイデア", route: "opendata/idea", shortcut: "show",
  layout_id: layouts["idea-top"].id,
  page_layout_id: layouts["idea-page"].id
save_node filename: "idea/bunya", name: "分野", route: "opendata/idea_category",
  layout_id: layouts["idea-bunya"].id
save_node filename: "idea/search", name: "アイデア検索", route: "opendata/search_idea",
  layout_id: layouts["idea-bunya"].id

save_node filename: "sparql", name: "SPARQL", route: "opendata/sparql", shortcut: "show",
  layout_id: layouts["sparql"].id
save_node filename: "api", name: "API", route: "opendata/api", shortcut: "show"

save_node filename: "member", name: "ユーザー", route: "opendata/member",
  layout_id: layouts["member-general"].id

save_node filename: "mypage", name: "マイページ", route: "opendata/mypage",
  layout_id: layouts["mypage-login"].id
save_node filename: "mypage/profile", name: "プロフィール", route: "opendata/my_profile"
save_node filename: "mypage/dataset", name: "データカタログ", route: "opendata/my_dataset"
save_node filename: "mypage/app", name: "アプリ", route: "opendata/my_app"
save_node filename: "mypage/idea", name: "アイデア", route: "opendata/my_idea"

save_node filename: "bunya", name: "分野", route: "cms/node"
save_node filename: "bunya/kurashi", name: "くらし", route: "opendata/category", order: 1
save_node filename: "bunya/kyoiku", name: "教育・文化", route: "opendata/category", order: 2
save_node filename: "bunya/kanko", name: "観光・物産", route: "opendata/category", order: 3
save_node filename: "bunya/sangyo", name: "産業・労働", route: "opendata/category", order: 4
save_node filename: "bunya/kendo", name: "県土づくり", route: "opendata/category", order: 5
save_node filename: "bunya/gyosei", name: "行政・地域", route: "opendata/category", order: 6
save_node filename: "bunya/bosai", name: "防災", route: "opendata/category", order: 7
save_node filename: "bunya/tokei", name: "統計", route: "opendata/category", order: 8

save_node filename: "chiiki", name: "地域", route: "cms/node"
save_node filename: "chiiki/tokushima", name: "徳島県", route: "opendata/area", order: 1

[ %w(徳島市 tokushima),
  %w(鳴門市 naruto),
  %w(小松島市 komatsushima),
  %w(阿南市 anan),
  %w(吉野川市 yoshinogawa),
  %w(阿波市 awa),
  %w(美馬市 mima),
  %w(三好市 miyoshi),
  %w(勝浦町 katsuura),
  %w(上勝町 kamikatsu),
  %w(佐那河内村 sanagochi),
  %w(石井町 ishii),
  %w(神山町 kamiyama),
  %w(那賀町 naka),
  %w(牟岐町 mugi),
  %w(美波町 minami),
  %w(海陽町 kaiyo),
  %w(松茂町 matsushige),
  %w(北島町 kitajima),
  %w(藍住町 aizumi),
  %w(板野町 itano),
  %w(上板町 kamiita),
  %w(つるぎ町 tsurugi),
  %w(東みよし町 higashimiyoshi),
].each_with_index do |data, idx|
  save_node filename: "chiiki/tokushima/#{data[1]}", name: data[0], route: "opendata/area", order: idx + 1
end

## set layout
[/^mypage\//].each do |name|
  Cms::Node.where(site_id: @site._id, filename: name).
    update_all(layout_id: layouts["mypage-general"].id)
end

## -------------------------------------
puts "# parts"

def save_part(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }
  html = File.read("parts/" + data[:filename]) rescue nil

  item = Cms::Part.unscoped.find_or_create_by(cond).becomes_with_route(data[:route])
  item.html = html if html
  item.update data
end

save_part filename: "tab.part.html" , name: "サイト切り替えタブ", route: "cms/free"
save_part filename: "mypage-login.part.html" , name: "ログイン", route: "opendata/mypage_login", ajax_view: "enabled"
save_part filename: "crumbs.part.html" , name: "パンくず", route: "cms/crumb"
save_part filename: "foot.part.html" , name: "フッター", route: "cms/free"
save_part filename: "ads/banner.part.html" , name: "広告", route: "ads/banner"
save_part filename: "twitter.part.html" , name: "twitter", route: "cms/free"
save_part filename: "facebook.part.html" , name: "facebook", route: "cms/free"
save_part filename: "sns-share.part.html" , name: "SNSシェアボタン", route: "cms/sns_share"
save_part filename: "portal-kv.part.html" , name: "ポータル：キービジュアル", route: "cms/free"
save_part filename: "portal-about.part.html" , name: "ポータル：Our Open Dateとは", route: "cms/free"
save_part filename: "portal-tab.part.html" , name: "ポータル：新着タブ", route: "cms/tabs", conditions: %w(info event), limit: 5
save_part filename: "portal-dataset.part.html" , name: "ポータル：オープンデータカタログ", route: "opendata/dataset", limit: 5
save_part filename: "portal-idea.part.html" , name: "ポータル：オープンアイデアボックス", route: "opendata/idea", limit: 5
save_part filename: "portal-plan.part.html" , name: "ポータル：公開予定", route: "cms/free"
save_part filename: "portal-fb.part.html" , name: "ポータル：facebook", route: "cms/free"
save_part filename: "dataset-head.part.html" , name: "データ：ヘッダー", route: "cms/free"
save_part filename: "dataset-kv.part.html" , name: "データ：キービジュアル", route: "cms/free"
save_part filename: "dataset-group.part.html" , name: "データ：グループ", route: "opendata/dataset_group"
save_part filename: "dataset-news.part.html" , name: "データ：新着順", route: "opendata/dataset", limit: 7
save_part filename: "dataset-popular.part.html" , name: "データ：人気順", route: "opendata/dataset", limit: 7
save_part filename: "dataset-attention.part.html" , name: "データ：注目順", route: "opendata/dataset", limit: 7
save_part filename: "idea-head.part.html" , name: "アイデア：ヘッダー", route: "cms/free"
save_part filename: "idea-kv.part.html" , name: "アイデア：キービジュアル", route: "cms/free"
save_part filename: "mypage-head.part.html" , name: "マイページ：ヘッダー", route: "cms/free"

## -------------------------------------
puts "# pages"

def save_page(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }

  item = Cms::Page.find_or_create_by(cond).becomes_with_route(data[:route])
  item.update data
end

body = "<p></p>"

save_page filename: "index.html", name: "トップページ", layout_id: layouts["portal-top"].id

## -------------------------------------
puts "# articles"

#1.step(3) do |i|
#  save_page filename: "info/#{i}.html", name: "サンプル記事#{i}", html: body,
#    route: "article/page", layout_id: layouts["portal-info"].id,
#    category_ids: Category::Node::Base.site(@site).pluck(:_id).sample(2)
#end

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
end

save_license name: "いかなる権利も保有しない（CC 0）", in_file: license_file("cc-zero.png"), order: 1
save_license name: "表示（CC BY）", in_file: license_file("cc-by.png"), order: 2
save_license name: "表示-継承（CC BY-SA）", in_file: license_file("cc-by-sa.png"), order: 3
save_license name: "表示-改変禁止（CC BY-ND）", in_file: license_file("cc-by-nd.png"), order: 4
save_license name: "表示-非営利（CC BY-NC）", in_file: license_file("cc-by-nc.png"), order: 5
save_license name: "表示-非営利-継承（CC BY-NC-SA）", in_file: license_file("cc-by-nc-sa.png"), order: 6
save_license name: "表示-非営利-改変禁止（CC BY-NC-ND）", in_file: license_file("cc-by-nc-nd.png"), order: 7

## -------------------------------------
puts "# opendata dataset_groups"

def save_dataset_group(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Opendata::DatasetGroup.find_or_create_by cond
  item.update data
end

#1.step(3) do |i|
#  save_dataset_group name: "データセットグループ#{i}",
#                     category_ids: Opendata::Node::Category.site(@site).pluck(:_id).sample(1)
#end

## -------------------------------------
puts "# opendata datasets"

def save_data(data)
  puts data[:name]
  cond = { site_id: @site.id, filename: data[:filename] }

  item = Opendata::Dataset.find_or_create_by cond
  puts item.errors.full_messages unless item.update data
end

#1.step(3) do |i|
#  save_data filename: "dataset/#{i}.html", name: "データセット#{i}", text: "<s>s</s>",
#    route: "opendata/dataset", layout_id: layouts["dataset-page"].id,
#    category_ids: Opendata::Node::Category.site(@site).pluck(:_id).sample(1),
#    dataset_group_ids: Opendata::DatasetGroup.site(@site).pluck(:_id).sample(1),
#    area_ids: Opendata::Node::Area.site(@site).pluck(:_id).sample(1)
#end

## -------------------------------------
puts "# opendata apps"

def save_app(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }

  item = Opendata::App.find_or_create_by cond
  item.update data
end

#1.step(3) do |i|
#  save_app name: "アプリ#{i}", text: "aaaaaa",
#    category_ids: Opendata::Node::Category.site(@site).pluck(:_id).sample(1),
#    dataset_ids: Opendata::Dataset.site(@site).pluck(:_id).sample(1)
#end

## -------------------------------------
puts "# opendata ideas"

def save_idea(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }

  item = Opendata::Idea.find_or_create_by cond
  item.update data
end

#1.step(3) do |i|
#  save_idea name: "アイデア#{i}", text: "aaaaaa",
#    category_ids: Opendata::Node::Category.site(@site).pluck(:_id).sample(1),
#    dataset_ids: Opendata::Dataset.site(@site).pluck(:_id).sample(1),
#    app_ids: Opendata::App.site(@site).pluck(:_id).sample(1)
#end
