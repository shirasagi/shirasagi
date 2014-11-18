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

save_layout filename: "category-kanko.layout.html", name: "カテゴリー：観光・文化・スポーツ"
save_layout filename: "category-kenko.layout.html", name: "カテゴリー：健康・福祉"
save_layout filename: "category-kosodate.layout.html", name: "カテゴリー：子育て・教育"
save_layout filename: "category-kurashi.layout.html", name: "カテゴリー：くらし・手続き"
save_layout filename: "category-middle.layout.html", name: "カテゴリー：中間階層"
save_layout filename: "category-sangyo.layout.html", name: "カテゴリー：産業・仕事"
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
save_layout filename: "urgency-layout/top-level1.layout.html", name: "緊急災害1：トップページ"
save_layout filename: "urgency-layout/top-level2.layout.html", name: "緊急災害2：トップページ"
save_layout filename: "urgency-layout/top-level3.layout.html", name: "緊急災害3：トップページ"

array   = Cms::Layout.where(site_id: @site._id).map { |m| [m.filename.sub(/\..*/, ""), m] }
layouts = Hash[*array.flatten]

## -------------------------------------
puts "# nodes"

def save_node(data)
  puts data[:name]
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

## category
save_node route: "category/node", filename: "guide", name: "くらしのガイド"
save_node route: "category/node", filename: "kanko", name: "観光・文化・スポーツ"
save_node route: "category/node", filename: "kenko", name: "健康・福祉"
save_node route: "category/node", filename: "kosodate", name: "子育て・教育"
save_node route: "category/node", filename: "kurashi", name: "くらし・手続き", shortcut: "show"
save_node route: "category/node", filename: "kurashi/anzen", name: "交通安全・防犯"
save_node route: "category/node", filename: "kurashi/bosai", name: "防災情報"
save_node route: "category/node", filename: "kurashi/kankyo", name: "環境"
save_node route: "category/node", filename: "kurashi/koseki", name: "戸籍・印鑑登録・住民登録"
save_node route: "category/node", filename: "kurashi/nenkin", name: "年金・保険"
save_node route: "category/node", filename: "kurashi/zeikin", name: "税金"
save_node route: "category/node", filename: "sangyo", name: "産業・仕事"
save_node route: "category/node", filename: "sangyo/keiei", name: "経営支援・金融支援・企業立"
save_node route: "category/node", filename: "sangyo/nyusatsu", name: "入札・契約"
save_node route: "category/node", filename: "sangyo/shinko", name: "産業振興"
save_node route: "category/node", filename: "sangyo/todokede", name: "届出・証明・法令・規制"
save_node route: "category/node", filename: "shisei", name: "市政情報"
save_node route: "category/node", filename: "shisei/koho", name: "広報・広聴"
save_node route: "category/page", filename: "attention", name: "注目情報"
save_node route: "category/page", filename: "guide/fukushi", name: "福祉・介護"
save_node route: "category/page", filename: "guide/hikkoshi", name: "引越し・住まい"
save_node route: "category/page", filename: "guide/kekkon", name: "結婚・離婚"
save_node route: "category/page", filename: "guide/kosodate", name: "子育て"
save_node route: "category/page", filename: "guide/kyoiku", name: "教育"
save_node route: "category/page", filename: "guide/ninshin", name: "妊娠・出産"
save_node route: "category/page", filename: "guide/okuyami", name: "おくやみ"
save_node route: "category/page", filename: "guide/shushoku", name: "就職・退職"
save_node route: "category/page", filename: "kanko/bunkazai", name: "文化財"
save_node route: "category/page", filename: "kanko/geijyutsu", name: "文化・芸術"
save_node route: "category/page", filename: "kanko/kanko", name: "観光"
save_node route: "category/page", filename: "kanko/koryu", name: "国内・国際交流"
save_node route: "category/page", filename: "kanko/sports", name: "レジャー・スポーツ"
save_node route: "category/page", filename: "kenko/boshi", name: "母子保健"
save_node route: "category/page", filename: "kenko/hoken", name: "保健・健康・医療"
save_node route: "category/page", filename: "kenko/kaigo", name: "介護保険"
save_node route: "category/page", filename: "kenko/korei", name: "高齢者福祉"
save_node route: "category/page", filename: "kenko/kyukyu", name: "救急医療"
save_node route: "category/page", filename: "kenko/shogai", name: "障害福祉"
save_node route: "category/page", filename: "kenko/shokuiku", name: "食育"
save_node route: "category/page", filename: "kenko/yobo", name: "予防接種"
save_node route: "category/page", filename: "kenko/zoshin", name: "健康増進"
save_node route: "category/page", filename: "kosodate/hoikuen", name: "保育園・幼稚園"
save_node route: "category/page", filename: "kosodate/hoken", name: "母子の保健"
save_node route: "category/page", filename: "kosodate/jinken", name: "人権・平和啓発", shortcut: "show"
save_node route: "category/page", filename: "kosodate/kenko", name: "母子の健康・予防接種"
save_node route: "category/page", filename: "kosodate/kyoikuiinkai", name: "教育委員会"
save_node route: "category/page", filename: "kosodate/shien", name: "子育て支援"
save_node route: "category/page", filename: "kosodate/shogai", name: "生涯学習"
save_node route: "category/page", filename: "kosodate/shogakko", name: "小学校・中学校"
save_node route: "category/page", filename: "kosodate/sodan", name: "教育相談"
save_node route: "category/page", filename: "kurashi/anzen/bohan", name: "防犯"
save_node route: "category/page", filename: "kurashi/anzen/fushinsha", name: "不審者情報"
save_node route: "category/page", filename: "kurashi/anzen/kotsu", name: "交通安全"
save_node route: "category/page", filename: "kurashi/bosai/jyoho", name: "防災情報"
save_node route: "category/page", filename: "kurashi/bosai/kanri", name: "危機管理情報"
save_node route: "category/page", filename: "kurashi/bosai/keikaku", name: "計画"
save_node route: "category/page", filename: "kurashi/bosai/kunren", name: "防災訓練"
save_node route: "category/page", filename: "kurashi/bosai/shinsai", name: "東日本大震災"
save_node route: "category/page", filename: "kurashi/bosai/shobo", name: "消防・救急"
save_node route: "category/page", filename: "kurashi/gomi", name: "ごみ・リサイクル"
save_node route: "category/page", filename: "kurashi/kankyo/hozen", name: "環境保全"
save_node route: "category/page", filename: "kurashi/kankyo/pet", name: "愛玩動物・有害鳥獣"
save_node route: "category/page", filename: "kurashi/kankyo/seisaku", name: "環境政策"
save_node route: "category/page", filename: "kurashi/koseki/foreigner", name: "外国人住民の方へ"
save_node route: "category/page", filename: "kurashi/koseki/inkan", name: "印鑑登録"
save_node route: "category/page", filename: "kurashi/koseki/jyuki", name: "住民基本台帳・電子申請"
save_node route: "category/page", filename: "kurashi/koseki/jyumin", name: "住民登録"
save_node route: "category/page", filename: "kurashi/koseki/koseki", name: "戸籍"
save_node route: "category/page", filename: "kurashi/koseki/passport", name: "パスポート"
save_node route: "category/page", filename: "kurashi/nenkin/hoken", name: "国民健康保険"
save_node route: "category/page", filename: "kurashi/nenkin/korei", name: "高齢者医療"
save_node route: "category/page", filename: "kurashi/nenkin/nenkin", name: "国民年金"
save_node route: "category/page", filename: "kurashi/shimin", name: "市民活動"
save_node route: "category/page", filename: "kurashi/sodan", name: "相談窓口"
save_node route: "category/page", filename: "kurashi/suido", name: "上水道・下水道"
save_node route: "category/page", filename: "kurashi/sumai", name: "住まい"
save_node route: "category/page", filename: "kurashi/zeikin/kotei", name: "固定資産税"
save_node route: "category/page", filename: "kurashi/zeikin/other", name: "その他税について"
save_node route: "category/page", filename: "kurashi/zeikin/shimin", name: "市民税"
save_node route: "category/page", filename: "kurashi/zeikin/tokubetsu", name: "特別徴収"
save_node route: "category/page", filename: "kurashi/zeikin/yogo", name: "税務用語"
save_node route: "category/page", filename: "oshirase", name: "お知らせ", shortcut: "show"
save_node route: "category/page", filename: "oshirase/event", name: "イベント"
save_node route: "category/page", filename: "oshirase/kanko", name: "観光・文化・スポーツ", shortcut: "show"
save_node route: "category/page", filename: "oshirase/kenko", name: "健康・福祉", shortcut: "show"
save_node route: "category/page", filename: "oshirase/kosodate", name: "子育て・教育", shortcut: "show"
save_node route: "category/page", filename: "oshirase/kurashi", name: "くらし・手続き", shortcut: "show"
save_node route: "category/page", filename: "oshirase/sangyo", name: "産業・仕事", shortcut: "show"
save_node route: "category/page", filename: "oshirase/shisei", name: "市政情報", shortcut: "show"
save_node route: "category/page", filename: "sangyo/jinzai", name: "人材募集"
save_node route: "category/page", filename: "sangyo/keiei/hojo", name: "補助・助成"
save_node route: "category/page", filename: "sangyo/keiei/keiei", name: "経営支援"
save_node route: "category/page", filename: "sangyo/keiei/kigyo", name: "企業支援"
save_node route: "category/page", filename: "sangyo/keiei/kinyu", name: "金融支援"
save_node route: "category/page", filename: "sangyo/keiei/ricchi", name: "企業立地"
save_node route: "category/page", filename: "sangyo/nyusatsu/buppin", name: "物品・業務委託等"
save_node route: "category/page", filename: "sangyo/nyusatsu/kobai", name: "公売・市有地売却"
save_node route: "category/page", filename: "sangyo/nyusatsu/koji", name: "工事"
save_node route: "category/page", filename: "sangyo/nyusatsu/kokoku", name: "入札・企画提案の公告"
save_node route: "category/page", filename: "sangyo/nyusatsu/tokutei", name: "特定調達契約情報"
save_node route: "category/page", filename: "sangyo/shinko/kaigai", name: "海外ビジネス支援"
save_node route: "category/page", filename: "sangyo/shinko/norinsuisan", name: "農林水産業"
save_node route: "category/page", filename: "sangyo/shinko/sangakukan", name: "産学官連携"
save_node route: "category/page", filename: "sangyo/shinko/shoko", name: "商工業"
save_node route: "category/page", filename: "sangyo/shinko/shotengai", name: "商店街"
save_node route: "category/page", filename: "sangyo/shitei", name: "指定管理者制度"
save_node route: "category/page", filename: "sangyo/shuro", name: "就労支援"
save_node route: "category/page", filename: "sangyo/todokede/kaigo", name: "介護・福祉"
save_node route: "category/page", filename: "sangyo/todokede/kankyo", name: "環境・ごみ・リサイクル"
save_node route: "category/page", filename: "sangyo/todokede/kenchiku", name: "建築・土地・開発・景観"
save_node route: "category/page", filename: "sangyo/todokede/kenko", name: "健康・医療"
save_node route: "category/page", filename: "sangyo/todokede/kosodate", name: "子育て"
save_node route: "category/page", filename: "sangyo/todokede/norinsuisan", name: "農林水産業"
save_node route: "category/page", filename: "sangyo/todokede/shobo", name: "消防・救急"
save_node route: "category/page", filename: "sangyo/todokede/shoko", name: "商工業"
save_node route: "category/page", filename: "sangyo/todokede/shokuhin", name: "食品・衛生"
save_node route: "category/page", filename: "sangyo/zeikin", name: "企業の税金"
save_node route: "category/page", filename: "shisei/chosha", name: "庁舎案内"
save_node route: "category/page", filename: "shisei/gaiyo", name: "市の概要"
save_node route: "category/page", filename: "shisei/jinji", name: "人事・職員募集"
save_node route: "category/page", filename: "shisei/koho/pamphlet", name: "パンフレット"
save_node route: "category/page", filename: "shisei/koho/shirasagi", name: "広報SHIRASAGI"
save_node route: "category/page", filename: "shisei/koho/shiryo", name: "報道発表資料"
save_node route: "category/page", filename: "shisei/senkyo", name: "選挙"
save_node route: "category/page", filename: "shisei/shicho", name: "市長の部屋"
save_node route: "category/page", filename: "shisei/shisaku", name: "施策・計画"
save_node route: "category/node", filename: "shisei/soshiki", name: "組織案内"
save_node route: "category/node", filename: "shisei/soshiki/kikaku", name: "企画政策部", order: 10
save_node route: "category/node", filename: "shisei/soshiki/soumu", name: "総務部", order: 20
save_node route: "category/node", filename: "shisei/soshiki/keizai", name: "経済部", order: 30
save_node route: "category/node", filename: "shisei/soshiki/kensetu", name: "建設部", order: 40
save_node route: "category/node", filename: "shisei/soshiki/kikikanri", name: "危機管理部", order: 50
save_node route: "category/node", filename: "shisei/soshiki/kyoiku", name: "教育委員会", order: 60
save_node route: "category/page", filename: "shisei/soshiki/kikaku/koho", name: "広報課", order: 10
save_node route: "category/page", filename: "shisei/soshiki/kikaku/seisaku", name: "政策課", order: 20
save_node route: "category/page", filename: "shisei/soshiki/kikaku/hisho", name: "秘書課", order: 30
save_node route: "category/page", filename: "shisei/soshiki/soumu/somu", name: "総務課", order: 10
save_node route: "category/page", filename: "shisei/soshiki/soumu/shokuin", name: "職員課", order: 20
save_node route: "category/page", filename: "shisei/soshiki/soumu/nouzei", name: "納税課", order: 30
save_node route: "category/page", filename: "shisei/toke", name: "統計・人口"
save_node route: "category/page", filename: "shisei/toshi", name: "都市整備"
save_node route: "category/page", filename: "shisei/zaisei", name: "財政・行政改革"
save_node route: "category/page", filename: "urgency", name: "緊急情報", shortcut: "show"
save_node route: "category/node", filename: "faq", name: "よくある質問", shortcut: "show", sort: "order"
save_node route: "category/page", filename: "faq/kurashi", name: "くらし・手続き", order: 10
save_node route: "category/page", filename: "faq/kosodate", name: "子育て・教育", order: 20
save_node route: "category/page", filename: "faq/kenko", name: "健康・福祉", order: 30
save_node route: "category/page", filename: "faq/kanko", name: "観光・文化・スポーツ", order: 40
save_node route: "category/page", filename: "faq/sangyo", name: "産業・仕事", order: 50
save_node route: "category/page", filename: "faq/shisei", name: "市政情報", order: 60
save_node route: "category/page", filename: "calendar/bunka", name: "文化・芸術", order: 10
save_node route: "category/page", filename: "calendar/kohen", name: "講演・講座", order: 20
save_node route: "category/page", filename: "calendar/sports", name: "スポーツ", order: 60

