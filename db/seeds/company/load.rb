Dir.chdir @root = File.dirname(__FILE__)
@site = SS::Site.find_by host: ENV["site"]

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

  item = Cms::Layout.find_or_create_by(cond)
  item.attributes = data.merge html: html
  item.update
  item.add_to_set group_ids: @site.group_ids

  item
end

save_layout filename: "company.layout.html", name: "会社案内",
  css_paths: %w(/css/style.css), js_paths: %w(/js/common.js /js/selectivizr.js),
  part_paths: %w(head.part.html breadcrumbs.part.html company/side-menu.part.html page-top.part.html foot.part.html)
save_layout filename: "news.layout.html", name: "ニュース",
  css_paths: %w(/css/style.css), js_paths: %w(/js/common.js /js/selectivizr.js),
  part_paths: %w(head.part.html breadcrumbs.part.html news/side-menu.part.html page-top.part.html, foot.part.html)
save_layout filename: "one.layout.html", name: "1カラム",
  css_paths: %w(/css/style.css), js_paths: %w(/js/common.js /js/selectivizr.js),
  part_paths: %w(head.part.html breadcrumbs.part.html page-top.part.html foot.part.html)
save_layout filename: "product-top.layout.html", name: "製品サービス:トップ",
  css_paths: %w(/css/style.css), js_paths: %w(/js/common.js /js/selectivizr.js),
  part_paths: %w(
    head.part.html breadcrumbs.part.html product/solution/side-menu.part.html product/software/side-menu.part.html
    product/office/side-menu.part.html product/marketing/side-menu.part.html product/solution/solution.part.html
    product/software/software.part.html product/office/office.part.html product/marketing/marketing.part.html
    page-top.part.html foot.part.html)
save_layout filename: "product.layout.html", name: "製品サービス",
  css_paths: %w(/css/style.css), js_paths: %w(/js/common.js /js/selectivizr.js),
  part_paths: %w(
    head.part.html breadcrumbs.part.html product/solution/side-menu.part.html product/software/side-menu.part.html
    product/office/side-menu.part.html product/marketing/side-menu.part.html page-top.part.html foot.part.html)
save_layout filename: "recruit.layout.html", name: "採用情報",
  css_paths: %w(/css/style.css), js_paths: %w(/js/common.js /js/selectivizr.js),
  part_paths: %w(head.part.html breadcrumbs.part.html recruit/side-menu.part.html page-top.part.html foot.part.html)
save_layout filename: "sitemap.layout.html", name: "サイトマップ",
  css_paths: %w(/css/style.css), js_paths: %w(/js/common.js /js/selectivizr.js),
  part_paths: %w(head.part.html breadcrumbs.part.html page-top.part.html foot.part.html)
save_layout filename: "top.layout.html", name: "トップページ",
  css_paths: %w(/css/style.css), js_paths: %w(/js/camera.min.js /js/keyvisual.js /js/common.js /js/selectivizr.js),
  part_paths: %w(
    head.part.html keyvisual.part.html news.part.html inquiry.part.html
    product/folder-list.part.html connection.part.html page-top.part.html
    foot-top.part.html)

array   = Cms::Layout.where(site_id: @site._id).map { |m| [m.filename.sub(/\..*/, ""), m] }
layouts = Hash[*array.flatten]

## -------------------------------------
puts "# nodes"

def save_node(data)
  puts data[:name]
  klass = data[:route].sub("/", "/node/").singularize.camelize.constantize
  cond = { site_id: @site._id, filename: data[:filename] }

  upper_html = File.read("nodes/" + data[:filename] + ".upper_html") rescue nil
  loop_html  = File.read("nodes/" + data[:filename] + ".loop_html") rescue nil
  lower_html = File.read("nodes/" + data[:filename] + ".lower_html") rescue nil
  summary_html = File.read("nodes/" + data[:filename] + ".summary_html") rescue nil

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

