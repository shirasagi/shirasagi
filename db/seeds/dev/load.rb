## -------------------------------------
# Require

puts "Please input site_name: site=[site_host]" or exit if ENV['site'].blank?

@site = Cms::Site.where(host: ENV['site']).first
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

  item
end

save_layout filename: "home.layout.html", name: "トップレイアウト"
save_layout filename: "page.layout.html", name: "汎用レイアウト"
save_layout filename: "docs/index.layout.html", name: "記事レイアウト"
save_layout filename: "product/index.layout.html", name: "製品情報レイアウト"
save_layout filename: "recruit/index.layout.html", name: "採用情報レイアウト"

array = Cms::Layout.where(site_id: @site._id).map { |m| [m.filename.sub(/\..*$/, '\1'), m] }
layouts = Hash[*array.flatten]

## -------------------------------------
puts "# nodes"

def save_node(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }

  item = data[:route].sub("/", "/node/").camelize.constantize.unscoped.find_or_initialize_by(cond)
  item.attributes = data
  item.cur_user = @user
  item.save

  item
end

save_node filename: "css", name: "CSS", route: "uploader/file", shortcut: "show"

save_node filename: "docs", name: "記事", route: "article/page", shortcut: "show"
save_node filename: "topics", name: "注目記事", route: "category/page", shortcut: "show", conditions: %w(product)

save_node filename: "product", name: "製品情報", route: "cms/node", shortcut: "show"
save_node filename: "product/word", name: "文書管理", route: "cms/page"
save_node filename: "product/calc", name: "表計算", route: "cms/page"

save_node filename: "recruit", name: "採用情報", shortcut: "show", route: "category/node"
save_node filename: "recruit/sales", name: "営業部", route: "category/page"
save_node filename: "recruit/devel", name: "開発部", route: "category/page"

save_node route: "event/page", filename: "plan", name: "事業計画", shortcut: "show"

## layout
Cms::Node.where(site_id: @site._id, filename: /^topics/).update_all(layout_id: layouts["page"].id)
Cms::Node.where(site_id: @site._id, filename: /^docs/).update_all(layout_id: layouts["page"].id)
Cms::Node.where(site_id: @site._id, filename: /^product/).update_all(layout_id: layouts["product/index"].id)
Cms::Node.where(site_id: @site._id, filename: /^recruit/).update_all(layout_id: layouts["recruit/index"].id)
Cms::Node.where(site_id: @site._id, filename: /^plan/).update_all(layout_id: layouts["page"].id)

## -------------------------------------
puts "# parts"

def save_part(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }
  html = File.read("parts/" + data[:filename]) rescue nil

  item = data[:route].sub("/", "/part/").camelize.constantize.unscoped.find_or_initialize_by(cond)
  item.html = html if html
  item.attributes = data
  item.cur_user = @user
  item.save

  item
end

save_part filename: "head.part.html", name: "ヘッダー", route: "cms/free"
save_part filename: "navi.part.html", name: "ナビ", route: "cms/free"
save_part filename: "foot.part.html", name: "フッター", route: "cms/free"
save_part filename: "crumbs.part.html", name: "パンくず", route: "cms/crumb"
save_part filename: "tabs.part.html", name: "新着タブ", route: "cms/tabs",
  conditions: %w(topics product recruit), limit: 5, ajax_view: "enabled"

save_part filename: "docs/pages.part.html", name: "新着記事リスト", route: "article/page"
save_part filename: "topics/pages.part.html", name: "注目記事リスト", route: "cms/page", conditions: %w(product)

save_part filename: "product/nodes.part.html", name: "製品情報/フォルダ", route: "cms/node"
save_part filename: "product/pages.part.html", name: "製品情報/ページ", route: "cms/page"

save_part filename: "recruit/nodes.part.html", name: "採用情報/フォルダ", route: "category/node"
save_part filename: "recruit/pages.part.html", name: "採用情報/ページ", route: "cms/page"

## -------------------------------------
puts "# pages"

def save_page(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }

  route = data[:route].presence || 'cms/page'
  item = route.camelize.constantize.find_or_initialize_by(cond)
  item.attributes = data
  item.cur_user = @user
  item.save

  item
end

body = "<p>#{'本文です。<br />' * 3}</p>" * 2

save_page filename: "index.html", name: "トップページ", layout_id: layouts["home"].id
save_page filename: "product/index2.html", name: "仕様について", layout_id: layouts["product/index"].id, html: body
save_page filename: "product/index3.html", name: "サポートについて", layout_id: layouts["product/index"].id, html: body
save_page filename: "product/word/page1.html", name: "仕様", layout_id: layouts["product/index"].id, html: body
save_page filename: "product/word/page2.html", name: "環境", layout_id: layouts["product/index"].id, html: body
save_page filename: "product/calc/page3.html", name: "価格", layout_id: layouts["product/index"].id, html: body
save_page filename: "product/calc/page4.html", name: "実績", layout_id: layouts["product/index"].id, html: body

## -------------------------------------
puts "# articles"

1.step(9) do |i|
  save_page filename: "docs/#{i}.html", name: "サンプル記事#{i}", html: body,
    route: "article/page", layout_id: layouts["page"].id,
    category_ids: Category::Node::Base.site(@site).pluck(:_id).sample(2)
end

## -------------------------------------
puts "# word dictionary"

def save_word_dictionary(data)
  puts data[:name]
  cond = { site_id: @site.id, name: data[:name] }

  body_file = data.delete(:body_file)
  data[:body] = File.read(body_file)

  item = Cms::WordDictionary.find_or_initialize_by cond
  puts item.errors.full_messages unless item.update data
  item
end

save_word_dictionary name: "機種依存文字", body_file: "#{Rails.root}/db/seeds/cms/word_dictionary/dependent_characters.txt"

if @site.subdir.present?
  # rake cms:set_subdir_url site=@site.host
  require 'rake'
  Rails.application.load_tasks
  ENV["site"]=@site.host
  Rake::Task['cms:set_subdir_url'].invoke
end