array   =  Category::Node::Base.where(site_id: @site._id).map { |m| [m.filename, m] }
categories = Hash[*array.flatten]

## node
save_node route: "cms/node", filename: "sitemap", name: "サイトマップ"
save_node route: "cms/node", filename: "use", name: "ご利用案内"

## article
save_node route: "article/page", filename: "docs", name: "記事", shortcut: "show"

## event
save_node route: "event/page", filename: "calendar", name: "イベントカレンダー", conditions: %w(docs),
  st_category_ids: %w(calendar/bunka calendar/kohen calendar/sports).map{ |c| categories[c].id }

## uploader
save_node route: "uploader/file", filename: "css", name: "CSS", shortcut: "show"
save_node route: "uploader/file", filename: "img", name: "画像", shortcut: "show"
save_node route: "uploader/file", filename: "js", name: "javascript", shortcut: "show"

## faq
save_node route: "faq/page", filename: "faq/docs", name: "よくある質問記事", st_category_ids: [categories["faq"].id]
save_node route: "faq/search", filename: "faq/faq-search", name: "よくある質問検索", st_category_ids: [categories["faq"].id]

## urgency
save_node route: "urgency/layout", filename: "urgency-layout", name: "緊急災害レイアウト",
  urgency_default_layout_id: layouts["top"].id, shortcut: "show"