save_node route: "cms/node", filename: "company", name: "会社案内", shortcut: "show", layout_id: layouts["company"].id
save_node route: "uploader/file", name: "CSS", filename: "css", shortcut: "show"
save_node route: "uploader/file", name: "画像", filename: "img", shortcut: "show"
save_node route: "uploader/file", name: "JavaScript", filename: "js", shortcut: "show"
save_node route: "article/page", name: "ニュース", filename: "news", shortcut: "show", layout_id: layouts["news"].id, new_days: 1,
  conditions: %w(product/solution product/software product/office product/marketing recruit)
save_node route: "category/page", name: "お知らせ", filename: "oshirase", shortcut: "show", layout_id: layouts["news"].id
save_node route: "category/page", name: "製品・サービス", filename: "product", shortcut: "show", layout_id: layouts["product"].id,
  sort: "order", new_days: 1, conditions: %w(product/solution product/software product/office product/marketing)
save_node route: "category/page", name: "採用情報", filename: "recruit", shortcut: "show", layout_id: layouts["recruit"].id
save_node route: "category/page", name: "マーケティング", filename: "product/marketing", order: 40, layout_id: layouts["product"].id
save_node route: "category/page", name: "オフィス機器", filename: "product/office", order: 30, layout_id: layouts["product"].id
save_node route: "category/page", name: "ソフトウェア", filename: "product/software", order: 20, layout_id: layouts["product"].id
save_node route: "category/page", name: "ビジネスソリューション", filename: "product/solution", order: 10, layout_id: layouts["product"].id

## inquiry
inquiry_html = File.read("nodes/inquiry.inquiry_html") rescue nil
inquiry_sent_html  = File.read("nodes/inquiry.inquiry_sent_html") rescue nil
inquiry_node = save_node route: "inquiry/form", filename: "inquiry",
  name: "お問い合わせ", shortcut: "show", layout_id: layouts["one"].id,
  inquiry_captcha: "enabled", notice_state: "disabled",
  inquiry_html: inquiry_html, inquiry_sent_html: inquiry_sent_html,
  reply_state: "disabled",
  reply_subject: "シラサギ株式会社へのお問い合わせを受け付けました。",
  reply_upper_text: "以下の内容でお問い合わせを受け付けました。",
  reply_lower_text: "以上。"

def save_inquiry_column(data)
  puts data[:name]
  cond = { node_id: data[:node_id], name: data[:name] }

  item = Inquiry::Column.find_or_create_by(cond)
  item.attributes = data
  item.update

  item
end

puts "# inquiery"

column_company_html = File.read("columns/company.html") rescue nil
column_position_html = File.read("columns/position.html") rescue nil
column_name_html = File.read("columns/name.html") rescue nil
column_kana_html = File.read("columns/kana.html") rescue nil
column_email_html = File.read("columns/email.html") rescue nil
column_tel_html = File.read("columns/tel.html") rescue nil
column_post_html = File.read("columns/post.html") rescue nil
column_address_html = File.read("columns/address.html") rescue nil
column_question_html = File.read("columns/question.html") rescue nil

save_inquiry_column node_id: inquiry_node.id, name: "企業・団体名", order: 10, input_type: "text_field",
  html: column_company_html, select_options: [], required: "optional", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "部署名", order: 20, input_type: "text_field",
  html: column_position_html, select_options: [], required: "optional", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "お名前", order: 30, input_type: "text_field",
  html: column_name_html, select_options: [], required: "required", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "ふりがな", order: 40, input_type: "text_field",
  html: column_kana_html, select_options: [], required: "required", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "メールアドレス", order: 50, input_type: "email_field",
  html: column_email_html, select_options: [], required: "required", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "電話番号", order: 60, input_type: "text_field",
  html: column_tel_html, select_options: [], required: "optional", site_id: @site._id, additional_attr: "pattern=\"[0-9]*\""
