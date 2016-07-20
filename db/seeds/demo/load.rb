## -------------------------------------
# Require

puts "Please input site_name: site=[site_host]" or exit if ENV['site'].blank?

@site = SS::Site.where(host: ENV['site']).first
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

## -------------------------------------
def save_member(data)
  puts data[:email]
  cond = { site_id: @site._id, email: data[:email] }

  item = Cms::Member.find_or_create_by(cond)
  item.attributes = data
  item.update
  item
end

@member_1 = save_member(
  email: "member@example.jp",
  in_password: "pass123",
  state: "enabled",
  name: "白鷺　太郎",
  kana: "しらさぎ　たろう",
  job: "シラサギ株式会社",
  postal_code: "1050001",
  addr: "東京都港区虎ノ門1-1-1",
  sex: "male",
  birthday: Date.parse("1988/10/10")
)
@member_2 = save_member(
  email: "shirasagi_hanako@example.jp",
  in_password: "pass123",
  state: "enabled",
  name: "白鷺　花子",
  kana: "しらさぎ　はなこ",
  postal_code: "1050001",
  addr: "東京都港区虎ノ門1-1-1",
  sex: "female",
  birthday: Date.parse("1990/07/07")
)
member_group = Member::Group.create cur_site: @site, name: "白鷺家",
  invitation_message: "白鷺家のグループです。", in_admin_member_ids: [ @member_1.id ]
member_group.members.new(member_id: @member_2.id, state: "user")
member_group.save

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
save_layout filename: "ezine.layout.html", name: "メールマガジン"
save_layout filename: "urgency-layout/top-level1.layout.html", name: "緊急災害1：トップページ"
save_layout filename: "urgency-layout/top-level2.layout.html", name: "緊急災害2：トップページ"
save_layout filename: "urgency-layout/top-level3.layout.html", name: "緊急災害3：トップページ"
save_layout filename: "kanko-info.layout.html", name: "写真データベース、ブログ"
save_layout filename: "kanko-info-top.layout.html", name: "観光情報"
save_layout filename: "kanko-info-photo.layout.html", name: "写真データベース：検索"
save_layout filename: "login.layout.html", name: "ログイン"
save_layout filename: "kanko-info/blog/blog1.layout.html", name: "ブログレイアウト1"
save_layout filename: "kanko-info/blog/blog2.layout.html", name: "ブログレイアウト2"
save_layout filename: "mypage.layout.html", name: "マイページ"

array   = Cms::Layout.where(site_id: @site._id).map { |m| [m.filename.sub(/\..*/, ""), m] }
layouts = Hash[*array.flatten]

## -------------------------------------
puts "# nodes"

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

array = Category::Node::Base.where(site_id: @site._id).map { |m| [m.filename, m] }
categories = Hash[*array.flatten]

## node
save_node route: "cms/node", filename: "use", name: "ご利用案内"

## article
save_node route: "article/page", filename: "docs", name: "記事", shortcut: "show"

## archive
save_node route: "cms/archive", filename: "docs/archive", name: "アーカイブ", layout_id: layouts["more"].id

## sitemap
save_node route: "sitemap/page", filename: "sitemap", name: "サイトマップ"

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

## ads
save_node route: "ads/banner", filename: "add", name: "広告バナー", shortcut: "show"

## urgency
save_node route: "urgency/layout", filename: "urgency-layout", name: "緊急災害レイアウト",
  urgency_default_layout_id: layouts["top"].id, shortcut: "show"

## inquiry
inquiry_html = File.read("nodes/inquiry.inquiry_html") rescue nil
inquiry_sent_html = File.read("nodes/inquiry.inquiry_sent_html") rescue nil
inquiry_node = save_node route: "inquiry/form", filename: "inquiry", name: "市へのお問い合わせ", shortcut: "show",
  from_name: "シラサギサンプルサイト",
  inquiry_captcha: "enabled", notice_state: "disabled",
  inquiry_html: inquiry_html, inquiry_sent_html: inquiry_sent_html,
  reply_state: "disabled",
  reply_subject: "シラサギ市へのお問い合わせを受け付けました。",
  reply_upper_text: "以下の内容でお問い合わせを受け付けました。",
  reply_lower_text: "以上。",
  aggregation_state: "disabled"

## feedback
feedback_html = File.read("nodes/feedback.inquiry_html") rescue nil
feedback_sent_html = File.read("nodes/feedback.inquiry_sent_html") rescue nil
feedback_node = save_node route: "inquiry/form", filename: "feedback", name: "この情報はお役に立ちましたか？",
  inquiry_captcha: "disabled", notice_state: "disabled",
  inquiry_html: feedback_html, inquiry_sent_html: feedback_sent_html,
  reply_state: "disabled",
  aggregation_state: "disabled"

## public comment
save_node route: "inquiry/node", filename: "comment", name: "パブリックコメント",
  upper_html: "パブリックコメント一覧です。"
inquiry_comment_1 = save_node route: "inquiry/form", filename: "comment/comment01", name: "シラサギ市政について",
  from_name: "シラサギサンプルサイト",
  inquiry_captcha: "enabled", notice_state: "disabled",
  inquiry_html: inquiry_html,
  inquiry_sent_html: "<p>パブリックコメントを受け付けました。</p>",
  reply_state: "disabled",
  reply_subject: "シラサギ市へのお問い合わせを受け付けました。",
  reply_upper_text: "以下の内容でお問い合わせを受け付けました。",
  reply_lower_text: "以上。",
  aggregation_state: "enabled",
  reception_start_date: Time.zone.now.beginning_of_month,
  reception_close_date: Time.zone.now.end_of_month
