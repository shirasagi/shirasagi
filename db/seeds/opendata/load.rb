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

save_layout filename: "opendata.layout.html", name: "オープンデータレイアウト"

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

## layout
%w[dataset app idea sparql api user].each do |name|
  Cms::Node.where(site_id: @site._id, filename: name).update_all(layout_id: layouts["opendata"].id)
end