## inquiry
inquiry_html = File.read("nodes/inquiry.inquiry_html") rescue nil
inquiry_sent_html  = File.read("nodes/inquiry.inquiry_sent_html") rescue nil
inquiry_node = save_node route: "inquiry/form", filename: "inquiry", name: "市へのお問い合わせ", shortcut: "show",
  from_name: "シラサギサンプルサイト",
  inquiry_captcha: "enabled", notice_state: "disabled",
  inquiry_html: inquiry_html, inquiry_sent_html: inquiry_sent_html,
  reply_state: "disabled",
  reply_subject: "シラサギ市へのお問い合わせを受け付けました。",
  reply_upper_text: "以下の内容でお問い合わせを受け付けました。",
  reply_lower_text: "以上。"

## facility
save_node route: "cms/node", filename: "institution/chiki", name: "施設のある地域"
save_node route: "facility/location", filename: "institution/chiki/higashii", name: "東区", order: 10
save_node route: "facility/location", filename: "institution/chiki/nishi", name: "西区", order: 20
save_node route: "facility/location", filename: "institution/chiki/minami", name: "南区", order: 30
save_node route: "facility/location", filename: "institution/chiki/kita", name: "北区", order: 40

save_node route: "cms/node", filename: "institution/shurui", name: "施設の種類"
save_node route: "facility/category", filename: "institution/shurui/bunka", name: "文化施設", order: 10
save_node route: "facility/category", filename: "institution/shurui/sports", name: "運動施設", order: 20
save_node route: "facility/category", filename: "institution/shurui/school", name: "小学校", order: 30
save_node route: "facility/category", filename: "institution/shurui/kokyo", name: "公園・公共施設", order: 40