inquiry_comment_2 = save_node route: "inquiry/form", filename: "comment/comment02", name: "シラサギ市都市計画について",
  from_name: "シラサギサンプルサイト",
  inquiry_captcha: "enabled", notice_state: "disabled",
  inquiry_html: inquiry_html,
  inquiry_sent_html: "<p>パブリックコメントを受け付けました。</p>",
  reply_state: "disabled",
  reply_subject: "シラサギ市へのお問い合わせを受け付けました。",
  reply_upper_text: "以下の内容でお問い合わせを受け付けました。",
  reply_lower_text: "以上。",
  aggregation_state: "enabled",
  reception_start_date: Time.zone.now.prev_month.beginning_of_month,
  reception_close_date: Time.zone.now.prev_month.end_of_month

## ezine
def save_ezine_column(data)
  puts data[:name]
  cond = { site_id: data[:site_id], node_id: data[:node_id], name: data[:name] }

  item = Ezine::Column.find_or_create_by(cond)
  item.attributes = data
  item.update

  item
end

ezine_signature_html = File.read("nodes/ezine.signature_html") rescue nil
ezine_signature_text = File.read("nodes/ezine.signature_text") rescue nil
ezine_reply_signature = File.read("nodes/ezine.reply_signature") rescue nil
ezine_page_node = save_node route: "ezine/page", filename: "ezine", name: "メールマガジン",
  sender_name: "シラサギサンプルサイト",
  sender_email: "admin@example.jp",
  reply_upper_text: "メールマガジン登録を受け付けました。",
  signature_html: ezine_signature_html,
  signature_text: ezine_signature_text,
  reply_signature: ezine_reply_signature
ezine_backnumber_node = save_node route: "ezine/backnumber", filename: "ezine/backnumber",
  name: "メールマガジン　バックナンバー", conditions: %w(ezine)
save_ezine_column node_id: ezine_page_node.id, name: "性別", order: 0, input_type: "radio_button",
  select_options: %w(男性 女性), required: "required", site_id: @site._id

# ezine anpi
save_node route: "ezine/category_node", filename: "anpi-ezine", name: "安否メールマガジン", layout_id: layouts["kanko-info"].id
ezine_anpi = save_node route: "ezine/member_page", filename: "anpi-ezine/anpi", name: "安否確認",
  layout_id: layouts["kanko-info"].id,
  sender_name: "シラサギサンプルサイト", sender_email: "admin@example.jp",
  signature_html: ezine_signature_html, signature_text: ezine_signature_text,
  subscription_constraint: "required"
ezine_event = save_node route: "ezine/member_page", filename: "anpi-ezine/event", name: "イベント情報",
  layout_id: layouts["kanko-info"].id,
  sender_name: "シラサギサンプルサイト", sender_email: "admin@example.jp",
  signature_html: ezine_signature_html, signature_text: ezine_signature_text
@member_1.subscription_ids = [ ezine_anpi.id, ezine_event.id ]
@member_1.save
@member_2.subscription_ids = [ ezine_anpi.id, ezine_event.id ]
@member_2.save

## facility
save_node route: "cms/node", filename: "institution/chiki", name: "施設のある地域", layout_id: layouts["one"].id
center_point = Map::Extensions::Point.mongoize(loc: [34.075593, 134.550614], zoom_level: 10)
save_node route: "facility/location", filename: "institution/chiki/higashii",
  name: "東区", order: 10, center_point: center_point
center_point = Map::Extensions::Point.mongoize(loc: [34.034417, 133.808902], zoom_level: 10)
save_node route: "facility/location", filename: "institution/chiki/nishi",
  name: "西区", order: 20, center_point: center_point
center_point = Map::Extensions::Point.mongoize(loc: [33.609123, 134.352387], zoom_level: 10)
save_node route: "facility/location", filename: "institution/chiki/minami",
  name: "南区", order: 30, center_point: center_point
center_point = Map::Extensions::Point.mongoize(loc: [34.179472, 134.608579], zoom_level: 10)
save_node route: "facility/location", filename: "institution/chiki/kita",
  name: "北区", order: 40, center_point: center_point
save_node route: "cms/node", filename: "institution/shurui", name: "施設の種類", layout_id: layouts["one"].id
save_node route: "facility/category", filename: "institution/shurui/bunka", name: "文化施設", order: 10
save_node route: "facility/category", filename: "institution/shurui/sports", name: "運動施設", order: 20
save_node route: "facility/category", filename: "institution/shurui/school", name: "小学校", order: 30
save_node route: "facility/category", filename: "institution/shurui/kokyo", name: "公園・公共施設", order: 40

save_node route: "cms/node", filename: "institution/yoto", name: "施設の用途", layout_id: layouts["one"].id
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

save_node route: "facility/node", filename: "institution/shisetsu", name: "施設一覧",
  st_category_ids: facility_categories.values.map{ |cate| cate.id },
  st_location_ids: facility_locations.values.map{ |loc| loc.id },
  st_service_ids: facility_services.values.map{ |serv| serv.id }

save_node route: "facility/page", filename: "institution/shisetsu/library", name: "シラサギ市立図書館",
  kana: "しらさぎとしょかん",
  address: "大鷺県シラサギ市小鷺町1丁目1番地1号",
  tel: "00-0000-0000",
  fax: "00-0000-0000",
  related_url: "http://demo.ss-proj.org/",
  category_ids: facility_categories.values.map(&:id),
  location_ids: facility_locations.values.map(&:id),
  service_ids: facility_services.values.map(&:id)

save_node route: "key_visual/image", filename: "key_visual", name: "キービジュアル"

## inquiry
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
  html: column_email_html, select_options: [], required: "required", input_confirm: "enabled", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "性別", order: 30, input_type: "radio_button",
  html: column_gender_html, select_options: %w(男性 女性), required: "required", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "年齢", order: 40, input_type: "select",
  html: column_age_html, select_options: %w(10代 20代 30代 40代 50代 60代 70代 80代), required: "required", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "お問い合わせ区分", order: 50, input_type: "check_box",
  html: column_category_html, select_options: %w(市政について ご意見・ご要望 申請について その他), required: "required", site_id: @site._id
save_inquiry_column node_id: inquiry_node.id, name: "お問い合わせ内容", order: 60, input_type: "text_area",
  html: column_question_html, select_options: [], required: "required", site_id: @site._id

