# site=kanamic
puts "Please input site_name: site=[site_host]" or exit if ENV['site'].blank?

@site = Cms::Site.where(host: ENV['site']).first
puts "Site not found: #{ENV['site']}" or exit unless @site
link_url = "http://#{@site.domains.first}"

require "#{Rails.root}/db/seeds/cms/users"
require "#{Rails.root}/db/seeds/cms/workflow"

Dir.chdir @root = File.dirname(__FILE__)

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

CSS_PATHS = %w(/css/style.css).freeze
# JS_PATHS = %w(/js/common.js /js/heightLine.js).freeze

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

save_layout filename: "index.layout.html", name: "トップページ",
  css_paths: CSS_PATHS,
  # js_paths: JS_PATHS,
  part_paths: %w(
    header_text.part.html index.part.html
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

save_part route: "cms/free", filename: "header_text.part.html", name: "header_text",
  mobile_view: "disabled"

save_part route: "cms/free", filename: "inner.part.html", name: "inner",
  mobile_view: "disabled"

save_part route: "cms/free", filename: "mobile_inner.part.html", name: "mobile_inner",
  mobile_view: "enabled"

save_part route: "cms/free", filename: "news2.part.html", name: "news2",
  mobile_view: "enabled"

save_part route: "cms/free", filename: "main/news3.part.html", name: "news3",
  mobile_view: "enabled"

save_part route: "cms/free", filename: "main/sp_banner_box.part.html", name: "sp_banner_box",
  mobile_view: "enabled"

save_part route: "cms/free", filename: "main/top_news.part.html", name: "top_news",
  mobile_view: "enabled"

save_part route: "cms/free", filename: "main/top_renkei.part.html", name: "top_renkei",
  mobile_view: "enabled"

save_part route: "cms/free", filename: "main/top_kaigo.part.html", name: "top_kaigo",
  mobile_view: "enabled"

save_part route: "cms/free", filename: "main/top_kosodate.part.html", name: "top_kosodate",
  mobile_view: "enabled"

save_part route: "cms/free", filename: "main/questionlist.part.html", name: "questionlist",
  mobile_view: "enabled"

save_part route: "cms/free", filename: "main/topsecurity.part.html", name: "topsecurity",
  mobile_view: "enabled"

save_part route: "cms/free", filename: "main/more_kanamic.part.html", name: "more_kanamic",
  mobile_view: "enabled"

save_part route: "cms/free", filename: "footer.part.html", name: "footer",
  mobile_view: "enabled"

save_part route: "cms/free", filename: "footer2nd.part.html", name: "footer2nd",
  mobile_view: "enabled"

## -------------------------------------
puts "# nodes"

def save_node(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename], route: data[:route] }

  upper_html = File.read("nodes/" + data[:filename] + ".upper_html") rescue nil
  loop_html  = File.read("nodes/" + data[:filename] + ".loop_html") rescue nil
  lower_html = File.read("nodes/" + data[:filename] + ".lower_html") rescue nil
  summary_html = File.read("nodes/" + data[:filename] + ".summary_html") rescue nil

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

## uploader
save_node route: "uploader/file", name: "CSS", filename: "css"
save_node route: "uploader/file", name: "画像", filename: "img"
save_node route: "uploader/file", name: "JavaScript", filename: "js"

save_node route: "uploader/file", name: "Care", filename: "care"
save_node route: "uploader/file", name: "Medical", filename: "medical"
save_node route: "uploader/file", name: "Login", filename: "login"

## -------------------------------------
puts "# pages"
def save_page(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }

  html ||= File.read("pages/" + data[:filename]) rescue nil
  summary_html ||= File.read("pages/" + data[:filename].sub(/\.html$/, "") + ".summary_html") rescue nil

  route = data[:route].presence || 'cms/page'
  item = route.camelize.constantize.unscoped.find_or_initialize_by(cond)
  item.html = html if html
  item.summary_html = summary_html if summary_html

  item.attributes = data
  item.cur_user = @user
  item.save
  item.add_to_set group_ids: @site.group_ids

  item
end

save_page route: "cms/page", filename: "index.html", name: "介護ソフト・介護システム大手｜東証プライム上場企業のカナミック", layout_id: layouts["index"].id