save_inquiry_column node_id: inquiry_node.id, name: "郵便番号", order: 70, input_type: "text_field",
  html: column_post_html, select_options: [], required: "optional", site_id: @site._id, additional_attr: "pattern=\"[0-9]*\""
save_inquiry_column node_id: inquiry_node.id, name: "住所", order: 80, input_type: "text_field",
  html: column_address_html, select_options: [], required: "optional", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "お問い合わせ内容", order: 90, input_type: "text_field",
  html: column_question_html, select_options: [], required: "required", site_id: @site._id

array   =  Category::Node::Base.where(site_id: @site._id).map { |m| [m.filename, m] }
categories = Hash[*array.flatten]

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

save_part route: "cms/crumb", filename: "breadcrumbs.part.html", name: "パンくず",
  home_label: "トップ" , mobile_view: "hide"
save_part route: "cms/free", filename: "connection.part.html", name: "関連サイト"
save_part route: "cms/free", filename: "foot-top.part.html", name: "フッター：トップ"
save_part route: "cms/free", filename: "foot.part.html", name: "フッター"
save_part route: "cms/free", filename: "head.part.html", name: "ヘッダー"
save_part route: "cms/free", filename: "inquiry.part.html", name: "お問い合わせ",
  mobile_view: "hide"
save_part route: "cms/free", filename: "keyvisual.part.html", name: "キービジュアル"
save_part route: "cms/tabs", filename: "news.part.html", name: "ニュース",
  new_days: 7, conditions: %w(oshirase product recruit)
save_part route: "cms/free", filename: "page-top.part.html", name: "ページトップ"
save_part route: "cms/page", filename: "news/side-menu.part.html", name: "サイドメニュー",
  new_days: 0, limit: 10, mobile_view: "hide",
  conditions: %w(product/solution product/software product/office product/marketing recruit)
save_part route: "cms/page", filename: "company/side-menu.part.html", name: "サイドメニュー",
  sort: "order", new_days: 0, limit: 10
save_part route: "cms/page", filename: "recruit/side-menu.part.html", name: "サイドメニュー",
  new_days: 0, limit: 10, mobile_view: "hide"
save_part route: "cms/node", filename: "product/folder-list.part.html", name: "製品サービスカテゴリー",
  sort: "order",  limit: 4
save_part route: "cms/page", filename: "product/marketing/marketing.part.html", name: "ページ一覧",
  sort: "order", new_days: 0,  limit: 20
save_part route: "cms/page", filename: "product/marketing/side-menu.part.html", name: "サイドメニュー",
  sort: "order", new_days: 0,  limit: 20, mobile_view: "hide"
save_part route: "cms/page", filename: "product/office/office.part.html", name: "ページ一覧",
  sort: "order", new_days: 0,  limit: 20
save_part route: "cms/page", filename: "product/office/side-menu.part.html", name: "サイドメニュー",
  sort: "order", new_days: 0,  limit: 20, mobile_view: "hide"
save_part route: "cms/page", filename: "product/software/software.part.html", name: "ページ一覧",
  sort: "order", new_days: 0,  limit: 20
save_part route: "cms/page", filename: "product/software/side-menu.part.html", name: "サイドメニュー",
  sort: "order", new_days: 0,  limit: 20, mobile_view: "hide"
save_part route: "cms/page", filename: "product/solution/solution.part.html", name: "ページ一覧",
  sort: "order", new_days: 0,  limit: 20
save_part route: "cms/page", filename: "product/solution/side-menu.part.html", name: "サイドメニュー",
  sort: "order", new_days: 0,  limit: 20, mobile_view: "hide"

## -------------------------------------
puts "# pages"

def save_page(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }

  html = File.read("pages/" + data[:filename]) rescue nil
  summary_html = File.read("pages/" + data[:filename].sub(/\.html$/, "") + ".summary_html") rescue nil

  item = Cms::Page.find_or_create_by(cond).becomes_with_route(data[:route])
  item.html = html if html
  item.summary_html = summary_html if summary_html

  item.attributes = data
  item.update
  item.add_to_set group_ids: @site.group_ids

  item