puts "# inquiry public comment"
save_inquiry_column node_id: inquiry_comment_1.id, name: "性別", order: 0, input_type: "radio_button",
  html: column_gender_html, select_options: %w(男性 女性), required: "required", site_id: @site._id
save_inquiry_column node_id: inquiry_comment_1.id, name: "年齢", order: 10, input_type: "select",
  html: column_age_html, select_options: %w(10代 20代 30代 40代 50代 60代 70代 80代), required: "required", site_id: @site._id
save_inquiry_column node_id: inquiry_comment_1.id, name: "意見", order: 20, input_type: "text_area",
  html: "<p>ご意見を入力してください。</p>", select_options: [], required: "required", site_id: @site._id

column_gender = save_inquiry_column node_id: inquiry_comment_2.id, name: "性別", order: 0, input_type: "radio_button",
  html: column_gender_html, select_options: %w(男性 女性), required: "required", site_id: @site._id
column_age = save_inquiry_column node_id: inquiry_comment_2.id, name: "年齢", order: 10, input_type: "select",
  html: column_age_html, select_options: %w(10代 20代 30代 40代 50代 60代 70代 80代), required: "required",
  site_id: @site._id
column_opinion = save_inquiry_column node_id: inquiry_comment_2.id, name: "意見", order: 20, input_type: "text_area",
  html: "<p>ご意見を入力してください。</p>", select_options: [], required: "required", site_id: @site._id

save_inquiry_answer node_id: inquiry_comment_2.id, site_id: @site._id,
  remote_addr: "192.0.2.0", user_agent: "dummy connection (input by seed demo)",
  data: {
    column_gender.id => "女性",
    column_age.id => "10代",
    column_opinion.id => "意見があります。"
  }
save_inquiry_answer node_id: inquiry_comment_2.id, site_id: @site._id,
  remote_addr: "192.0.2.0", user_agent: "dummy connection (input by seed demo)",
  data: {
    column_gender.id => "女性",
    column_age.id => "80代",
    column_opinion.id => "意見があります。"
  }
save_inquiry_answer node_id: inquiry_comment_2.id, site_id: @site._id,
  remote_addr: "192.0.2.0", user_agent: "dummy connection (input by seed demo)",
  data: {
    column_gender.id => "男性",
    column_age.id => "50代",
    column_opinion.id => "意見があります。"
  }
save_inquiry_answer node_id: inquiry_comment_2.id, site_id: @site._id,
  remote_addr: "192.0.2.0", user_agent: "dummy connection (input by seed demo)",
  data: {
    column_gender.id => "男性",
    column_age.id => "10代",
    column_opinion.id => "意見があります。"
  }

puts "# feedback"

column_feedback_1 = save_inquiry_column node_id: feedback_node.id, name: "このページの内容は役に立ちましたか？",
  order: 10, input_type: "radio_button", select_options: %w(役に立った どちらともいえない 役に立たなかった),
  required: "required", site_id: @site._id
column_feedback_2 = save_inquiry_column node_id: feedback_node.id, name: "このページの内容は分かりやすかったですか？",
  order: 20, input_type: "radio_button", select_options: %w(分かりやすかった どちらともいえない 分かりにくかった),
  required: "required", site_id: @site._id
column_feedback_3 = save_inquiry_column node_id: feedback_node.id, name: "このページの情報は見つけやすかったですか？",
  order: 30, input_type: "radio_button", select_options: %w(見つけやすかった どちらともいえない 見つけにくかった),
  required: "required", site_id: @site._id

save_inquiry_answer node_id: feedback_node.id, site_id: @site._id,
  remote_addr: "192.0.2.0", user_agent: "dummy connection (input by seed demo)",
  data: {
    column_feedback_1.id => "どちらともいえない",
    column_feedback_2.id => "どちらともいえない",
    column_feedback_3.id => "どちらともいえない"
  }

## member
save_node route: "member/login", filename: "login", name: "ログイン", layout_id: layouts["login"].id,
  form_auth: "enabled", redirect_url: "/mypage/"
save_node route: "member/registration", filename: "registration", name: "会員登録", layout_id: layouts["one"].id,
  sender_email: "info@example.jp", sender_name: "送信者名", kana_required: "required", postal_code_required: "required",
  addr_required: "required", sex_required: "required", birthday_required: "required"
save_node route: "member/mypage", filename: "mypage", name: "マイページ", layout_id: layouts["mypage"].id
save_node route: "member/my_profile", filename: "mypage/profile", name: "プロフィール", layout_id: layouts["mypage"].id, order: 10,
  kana_required: "required", postal_code_required: "required", addr_required: "required", sex_required: "required",
  birthday_required: "required"
save_node route: "member/my_blog", filename: "mypage/blog", name: "ブログ", layout_id: layouts["mypage"].id, order: 20
save_node route: "member/my_photo", filename: "mypage/photo", name: "フォト", layout_id: layouts["mypage"].id, order: 30
anpi_node = save_node route: "member/my_anpi_post", filename: "mypage/anpi", name: "安否",
  layout_id: layouts["mypage"].id, order: 40, map_state: "enabled", map_view_state: "enabled", text_size_limit: 400
save_node route: "member/my_group", filename: "mypage/group", name: "グループ", layout_id: layouts["mypage"].id, order: 50,
  sender_name: "シラサギサンプルサイト", sender_email: "admin@example.jp"

## member blog
save_node route: "cms/node", filename: "kanko-info", name: "観光情報", layout_id: layouts["kanko-info-top"].id
save_node route: "member/blog", filename: "kanko-info/blog", name: "ブログ",
  layout_id: layouts["kanko-info"].id, order: 20, page_limit: 4

save_node route: "cms/node", filename: "kanko-info/blog/area", name: "地域", layout_id: layouts["kanko-info"].id
blog_l1 = save_node route: "member/blog_page_location", filename: "kanko-info/blog/area/east",
  name: "東区", layout_id: layouts["kanko-info"].id, order: 10
