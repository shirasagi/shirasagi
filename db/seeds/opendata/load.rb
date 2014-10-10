# coding: utf-8

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
save_layout filename: "mypage-login.layout.html", name: "マイページ：トップ"
save_layout filename: "mypage-general.layout.html", name: "マイページ：トップ汎用"
save_layout filename: "sparql.layout.html", name: "SPARQL"

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
save_node filename: "js", name: "CSS", route: "uploader/file"
save_node filename: "img", name: "CSS", route: "uploader/file"

save_node filename: "info", name: "お知らせ", route: "article/page", shortcut: "show",
  layout_id: layouts["portal-info"].id
save_node filename: "event", name: "イベント", route: "event/page", shortcut: "show",
  layout_id: layouts["portal-info"].id

save_node filename: "dataset", name: "データセット", route: "opendata/dataset", shortcut: "show",
  layout_id: layouts["dataset-top"].id,
  dataset_layout_id: layouts["dataset-page"].id
save_node filename: "dataset/bunya", name: "分野", route: "opendata/dataset_category", shortcut: "show",
  layout_id: layouts["dataset-bunya"].id
save_node filename: "dataset/search_group", name: "グループ検索", route: "opendata/search_group", shortcut: "show",
  layout_id: layouts["dataset-group"].id
save_node filename: "dataset/search", name: "データセット検索", route: "opendata/search_dataset", shortcut: "show",
  layout_id: layouts["dataset-bunya"].id

save_node filename: "app", name: "アプリ", route: "opendata/app", shortcut: "show"
save_node filename: "idea", name: "アイデア", route: "opendata/idea", shortcut: "show"
save_node filename: "sparql", name: "SPARQL", route: "opendata/sparql", shortcut: "show",
  layout_id: layouts["sparql"].id
save_node filename: "api", name: "API", route: "opendata/api", shortcut: "show"

save_node filename: "mypage", name: "マイページ", route: "opendata/mypage",
  layout_id: layouts["mypage-login"].id
save_node filename: "mypage/profile", name: "プロフィール", route: "opendata/my_profile"
save_node filename: "mypage/dataset", name: "データカタログ", route: "opendata/my_dataset"
save_node filename: "mypage/app", name: "アプリ", route: "opendata/my_app"
save_node filename: "mypage/idea", name: "アイデア", route: "opendata/my_idea"

save_node filename: "bunya", name: "分野", route: "cms/node"
save_node filename: "bunya/kurashi", name: "くらし", route: "opendata/category", order: 1
save_node filename: "bunya/kyoiku", name: "教育・分野", route: "opendata/category", order: 2
save_node filename: "bunya/kanko", name: "観光・物産", route: "opendata/category", order: 3
save_node filename: "bunya/sangyo", name: "産業・労働", route: "opendata/category", order: 4
save_node filename: "bunya/kendo", name: "県土づくり", route: "opendata/category", order: 5
save_node filename: "bunya/gyosei", name: "行政・地域", route: "opendata/category", order: 6
save_node filename: "bunya/bosai", name: "防災", route: "opendata/category", order: 7
save_node filename: "bunya/tokei", name: "統計", route: "opendata/category", order: 8