end

puts "# articles"

save_page route: "article/page", name: "お知らせ情報が入ります。",  filename: "news/314.html",
  layout_id: layouts["news"].id, category_ids: [categories["oshirase"].id]
save_page route: "article/page", name: "お知らせ情報が入ります。お知らせ情報が入ります。", filename: "news/315.html",
  layout_id: layouts["news"].id, category_ids: [categories["oshirase"].id]
save_page route: "article/page", name: "お知らせ情報が入ります。お知らせ情報が入ります。", filename: "news/316.html",
  layout_id: layouts["news"].id, category_ids: [categories["oshirase"].id]
save_page route: "article/page", name: "新卒採用", filename: "news/334.html",
  layout_id: layouts["recruit"].id, category_ids: [categories["oshirase"].id, categories["recruit"].id]
save_page route: "article/page", name: "中途採用", filename: "news/335.html",
  layout_id: layouts["recruit"].id, category_ids: [categories["oshirase"].id, categories["recruit"].id]

puts "# pages"

save_page route: "cms/page", name: "シラサギ株式会社", filename: "index.html",
  layout_id: layouts["top"].id
save_page route: "cms/page", name: "リンク集", filename: "link.html",
  layout_id: layouts["one"].id
save_page route: "cms/page", name: "個人情報保護方針", filename: "privacy.html",
  layout_id: layouts["one"].id
save_page route: "cms/page", name: "サイトマップ", filename: "sitemap.html",
  layout_id: layouts["sitemap"].id
save_page route: "cms/page", name: "アクセス", filename: "company/access.html",
  order: 40, layout_id: layouts["company"].id
save_page route: "cms/page", name: "ご挨拶", filename: "company/greeting.html",
  order: 20, layout_id: layouts["company"].id
save_page route: "cms/page", name: "沿革", filename: "company/history.html",
  order: 30, layout_id: layouts["company"].id
save_page route: "cms/page", name: "会社概要",  filename: "company/index.html",
  order: 10, layout_id: layouts["company"].id
save_page route: "cms/page", name: "製品・サービス", filename: "product/index.html",
  layout_id: layouts["product-top"].id
save_page route: "cms/page", name: "WEBマーケティング", filename: "product/marketing/web.html",
  order: 0, layout_id: layouts["product"].id
save_page route: "cms/page", name: "マーケティングリサーチ", filename: "product/marketing/research.html",
  order: 10, layout_id: layouts["product"].id
save_page route: "cms/page", name: "モバイルマーケティング", filename: "product/marketing/mobile.html",
  order: 20, layout_id: layouts["product"].id
save_page route: "cms/page", name: "データベース構築・運用", filename: "product/office/database.html",
  order: 0, layout_id: layouts["product"].id
save_page route: "cms/page", name: "複合機販売", filename: "product/office/printer.html",
  order: 10, layout_id: layouts["product"].id
save_page route: "cms/page", name: "社内ネットワーク構築", filename: "product/office/network.html",
  order: 20, layout_id: layouts["product"].id
save_page route: "cms/page", name: "画像編集ソフト", filename: "product/software/img.html",
  order: 0, layout_id: layouts["product"].id
save_page route: "cms/page", name: "地図ソフト", filename: "product/software/map.html",
  order: 10, layout_id: layouts["product"].id
save_page route: "cms/page", name: "ワープロソフト", filename: "product/software/word.html",
  order: 20, layout_id: layouts["product"].id
save_page route: "cms/page", name: "コンサルティングサービス", filename: "product/solution/consulting.html",
  order: 0, layout_id: layouts["product"].id
save_page route: "cms/page", name: "人材紹介サービス", filename: "product/solution/introduction.html",
  order: 10, layout_id: layouts["product"].id
save_page route: "cms/page", name: "販売促進支援", filename: "product/solution/sales.html",
  order: 20, layout_id: layouts["product"].id