blog_l2 = save_node route: "member/blog_page_location", filename: "kanko-info/blog/area/west",
  name: "西区", layout_id: layouts["kanko-info"].id, order: 20
blog_l3 = save_node route: "member/blog_page_location", filename: "kanko-info/blog/area/south",
  name: "南区", layout_id: layouts["kanko-info"].id, order: 30
blog_l4 = save_node route: "member/blog_page_location", filename: "kanko-info/blog/area/north",
  name: "北区", layout_id: layouts["kanko-info"].id, order: 40
blog_thumb = Fs::UploadedFile.create_from_file("files/img/logo.png")

save_node route: "member/blog_page", filename: "kanko-info/blog/shirasagi", name: "白鷺太郎のブログ",
  layout_id: layouts["kanko-info/blog/blog1"].id, member_id: @member_1.id, description: "白鷺太郎のブログです。よろしくお願いしいます。",
  genres: %w(ジャンル1 ジャンル2 ジャンル3), blog_page_location_ids: [blog_l1.id], in_image: blog_thumb

## member photo
save_node route: "member/photo", filename: "kanko-info/photo", name: "写真データベース",
  layout_id: layouts["kanko-info-photo"].id, order: 10,
  license_free: "<h2>ライセンスについて</h2><p>どなたでも自由にご利用いただけます。<br />肖像権については、使用者の判断によるものとし、当サイトは関与しません。</p>",
  license_not_free: "<h2>ライセンスについて</h2><p>画像のご利用には画像投稿者からの利用許可が必要です。</p>",
  limit: 40,
  page_layout_id: layouts["kanko-info"].id

save_node route: "cms/node", filename: "kanko-info/photo/area", name: "地域", layout_id: layouts["kanko-info"].id
photo_l1 = save_node route: "member/photo_location", filename: "kanko-info/photo/area/east",
  name: "東区", layout_id: layouts["kanko-info"].id, order: 10
photo_l2 = save_node route: "member/photo_location", filename: "kanko-info/photo/area/west",
  name: "西区", layout_id: layouts["kanko-info"].id, order: 20
photo_l3 = save_node route: "member/photo_location", filename: "kanko-info/photo/area/south",
  name: "南区", layout_id: layouts["kanko-info"].id, order: 30
photo_l4 = save_node route: "member/photo_location", filename: "kanko-info/photo/area/north",
  name: "北区", layout_id: layouts["kanko-info"].id, order: 40

save_node route: "cms/node", filename: "kanko-info/photo/category", name: "カテゴリー", layout_id: layouts["kanko-info"].id
photo_c1 = save_node route: "member/photo_category", filename: "kanko-info/photo/category/institution",
  name: "施設", layout_id: layouts["kanko-info"].id, order: 10
photo_c2 = save_node route: "member/photo_category", filename: "kanko-info/photo/category/nature",
  name: "自然", layout_id: layouts["kanko-info"].id, order: 20
photo_c3 = save_node route: "member/photo_category", filename: "kanko-info/photo/category/souvenir",
  name: "物産", layout_id: layouts["kanko-info"].id, order: 30
photo_c4 = save_node route: "member/photo_category", filename: "kanko-info/photo/category/other",
  name: "その他", layout_id: layouts["kanko-info"].id, order: 40

