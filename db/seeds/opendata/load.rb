# coding: utf-8

Dir.chdir @root = File.dirname(__FILE__)
@site = SS::Site.find_by host: ENV["site"]

## -------------------------------------
puts "files:"

Dir.glob "files/**/*.*" do |file|
  puts "  " + name = file.sub(/^files\//, "")
  Fs.binwrite "#{@site.path}/#{name}", File.binread(file)
end

## -------------------------------------
puts "layouts:"

def save_layout(data)
  puts "  #{data[:name]}"
  cond = { site_id: @site._id, filename: data[:filename] }
  html = File.read("layouts/" + data[:filename]) rescue nil

  item = Cms::Layout.find_or_create_by cond
  item.update data.merge html: html
end

save_layout filename: "home.layout.html", name: "オープンデータレイアウト"

array   = Cms::Layout.where(site_id: @site._id).map {|m| [m.filename.sub(/\..*$/, '\1'), m] }
layouts = Hash[*array.flatten]

## -------------------------------------
puts "nodes:"

def save_node(data)
  puts "  #{data[:name]}"
  klass = data[:route].sub("/", "/node/").camelize.constantize

  cond = { site_id: @site._id, filename: data[:filename] }
  item = klass.unscoped.find_or_create_by cond
  item.update data
end

save_node filename: "dataset", name: "データセット", route: "opendata/dataset", shortcut: "show"
save_node filename: "app", name: "アプリ", route: "opendata/app", shortcut: "show"
save_node filename: "idea", name: "アイデア", route: "opendata/idea", shortcut: "show"
save_node filename: "sparql", name: "SPARQL", route: "opendata/sparql", shortcut: "show"
save_node filename: "api", name: "API", route: "opendata/api", shortcut: "show"
save_node filename: "user", name: "ユーザーページ", route: "opendata/user", shortcut: "show"

save_node filename: "mypage", name: "マイページ", route: "opendata/mypage"

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

## layout
%w[dataset app idea sparql api user].each do |name|
  Cms::Node.where(site_id: @site._id, filename: name).update_all(layout_id: layouts["opendata"].id)
end

## -------------------------------------
puts "parts:"

def save_part(data)
  puts "  #{data[:name]}"
  klass = data[:route].sub("/", "/part/").camelize.constantize

  cond = { site_id: @site._id, filename: data[:filename] }
  item = klass.unscoped.find_or_create_by cond
  html = File.read("parts/" + data[:filename]) rescue nil
  item.html = html if html
  item.update data
end

save_part filename: "head.part.html"  , name: "ヘッダー", route: "cms/free"
save_part filename: "mypage.part.html" , name: "マイページ", route: "opendata/mypage"
save_part filename: "dataset/pages.part.html" , name: "データセットリスト", route: "opendata/dataset"
save_part filename: "app/pages.part.html" , name: "アプリリスト", route: "opendata/app"
save_part filename: "idea/pages.part.html" , name: "アイデアリスト", route: "opendata/idea"

## -------------------------------------
puts "pages:"

def save_page(data)
  puts "  #{data[:name]}"
  cond = { site_id: @site._id, filename: data[:filename] }

  item = Cms::Page.find_or_create_by cond
  item.update data
end

body = "<p></p>"

save_page filename: "index.html", name: "トップページ", layout_id: layouts["home"].id
#save_page filename: "product/index2.html", name: "仕様について", layout_id: layouts["product/index"].id, html: body

## -------------------------------------
puts "opendata data_groups:"

def save_data_group(data)
  puts "  #{data[:name]}"
  cond = { site_id: @site._id, name: data[:name] }
  item = Opendata::DataGroup.find_or_create_by cond
  item.update data
end

1.step(3) do |i|
  save_data_group name: "データグループ#{i}",
    category_ids: Opendata::Node::Category.site(@site).pluck(:_id).sample(1)
end

## -------------------------------------
puts "opendata datasets:"

def save_data(data)
  puts "  #{data[:name]}"
  cond = { site_id: @site._id, name: data[:name] }
  item = Opendata::Dataset.find_or_create_by cond
  item.update data
end

1.step(3) do |i|
  save_data name: "データセット#{i}", text: "aaaaaa",
    category_ids: Opendata::Node::Category.site(@site).pluck(:_id).sample(1),
    data_group_ids: Opendata::DataGroup.site(@site).pluck(:_id).sample(1),
    area_ids: Opendata::Node::Area.site(@site).pluck(:_id).sample(1)
end

## -------------------------------------
puts "opendata apps:"

def save_app(data)
  puts "  #{data[:name]}"
  cond = { site_id: @site._id, name: data[:name] }
  item = Opendata::App.find_or_create_by cond
  item.update data
end

1.step(3) do |i|
  save_app name: "アプリ#{i}", text: "aaaaaa",
    category_ids: Opendata::Node::Category.site(@site).pluck(:_id).sample(1),
    dataset_ids: Opendata::Dataset.site(@site).pluck(:_id).sample(1)
end

## -------------------------------------
puts "opendata ideas:"

def save_idea(data)
  puts "  #{data[:name]}"
  cond = { site_id: @site._id, name: data[:name] }
  item = Opendata::Idea.find_or_create_by cond
  item.update data
end

1.step(3) do |i|
  save_idea name: "アイデア#{i}", text: "aaaaaa",
    category_ids: Opendata::Node::Category.site(@site).pluck(:_id).sample(1),
    dataset_ids: Opendata::Dataset.site(@site).pluck(:_id).sample(1),
    app_ids: Opendata::App.site(@site).pluck(:_id).sample(1)
end
