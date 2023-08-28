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
save_inquiry_column node_id: @inquiry_node.id, name: "お名前", order: 0, input_type: "text_field",
  html: column_name_html, select_options: [], required: "required", site_id: @site._id
save_inquiry_column node_id: @inquiry_node.id, name: "企業・団体名", order: 10, input_type: "text_field",
  html: column_company_html, select_options: [], required: "optional", site_id: @site._id
save_inquiry_column node_id: @inquiry_node.id, name: "メールアドレス", order: 20, input_type: "email_field",
  html: column_email_html, select_options: [], required: "required",
  input_confirm: "enabled", site_id: @site._id
save_inquiry_column node_id: @inquiry_node.id, name: "性別", order: 30, input_type: "radio_button",
  html: column_gender_html, select_options: %w(男性 女性), required: "required", site_id: @site._id
save_inquiry_column node_id: @inquiry_node.id, name: "年齢", order: 40, input_type: "select",
  html: column_age_html, select_options: %w(10代 20代 30代 40代 50代 60代 70代 80代),
  required: "required", site_id: @site._id
save_inquiry_column node_id: @inquiry_node.id, name: "お問い合わせ区分", order: 50, input_type: "check_box",
  html: column_category_html, select_options: %w(市政について ご意見・ご要望 申請について その他),
  required: "required", site_id: @site._id
save_inquiry_column node_id: @inquiry_node.id, name: "お問い合わせ内容", order: 60, input_type: "text_area",
  html: column_question_html, select_options: [], required: "required", site_id: @site._id
save_inquiry_column node_id: @inquiry_node.id, name: "添付ファイル", order: 70, input_type: "upload_file",
  select_options: [], required: "optional", site_id: @site._id

puts "# inquiry public comment"
save_inquiry_column node_id: @inquiry_comment1.id, name: "性別", order: 0, input_type: "radio_button",
  html: column_gender_html, select_options: %w(男性 女性), required: "required", site_id: @site._id
save_inquiry_column node_id: @inquiry_comment1.id, name: "年齢", order: 10, input_type: "select",
  html: column_age_html, select_options: %w(10代 20代 30代 40代 50代 60代 70代 80代),
  required: "required", site_id: @site._id
save_inquiry_column node_id: @inquiry_comment1.id, name: "意見", order: 20, input_type: "text_area",
  html: "<p>ご意見を入力してください。</p>", select_options: [], required: "required", site_id: @site._id

column_gender = save_inquiry_column node_id: @inquiry_comment2.id, name: "性別", order: 0, input_type: "radio_button",
  html: column_gender_html, select_options: %w(男性 女性), required: "required", site_id: @site._id
column_age = save_inquiry_column node_id: @inquiry_comment2.id, name: "年齢", order: 10, input_type: "select",
  html: column_age_html, select_options: %w(10代 20代 30代 40代 50代 60代 70代 80代), required: "required",
  site_id: @site._id
column_opinion = save_inquiry_column node_id: @inquiry_comment2.id, name: "意見", order: 20, input_type: "text_area",
  html: "<p>ご意見を入力してください。</p>", select_options: [], required: "required", site_id: @site._id

save_inquiry_answer node_id: @inquiry_comment2.id, site_id: @site._id,
  remote_addr: "192.0.2.0", user_agent: "dummy connection (input by seed demo)",
  data: {
    column_gender.id => "女性",
    column_age.id => "10代",
    column_opinion.id => "意見があります。"
  }
save_inquiry_answer node_id: @inquiry_comment2.id, site_id: @site._id,
  remote_addr: "192.0.2.0", user_agent: "dummy connection (input by seed demo)",
  data: {
    column_gender.id => "女性",
    column_age.id => "80代",
    column_opinion.id => "意見があります。"
  }
save_inquiry_answer node_id: @inquiry_comment2.id, site_id: @site._id,
  remote_addr: "192.0.2.0", user_agent: "dummy connection (input by seed demo)",
  data: {
    column_gender.id => "男性",
    column_age.id => "50代",
    column_opinion.id => "意見があります。"
  }
save_inquiry_answer node_id: @inquiry_comment2.id, site_id: @site._id,
  remote_addr: "192.0.2.0", user_agent: "dummy connection (input by seed demo)",
  data: {
    column_gender.id => "男性",
    column_age.id => "10代",
    column_opinion.id => "意見があります。"
  }

puts "# feedback"

column_feedback1 = save_inquiry_column node_id: @feedback_node.id, name: "このページの内容は役に立ちましたか？",
  order: 10, input_type: "radio_button",
  select_options: %w(役に立った どちらともいえない 役に立たなかった),
  required: "required", site_id: @site._id
column_feedback2 = save_inquiry_column node_id: @feedback_node.id, name: "このページの内容は分かりやすかったですか？",
  order: 20, input_type: "radio_button",
  select_options: %w(分かりやすかった どちらともいえない 分かりにくかった),
  required: "required", site_id: @site._id