save_node route: "cms/node", filename: "institution/yoto", name: "施設の用途"
save_node route: "facility/service", filename: "institution/yoto/asobu", name: "遊ぶ", order: 10
save_node route: "facility/service", filename: "institution/yoto/manabu", name: "学ぶ", order: 20
save_node route: "facility/service", filename: "institution/yoto/sodan", name: "相談する", order: 30

array = Facility::Node::Category.where(site_id: @site._id).map { |m| [m.filename, m] }
facility_categories = Hash[*array.flatten]
array = Facility::Node::Location.where(site_id: @site._id).map { |m| [m.filename, m] }
facility_locations = Hash[*array.flatten]
array = Facility::Node::Service.where(site_id: @site._id).map { |m| [m.filename, m] }
facility_services = Hash[*array.flatten]

save_node route: "facility/search", filename: "institution", name: "施設ガイド",
  st_category_ids: facility_categories.values.map{ |cate| cate.id },
  st_location_ids: facility_locations.values.map{ |loc| loc.id },
  st_service_ids: facility_services.values.map{ |serv| serv.id }

save_node route: "facility/node", filename: "institution/bunka", name: "文化施設一覧",
  st_category_ids: facility_categories.values.map{ |cate| cate.id },
  st_location_ids: facility_locations.values.map{ |loc| loc.id },
  st_service_ids: facility_services.values.map{ |serv| serv.id }

