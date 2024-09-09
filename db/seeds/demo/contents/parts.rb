puts "# parts"

def save_part(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }

  item = data[:route].sub("/", "/part/").camelize.constantize.unscoped.find_or_initialize_by(cond)
  %w(html upper_html loop_html lower_html substitute_html loop_liquid summary_html).each do |field|
    item.try(:"#{field}=", File.read("parts/" + data[:filename].sub(/\.html$/, ".#{field}"))) rescue nil
  end
  item.attributes = data
  item.cur_user = @user
  item.save
  item.add_to_set group_ids: @site.group_ids

  item
end

save_part route: "cms/free", filename: "about.part.html", name: "シラサギ市について"
save_part route: "cms/free", filename: "foot.part.html", name: "フッター"
save_part route: "cms/free", filename: "guide.part.html", name: "くらしのガイド"
save_part route: "cms/free", filename: "head.part.html", name: "ヘッダー"
save_part route: "cms/free", filename: "links-life.part.html", name: "関連リンク：くらし・手続き"
save_part route: "cms/free", filename: "links-garbage.part.html", name: "関連リンク：ゴミ品目"
save_part route: "cms/node", filename: "navi.part.html", name: "グローバルナビ", sort: "order -1", loop_format: 'liquid'
save_part route: "cms/free", filename: "online.part.html", name: "オンラインサービス"
save_part route: "cms/free", filename: "connect.part.html", name: "関連サイト", mobile_view: "hide"
save_part route: "cms/free", filename: "propose.part.html", name: "ご意見・ご提案"
save_part route: "cms/free", filename: "ranking.part.html", name: "アクセスランキング", mobile_view: "hide"
save_part route: "cms/free", filename: "relations.part.html", name: "広報"
save_part route: "cms/free", filename: "safety.part.html", name: "安心安全情報"
save_part route: "cms/free", filename: "tool.part.html", name: "アクセシビリティーツール", mobile_view: "hide"
save_part route: "cms/free", filename: "useful.part.html", name: "お役立ち情報"
save_part route: "cms/free", filename: "ezine-side.part.html", name: "サイドメニュー：メールマガジン"
save_part route: "article/page", filename: "attention/recent.part.html", name: "注目情報", limit: 5
save_part route: "article/page", filename: "docs/recent.part.html", name: "新着情報"
save_part route: "article/page", filename: "oshirase/kanko/recent.part.html", name: "お知らせ", limit: 5
save_part route: "article/page", filename: "oshirase/kenko/recent.part.html", name: "お知らせ", limit: 5
save_part route: "article/page", filename: "oshirase/kosodate/recent.part.html", name: "お知らせ", limit: 5
save_part route: "article/page", filename: "oshirase/kurashi/recent.part.html", name: "お知らせ", limit: 5
save_part route: "article/page", filename: "oshirase/recent.part.html", name: "お知らせ", limit: 5
save_part route: "article/page", filename: "oshirase/sangyo/recent.part.html", name: "お知らせ", limit: 5
save_part route: "article/page", filename: "oshirase/shisei/recent.part.html", name: "お知らせ", limit: 5
save_part route: "cms/crumb", filename: "breadcrumb.part.html", name: "パンくず", mobile_view: "hide"
save_part route: "category/node", filename: "category-list.part.html", name: "カテゴリーリスト", sort: "order"
save_part route: "cms/tabs", filename: "recent-tabs.part.html", name: "新着タブ",
  conditions: %w(shinchaku oshirase oshirase/event shisei/jinji), limit: 6
save_part route: "cms/free", filename: "urgency-layout/announce.part.html", name: "緊急アナウンス"
save_part route: "cms/free", filename: "urgency-layout/calamity.part.html", name: "災害関係ホームページ"
save_part route: "cms/free", filename: "urgency-layout/connect.part.html", name: "関連サイト"
save_part route: "cms/free", filename: "urgency-layout/head.part.html", name: "ヘッダー"
save_part route: "cms/free", filename: "urgency-layout/mode.part.html", name: "緊急災害表示"
save_part route: "cms/free", filename: "urgency-layout/navi.part.html", name: "グローバルナビ"
save_part route: "article/page", filename: "urgency/recent.part.html", name: "緊急情報"
save_part route: "category/node", filename: "faq/category-list.part.html", name: "カテゴリーリスト", sort: "order",
  loop_format: 'liquid'
save_part route: "faq/search", filename: "faq/faq-search/search.part.html", name: "FAQ記事検索"
save_part route: "event/calendar", filename: "calendar/calendar.part.html", name: "カレンダー", ajax_view: "enabled"
save_part route: "event/search", filename: "calendar/search/search.part.html", name: "イベント検索"
save_part route: "ads/banner", filename: "ad/ad.part.html", name: "広告バナー", mobile_view: "hide", with_category: "enabled"
save_part route: "cms/sns_share", filename: "sns.part.html", name: "SNSシェアボタン", mobile_view: "hide",
  sns_share_orders: { fb_share: "20", twitter: "10", hatena: "30", line: "40" }