save_node route: "member/photo_search", filename: "kanko-info/photo/search", name: "検索結果", layout_id: layouts["kanko-info"].id
save_node route: "member/photo_spot", filename: "kanko-info/photo/spot", name: "おすすめスポット", layout_id: layouts["kanko-info"].id

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
Cms::Node.where(site_id: @site._id, route: /^inquiry\//).
  update_all(layout_id: layouts["one"].id)
Cms::Node.where(site_id: @site._id, filename: /^sitemap$/).
  update_all(layout_id: layouts["one"].id)
Cms::Node.where(site_id: @site._id, filename: /^faq$/).
  update_all(layout_id: layouts["faq-top"].id)
Cms::Node.where(site_id: @site._id, filename: /^add$/).
  update_all(layout_id: layouts["one"].id)
Cms::Node.where(site_id: @site._id, filename: /faq\//).
  update_all(layout_id: layouts["faq"].id)
Cms::Node.where(site_id: @site._id, route: /facility\//).
  update_all(layout_id: layouts["map"].id)
Cms::Node.where(site_id: @site._id, route: /ezine\//).
  update_all(layout_id: layouts["ezine"].id)

## -------------------------------------
puts "# parts"

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

save_part route: "cms/free", filename: "about.part.html", name: "シラサギ市について"
save_part route: "cms/free", filename: "foot.part.html", name: "フッター"
save_part route: "cms/free", filename: "guide.part.html", name: "くらしのガイド"
save_part route: "cms/free", filename: "head.part.html", name: "ヘッダー", mobile_view: "hide"
save_part route: "cms/free", filename: "head-top.part.html", name: "ヘッダー：トップ"
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
save_part route: "cms/free", filename: "ezine-side.part.html", name: "サイドメニュー：メールマガジン"
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
save_part route: "ads/banner", filename: "add/add.part.html", name: "広告バナー", mobile_view: "hide", with_category: "enabled"
save_part route: "cms/sns_share", filename: "sns.part.html", name: "sns", mobile_view: "hide"
save_part route: "key_visual/slide", filename: "key_visual/slide.part.html", name: "スライドショー", mobile_view: "hide"
save_part route: "inquiry/feedback", filename: "feedback/feedback.part.html", name: "フィードバック", mobile_view: "hide",
  upper_html: '<section id="feedback"><h2>この情報は役に立ちましたか？</h2>',
  lower_html: '</section>'
save_part route: "member/photo", filename: "kanko-info/photo/recent.part.html", name: "新着写真一覧", mobile_view: "hide", limit: 4
save_part route: "member/photo_slide", filename: "kanko-info/photo/slide.part.html", name: "スライド", mobile_view: "hide"
save_part route: "member/photo_search", filename: "kanko-info/photo/search/search.part.html", name: "スライド", mobile_view: "hide"
save_part route: "member/blog_page", filename: "kanko-info/blog/recent.part.html", name: "新着ブログ", mobile_view: "hide"
save_part route: "member/login", filename: "login/login.part.html", name: "ログイン", mobile_view: "hide", ajax_view: "enabled"

## -------------------------------------
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

## -------------------------------------
puts "# articles"
contact_group = SS::Group.where(name: "シラサギ市/企画政策部/政策課").first
contact_group_id = contact_group.id rescue nil
contact_email = contact_group_id ? "kikakuseisaku@example.jp" : nil
contact_tel = contact_group_id ? "000-000-0000" : nil
contact_fax = contact_group_id ? "000-000-0000" : nil

save_page route: "article/page", filename: "docs/page1.html", name: "インフルエンザによる学級閉鎖状況",
  layout_id: layouts["pages"].id, category_ids: [categories["attention"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/page2.html", name: "コンビニ納付のお知らせ",
  layout_id: layouts["oshirase"].id,
  category_ids: [ categories["attention"].id,
                  categories["shisei/soshiki"].id,
                  categories["shisei/soshiki/kikaku"].id,
                  categories["shisei/soshiki/kikaku/koho"].id,
                  categories["shisei/soshiki/kikaku/seisaku"].id,
                  categories["shisei/soshiki/soumu"].id,
                  categories["shisei/soshiki/soumu/nouzei"].id
                ],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/page3.html", name: "平成26年第1回シラサギ市議会定例会を開催します",
  layout_id: layouts["oshirase"].id, category_ids: [categories["attention"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/page4.html", name: "放射性物質・震災関連情報",
  layout_id: layouts["oshirase"].id, category_ids: [categories["attention"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/page5.html", name: "市内の微小粒子状物質（PM2.5）の測定データ（速報値）を公開しています。",
  layout_id: layouts["oshirase"].id, category_ids: [categories["attention"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/page6.html", name: "還付金詐欺と思われる不審な電話にご注意ください",
  layout_id: layouts["oshirase"].id,
  category_ids: [ categories["oshirase"].id,
                  categories["shisei/soshiki"].id,
                  categories["shisei/soshiki/kikaku"].id,
                  categories["shisei/soshiki/kikaku/koho"].id,
                  categories["shisei/soshiki/kikaku/seisaku"].id,
                ],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/page7.html", name: "平成26年度　シラサギ市システム構築に係るの公募型企画競争",
  layout_id: layouts["oshirase"].id,
  category_ids: [ categories["oshirase"].id,
                  categories["shisei/soshiki"].id,
                  categories["shisei/soshiki/kikaku"].id,
                  categories["shisei/soshiki/kikaku/koho"].id,
                  categories["shisei/soshiki/kikaku/seisaku"].id,
                ],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/page8.html", name: "冬の感染症に備えましょう",
  layout_id: layouts["oshirase"].id, category_ids: [categories["oshirase"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/page9.html", name: "広報SHIRASAGI3月号を掲載",
  layout_id: layouts["oshirase"].id,
  category_ids: [ categories["oshirase"].id,
                  categories["oshirase/kurashi"].id,
                  categories["shisei/soshiki"].id,
                  categories["shisei/soshiki/kikaku"].id,
                  categories["shisei/soshiki/kikaku/koho"].id,
                ],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/page10.html", name: "インフルエンザ流行警報がでています",
  layout_id: layouts["oshirase"].id, category_ids: [categories["oshirase"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/page11.html", name: "転出届", gravatar_screen_name: "サイト管理者",
  layout_id: layouts["pages"].id, category_ids: [categories["kurashi/koseki/jyumin"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/page12.html", name: "転入届",
  layout_id: layouts["pages"].id, category_ids: [categories["kurashi/koseki/jyumin"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/page13.html", name: "世帯または世帯主を変更するとき",
  layout_id: layouts["pages"].id, category_ids: [categories["kurashi/koseki/jyumin"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/page14.html", name: "証明書発行窓口",
  layout_id: layouts["pages"].id, category_ids: [categories["kurashi/koseki/jyumin"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/page15.html", name: "住民票記載事項証明書様式",
  layout_id: layouts["pages"].id, category_ids: [categories["kurashi/koseki/jyumin"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/page16.html", name: "住所変更の証明書について",
  layout_id: layouts["pages"].id, category_ids: [categories["kurashi/koseki/jyumin"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/page17.html", name: "住民票コードとは",
  layout_id: layouts["pages"].id, category_ids: [categories["kurashi/koseki/jyumin"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/page18.html", name: "住民票コードの変更",
  layout_id: layouts["pages"].id, category_ids: [categories["kurashi/koseki/jyumin"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/page19.html", name: "自動交付機・コンビニ交付サービスについて",
  layout_id: layouts["pages"].id,
  category_ids: [ categories["oshirase"].id,
                  categories["oshirase/kurashi"].id,
                  categories["shisei/soshiki"].id,
                  categories["shisei/soshiki/kikaku"].id,
                  categories["shisei/soshiki/kikaku/koho"].id,
                  categories["shisei/soshiki/kikaku/seisaku"].id,
                ],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "docs/tenkyo.html", name: "転居届",
  layout_id: layouts["pages"].id, category_ids: [categories["kurashi/koseki/jyumin"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "oshirase/kurashi/page20.html", name: "犬・猫を譲り受けたい方",
  layout_id: layouts["oshirase"].id, category_ids: [categories["oshirase"].id, categories["oshirase/kurashi"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "oshirase/kurashi/page21.html", name: "平成26年度住宅補助金の募集について掲載しました。",
  layout_id: layouts["oshirase"].id, category_ids: [categories["oshirase"].id, categories["oshirase/kurashi"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "oshirase/kurashi/page22.html", name: "休日臨時窓口を開設します。",
  layout_id: layouts["oshirase"].id,
  category_ids: [ categories["oshirase"].id,
                  categories["oshirase/kurashi"].id,
                  categories["shisei/soshiki"].id,
                  categories["shisei/soshiki/kikaku"].id,
                  categories["shisei/soshiki/kikaku/koho"].id,
                  categories["shisei/soshiki/kikaku/seisaku"].id,
                ],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "oshirase/kurashi/page23.html", name: "身体障害者手帳の認定基準が変更",
  layout_id: layouts["oshirase"].id, category_ids: [categories["oshirase"].id, categories["oshirase/kurashi"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "oshirase/kurashi/page24.html", name: "平成26年4月より国民健康保険税率が改正されます",
  layout_id: layouts["oshirase"].id,
  category_ids: [ categories["oshirase"].id,
                  categories["oshirase/kurashi"].id,
                  categories["shisei/soshiki/soumu"].id,
                  categories["shisei/soshiki/soumu/nouzei"].id
                ],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "urgency/page25.html", name: "黒鷺県沖で発生した地震による当市への影響について。",
  layout_id: layouts["oshirase"].id, category_ids: [categories["urgency"].id],
  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
save_page route: "article/page", filename: "urgency/page26.html", name: "黒鷺県沖で発生した地震による津波被害について。",
  layout_id: layouts["more"].id, category_ids: [categories["urgency"].id],
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
dates = (Time.zone.today..(Time.zone.today + 20)).map { |d| d.mongoize }
save_page route: "event/page", filename: "calendar/page28.html", name: "住民相談会を開催します。",
  layout_id: layouts["event"].id, category_ids: [categories["calendar/kohen"].id], event_dates: dates,
  schedule: "〇〇年○月〇日", venue: "○○○○○○○○○○", cost: "○○○○○○○○○○",
  content: "○○○○○○○○○○○○○○○○○○○○", related_url: "http://demo.ss-proj.org/"

## -------------------------------------
puts "sitemap"
sitemap_urls = File.read("sitemap/urls.txt") rescue nil
save_page route: "sitemap/page", filename: "sitemap/index.html", name: "サイトマップ",
  layout_id: layouts["one"].id, sitemap_urls: sitemap_urls

## -------------------------------------
puts "# faq"

save_page route: "faq/page", filename: "faq/docs/page29.html", name: "休日や夜間の戸籍の届出について",
  layout_id: layouts["faq"].id, category_ids: [categories["faq/kurashi"].id], question: "<p>休日や夜間でも戸籍の届出は可能でしょうか。</p>"

## -------------------------------------
puts "# ads"

banner1 = save_ss_files "ss_files/ads/dummy_banner_1.gif", filename: "dummy_banner_1.gif", model: "ads/banner"
banner2 = save_ss_files "ss_files/ads/dummy_banner_2.gif", filename: "dummy_banner_2.gif", model: "ads/banner"
banner3 = save_ss_files "ss_files/ads/dummy_banner_3.gif", filename: "dummy_banner_3.gif", model: "ads/banner"
banner4 = save_ss_files "ss_files/ads/dummy_banner_4.gif", filename: "dummy_banner_4.gif", model: "ads/banner"
banner5 = save_ss_files "ss_files/ads/dummy_banner_5.gif", filename: "dummy_banner_5.gif", model: "ads/banner"
banner6 = save_ss_files "ss_files/ads/dummy_banner_6.gif", filename: "dummy_banner_6.gif", model: "ads/banner"
banner1.set(state: "public")
banner2.set(state: "public")
banner3.set(state: "public")
banner4.set(state: "public")
banner5.set(state: "public")
banner6.set(state: "public")

save_page route: "ads/banner", filename: "add/page30.html", name: "くらし・手続き",
  link_url: "/kurashi/", file_id: banner1.id, ads_category_ids: [categories["kurashi"].id], order: 10
save_page route: "ads/banner", filename: "add/page31.html", name: "子育て・教育",
  link_url: "/kosodate/", file_id: banner2.id, ads_category_ids: [categories["kosodate"].id], order: 20
save_page route: "ads/banner", filename: "add/page32.html", name: "健康・福祉",
  link_url: "/kenko/", file_id: banner3.id, ads_category_ids: [categories["kenko"].id], order: 30
save_page route: "ads/banner", filename: "add/page33.html", name: "観光・文化・スポーツ",
  link_url: "/kanko/", file_id: banner4.id, ads_category_ids: [categories["kanko"].id], order: 40
save_page route: "ads/banner", filename: "add/page34.html", name: "産業・仕事",
  link_url: "/sangyo/", file_id: banner5.id, ads_category_ids: [categories["sangyo"].id], order: 50
save_page route: "ads/banner", filename: "add/page35.html", name: "市政情報",
  link_url: "/shisei/", file_id: banner6.id, ads_category_ids: [categories["shisei"].id], order: 60

## -------------------------------------
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

puts "# ezine"
save_page route: "ezine/page", filename: "ezine/page36.html", name: "シラサギ市メールマガジン", completed: true,
  layout_id: layouts["ezine"].id, html: "<p>シラサギ市メールマガジンを配信します。</p>\r\n",
  text: "シラサギ市メールマガジンを配信します。\r\n"

puts "# anpi-ezine"
anpi_text = File.read("pages/anpi-ezine/anpi/anpi37.text.txt") rescue nil
save_page route: "ezine/page", filename: "anpi-ezine/anpi/anpi37.html",
  name: "2011年03月11日 14時46分 ころ地震がありました", completed: true, layout_id: layouts["ezine"].id,
  text: anpi_text
save_page route: "ezine/page", filename: "anpi-ezine/event/page38.html",
  name: "シラサギ市イベント情報 No.12", completed: true, layout_id: layouts["ezine"].id,
  html: "<p>シラサギ市イベント情報を配信します。</p>\r\n",
  text: "シラサギ市イベント情報を配信します。\r\n"

puts "# weather-xml"

## -------------------------------------
puts "# member blog"
file = save_ss_files "ss_files/key_visual/keyvisual01.jpg", filename: "keyvisual01.jpg", model: "member/blog_page"
blog_page = save_page route: "member/blog_page", filename: "kanko-info/blog/shirasagi/page1.html", name: "初投稿です。",
  member_id: @member_1.id,
  genres: %w(ジャンル1 ジャンル2 ジャンル3)

blog_page.file_ids = [file.id]
blog_page.html = blog_page.html.sub("src=\"#\"", "src=\"#{file.url}\"")
blog_page.update

## -------------------------------------
puts "# member photo"

photo_page_1 = save_page route: "member/photo", filename: "kanko-info/photo/page1.html", name: "観光地1",
  member_id: @member_1.id,
  layout_id: layouts["kanko-info"].id,
  map_points: [ { loc: [33.902679, 134.526215] } ],
  listable_state: "public",
  slideable_state: "hide",
  license_name: "not_free",
  photo_category_ids: [photo_c1.id],
  photo_location_ids: [photo_l3.id],
  in_image: Fs::UploadedFile.create_from_file("ss_files/key_visual/keyvisual01.jpg")

photo_page_2 = save_page route: "member/photo", filename: "kanko-info/photo/page2.html", name: "観光地2",
  member_id: @member_1.id,
  layout_id: layouts["kanko-info"].id,
  map_points: [ { loc: [33.729822, 134.538575] } ],
  listable_state: "public",
  slideable_state: "public",
  license_name: "not_free",
  photo_category_ids: [photo_c1.id, photo_c2.id, photo_c3.id, photo_c4.id],
  photo_location_ids: [photo_l1.id, photo_l2.id, photo_l3.id, photo_l4.id],
  in_image: Fs::UploadedFile.create_from_file("ss_files/key_visual/keyvisual02.jpg")

photo_page_3 = save_page route: "member/photo", filename: "kanko-info/photo/page3.html", name: "観光地3",
  member_id: @member_1.id,
  layout_id: layouts["kanko-info"].id,
  map_points: [ { loc: [33.839396, 134.450684] } ],
  listable_state: "public",
  slideable_state: "public",
  license_name: "not_free",
  photo_category_ids: [photo_c2.id, photo_c3.id],
  photo_location_ids: [photo_l2.id, photo_l3.id],
  in_image: Fs::UploadedFile.create_from_file("ss_files/key_visual/keyvisual03.jpg")

photo_page_4 = save_page route: "member/photo", filename: "kanko-info/photo/page4.html", name: "観光地4",
  member_id: @member_1.id,
  layout_id: layouts["kanko-info"].id,
  map_points: [ { loc: [33.946095, 134.088135] } ],
  listable_state: "public",
  slideable_state: "public",
  license_name: "not_free",
  photo_category_ids: [photo_c1.id, photo_c2.id, photo_c4.id],
  photo_location_ids: [photo_l1.id, photo_l4.id],
  in_image: Fs::UploadedFile.create_from_file("ss_files/key_visual/keyvisual04.jpg")

photo_page_5 = save_page route: "member/photo", filename: "kanko-info/photo/page5.html", name: "観光地5",
  member_id: @member_1.id,
  layout_id: layouts["kanko-info"].id,
  map_points: [ { loc: [33.793757, 134.538575] } ],
  listable_state: "public",
  slideable_state: "hide",
  license_name: "not_free",
  photo_category_ids: [photo_c1.id, photo_c2.id, photo_c4.id],
  photo_location_ids: [photo_l3.id, photo_l4.id],
  in_image: Fs::UploadedFile.create_from_file("ss_files/key_visual/keyvisual05.jpg")

save_page route: "member/photo_spot", filename: "kanko-info/photo/spot/index.html", name: "スポット",
  layout_id: layouts["kanko-info"].id,
  member_photo_ids: [photo_page_1.id, photo_page_2.id, photo_page_3.id]

puts "# key visual"
keyvisual1 = save_ss_files "ss_files/key_visual/keyvisual01.jpg", filename: "keyvisual01.jpg", model: "key_visual/image"
keyvisual2 = save_ss_files "ss_files/key_visual/keyvisual02.jpg", filename: "keyvisual02.jpg", model: "key_visual/image"
keyvisual3 = save_ss_files "ss_files/key_visual/keyvisual03.jpg", filename: "keyvisual03.jpg", model: "key_visual/image"
keyvisual4 = save_ss_files "ss_files/key_visual/keyvisual04.jpg", filename: "keyvisual04.jpg", model: "key_visual/image"
keyvisual5 = save_ss_files "ss_files/key_visual/keyvisual05.jpg", filename: "keyvisual05.jpg", model: "key_visual/image"
keyvisual1.set(state: "public")
keyvisual2.set(state: "public")
keyvisual3.set(state: "public")
keyvisual4.set(state: "public")
keyvisual5.set(state: "public")
save_page route: "key_visual/image", filename: "key_visual/page37.html", name: "キービジュアル1", order: 10, file_id: keyvisual1.id
save_page route: "key_visual/image", filename: "key_visual/page38.html", name: "キービジュアル2", order: 20, file_id: keyvisual2.id
save_page route: "key_visual/image", filename: "key_visual/page39.html", name: "キービジュアル3", order: 30, file_id: keyvisual3.id
save_page route: "key_visual/image", filename: "key_visual/page40.html", name: "キービジュアル4", order: 40, file_id: keyvisual4.id
save_page route: "key_visual/image", filename: "key_visual/page50.html", name: "キービジュアル5", order: 50, file_id: keyvisual5.id

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

## -------------------------------------
def save_theme_template(data)
  puts data[:class_name]
  cond = { site_id: data[:site_id], name: data[:class_name] }

  item = Cms::ThemeTemplate.find_or_create_by(cond)
  item.attributes = data
  item.update

  item
end

puts "# theme templates"
save_theme_template class_name: "white", name: "白", order: 0, state: "public", site_id: @site.id,
  high_contrast_mode: "disabled"
save_theme_template class_name: "blue", name: "青", order: 10, state: "public", site_id: @site.id,
  high_contrast_mode: "enabled", font_color: '#FFFFFF', background_color: '#0066CC'
save_theme_template class_name: "black", name: "黒", order: 20, state: "public", site_id: @site.id,
  high_contrast_mode: "disabled", css_path: "/css/black.css"

puts "# board"
def save_board_post(data)
  puts data[:name]
  cond = { site_id: data[:site_id], node_id: data[:node_id], name: data[:name], poster: data[:poster] }
  item = Board::Post.where(cond).first || Board::Post.new
  item.attributes = data
  item.save

  item
end

node = save_node route: "board/post", filename: "board", name: "災害掲示板", layout_id: layouts["one"].id,
  mode: "tree", file_limit: 1, text_size_limit: 400, captcha: "enabled", deletable_post: "enabled",
  deny_url: "deny", file_size_limit: (1024 * 1024 * 2), file_scan: "disabled", show_email: "enabled", show_url: "enabled"
topic1 = save_board_post name: "テスト投稿", text: "テスト投稿です。", site_id: @site.id, node_id: node.id,
  poster: "白鷺　太郎", delete_key: 1234
comment1 = save_board_post name: "Re:テスト投稿", text: "返信します。", site_id: @site.id, node_id: node.id,
  poster: "鷺　智子", delete_key: 1234, parent_id: topic1.id, topic_id: topic1.id
comment2 = save_board_post name: "Re:テスト投稿", text: "返信します。", site_id: @site.id, node_id: node.id,
  poster: "黒鷺　次郎", delete_key: 1234, parent_id: topic1.id, topic_id: topic1.id
topic2 = save_board_post name: "タイトル", text: "投稿します。", site_id: @site.id, node_id: node.id,
  poster: "白鷺　太郎", delete_key: 1234

save_node route: "board/anpi_post", filename: "anpi", name: "安否掲示板", layout_id: layouts["one"].id

user = Cms::User.first
if user
  file = save_ss_files "ss_files/article/pdf_file.pdf", filename: "file.pdf", model: "board/post", site_id: @site.id
  file.set(state: "public")
  topic3 = save_board_post name: "管理画面から", text: "管理画面からの投稿です。", site_id: @site.id, node_id: node.id,
    user_id: user.id, poster: "管理者", delete_key: 1234, poster_url: " http://demo.ss-proj.org/", file_ids: [file.id]
end

puts "# anpi"

def save_board_anpi_post(data)
  puts data[:name]
  cond = { site_id: @site._id, member_id: data[:member_id] }
  item = Board::AnpiPost.find_or_create_by(cond)
  item.attributes = data
  item.save

  item
end

save_board_anpi_post member_id: @member_1.id, name: @member_1.name, kana: @member_1.kana, tel: @member_1.tel,
  addr: @member_1.addr, sex: @member_1.sex, age: @member_1.age, email: @member_1.email,
  text: "立川の避難所に花子と一緒に居ます。\r\n私も花子も無事です。", public_scope: "public",
  point: { "loc"=>[35.712948784, 139.399852752], "zoom_level"=>11 }
save_board_anpi_post member_id: @member_2.id, name: @member_2.name, kana: @member_2.kana, tel: @member_2.tel,
  addr: @member_2.addr, sex: @member_2.sex, age: @member_2.age, email: @member_2.email,
  text: "主人と一緒に必死で立川の避難所まで避難してきました。", public_scope: "public",
  point: { "loc"=>[35.713576996, 139.407887933], "zoom_level"=>11 }

puts "# body_layouts"
def save_body_layouts(data)
  puts data[:name]
  cond = { site_id: data[:site_id], node_id: data[:node_id], name: data[:name], poster: data[:poster] }
  item = Cms::BodyLayout.where(cond).first || Cms::BodyLayout.new
  item.attributes = data
  item.save

  item
end
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

## -------------------------------------
puts "# weather xml"

def save_rss_weather_xml_region(data)
  # puts data[:name]
  cond = { site_id: @site._id, code: data[:code], name: data[:name] }
  item = Rss::WeatherXmlRegion.find_or_create_by(cond)
  item.attributes = data
  item.save

  item
end

CSV.table("weather_xml_regions/regions.csv").each do |row|
  save_rss_weather_xml_region code: row[:code].to_s, name: row[:name], order: row[:code].to_i
end

save_node route: "rss/weather_xml", filename: "weather", name: "気象庁防災XML", layout_id: layouts["one"].id,
  page_state: "closed", earthquake_intensity: "5+", anpi_mail_id: ezine_anpi.id, my_anpi_post_id: anpi_node.id,
  target_region_ids: %w(350 351 352).map { |code| Rss::WeatherXmlRegion.site(@site).find_by(code: code).id }

## -------------------------------------
puts "# max file size"

def save_max_file_size(data)
  # 100 MiB
  data = {size: 100 * 1_024 * 1_024}.merge(data)

  puts data[:name]
  cond = { name: data[:name] }

  item = SS::MaxFileSize.find_or_create_by cond
  puts item.errors.full_messages unless item.update data
  item
end

save_max_file_size name: '画像ファイル', extensions: %w(gif png jpg jpeg bmp), order: 1, state: 'enabled'
save_max_file_size name: '音声ファイル', extensions: %w(wav wma mp3 ogg), order: 2, state: 'enabled'
save_max_file_size name: '動画ファイル', extensions: %w(wmv avi mpeg mpg flv mp4), order: 3, state: 'enabled'
save_max_file_size name: 'Microsoft Office', extensions: %w(doc docx ppt pptx xls xlsx), order: 4, state: 'enabled'
save_max_file_size name: 'PDF', extensions: %w(pdf), order: 5, state: 'enabled'
save_max_file_size name: 'その他', extensions: %w(*), order: 9999, state: 'enabled'

## -------------------------------------
puts "# postal code"
Cms::PostalCode::OfficialCsvImportJob.import_from_zip("postal_code/13tokyo.zip")
