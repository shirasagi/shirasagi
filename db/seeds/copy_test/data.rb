print "##################################################################################\n"
print " begin regist test data\n"
print "##################################################################################\n"

def save_group(data)
  puts "create #{data[:name]}"
  item = SS::Group.new(data)
  item.save
  item
end

def save_role(data)
  puts "create #{data[:name]}"
  item = Cms::Role.new(data)
  item.save
  item
end

def save_user(data)
  puts "create #{data[:name]}"
  item = SS::User.new(data)
  item.save
  item
end

def save_workflow_route(data)
  puts "create #{data[:name]}"
  item = Workflow::Route.new(data)
  item.save
  item
end

def save_layout(data)
  puts data[:name]
  cond = { site_id: @site.id, filename: data[:filename] }
  html = File.read("layouts/" + data[:filename]) rescue nil

  item = Cms::Layout.find_or_create_by(cond)
  item.attributes = data.merge html: html
  item.update
  item.add_to_set group_ids: @site.group_ids

  item
end

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

def save_part(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }

  html = File.read("parts/" + data[:filename]) rescue nil
  upper_html ||= File.read("parts/" + data[:filename].sub(/\.html$/, ".upper_html")) rescue nil
  loop_html  ||= File.read("parts/" + data[:filename].sub(/\.html$/, ".loop_html")) rescue nil
  lower_html ||= File.read("parts/" + data[:filename].sub(/\.html$/, ".lower_html")) rescue nil

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

def save_ss_files(path, data)
  puts path
  cond = { site_id: @site._id, filename: data[:filename], model: data[:model] }

  file = Fs::UploadedFile.create_from_file(path)
  file.original_filename = data[:filename] if data[:filename].present?

  item = SS::File.find_or_create_by(cond)
  item.in_file = file
  item.update

  item
end

def save_editor_template(data)
  puts data[:name]
  cond = { site_id: data[:site_id], name: data[:name] }

  item = Cms::EditorTemplate.find_or_create_by(cond)
  item.attributes = data
  item.update

  item
end

def save_board_post(data)
  puts data[:name]
  cond = { site_id: data[:site_id], node_id: data[:node_id], name: data[:name], poster: data[:poster] }
  item = Board::Post.where(cond).first || Board::Post.new
  item.attributes = data
  item.save

  item
end

def save_body_layouts(data)
  puts data[:name]
  cond = { site_id: data[:site_id], node_id: data[:node_id], name: data[:name], poster: data[:poster] }
  item = Cms::BodyLayout.where(cond).first || Cms::BodyLayout.new
  item.attributes = data
  item.save

  item
end

def save_max_file_size(data)
  # 100 MiB
  data = {size: 100 * 1_024 * 1_024}.merge(data)

  puts data[:name]
  cond = { name: data[:name] }

  item = SS::MaxFileSize.find_or_create_by cond
  puts item.errors.full_messages unless item.update data
  item
end

def save_dictionary(data)
  puts "create #{data[:name]}"
  item = Kana::Dictionary.new(data)
  item.save!
  item
end

site = SS::Site.create({ name: "コピーテスト", host: "copy_test", domains: "localhost:3000" })
@site = site