column_feedback3 = save_inquiry_column node_id: @feedback_node.id, name: "このページの情報は見つけやすかったですか？",
  order: 30, input_type: "radio_button",
  select_options: %w(見つけやすかった どちらともいえない 見つけにくかった),
  required: "required", site_id: @site._id

save_inquiry_answer node_id: @feedback_node.id, site_id: @site._id,
  remote_addr: "192.0.2.0", user_agent: "dummy connection (input by seed demo)",
  data: {
    column_feedback1.id => "役に立った",
    column_feedback2.id => "分かりやすかった",
    column_feedback3.id => "見つけやすかった"
  }
save_inquiry_answer node_id: @feedback_node.id, site_id: @site._id,
  remote_addr: "192.0.2.0", user_agent: "dummy connection (input by seed demo)",
  data: {
    column_feedback1.id => "どちらともいえない",
    column_feedback2.id => "分かりやすかった",
    column_feedback3.id => "どちらともいえない"
  }

## member
save_node route: "member/login", filename: "login", name: "ログイン", layout_id: @layouts["login"].id,
  form_auth: "enabled", redirect_url: "/mypage/"
save_node route: "member/registration", filename: "registration", name: "会員登録", layout_id: @layouts["general"].id,
  sender_email: "info@example.jp", sender_name: "送信者名", kana_required: "required", postal_code_required: "required",
  addr_required: "required", sex_required: "required", birthday_required: "required"
save_node route: "member/mypage", filename: "mypage", name: "マイページ", layout_id: @layouts["mypage"].id
save_node route: "member/my_profile", filename: "mypage/profile", name: "プロフィール", layout_id: @layouts["mypage"].id, order: 10,
  kana_required: "required", postal_code_required: "required", addr_required: "required", sex_required: "required",
  birthday_required: "required"
save_node route: "member/my_blog", filename: "mypage/blog", name: "ブログ", layout_id: @layouts["mypage"].id, order: 20
save_node route: "member/my_photo", filename: "mypage/photo", name: "フォト", layout_id: @layouts["mypage"].id, order: 30
save_node route: "member/my_group", filename: "mypage/group", name: "グループ", layout_id: @layouts["mypage"].id, order: 50,
  sender_name: "シラサギサンプルサイト", sender_email: "admin@example.jp"

## member blog
save_node route: "cms/node", filename: "kanko-info", name: "観光情報", layout_id: @layouts["kanko-info-top"].id,
  sort: 'order', loop_format: 'liquid'
save_node route: "member/blog", filename: "kanko-info/blog", name: "ブログ",
  layout_id: @layouts["kanko-info"].id, order: 20, page_limit: 4

save_node route: "cms/node", filename: "kanko-info/blog/area", name: "地域", layout_id: @layouts["kanko-info"].id
@blog_l1 = save_node route: "member/blog_page_location", filename: "kanko-info/blog/area/east",
  name: "東区", layout_id: @layouts["kanko-info"].id, order: 10
@blog_l2 = save_node route: "member/blog_page_location", filename: "kanko-info/blog/area/west",
  name: "西区", layout_id: @layouts["kanko-info"].id, order: 20
@blog_l3 = save_node route: "member/blog_page_location", filename: "kanko-info/blog/area/south",
  name: "南区", layout_id: @layouts["kanko-info"].id, order: 30
@blog_l4 = save_node route: "member/blog_page_location", filename: "kanko-info/blog/area/north",
  name: "北区", layout_id: @layouts["kanko-info"].id, order: 40
blog_thumb = Fs::UploadedFile.create_from_file("files/img/logo.png")

save_node route: "member/blog_page", filename: "kanko-info/blog/shirasagi", name: "白鷺太郎のブログ",
  layout_id: @layouts["kanko-info/blog/blog1"].id, member_id: @member_1.id, description: "白鷺太郎のブログです。よろしくお願いしいます。",
  genres: %w(ジャンル1 ジャンル2 ジャンル3), blog_page_location_ids: [@blog_l1.id], in_image: blog_thumb
save_node route: "member/blog_page", filename: "kanko-info/blog/newblog", name: "はじめてのブログ",
  layout_id: @layouts["kanko-info/blog/blog1"].id, member_id: @member_2.id, description: "はじめてのブログです。",
  genres: %w(自治体ブログ), in_image: blog_thumb

## member photo
save_node route: "member/photo", filename: "kanko-info/photo", name: "写真データベース",
  layout_id: @layouts["kanko-info"].id, order: 10,
  license_free: "<h2>ライセンスについて</h2><p>どなたでも自由にご利用いただけます。<br />肖像権については、使用者の判断によるものとし、当サイトは関与しません。</p>",
  license_not_free: "<h2>ライセンスについて</h2><p>画像のご利用には画像投稿者からの利用許可が必要です。</p>",
  limit: 40,
  page_layout_id: @layouts["kanko-info"].id

