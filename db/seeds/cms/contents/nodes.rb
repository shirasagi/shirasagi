puts "# nodes"

def save_node(data)
  return if SS.config.cms.enable_lgwan && data[:route].start_with?('member/')
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename], route: data[:route] }

  upper_html ||= File.read("nodes/" + data[:filename] + ".upper_html") rescue nil
  loop_html ||= File.read("nodes/" + data[:filename] + ".loop_html") rescue nil
  lower_html ||= File.read("nodes/" + data[:filename] + ".lower_html") rescue nil
  summary_html ||= File.read("nodes/" + data[:filename] + ".summary_html") rescue nil

  item = data[:route].sub("/", "/node/").camelize.constantize.unscoped.find_or_initialize_by(cond)
  item.upper_html = upper_html if upper_html
  item.loop_html = loop_html if loop_html
  item.lower_html = lower_html if lower_html
  item.summary_html = summary_html if summary_html

  item.attributes = data
  item.cur_site ||= @site
  item.cur_user ||= @user
  item.save
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
save_node route: "category/page", filename: "oshirase/event", name: "イベント",
          conditions: %w(docs calendar), sort: "unfinished_event_dates", limit: 20
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
save_node route: "category/node", filename: "shisei/soshiki/kikikanri", name: "危機管理部", order: 50
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
save_node route: "event/search", filename: "calendar/search", name: "イベント検索", conditions: %w(calendar)

array = Category::Node::Base.where(site_id: @site._id).map { |m| [m.filename, m] }
@categories = Hash[*array.flatten]

## node
save_node route: "cms/node", filename: "use", name: "ご利用案内"

## article
save_node route: "article/page", filename: "docs", name: "記事", shortcut: "show",
          st_form_ids: [@form.id, @form_2.id, @form_3.id, @form_4.id, @form_5.id], st_form_default_id: @form_4.id

## archive
save_node route: "cms/archive", filename: "docs/archive", name: "アーカイブ", layout_id: @layouts["pages"].id, conditions: %w(docs)

## photo album
save_node route: "cms/photo_album", filename: "docs/photo", name: "写真一覧", layout_id: @layouts["pages"].id, conditions: %w(docs)

## site search
save_node route: "cms/site_search", filename: "search", name: "サイト内検索", layout_id: @layouts["one"].id

## sitemap
save_node route: "sitemap/page", filename: "sitemap", name: "サイトマップ"

## event
save_node route: "event/page", filename: "calendar", name: "イベントカレンダー", conditions: %w(docs), event_display: "table",
          st_category_ids: %w(calendar/bunka calendar/kohen calendar/sports).map { |c| @categories[c].id }

## uploader
save_node route: "uploader/file", filename: "css", name: "CSS", shortcut: "show"
save_node route: "uploader/file", filename: "img", name: "画像", shortcut: "show"
save_node route: "uploader/file", filename: "js", name: "javascript", shortcut: "show"

## faq
save_node route: "faq/page", filename: "faq/docs", name: "よくある質問記事", st_category_ids: [@categories["faq"].id]
save_node route: "faq/search", filename: "faq/faq-search", name: "よくある質問検索", st_category_ids: [@categories["faq"].id]

## ads
save_node route: "ads/banner", filename: "ad", name: "広告バナー", shortcut: "show"

## group page
@g_koho = SS::Group.where(name: "シラサギ市/企画政策部/広報課").first
@g_seisaku = SS::Group.where(name: "シラサギ市/企画政策部/政策課").first
save_node route: "cms/group_page", filename: "shisei/soshiki/kikaku/koho", name: "広報課", order: 10, conditions: %w(docs),
          layout_id: @layouts["category-middle"].id, condition_group_ids: [@g_koho.id]
save_node route: "cms/group_page", filename: "shisei/soshiki/kikaku/seisaku", name: "政策課", order: 20, conditions: %w(docs),
          layout_id: @layouts["category-middle"].id, condition_group_ids: [@g_seisaku.id]

## urgency
save_node route: "urgency/layout", filename: "urgency-layout", name: "緊急災害レイアウト",
          urgency_default_layout_id: @layouts["top"].id, shortcut: "show"

## inquiry
inquiry_html = File.read("nodes/inquiry.inquiry_html") rescue nil
inquiry_sent_html = File.read("nodes/inquiry.inquiry_sent_html") rescue nil
@inquiry_node = save_node route: "inquiry/form", filename: "inquiry", name: "市へのお問い合わせ", shortcut: "show",
                          from_name: "シラサギサンプルサイト",
                          inquiry_captcha: "enabled", notice_state: "disabled",
                          inquiry_html: inquiry_html, inquiry_sent_html: inquiry_sent_html,
                          reply_state: "disabled",
                          reply_subject: "シラサギ市へのお問い合わせを受け付けました。",
                          reply_upper_text: "",
                          reply_content_state: "static",
                          reply_lower_text: "",
                          aggregation_state: "disabled"

