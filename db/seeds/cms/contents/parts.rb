puts "# parts"

def save_part(data)
  return if SS.config.cms.enable_lgwan && data[:route].start_with?('member/')
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }

  html = File.read("parts/" + data[:filename]) rescue nil
  upper_html ||= File.read("parts/" + data[:filename].sub(/\.html$/, ".upper_html")) rescue nil
  loop_html ||= File.read("parts/" + data[:filename].sub(/\.html$/, ".loop_html")) rescue nil
  lower_html ||= File.read("parts/" + data[:filename].sub(/\.html$/, ".lower_html")) rescue nil

  item = data[:route].sub("/", "/part/").camelize.constantize.unscoped.find_or_initialize_by(cond)
  if html
    if SS.config.cms.enable_lgwan
      html.gsub!('<li class="sight"><a href="/kanko-info/">観光情報</a></li>', '')
      html.gsub!('<li><a href="/mypage/">安否確認</a></li>', '')
    end
    item.html = html
  end
  item.upper_html = upper_html if upper_html
  item.loop_html = loop_html if loop_html
  item.lower_html = lower_html if lower_html

  item.attributes = data
  item.cur_user = @user
  item.save
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
save_part route: "event/search", filename: "calendar/search/search.part.html", name: "イベント検索"
save_part route: "ads/banner", filename: "ad/ad.part.html", name: "広告バナー", mobile_view: "hide", with_category: "enabled"
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
save_part route: "member/invited_group", filename: "invited_group.part.html", name: "招待されたグループ",
          mobile_view: "hide", ajax_view: "enabled"
save_part route: "cms/calendar_nav", filename: "docs/archive/calendar.part.html", name: "カレンダー"
save_part route: "cms/monthly_nav", filename: "docs/archive/month.part.html", name: "月次", periods: 12
save_part route: "recommend/history", filename: "history.part.html", name: "閲覧履歴",
          mobile_view: "hide", ajax_view: "enabled", limit: 5
save_part route: "translate/tool", filename: "translate.part.html", name: "翻訳ツール", mobile_view: "hide", ajax_view: "enabled"