save_node filename: "chiiki", name: "地域", route: "cms/node"
save_node filename: "chiiki/tokushimaken", name: "徳島県", route: "opendata/area", order: 1
save_node filename: "chiiki/tokushimashi", name: "徳島市", route: "opendata/area", order: 2
save_node filename: "chiiki/narutoshi", name: "鳴門市", route: "opendata/area", order: 3
save_node filename: "chiiki/komatsushimashi", name: "小松島市", route: "opendata/area", order: 4
save_node filename: "chiiki/ananshi", name: "阿南市", route: "opendata/area", order: 5
save_node filename: "chiiki/yoshinogawashi", name: "吉野川市", route: "opendata/area", order: 6
save_node filename: "chiiki/awashi", name: "阿波市", route: "opendata/area", order: 7
save_node filename: "chiiki/mimashi", name: "美馬市", route: "opendata/area", order: 8
save_node filename: "chiiki/miyoshishi", name: "三好市", route: "opendata/area", order: 9

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
save_part filename: "add.part.html" , name: "広告", route: "cms/free"
save_part filename: "twitter.part.html" , name: "twitter", route: "cms/free"
save_part filename: "facebook.part.html" , name: "facebook", route: "cms/free"
save_part filename: "portal-kv.part.html" , name: "ポータル：キービジュアル", route: "cms/free"
save_part filename: "portal-about.part.html" , name: "ポータル：Our Open Dateとは", route: "cms/free"
save_part filename: "portal-tab.part.html" , name: "ポータル：新着タブ", route: "cms/tabs", conditions: %w(info event), limit: 5
save_part filename: "portal-dataset.part.html" , name: "ポータル：オープンデータカタログ", route: "opendata/dataset"
save_part filename: "portal-plan.part.html" , name: "ポータル：公開予定", route: "cms/free"
save_part filename: "portal-fb.part.html" , name: "ポータル：facebook", route: "cms/free"
save_part filename: "dataset-head.part.html" , name: "データ：ヘッダー", route: "cms/free"
save_part filename: "dataset-kv.part.html" , name: "データ：キービジュアル", route: "cms/free"
save_part filename: "dataset-group.part.html" , name: "データ：グループ", route: "opendata/dataset_group"
save_part filename: "dataset-news.part.html" , name: "データ：新着順", route: "opendata/dataset"
save_part filename: "dataset-popular.part.html" , name: "データ：人気順", route: "opendata/dataset"
save_part filename: "dataset-attention.part.html" , name: "データ：注目順", route: "opendata/dataset"
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

1.step(3) do |i|
  save_page filename: "info/#{i}.html", name: "サンプル記事#{i}", html: body,
    route: "article/page", layout_id: layouts["portal-info"].id,
    category_ids: Category::Node::Base.site(@site).pluck(:_id).sample(2)
end

## -------------------------------------
puts "# opendata dataset_groups"

def save_dataset_group(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Opendata::DatasetGroup.find_or_create_by cond
  item.update data
end

1.step(3) do |i|
  save_dataset_group name: "データグループ#{i}",
                  category_ids: Opendata::Node::Category.site(@site).pluck(:_id).sample(1)
end

## -------------------------------------
puts "# opendata datasets"

def save_data(data)
  puts data[:name]
  cond = { site_id: @site.id, filename: data[:filename] }

  item = Opendata::Dataset.find_or_create_by cond
  puts item.errors.full_messages unless item.update data
end

1.step(3) do |i|
  save_data filename: "dataset/#{i}.html", name: "データセット#{i}", text: "<s>s</s>",
    route: "opendata/dataset", layout_id: layouts["dataset-page"].id,
    category_ids: Opendata::Node::Category.site(@site).pluck(:_id).sample(1),
    dataset_group_ids: Opendata::DatasetGroup.site(@site).pluck(:_id).sample(1),
    area_ids: Opendata::Node::Area.site(@site).pluck(:_id).sample(1),
    license: "CC"
end

## -------------------------------------
puts "# opendata apps"

def save_app(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }

  item = Opendata::App.find_or_create_by cond
  item.update data
end

1.step(3) do |i|
#  save_app name: "アプリ#{i}", text: "aaaaaa",
#    category_ids: Opendata::Node::Category.site(@site).pluck(:_id).sample(1),
#    dataset_ids: Opendata::Dataset.site(@site).pluck(:_id).sample(1)
end

## -------------------------------------
puts "# opendata ideas"

def save_idea(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }

  item = Opendata::Idea.find_or_create_by cond
  item.update data
end

1.step(3) do |i|
#  save_idea name: "アイデア#{i}", text: "aaaaaa",
#    category_ids: Opendata::Node::Category.site(@site).pluck(:_id).sample(1),
#    dataset_ids: Opendata::Dataset.site(@site).pluck(:_id).sample(1),
#    app_ids: Opendata::App.site(@site).pluck(:_id).sample(1)
end