save_node route: "facility/node", filename: "institution/kokyo", name: "公共施設一覧",
  st_category_ids: facility_categories.values.map{ |cate| cate.id },
  st_location_ids: facility_locations.values.map{ |loc| loc.id },
  st_service_ids: facility_services.values.map{ |serv| serv.id }

save_node route: "facility/node", filename: "institution/school", name: "学校一覧",
  st_category_ids: facility_categories.values.map{ |cate| cate.id },
  st_location_ids: facility_locations.values.map{ |loc| loc.id },
  st_service_ids: facility_services.values.map{ |serv| serv.id }

save_node route: "facility/node", filename: "institution/sports", name: "運動施設一覧",
  st_category_ids: facility_categories.values.map{ |cate| cate.id },
  st_location_ids: facility_locations.values.map{ |loc| loc.id },
  st_service_ids: facility_services.values.map{ |serv| serv.id }

save_node route: "facility/page", filename: "institution/bunka/library", name: "シラサギ市立図書館",
  kana: "しらさぎとしょかん",
  address: "大鷺県シラサギ市小鷺町1丁目1番地1号",
  tel: "00-0000-0000",
  fax: "00-0000-0000",
  related_url: "http://demo.ss-proj.org/",
  category_ids: [facility_categories["institution/shurui/bunka"].id],
  location_ids: [facility_locations["institution/chiki/higashii"].id],
  service_ids: [facility_services["institution/yoto/manabu"].id]

def save_inquiry_column(data)
  puts data[:name]
  cond = { node_id: data[:node_id], name: data[:name] }

  item = Inquiry::Column.find_or_create_by(cond)
  item.attributes = data
  item.update

  item
end

puts "# inquiry"

column_name_html = File.read("columns/name.html") rescue nil
column_company_html = File.read("columns/company.html") rescue nil
column_email_html = File.read("columns/email.html") rescue nil
column_gender_html = File.read("columns/gender.html") rescue nil
column_age_html = File.read("columns/age.html") rescue nil
column_category_html = File.read("columns/category.html") rescue nil
column_question_html = File.read("columns/question.html") rescue nil
save_inquiry_column node_id: inquiry_node.id, name: "お名前", order: 0, input_type: "text_field",
  html: column_name_html, select_options: [], required: "required", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "企業・団体名", order: 10, input_type: "text_field",
  html: column_company_html, select_options: [], required: "optional", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "メールアドレス", order: 20, input_type: "email_field",
  html: column_email_html, select_options: [], required: "required", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "性別", order: 30, input_type: "radio_button",
  html: column_gender_html, select_options: %w(男性 女性), required: "required", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "年齢", order: 40, input_type: "select",
  html: column_age_html, select_options: %w(10代 20代 30代 40代 50代 60代 70代 80代), required: "required", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "お問い合わせ区分", order: 50, input_type: "check_box",
  html: column_category_html, select_options: %w(市政について ご意見・ご要望 申請について その他), required: "required", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "お問い合わせ内容", order: 60, input_type: "text_area",
  html: column_question_html, select_options: [], required: "required", site_id: @site._id

