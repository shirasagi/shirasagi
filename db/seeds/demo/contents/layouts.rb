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

save_layout filename: "category-middle.layout.html", name: "カテゴリー：中間階層"
save_layout filename: "category-middle-shisei-gaiyo.layout.html", name: "カテゴリー中間層：市の概要"
save_layout filename: "category-top.layout.html", name: "カテゴリー：トップページ"
save_layout filename: "more.layout.html", name: "記事一覧"
save_layout filename: "oshirase.layout.html", name: "お知らせ"
save_layout filename: "pages.layout.html", name: "記事レイアウト"
save_layout filename: "top.layout.html", name: "トップレイアウト"
save_layout filename: "general.layout.html", name: "汎用レイアウト（1カラム）"
save_layout filename: "faq-top.layout.html", name: "FAQトップ"
save_layout filename: "faq.layout.html", name: "FAQ"
save_layout filename: "event.layout.html", name: "イベントページ"
save_layout filename: "event-top.layout.html", name: "イベントトップ"
save_layout filename: "event-search.layout.html", name: "イベント検索"
save_layout filename: "map.layout.html", name: "施設ガイド"
save_layout filename: "garbage.layout.html", name: "ゴミ品目検索"
save_layout filename: "ezine.layout.html", name: "メールマガジン"
save_layout filename: "urgency-layout/top-level1.layout.html", name: "緊急災害1：トップページ"
save_layout filename: "kanko-info.layout.html", name: "観光情報：下層ページ"
save_layout filename: "kanko-info-top.layout.html", name: "観光情報"
save_layout filename: "kanko-info-photo.layout.html", name: "写真データベース：検索"
save_layout filename: "login.layout.html", name: "ログイン"
save_layout filename: "kanko-info/blog/blog1.layout.html", name: "ブログレイアウト1"
save_layout filename: "kanko-info/blog/blog2.layout.html", name: "ブログレイアウト2"
save_layout filename: "mypage.layout.html", name: "マイページ"

array = Cms::Layout.where(site_id: @site._id).map { |m| [m.filename.sub(/\..*/, ""), m] }
@layouts = Hash[*array.flatten]