save_node route: "cms/node", filename: "kanko-info/photo/area", name: "地域", layout_id: @layouts["kanko-info"].id
@photo_l1 = save_node route: "member/photo_location", filename: "kanko-info/photo/area/east",
  name: "東区", layout_id: @layouts["kanko-info"].id, order: 10
@photo_l2 = save_node route: "member/photo_location", filename: "kanko-info/photo/area/west",
  name: "西区", layout_id: @layouts["kanko-info"].id, order: 20
@photo_l3 = save_node route: "member/photo_location", filename: "kanko-info/photo/area/south",
  name: "南区", layout_id: @layouts["kanko-info"].id, order: 30
@photo_l4 = save_node route: "member/photo_location", filename: "kanko-info/photo/area/north",
  name: "北区", layout_id: @layouts["kanko-info"].id, order: 40

save_node route: "cms/node", filename: "kanko-info/photo/category", name: "カテゴリー", layout_id: @layouts["kanko-info"].id
@photo_c1 = save_node route: "member/photo_category", filename: "kanko-info/photo/category/institution",
  name: "施設", layout_id: @layouts["kanko-info"].id, order: 10
@photo_c2 = save_node route: "member/photo_category", filename: "kanko-info/photo/category/nature",
  name: "自然", layout_id: @layouts["kanko-info"].id, order: 20
@photo_c3 = save_node route: "member/photo_category", filename: "kanko-info/photo/category/souvenir",
  name: "物産", layout_id: @layouts["kanko-info"].id, order: 30
@photo_c4 = save_node route: "member/photo_category", filename: "kanko-info/photo/category/other",
  name: "その他", layout_id: @layouts["kanko-info"].id, order: 40

save_node route: "member/photo_search", filename: "kanko-info/photo/search", name: "検索結果", layout_id: @layouts["kanko-info"].id
save_node route: "member/photo_spot", filename: "kanko-info/photo/spot", name: "おすすめスポット", layout_id: @layouts["kanko-info"].id

## layout
Cms::Node.where(site_id: @site._id, route: /^article\//).update_all(layout_id: @layouts["more"].id)
Cms::Node.where(site_id: @site._id, route: /^article\//, filename: "hinanjo").
  update_all(layout_id: @layouts["general"].id)
Cms::Node.where(site_id: @site._id, route: /^event\//, filename: "calendar").
  update_all(layout_id: @layouts["event-top"].id)
Cms::Node.where(site_id: @site._id, route: /^event\//, filename: "calendar/search").
  update_all(layout_id: @layouts["event-search"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "oshirase").
  update_all(layout_id: @layouts["more"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "kanko").
  update_all(layout_id: @layouts["category-top"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "kenko").
  update_all(layout_id: @layouts["category-top"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "kosodate").
  update_all(layout_id: @layouts["category-top"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "kurashi").
  update_all(layout_id: @layouts["category-top"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "guide").
  update_all(layout_id: @layouts["category-middle"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "sangyo").
  update_all(layout_id: @layouts["category-top"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "shisei").
  update_all(layout_id: @layouts["category-top"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "attention").
  update_all(layout_id: @layouts["more"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: /\//).
  update_all(layout_id: @layouts["category-middle"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: /^guide\//).
  update_all(layout_id: @layouts["more"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: /^hinanjo\//).
  update_all(layout_id: @layouts["more"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: /^oshirase\//).
  update_all(layout_id: @layouts["more"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "urgency").
  update_all(layout_id: @layouts["more"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "shisei/gaiyo").
  update_all(layout_id: @layouts["category-middle-shisei-gaiyo"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "kohoshi/kakopdf").
  update_all(layout_id: @layouts["more"].id)
Cms::Node.where(site_id: @site._id, route: /^category\//, filename: "kohoshi/kongetsukoho").
  update_all(layout_id: @layouts["pages"].id)
Cms::Node.where(site_id: @site._id, route: /^inquiry\//).
  update_all(layout_id: @layouts["general"].id)
Cms::Node.where(site_id: @site._id, filename: /^sitemap$/).
  update_all(layout_id: @layouts["general"].id)
Cms::Node.where(site_id: @site._id, filename: /^faq$/).
  update_all(layout_id: @layouts["faq-top"].id)
Cms::Node.where(site_id: @site._id, filename: /^ad$/).
  update_all(layout_id: @layouts["general"].id)
Cms::Node.where(site_id: @site._id, filename: /faq\//).
  update_all(layout_id: @layouts["faq"].id)
Cms::Node.where(site_id: @site._id, route: /facility\//).
  update_all(layout_id: @layouts["map"].id)
Cms::Node.where(site_id: @site._id, route: /ezine\//).
  update_all(layout_id: @layouts["ezine"].id)