## layout
Cms::Node.where(site_id: @site._id, route: /^article\//).update_all(layout_id: layouts["pages"].id)
Cms::Node.where(site_id: @site._id, route: /^event\//).update_all(layout_id: layouts["event"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "oshirase").
  update_all(layout_id: layouts["more"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "kanko").
  update_all(layout_id: layouts["category-kanko"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "kenko").
  update_all(layout_id: layouts["category-kenko"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "kosodate").
  update_all(layout_id: layouts["category-kosodate"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "kurashi").
  update_all(layout_id: layouts["category-kurashi"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "guide").
  update_all(layout_id: layouts["category-middle"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "sangyo").
  update_all(layout_id: layouts["category-sangyo"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "shisei").
  update_all(layout_id: layouts["category-shisei"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "attention").
  update_all(layout_id: layouts["category-shisei"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: /\//).
  update_all(layout_id: layouts["category-middle"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: /^oshirase\//).
  update_all(layout_id: layouts["more"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "urgency").
  update_all(layout_id: layouts["more"].id)
Cms::Node.where(site_id: @site._id, filename: /^inquiry$/).
  update_all(layout_id: layouts["one"].id)
Cms::Node.where(site_id: @site._id, filename: /^faq$/).
  update_all(layout_id: layouts["faq-top"].id)
Cms::Node.where(site_id: @site._id, filename: /faq\//).
  update_all(layout_id: layouts["faq"].id)
Cms::Node.where(site_id: @site._id, route: /facility\//).
  update_all(layout_id: layouts["map"].id)

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

save_part route: "cms/free", filename: "about.part.html", name: "シラサギ市について"
save_part route: "cms/free", filename: "add.part.html", name: "広告", mobile_view: "hide"
save_part route: "cms/free", filename: "foot.part.html", name: "フッター"
save_part route: "cms/free", filename: "guide.part.html", name: "くらしのガイド"
save_part route: "cms/free", filename: "head.part.html", name: "ヘッダー"
save_part route: "cms/free", filename: "keyvisual.part.html", name: "キービジュアル", mobile_view: "hide"
save_part route: "cms/free", filename: "links-life.part.html", name: "関連リンク：くらし・手続き"
save_part route: "cms/free", filename: "navi.part.html", name: "グローバルナビ"
save_part route: "cms/free", filename: "online.part.html", name: "オンラインサービス"
save_part route: "cms/free", filename: "connect.part.html", name: "関連サイト", mobile_view: "hide"
save_part route: "cms/free", filename: "page-top.part.html", name: "ページトップ"
save_part route: "cms/free", filename: "population.part.html", name: "人口・世帯数", mobile_view: "hide"
save_part route: "cms/free", filename: "propose.part.html", name: "ご意見・ご提案"
save_part route: "cms/free", filename: "ranking.part.html", name: "アクセスランキング", mobile_view: "hide"
save_part route: "cms/free", filename: "relations.part.html", name: "広報"
save_part route: "cms/free", filename: "safety.part.html", name: "安心安全情報"
save_part route: "cms/free", filename: "tool.part.html", name: "アクセシビリティーツール", mobile_view: "hide"
save_part route: "cms/free", filename: "topics.part.html", name: "街の話題"
save_part route: "cms/free", filename: "useful.part.html", name: "お役立ち情報"
save_part route: "cms/free", filename: "map-side.part.html", name: "サイドメニュー：施設ガイド"
save_part route: "article/page", filename: "attention/recent.part.html", name: "注目情報", limit: 5
save_part route: "article/page", filename: "docs/recent.part.html", name: "新着情報"
save_part route: "article/page", filename: "oshirase/kanko/recent.part.html", name: "お知らせ", limit: 6
save_part route: "article/page", filename: "oshirase/kenko/recent.part.html", name: "お知らせ", limit: 5
save_part route: "article/page", filename: "oshirase/kosodate/recent.part.html", name: "お知らせ", limit: 5
save_part route: "article/page", filename: "oshirase/kurashi/recent.part.html", name: "お知らせ", limit: 5
save_part route: "article/page", filename: "oshirase/recent.part.html", name: "お知らせ", limit: 5
save_part route: "article/page", filename: "oshirase/sangyo/recent.part.html", name: "お知らせ", limit: 5
save_part route: "article/page", filename: "oshirase/shisei/recent.part.html", name: "お知らせ", limit: 5
save_part route: "cms/crumb", filename: "breadcrumb.part.html", name: "パンくず", mobile_view: "hide"
save_part route: "category/node", filename: "category-list.part.html", name: "カテゴリーリスト", limit: 20, sort: "order"
save_part route: "cms/tabs", filename: "recent-tabs.part.html", name: "新着タブ",
  conditions: %w(oshirase oshirase/event shisei/jinji), limit: 6
save_part route: "cms/free", filename: "urgency-layout/announce.part.html", name: "緊急アナウンス"
save_part route: "cms/free", filename: "urgency-layout/calamity.part.html", name: "災害関係ホームページ"
save_part route: "cms/free", filename: "urgency-layout/connect.part.html", name: "関連サイト"
save_part route: "cms/free", filename: "urgency-layout/head.part.html", name: "ヘッダー"
save_part route: "cms/free", filename: "urgency-layout/mode.part.html", name: "緊急災害表示"
save_part route: "cms/free", filename: "urgency-layout/navi.part.html", name: "グローバルナビ"
save_part route: "article/page", filename: "urgency/recent.part.html", name: "緊急情報", limit: 20
save_part route: "category/node", filename: "faq/category-list.part.html", name: "カテゴリーリスト", sort: "order"
save_part route: "faq/search", filename: "faq/faq-search/search.part.html", name: "FAQ記事検索"
save_part route: "event/calendar", filename: "calendar/calendar.part.html", name: "カレンダー", ajax_view: "enabled"

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

save_page route: "cms/page", filename: "index.html", name: "自治体サンプル", layout_id: layouts["top"].id
save_page route: "cms/page", filename: "mobile.html", name: "スマートフォン・携帯サイト", layout_id: layouts["pages"].id
save_page route: "cms/page", filename: "sitemap/index.html", name: "サイトマップ", layout_id: layouts["one"].id
save_page route: "cms/page", filename: "use/index.html", name: "ご利用案内", layout_id: layouts["one"].id
save_page route: "cms/page", filename: "404.html", name: "お探しのページは見つかりません。 404 Not Found", layout_id: layouts["one"].id
save_page route: "cms/page", filename: "shisei/soshiki/index.html", name: "組織案内", layout_id: layouts["category-middle"].id

## -------------------------------------
puts "# articles"

save_page route: "article/page", filename: "docs/1.html", name: "インフルエンザによる学級閉鎖状況",
  layout_id: layouts["pages"].id, category_ids: [categories["attention"].id]
save_page route: "article/page", filename: "docs/2.html", name: "コンビニ納付のお知らせ",
  layout_id: layouts["oshirase"].id,
  category_ids: [ categories["attention"].id,
                  categories["shisei/soshiki"].id,
                  categories["shisei/soshiki/kikaku"].id,
                  categories["shisei/soshiki/kikaku/koho"].id,
                  categories["shisei/soshiki/kikaku/seisaku"].id,
                  categories["shisei/soshiki/soumu"].id,
                  categories["shisei/soshiki/soumu/nouzei"].id
                ]
save_page route: "article/page", filename: "docs/3.html", name: "平成26年第1回シラサギ市議会定例会を開催します",
  layout_id: layouts["oshirase"].id, category_ids: [categories["attention"].id]
save_page route: "article/page", filename: "docs/4.html", name: "放射性物質・震災関連情報",
  layout_id: layouts["oshirase"].id, category_ids: [categories["attention"].id]
save_page route: "article/page", filename: "docs/5.html", name: "市内の微小粒子状物質（PM2.5）の測定データ（速報値）を公開しています。",
  layout_id: layouts["oshirase"].id, category_ids: [categories["attention"].id]
save_page route: "article/page", filename: "docs/7.html", name: "還付金詐欺と思われる不審な電話にご注意ください",
  layout_id: layouts["oshirase"].id,
  category_ids: [ categories["oshirase"].id,
                  categories["shisei/soshiki"].id,
                  categories["shisei/soshiki/kikaku"].id,
                  categories["shisei/soshiki/kikaku/koho"].id,
                  categories["shisei/soshiki/kikaku/seisaku"].id,
                ]
save_page route: "article/page", filename: "docs/8.html", name: "平成26年度　シラサギ市システム構築に係るの公募型企画競争",
  layout_id: layouts["oshirase"].id,
  category_ids: [ categories["oshirase"].id,
                  categories["shisei/soshiki"].id,
                  categories["shisei/soshiki/kikaku"].id,
                  categories["shisei/soshiki/kikaku/koho"].id,
                  categories["shisei/soshiki/kikaku/seisaku"].id,
                ]
save_page route: "article/page", filename: "docs/9.html", name: "冬の感染症に備えましょう",
  layout_id: layouts["oshirase"].id, category_ids: [categories["oshirase"].id]
save_page route: "article/page", filename: "docs/11.html", name: "広報SHIRASAGI3月号を掲載",
  layout_id: layouts["oshirase"].id,
  category_ids: [ categories["oshirase"].id,
                  categories["oshirase/kurashi"].id,
                  categories["shisei/soshiki"].id,
                  categories["shisei/soshiki/kikaku"].id,
                  categories["shisei/soshiki/kikaku/koho"].id,
                ]
save_page route: "article/page", filename: "docs/12.html", name: "インフルエンザ流行警報がでています",
  layout_id: layouts["oshirase"].id, category_ids: [categories["oshirase"].id]
save_page route: "article/page", filename: "docs/14.html", name: "転出届",
  layout_id: layouts["pages"].id, category_ids: [categories["kurashi/koseki/jyumin"].id]
save_page route: "article/page", filename: "docs/15.html", name: "転入届",
  layout_id: layouts["pages"].id, category_ids: [categories["kurashi/koseki/jyumin"].id]
save_page route: "article/page", filename: "docs/16.html", name: "世帯または世帯主を変更するとき",
  layout_id: layouts["pages"].id, category_ids: [categories["kurashi/koseki/jyumin"].id]
save_page route: "article/page", filename: "docs/17.html", name: "証明書発行窓口",
  layout_id: layouts["pages"].id, category_ids: [categories["kurashi/koseki/jyumin"].id]
save_page route: "article/page", filename: "docs/18.html", name: "住民票記載事項証明書様式",
  layout_id: layouts["pages"].id, category_ids: [categories["kurashi/koseki/jyumin"].id]
save_page route: "article/page", filename: "docs/19.html", name: "住所変更の証明書について",
  layout_id: layouts["pages"].id, category_ids: [categories["kurashi/koseki/jyumin"].id]
save_page route: "article/page", filename: "docs/20.html", name: "住民票コードとは",
  layout_id: layouts["pages"].id, category_ids: [categories["kurashi/koseki/jyumin"].id]
save_page route: "article/page", filename: "docs/21.html", name: "住民票コードの変更",
  layout_id: layouts["pages"].id, category_ids: [categories["kurashi/koseki/jyumin"].id]
save_page route: "article/page", filename: "docs/22.html", name: "自動交付機・コンビニ交付サービスについて",
  layout_id: layouts["pages"].id,
  category_ids: [ categories["oshirase"].id,
                  categories["oshirase/kurashi"].id,
                  categories["shisei/soshiki"].id,
                  categories["shisei/soshiki/kikaku"].id,
                  categories["shisei/soshiki/kikaku/koho"].id,
                  categories["shisei/soshiki/kikaku/seisaku"].id,
                ]
save_page route: "article/page", filename: "docs/tenkyo.html", name: "転居届",
  layout_id: layouts["pages"].id, category_ids: [categories["kurashi/koseki/jyumin"].id]
save_page route: "article/page", filename: "oshirase/kurashi/23.html", name: "犬・猫を譲り受けたい方",
  layout_id: layouts["oshirase"].id, category_ids: [categories["oshirase"].id, categories["oshirase/kurashi"].id]
save_page route: "article/page", filename: "oshirase/kurashi/24.html", name: "平成26年度住宅補助金の募集について掲載しました。",
  layout_id: layouts["oshirase"].id, category_ids: [categories["oshirase"].id, categories["oshirase/kurashi"].id]
save_page route: "article/page", filename: "oshirase/kurashi/25.html", name: "休日臨時窓口を開設します。",
  layout_id: layouts["oshirase"].id,
  category_ids: [ categories["oshirase"].id,
                  categories["oshirase/kurashi"].id,
                  categories["shisei/soshiki"].id,
                  categories["shisei/soshiki/kikaku"].id,
                  categories["shisei/soshiki/kikaku/koho"].id,
                  categories["shisei/soshiki/kikaku/seisaku"].id,
                ]
save_page route: "article/page", filename: "oshirase/kurashi/26.html", name: "身体障害者手帳の認定基準が変更",
  layout_id: layouts["oshirase"].id, category_ids: [categories["oshirase"].id, categories["oshirase/kurashi"].id]
save_page route: "article/page", filename: "oshirase/kurashi/27.html", name: "平成26年4月より国民健康保険税率が改正されます",
  layout_id: layouts["oshirase"].id,
  category_ids: [ categories["oshirase"].id,
                  categories["oshirase/kurashi"].id,
                  categories["shisei/soshiki/soumu"].id,
                  categories["shisei/soshiki/soumu/nouzei"].id
                ]
save_page route: "article/page", filename: "urgency/28.html", name: "黒鷺県沖で発生した地震による当市への影響について。",
  layout_id: layouts["oshirase"].id, category_ids: [categories["urgency"].id]
save_page route: "article/page", filename: "urgency/29.html", name: "黒鷺県沖で発生した地震による津波被害について。",
  layout_id: layouts["more"].id, category_ids: [categories["urgency"].id]
save_page route: "article/page", filename: "docs/30.html", name: "ふれあいフェスティバル",
  layout_id: layouts["oshirase"].id,
  category_ids: [ categories["oshirase"].id,
                  categories["oshirase/event"].id,
                  categories["shisei/soshiki"].id,
                  categories["shisei/soshiki/kikaku"].id,
                  categories["shisei/soshiki/kikaku/koho"].id,
                ]
dates = (Date.today..(Date.today + 20)).map { |d| d.mongoize }
save_page route: "event/page", filename: "calendar/31.html", name: "住民相談会を開催します。",
  layout_id: layouts["event"].id, category_ids: [categories["calendar/kohen"].id], event_dates: dates,
  schedule: "〇〇年○月〇日", venue: "○○○○○○○○○○", cost: "○○○○○○○○○○",
  content: "○○○○○○○○○○○○○○○○○○○○", related_url: "http://demo.ss-proj.org/"

## -------------------------------------
puts "# faq"

save_page route: "faq/page", filename: "faq/docs/32.html", name: "休日や夜間の戸籍の届出について",
  layout_id: layouts["faq"].id, category_ids: [categories["faq/kurashi"].id], question: "<p>休日や夜間でも戸籍の届出は可能でしょうか。</p>"

## -------------------------------------
puts "# facility"

def save_ss_files(path, data)
  puts path
  cond = { filename: data[:filename], model: data[:model] }

  file = Fs::UploadedFile.new("ss_file")
  file.binmode
  file.write(File.binread(path))
  file.rewind
  file.original_filename = data[:filename]
  file.content_type = Fs.content_type(path)

  item = SS::File.find_or_create_by(cond)
  item.in_file = file
  item.update

  item
end

Dir.glob "ss_files/facility/*.*" do |file|
  save_ss_files file, filename: File.basename(file), model: "facility/temp_file"
end

array   =  SS::File.where(model: "facility/temp_file").map { |m| [m.filename, m] }
facility_images = Hash[*array.flatten]

save_page route: "facility/image", filename: "institution/bunka/library/library.html", name: "シラサギ市立図書館",
  layout_id: layouts["map"].id, image_id: facility_images["library.jpg"].id, order: 0
save_page route: "facility/image", filename: "institution/bunka/library/equipment.html", name: "設備",
  layout_id: layouts["map"].id, image_id: facility_images["equipment.jpg"].id, order: 10
save_page route: "facility/map", filename: "institution/bunka/library/map.html", name: "地図",
  layout_id: layouts["map"].id, map_points: [  { name: "マーカー名",  loc: [  34.067035,  134.589971 ],  text: "" } ]
