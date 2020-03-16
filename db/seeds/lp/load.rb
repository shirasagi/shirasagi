## -------------------------------------
# Require

puts "Please input site_name: site=[site_host]" or exit if ENV['site'].blank?

@site = SS::Site.where(host: ENV['site']).first
puts "Site not found: #{ENV['site']}" or exit unless @site
link_url = "http://#{@site.domains.first}"

require "#{Rails.root}/db/seeds/cms/users"
require "#{Rails.root}/db/seeds/cms/workflow"

Dir.chdir @root = File.dirname(__FILE__)

## -------------------------------------
puts "# files"

def upload_files(files)
  files.each do |file|
    puts name = file.sub(/^files\//, "")
    Fs.binwrite "#{@site.path}/#{name}", File.binread(file)
  end
end

upload_files %w(files/css/_carousel.scss files/css/_original.scss files/css/bootstrap.scss)
upload_files %w(files/css/ckeditor_contents.css)
upload_files Dir.glob("files/js/*.*")
upload_files Dir.glob("files/img/*.*")
upload_files Dir.glob("files/fonts/*.*")
upload_files %w(files/robots.txt)

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
  item.cur_user = @user
  item.save
  item.add_to_set group_ids: @site.group_ids

  item
end

save_layout filename: "confirm.layout.html", name: "お問い合わせ確認画面"
save_layout filename: "general.layout.html", name: "汎用"
save_layout filename: "top.layout.html", name: "トップページ"

array   = Cms::Layout.where(site_id: @site._id).map { |m| [m.filename.sub(/\..*/, ""), m] }
layouts = Hash[*array.flatten]

## -------------------------------------
puts "# parts"

def save_part(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }

  html = File.read("parts/" + data[:filename]) rescue nil
  upper_html ||= File.read("parts/" + data[:filename].sub(/\.html$/, ".upper_html")) rescue nil
  loop_html  ||= File.read("parts/" + data[:filename].sub(/\.html$/, ".loop_html")) rescue nil
  lower_html ||= File.read("parts/" + data[:filename].sub(/\.html$/, ".lower_html")) rescue nil

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

save_part route: "cms/free", filename: "about.part.html", name: "シラサギサービスについて"
save_part route: "cms/crumb", filename: "breadcrumbs.part.html", name: "パンくず"
save_part route: "cms/free", filename: "company.part.html", name: "会社概要"
save_part route: "cms/free", filename: "foot.part.html", name: "フッター"
save_part route: "cms/free", filename: "head-top.part.html", name: "ヘッダー：トップ"
save_part route: "cms/free", filename: "head.part.html", name: "ヘッダー"
save_part route: "cms/free", filename: "service.part.html", name: "サービス"
save_part route: "cms/free", filename: "service1.part.html", name: "サービス1"
save_part route: "cms/free", filename: "service2.part.html", name: "サービス2"
save_part route: "cms/free", filename: "service3.part.html", name: "サービス3"
save_part route: "cms/free", filename: "slide.part.html", name: "スライド"
save_part route: "cms/page", filename: "docs/list.part.html", name: "お知らせ", limit: 3, sort: "updated -1", conditions: %w(docs)
save_part route: "inquiry/feedback", filename: "contact/form.part.html", name: "お問い合わせ"

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

## node
save_node route: "cms/page", filename: "service1", name: "サービス1", layout_id: layouts["general"].id

## article
save_node route: "article/page", filename: "docs", name: "記事", shortcut: "show", layout_id: layouts["general"].id

## uploader
save_node route: "uploader/file", filename: "css", name: "CSS"
save_node route: "uploader/file", filename: "img", name: "画像"
save_node route: "uploader/file", filename: "js", name: "javascript"
save_node route: "uploader/file", filename: "fonts", name: "fonts"

## inquiry
inquiry_node = save_node route: "inquiry/form", filename: "contact", name: "お問い合わせ", shortcut: "show",
  layout_id: layouts["confirm"].id,
  inquiry_html: '<p>名前とメールアドレス、内容を入力してください。</p>',
  inquiry_sent_html: '<p>送信しました。</p>',
  inquiry_results_html: '<p>集計結果です。</p>',
  inquiry_captcha: "enabled",
  notice_state: "disabled",
  reply_state: "disabled",
  aggregation_state: "disabled"

## inquiry columns
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
save_inquiry_column node_id: inquiry_node.id, name: "お名前", order: 10, input_type: "text_field",
  select_options: [], required: "required", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "メールアドレス", order: 20, input_type: "email_field",
  select_options: [], required: "required", input_confirm: "enabled", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "お問い合わせ内容", order: 30, input_type: "text_area",
  select_options: [], required: "required", site_id: @site._id

## -------------------------------------
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
contact_email = contact_group_id ? "kikakuseisaku@example.jp" : nil
contact_tel = contact_group_id ? "000-000-0000" : nil
contact_fax = contact_group_id ? "000-000-0000" : nil
contact_link_url = contact_group_id ? link_url : nil
contact_link_name = contact_group_id ? link_url : nil

puts "# articles"
file1 = save_ss_files "ss_files/article/img2.jpg", filename: "img2.jpg", model: "article/page"
page1 = save_page route: "article/page", filename: "docs/page2.html", name: "サンプル1", layout_id: layouts["general"].id,
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel,
  contact_fax: contact_fax, contact_link_url: contact_link_url, contact_link_name: contact_link_name,
  group_ids: [contact_group.id],
  html: "<p><img alt=\"パソコン\" src=\"#{file1.url}\" /></p>",
  map_points: [ { loc: [34.06126, 134.576147] } ],
  file_ids: [file1.id]

file2 = save_ss_files "ss_files/article/img3.jpg", filename: "img3.jpg", model: "article/page"
page2 = save_page route: "article/page", filename: "docs/page3.html", name: "イベントがありました。", layout_id: layouts["general"].id,
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel,
  contact_fax: contact_fax, contact_link_url: contact_link_url, contact_link_name: contact_link_name,
  group_ids: [contact_group.id],
  html: "<p><img alt=\"森\" src=\"#{file2.url}\" /></p>",
  file_ids: [file2.id]

file3 = save_ss_files "ss_files/article/img4.jpg", filename: "img4.jpg", model: "article/page"
page3 = save_page route: "article/page", filename: "docs/page4.html", name: "結果を報告します。", layout_id: layouts["general"].id,
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel,
  contact_fax: contact_fax, contact_link_url: contact_link_url, contact_link_name: contact_link_name,
  group_ids: [contact_group.id],
  html: "<p><img alt=\"森\" src=\"#{file3.url}\" /></p>",
  file_ids: [file3.id]

file4 = save_ss_files "ss_files/article/img1.jpg", filename: "img1.jpg", model: "article/page"
page4 = save_page route: "article/page", filename: "docs/page1.html", name: "お知らせが入ります。", layout_id: layouts["general"].id,
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel,
  contact_fax: contact_fax, contact_link_url: contact_link_url, contact_link_name: contact_link_name,
  group_ids: [contact_group.id],
  file_ids: [file4.id]

page4.html += "<p class=\"pull-left\"><img alt=\"ベンチ\" src=\"#{file4.url}\" /></p>"
page4.html += "<p>本文を入力してください。本文を入力してください。本文を入力してください。本文を入力してください。</p>"
page4.html += "<p class=\"clearfix\">回り込みを解除します。</p>"
page4.html += "<p class=\"pull-right\"><img alt=\"ベンチ\" src=\"#{file4.url}\" /></p>"
page4.html += "<p>本文を入力してください。本文を入力してください。本文を入力してください。本文を入力してください。</p>"
page4.html += "<p class=\"clearfix\">回り込みを解除します。</p>"
page4.update

puts "# cms pages"
top_page = save_page route: "cms/page", filename: "index.html", name: "LPサンプル", layout_id: layouts["top"].id,
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel,
  contact_fax: contact_fax, contact_link_url: contact_link_url, contact_link_name: contact_link_name,
  contact_state: "hide",
  group_ids: [contact_group.id],
  map_points: [ { loc: [34.061264, 134.57611] } ]
page1.related_page_ids = [top_page.id]
page1.update

file5 = save_ss_files "ss_files/article/img1.jpg", filename: "img1_2.jpg", model: "article/page"
service_page = save_page route: "cms/page", filename: "service1/index.html", name: "サービス1", layout_id: layouts["general"].id,
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel,
  contact_fax: contact_fax, contact_link_url: contact_link_url, contact_link_name: contact_link_name,
  group_ids: [contact_group.id],
  file_ids: [file5.id]
service_page.html += "<p class=\"pull-left\"><img alt=\"ベンチ\" src=\"#{file5.url}\" /></p>"
service_page.html += "<p>本文を入力してください。本文を入力してください。本文を入力してください。本文を入力してください。</p>"
service_page.html += "<p class=\"clearfix\">回り込みを解除します。</p>"
service_page.html += "<p class=\"pull-right\"><img alt=\"ベンチ\" src=\"#{file5.url}\" /></p>"
service_page.html += "<p>本文を入力してください。本文を入力してください。本文を入力してください。本文を入力してください。</p>"
service_page.html += "<p class=\"clearfix\">回り込みを解除します。</p>"
service_page.update

save_page route: "cms/page", name: "お探しのページは見つかりません。 404 Not Found", filename: "404.html",
  layout_id: layouts["general"].id

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
save_editor_template name: "画像左回り込み",
  description: "画像が左に回り込み右側がテキストになります",
  html: editor_template_html, thumb_id: thumb_left.id, order: 10, site_id: @site.id
thumb_left.set(state: "public")

editor_template_html = File.read("editor_templates/float-right.html") rescue nil
save_editor_template name: "画像右回り込み",
  description: "画像が右に回り込み左側がテキストになります",
  html: editor_template_html, thumb_id: thumb_right.id, order: 20, site_id: @site.id
thumb_right.set(state: "public")

editor_template_html = File.read("editor_templates/clear.html") rescue nil
save_editor_template name: "回り込み解除",
  description: "回り込みを解除します",
  html: editor_template_html, order: 30, site_id: @site.id

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

## editor css path
@site.editor_css_path = '/css/ckeditor_contents.css'
@site.update

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