## feedback
feedback_html = File.read("nodes/feedback.inquiry_html") rescue nil
feedback_sent_html = File.read("nodes/feedback.inquiry_sent_html") rescue nil
@feedback_node = save_node route: "inquiry/form", filename: "feedback", name: "この情報はお役に立ちましたか？",
                           inquiry_captcha: "disabled", notice_state: "disabled",
                           inquiry_html: feedback_html, inquiry_sent_html: feedback_sent_html,
                           reply_state: "disabled",
                           aggregation_state: "disabled"

## public comment
save_node route: "inquiry/node", filename: "comment", name: "パブリックコメント",
          upper_html: "パブリックコメント一覧です。"
@inquiry_comment1 = save_node route: "inquiry/form", filename: "comment/comment01", name: "シラサギ市政について",
                              from_name: "シラサギサンプルサイト",
                              inquiry_captcha: "enabled", notice_state: "disabled",
                              inquiry_html: inquiry_html,
                              inquiry_sent_html: "<p>パブリックコメントを受け付けました。</p>",
                              reply_state: "disabled",
                              reply_subject: "シラサギ市へのお問い合わせを受け付けました。",
                              reply_upper_text: "",
                              reply_content_state: "static",
                              reply_lower_text: "",
                              aggregation_state: "enabled",
                              reception_start_date: Time.zone.now.beginning_of_month,
                              reception_close_date: Time.zone.now.end_of_month
@inquiry_comment2 = save_node route: "inquiry/form", filename: "comment/comment02", name: "シラサギ市都市計画について",
                              from_name: "シラサギサンプルサイト",
                              inquiry_captcha: "enabled", notice_state: "disabled",
                              inquiry_html: inquiry_html,
                              inquiry_sent_html: "<p>パブリックコメントを受け付けました。</p>",
                              reply_state: "disabled",
                              reply_subject: "シラサギ市へのお問い合わせを受け付けました。",
                              reply_upper_text: "",
                              reply_content_state: "static",
                              reply_lower_text: "",
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
save_node route: "ezine/category_node", filename: "anpi-ezine", name: "安否メールマガジン", layout_id: @layouts["ezine"].id
@ezine_anpi = save_node route: "ezine/member_page", filename: "anpi-ezine/anpi", name: "安否確認",
                        layout_id: @layouts["ezine"].id,
                        sender_name: "シラサギサンプルサイト", sender_email: "admin@example.jp",
                        signature_html: ezine_signature_html, signature_text: ezine_signature_text,
                        subscription_constraint: "required"
ezine_event = save_node route: "ezine/member_page", filename: "anpi-ezine/event", name: "イベント情報",
                        layout_id: @layouts["ezine"].id,
                        sender_name: "シラサギサンプルサイト", sender_email: "admin@example.jp",
                        signature_html: ezine_signature_html, signature_text: ezine_signature_text
@member_1.subscription_ids = [@ezine_anpi.id, ezine_event.id]
@member_1.save
@member_2.subscription_ids = [@ezine_anpi.id, ezine_event.id]
@member_2.save

## facility
save_node route: "cms/node", filename: "institution/chiki", name: "施設のある地域", layout_id: @layouts["one"].id
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
save_node route: "cms/node", filename: "institution/shurui", name: "施設の種類", layout_id: @layouts["one"].id
save_node route: "facility/category", filename: "institution/shurui/bunka", name: "文化施設", order: 10
save_node route: "facility/category", filename: "institution/shurui/sports", name: "運動施設", order: 20
save_node route: "facility/category", filename: "institution/shurui/school", name: "小学校", order: 30
save_node route: "facility/category", filename: "institution/shurui/kokyo", name: "公園・公共施設", order: 40

save_node route: "cms/node", filename: "institution/yoto", name: "施設の用途", layout_id: @layouts["one"].id
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
          st_category_ids: facility_categories.values.map { |cate| cate.id },
          st_location_ids: facility_locations.values.map { |loc| loc.id },
          st_service_ids: facility_services.values.map { |serv| serv.id }

save_node route: "facility/node", filename: "institution/shisetsu", name: "施設一覧",
          st_category_ids: facility_categories.values.map { |cate| cate.id },
          st_location_ids: facility_locations.values.map { |loc| loc.id },
          st_service_ids: facility_services.values.map { |serv| serv.id }

save_node route: "facility/page", filename: "institution/shisetsu/library", name: "シラサギ市立図書館",
          kana: "しらさぎとしょかん",
          address: "大鷺県シラサギ市小鷺町1丁目1番地1号",
          tel: "00-0000-0000",
          fax: "00-0000-0000",
          related_url: @link_url,
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