puts "# files"
Dir.chdir @root = File.dirname(__FILE__)
Dir.glob "files/**/*.*" do |file|
  puts name = file.sub(/^files\//, "")
  Fs.binwrite "#{@site.path}/#{name}", File.binread(file)
end

puts "# groups"
g00 = save_group name: "シラサギ市", order: 10
g10 = save_group name: "シラサギ市/企画政策部", order: 20
g11 = save_group name: "シラサギ市/企画政策部/政策課", order: 30
g20 = save_group name: "シラサギ市/危機管理部", order: 50

@site.add_to_set group_ids: g00.id

puts "# roles"
user_permissions = Cms::Role.permission_names.select {|n| n =~ /_(private|other)_/ }
r01 = save_role name: I18n.t('cms.roles.admin'), site_id: @site.id, permissions: Cms::Role.permission_names, permission_level: 3
r02 = save_role name: I18n.t('cms.roles.user'), site_id: @site.id, permissions: user_permissions, permission_level: 1

puts "# users"
sys = save_user name: "システム管理者", uid: "sys", email: "sys@example.jp", in_password: "pass", group_ids: [g11.id]
adm = save_user name: "サイト管理者", uid: "admin", email: "admin@example.jp", in_password: "pass", group_ids: [g11.id]
u01 = save_user name: "一般ユーザー1", uid: "user1", email: "user1@example.jp", in_password: "pass", group_ids: [g11.id]
sys.add_to_set sys_role_ids: [r01.id]
Cms::User.find_by(uid: "sys").add_to_set(cms_role_ids: r01.id)
Cms::User.find_by(uid: "admin").add_to_set(cms_role_ids: r01.id)
Cms::User.find_by(uid: "user1").add_to_set(cms_role_ids: r02.id)

puts "# workflow"
approvers = Workflow::Extensions::Route::Approvers.new([ { level: 1, user_id: u01.id }, { level: 2, user_id: adm.id } ])
required_counts = Workflow::Extensions::Route::RequiredCounts.new([ false, false, false, false, false ])
save_workflow_route name: "多段承認", group_ids: [g00.id], approvers: approvers, required_counts: required_counts

puts "# layouts"
save_layout filename: "category-kanko.layout.html", name: "カテゴリー：観光・文化・スポーツ"
save_layout filename: "category-kenko.layout.html", name: "カテゴリー：健康・福祉"
save_layout filename: "category-middle.layout.html", name: "カテゴリー：中間階層"
save_layout filename: "category-shisei.layout.html", name: "カテゴリー：市政情報"
save_layout filename: "more.layout.html", name: "記事一覧"
save_layout filename: "oshirase.layout.html", name: "お知らせ"
save_layout filename: "pages.layout.html", name: "記事レイアウト"
save_layout filename: "top.layout.html", name: "トップレイアウト"
save_layout filename: "one.layout.html", name: "1カラム"
save_layout filename: "faq-top.layout.html", name: "FAQトップ"
save_layout filename: "faq.layout.html", name: "FAQ"
save_layout filename: "event.layout.html", name: "イベントカレンダー"
save_layout filename: "map.layout.html", name: "施設ガイド"
array   = Cms::Layout.where(site_id: @site._id).map { |m| [m.filename.sub(/\..*/, ""), m] }
layouts = Hash[*array.flatten]

puts "# nodes"
save_node route: "category/node", filename: "shisei", name: "市政情報"
save_node route: "category/page", filename: "attention", name: "注目情報"
save_node route: "category/page", filename: "oshirase", name: "お知らせ", shortcut: "show"
save_node route: "category/page", filename: "oshirase/event", name: "イベント"
save_node route: "category/node", filename: "shisei/soshiki", name: "組織案内"
save_node route: "category/node", filename: "shisei/soshiki/kikaku", name: "企画政策部", order: 10
save_node route: "category/page", filename: "shisei/soshiki/kikaku/koho", name: "広報課", order: 10
save_node route: "category/page", filename: "urgency", name: "緊急情報", shortcut: "show"
save_node route: "category/node", filename: "faq", name: "よくある質問", shortcut: "show", sort: "order"
save_node route: "category/page", filename: "calendar/bunka", name: "文化・芸術", order: 10
save_node route: "category/page", filename: "calendar/kohen", name: "講演・講座", order: 20
save_node route: "category/page", filename: "calendar/sports", name: "スポーツ", order: 60
array = Category::Node::Base.where(site_id: @site._id).map { |m| [m.filename, m] }
categories = Hash[*array.flatten]
save_node route: "cms/node", filename: "use", name: "ご利用案内"
save_node route: "article/page", filename: "docs", name: "記事", shortcut: "show"
save_node route: "event/page", filename: "calendar", name: "イベントカレンダー", conditions: %w(docs),
          st_category_ids: %w(calendar/bunka calendar/kohen calendar/sports).map{ |c| categories[c].id }
save_node route: "uploader/file", filename: "css", name: "CSS", shortcut: "show"
save_node route: "uploader/file", filename: "img", name: "画像", shortcut: "show"
save_node route: "uploader/file", filename: "js", name: "javascript", shortcut: "show"
save_node route: "faq/page", filename: "faq/docs", name: "よくある質問記事", st_category_ids: [categories["faq"].id]
save_node route: "faq/search", filename: "faq/faq-search", name: "よくある質問検索", st_category_ids: [categories["faq"].id]
save_node route: "ads/banner", filename: "add", name: "広告バナー", shortcut: "show"
save_node route: "urgency/layout", filename: "urgency-layout", name: "緊急災害レイアウト",
          urgency_default_layout_id: layouts["top"].id, shortcut: "show"

## layout
Cms::Node.where(site_id: @site._id, route: /^article\//).update_all(layout_id: layouts["pages"].id)
Cms::Node.where(site_id: @site._id, route: /^event\//).update_all(layout_id: layouts["event"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "oshirase").update_all(layout_id: layouts["more"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "kanko").update_all(layout_id: layouts["category-kanko"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "kenko").update_all(layout_id: layouts["category-kenko"].id)

puts "# parts"
save_part route: "cms/free", filename: "about.part.html", name: "シラサギ市について"
save_part route: "cms/free", filename: "foot.part.html", name: "フッター"

puts "# articles"
contact_group = SS::Group.where(name: "シラサギ市/企画政策部/政策課").first
contact_group_id = contact_group.id rescue nil
contact_email = contact_group_id ? "kikakuseisaku@example.jp" : nil
contact_tel = contact_group_id ? "000-000-0000" : nil
contact_fax = contact_group_id ? "000-000-0000" : nil
save_page route: "article/page", filename: "docs/page1.html", name: "インフルエンザによる学級閉鎖状況",
          layout_id: layouts["pages"].id, category_ids: [categories["attention"].id],
          contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
file = save_ss_files "ss_files/article/pdf_file.pdf", filename: "pdf_file.pdf", model: "article/page"
save_page route: "article/page", filename: "docs/page27.html", name: "ふれあいフェスティバル",
          layout_id: layouts["oshirase"].id,
          category_ids: [ categories["oshirase"].id,
                          categories["oshirase/event"].id,
                          categories["shisei/soshiki"].id,
                          categories["shisei/soshiki/kikaku"].id,
                          categories["shisei/soshiki/kikaku/koho"].id,
          ],
          file_ids: [file.id],
          html: '<p><a class="icon-pdf" href="' + file.url + '">サンプルファイル (PDF 783KB)</a></p>',
          contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax

puts "# ads"
banner1 = save_ss_files "ss_files/ads/dummy_banner_1.gif", filename: "dummy_banner_1.gif", model: "ads/banner"
banner2 = save_ss_files "ss_files/ads/dummy_banner_2.gif", filename: "dummy_banner_2.gif", model: "ads/banner"
banner1.set(state: "public")
banner2.set(state: "public")
save_page route: "ads/banner", filename: "add/page30.html", name: "シラサギ",
          link_url: "http://www.ss-proj.org/", file_id: banner1.id
save_page route: "ads/banner", filename: "add/page31.html", name: "シラサギ",
          link_url: "http://www.ss-proj.org/", file_id: banner2.id

puts "# facility"
Dir.glob "ss_files/facility/*.*" do |file|
  save_ss_files file, filename: File.basename(file), model: "facility/file"
end
array = SS::File.where(model: "facility/file").map { |m| [m.filename, m] }
facility_images = Hash[*array.flatten]
save_page route: "facility/image", filename: "institution/shisetsu/library/library.html", name: "シラサギ市立図書館",
          layout_id: layouts["map"].id, image_id: facility_images["library.jpg"].id, order: 0
save_page route: "facility/image", filename: "institution/shisetsu/library/equipment.html", name: "設備",
          layout_id: layouts["map"].id, image_id: facility_images["equipment.jpg"].id, order: 10
save_page route: "facility/map", filename: "institution/shisetsu/library/map.html", name: "地図",
          layout_id: layouts["map"].id, map_points: [ { name: "シラサギ市立図書館", loc: [ 34.067035, 134.589971 ], text: "" } ]

puts "# key visual"
keyvisual1 = save_ss_files "ss_files/key_visual/keyvisual01.jpg", filename: "keyvisual01.jpg", model: "key_visual/image"
keyvisual2 = save_ss_files "ss_files/key_visual/keyvisual02.jpg", filename: "keyvisual02.jpg", model: "key_visual/image"
keyvisual1.set(state: "public")
keyvisual2.set(state: "public")
save_page route: "key_visual/image", filename: "key_visual/page37.html", name: "キービジュアル1", order: 10, file_id: keyvisual1.id
save_page route: "key_visual/image", filename: "key_visual/page38.html", name: "キービジュアル2", order: 20, file_id: keyvisual2.id

puts "# editor templates"
thumb_left  = save_ss_files("editor_templates/float-left.jpg", filename: "float-left.jpg", model: "cms/editor_template")
thumb_right = save_ss_files("editor_templates/float-right.jpg", filename: "float-right.jpg", model: "cms/editor_template")
editor_template_html = File.read("editor_templates/float-left.html") rescue nil
save_editor_template name: "画像左回り込み", description: "画像が左に回り込み右側がテキストになります",
                     html: editor_template_html, thumb_id: thumb_left.id, order: 10, site_id: @site.id
thumb_left.set(state: "public")
editor_template_html = File.read("editor_templates/float-right.html") rescue nil
save_editor_template name: "画像右回り込み", description: "画像が右に回り込み左側がテキストになります",
                     html: editor_template_html, thumb_id: thumb_right.id, order: 20, site_id: @site.id
thumb_right.set(state: "public")
editor_template_html = File.read("editor_templates/clear.html") rescue nil
save_editor_template name: "回り込み解除", description: "回り込みを解除します",
                     html: editor_template_html, order: 30, site_id: @site.id

puts "# board"
node = save_node route: "board/post", filename: "board", name: "災害掲示板", layout_id: layouts["one"].id,
                 mode: "tree", file_limit: 1, text_size_limit: 400, captcha: "enabled", deletable_post: "enabled",
                 deny_url: "deny", file_size_limit: (1024 * 1024 * 2), file_scan: "disabled", show_email: "enabled",
                 show_url: "enabled"
topic1 = save_board_post name: "テスト投稿", text: "テスト投稿です。", site_id: @site.id, node_id: node.id,
                         poster: "白鷺　太郎", delete_key: 1234

puts "# body_layouts"
body_layout_html = File.read("body_layouts/layout.layout.html") rescue nil
body_layout = save_body_layouts name: "本文レイアウト",
                                html: body_layout_html,
                                parts: %W(本文1 本文2 本文3),
                                site_id: @site.id
save_page route: "article/page", filename: "docs/body_layout.html", name: "本文レイアウト",
          layout_id: layouts["pages"].id, body_layout_id: body_layout.id, body_parts: %W(本文1 本文2 本文3),
          contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax

puts "# cms pages"
save_page route: "cms/page", filename: "index.html", name: "自治体サンプル", layout_id: layouts["top"].id
save_page route: "cms/page", filename: "mobile.html", name: "スマートフォン・携帯サイト", layout_id: layouts["pages"].id
save_page route: "cms/page", filename: "use/index.html", name: "ご利用案内", layout_id: layouts["one"].id
save_page route: "cms/page", filename: "404.html", name: "お探しのページは見つかりません。 404 Not Found", layout_id: layouts["one"].id
save_page route: "cms/page", filename: "shisei/soshiki/index.html", name: "組織案内", layout_id: layouts["category-middle"].id

puts "# max file size"
save_max_file_size name: '画像ファイル', extensions: %w(gif png jpg jpeg bmp), order: 1, state: 'enabled'
save_max_file_size name: '音声ファイル', extensions: %w(wav wma mp3 ogg), order: 2, state: 'enabled'
save_max_file_size name: '動画ファイル', extensions: %w(wmv avi mpeg mpg flv mp4), order: 3, state: 'enabled'
save_max_file_size name: 'Microsoft Office', extensions: %w(doc docx ppt pptx xls xlsx), order: 4, state: 'enabled'
save_max_file_size name: 'PDF', extensions: %w(pdf), order: 5, state: 'enabled'
save_max_file_size name: 'その他', extensions: %w(*), order: 9999, state: 'enabled'

puts "# dictionary"
save_dictionary site_id: @site.id, name: 'テスト1', body: 'テスト1,テストイチ'
save_dictionary site_id: @site.id, name: 'テスト2', body: 'テスト2,テストニ'

print "##################################################################################\n"
print " end regist test data\n"
print "##################################################################################\n"