save_part route: "key_visual/swiper_slide", filename: "key-visual/slide.part.html", name: "スライドショー",
  mobile_view: "hide", kv_autoplay: "enabled", kv_navigation: "hide", kv_pagination_style: "disc", kv_thumbnail: "hide",
  kv_thumbnail_count: 5
save_part route: "inquiry/feedback", filename: "feedback/feedback.part.html", name: "フィードバック", mobile_view: "hide",
  upper_html: '<section id="feedback"><h2>この情報は役に立ちましたか？</h2>',
  lower_html: '</section>'
save_part route: "member/photo", filename: "kanko-info/photo/recent.part.html", name: "新着写真一覧", mobile_view: "hide", limit: 4
save_part route: "key_visual/swiper_slide", filename: "kanko-info/photo/slide.part.html", name: "スライド",
  mobile_view: "hide", kv_autoplay: "enabled", kv_navigation: "hide", kv_pagination_style: "none", kv_thumbnail: "hide",
  kv_thumbnail_count: 3
save_part route: "member/photo_search", filename: "kanko-info/photo/search/search.part.html", name: "スライド", mobile_view: "hide"
save_part route: "member/blog_page", filename: "kanko-info/blog/recent.part.html", name: "新着ブログ",
  mobile_view: "hide"
save_part route: "member/login", filename: "login/login.part.html", name: "ログイン", mobile_view: "hide", ajax_view: "enabled"
save_part route: "member/invited_group", filename: "invited-group.part.html", name: "招待されたグループ",
  mobile_view: "hide", ajax_view: "enabled"
save_part route: "cms/calendar_nav", filename: "docs/archive/calendar.part.html", name: "カレンダー"
save_part route: "cms/monthly_nav", filename: "docs/archive/month.part.html", name: "月次", periods: 12
save_part route: "recommend/history", filename: "browsing-history.part.html", name: "閲覧履歴",
  mobile_view: "hide", ajax_view: "enabled", limit: 5
save_part route: "translate/tool", filename: "translate.part.html", name: "翻訳ツール", mobile_view: "hide", ajax_view: "enabled"
save_part route: "cms/site_search_history", filename: "search.part.html", name: "検索フォーム"
save_part route: "cms/clipboard_copy", filename: "copy.part.html", name: "URLをコピー"
save_part route: "category/node", filename: "deepest-catelist.part.html", name: "最下層カテゴリーリスト",
  loop_format: 'liquid'
save_part route: "cms/node2", filename: "folder.part.html", name: "フォルダーリスト", sort: 'updated',
  node_routes: %w(category/page category/node), list_origin: 'content'
save_part route: "cms/node", filename: "guide/catelist.part.html", name: "カテゴリーリスト", sort: 'order'
save_part route: "recommend/similarity", filename: "highly-relevant.part.html", name: "このページと関連性の高いページ",
  limit: 5
save_part route: "cms/site_search_keyword", filename: "keyword.part.html", name: "注目ワード",
  site_search_keywords: %w(マイナンバー 防災情報)
save_part route: "cms/page", filename: "kohoshi/kongetsukoho/recent.part.html", name: "トップ　最新　広報SHIRASAGI",
  new_days: 0, loop_format: 'liquid'
save_part route: "cms/page", filename: "kurashi/bosai/urgency-disaster-top-list.part.html", name: "緊急災害 - 防災情報一覧",
  new_days: 0, no_items_display_state: 'show'
save_part route: "image_map/page", filename: "map-clickable/clickable.part.html", name: "シラサギ市クリッカブルマップ"
save_part route: "cms/page", filename: "population/show-top.part.html", name: "トップページ表示 - 人口・世帯数", order: 'released',
  limit: 1, new_days: 0, loop_format: 'liquid'
save_part route: "cms/print", filename: "print.part.html", name: "ページを印刷する"
save_part route: "cms/tabs", filename: "recent-tabsside.part.html", name: "新着タブ：サイドメニュー用",
  conditions: %w(oshirase oshirase/event shisei/jinji), limit: 5, new_days: 0
save_part route: "cms/node2", filename: "sub-catelist.part.html", name: "サブカテゴリー一覧", sort: 'order',
  loop_format: 'liquid', node_routes: %w(category/page category/node), list_origin: 'content'
save_part route: "cms/node", filename: "sub-catelist-old.part.html", name: "サブカテゴリー一覧（旧）", sort: 'order',
  loop_format: 'liquid'
save_part route: "cms/page", filename: "topics/top-topics.part.html", name: "街の話題", order: 'released',
  limit: 2, new_days: 0
save_part route: "cms/page", filename: "urgency-disaster-top-list.part.html", name: "緊急災害 - 防災情報一覧",
  conditions: %w(
    kurashi/bosai/jyoho kurashi/bosai/kanri kurashi/bosai/keikaku kurashi/bosai/kunren kurashi/bosai/shinsai
    kurashi/bosai/shobo
  ), new_days: 0
save_part route: "chat/bot", filename: "bot.part.html", name: "チャットボット", chat_path: 'chatbot', mobile_view: "hide"
