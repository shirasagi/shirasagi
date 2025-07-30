puts "# articles"

def save_page(data)
  puts data[:name]
  cond = { site_id: @site._id, filename: data[:filename] }

  html ||= File.read("pages/" + data[:filename]) rescue nil
  summary_html ||= File.read("pages/" + data[:filename].sub(/\.html$/, "") + ".summary_html") rescue nil

  route = data[:route].presence || 'cms/page'
  item = route.camelize.constantize.find_or_initialize_by(cond)
  item.html = html if html
  item.summary_html = summary_html if summary_html

  if data[:contact_group_id].present?
    contact_group = Cms::Group.where(id: data[:contact_group_id]).first
    contact = contact_group.contact_groups.first
    data[:contact_group_contact_id] ||= contact.id
    data[:contact_group_name] ||= contact.contact_group_name
    data[:contact_charge] ||= contact.contact_charge
    data[:contact_tel] ||= contact.contact_tel
    data[:contact_fax] ||= contact.contact_fax
    data[:contact_email] ||= contact.contact_email
    data[:contact_postal_code] ||= contact.contact_postal_code
    data[:contact_address] ||= contact.contact_address
    data[:contact_link_url] ||= contact.contact_link_url
    data[:contact_link_name] ||= contact.contact_link_name
  end

  item.attributes = data
  item.cur_user = @user
  item.save
  item.add_to_set group_ids: @site.group_ids

  item
end

save_page route: "article/page", filename: "docs/page1.html", name: "インフルエンザによる学級閉鎖状況",
  layout_id: @layouts["pages"].id, keywords: %w(記事 保健・健康・医療 統計・人口),
  category_ids: [@categories["kenko/hoken"].id, @categories["shisei/toke"].id],
  contact_group_id: g("シラサギ市/総務部/市民課").id, contact_group_relation: "related",
  group_ids: [g("シラサギ市").id, g("シラサギ市/企画政策部/政策課").id], contact_sub_group_ids: g("シラサギ市/危機管理部/管理課")
save_page route: "article/page", filename: "docs/page2.html", name: "コンビニ納付のお知らせ",
  layout_id: @layouts["pages"].id, keywords: %w(記事 年金・保険 税金 企業の税金),
  category_ids: [
    @categories["kurashi/nenkin"].id, @categories["kurashi/zeikin"].id,
    @categories["sangyo/zeikin"].id
  ],
  contact_group_id: g("シラサギ市/総務部/財産管理課/管理・営繕係").id, contact_group_relation: "related",
  group_ids: [@g_seisaku.id],
  contact_sub_group_ids: [
    g("シラサギ市/企画政策部/政策課/デジタル戦略係").id, g("シラサギ市/総務部/財産管理課/電算管理係").id,
    g("シラサギ市/総務部/市民課/市民税係").id
  ]
save_page route: "article/page", filename: "docs/page3.html", name: "平成26年第1回シラサギ市議会定例会を開催します",
  layout_id: @layouts["pages"].id, category_ids: [@categories["attention"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id],
  contact_sub_group_ids: @contact_sub_group_ids1
save_page route: "article/page", filename: "docs/page4.html", name: "放射性物質・震災関連情報",
  layout_id: @layouts["pages"].id, keywords: %w(記事 注目情報 危機管理情報),
  category_ids: [@categories["attention"].id, @categories["kurashi/bosai/kanri"].id],
  contact_group_id: g("シラサギ市/危機管理部/管理課").id, contact_group_relation: "related",
  group_ids: [@g_seisaku.id],
  contact_sub_group_ids: [g("シラサギ市/危機管理部/防災課/生活安全係").id, g("シラサギ市/危機管理部/防災課/消防団係").id]
file_page5_1 = save_ss_files "files/img/dummy.png", filename: "dummy.png", name: "dummy.png", model: "ss/temp_file"
file_page5_2 = save_ss_files "files/img/dummy.png", filename: "dummy.png", name: "dummy.png", model: "ss/temp_file"
html_page5_1 = []
html_page5_1 << "<table>"
html_page5_1 << "  <caption>表の見出し</caption>"
html_page5_1 << "  <tbody>"
html_page5_1 << "    <tr></tr>"
html_page5_1 << "    <tr>"
html_page5_1 << "      <th scope=\"row\" class=\"\">項目名</th>"
html_page5_1 << "      <td class=\"\">項目内容</td>"
html_page5_1 << "      <td class=\"\">項目内容</td>"
html_page5_1 << "    </tr>"
html_page5_1 << "    <tr>"
html_page5_1 << "      <th scope=\"row\" class=\"\">項目名</th>"
html_page5_1 << "      <td class=\"\">項目内容</td>"
html_page5_1 << "      <td class=\"\">項目内容</td>"
html_page5_1 << "    </tr>"
html_page5_1 << "    <tr>"
html_page5_1 << "      <th scope=\"row\" class=\"\">項目名</th>"
html_page5_1 << "      <td class=\"\">項目内容</td>"
html_page5_1 << "      <td class=\"\">項目内容</td>"
html_page5_1 << "    </tr>"
html_page5_1 << "  </tbody>"
html_page5_1 << "</table>"
html_page5_1 = html_page5_1.join
save_page route: "article/page", filename: "docs/page5.html", name: "市内の微小粒子状物質（PM2.5）の測定データ（速報値）を公開しています。",
  layout_id: @layouts["pages"].id, form_id: @form4.id, keywords: %w(記事 注目情報),
  column_values: [
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 0, head: 'h1', text: '見出し1'),
    @form_columns4[0].value_type.new(
      column: @form_columns4[0], order: 1, value: '記事の内容記事の内容記事の内容記事の内容記事の内容記事の内容記事の内容記事の内容'
    ),
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 2, head: 'h2', text: '見出し2'),
    @form_columns4[1].value_type.new(
      column: @form_columns4[1], order: 3, value: "記事の内容記事の内容記事の内容記事の内容記事の内容記事の内容記事の内容記事の内容記事の内容記事の内容\n
        記事の内容記事の内容記事の内容記事の内容記事の内容記事の内容記事の内容記事の内容記事の内容記事の内容"
    ),
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 4, head: 'h3', text: '見出し3'),
    @form_columns4[4].value_type.new(
      column: @form_columns4[4], order: 5, file_id: file_page5_1.id, file_label: "ダミーイメージ", image_html_type: "image"
    ),
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 6, head: 'h4', text: '見出し4'),
    @form_columns4[6].value_type.new(
      column: @form_columns4[6], order: 7, lists: %w(番号付きリスト 番号付きリスト 番号付きリスト)
    ),
    @form_columns4[7].value_type.new(
      column: @form_columns4[7], order: 8, lists: %w(番号なしリスト 番号なしリスト 番号なしリスト)
    ),
    @form_columns4[8].value_type.new(column: @form_columns4[8], order: 9, value: html_page5_1),
    @form_columns4[5].value_type.new(
      column: @form_columns4[5], order: 10, file_id: file_page5_2.id, file_label: "ダミーイメージ"
    )
  ],
  category_ids: [@categories["attention"].id],
  contact_group_id: g("シラサギ市/危機管理部/防災課/生活安全係").id, contact_group_relation: "related",
  group_ids: [@g_seisaku.id],
  contact_sub_group_ids: [g("シラサギ市/危機管理部/管理課").id, g("シラサギ市/危機管理部/防災課/消防団係").id]
save_page route: "article/page", filename: "docs/page6.html", name: "還付金詐欺と思われる不審な電話にご注意ください",
  layout_id: @layouts["pages"].id, keywords: %w(記事 相談窓口),
  category_ids: [@categories["faq/kurashi"].id, @categories["oshirase/kurashi"].id],
  contact_group_id: g("シラサギ市/総務部/市民課").id, contact_group_relation: "related",
  group_ids: [@g_seisaku.id],
  contact_sub_group_ids: [g("シラサギ市/企画政策部/政策課/経営戦略係").id]
save_page route: "article/page", filename: "docs/page7.html", name: "平成26年度　シラサギ市システム構築に係るの公募型企画競争",
  layout_id: @layouts["pages"].id,
  category_ids: [@categories["oshirase"].id, @categories["shisei/soshiki"].id, @categories["shisei/soshiki/kikaku"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id],
  contact_sub_group_ids: @contact_sub_group_ids2
save_page route: "article/page", filename: "docs/page8.html", name: "冬の感染症に備えましょう",
  layout_id: @layouts["pages"].id, category_ids: [@categories["oshirase"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page9.html", name: "広報SHIRASAGI3月号を掲載",
  layout_id: @layouts["pages"].id,
  category_ids: [@categories["oshirase"].id,
                 @categories["oshirase/kurashi"].id,
                 @categories["shisei/soshiki"].id,
                 @categories["shisei/soshiki/kikaku"].id,
  ],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page10.html", name: "インフルエンザ流行警報がでています",
  layout_id: @layouts["pages"].id, category_ids: [@categories["oshirase"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page11.html", name: "転出届", gravatar_screen_name: "サイト管理者",
  layout_id: @layouts["pages"].id, keywords: %w(記事 住民登録),
  category_ids: [@categories["kurashi/koseki/jyumin"].id],
  contact_group_id: g("シラサギ市/総務部/市民課/戸籍係").id, contact_group_relation: "related",
  group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page12.html", name: "転入届",
  layout_id: @layouts["pages"].id, keywords: %w(記事 住民登録),
  category_ids: [
    @categories["faq/kurashi"].id, @categories["guide/hikkoshi"].id,
    @categories["kurashi/koseki/jyumin"].id
  ],
  contact_group_id: g("シラサギ市/総務部/市民課/戸籍係").id, contact_group_relation: "related",
  group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page13.html", name: "世帯または世帯主を変更するとき",
  layout_id: @layouts["pages"].id, category_ids: [@categories["kurashi/koseki/jyumin"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page14.html", name: "証明書発行窓口",
  layout_id: @layouts["pages"].id, keywords: %w(記事 住民登録),
  category_ids: [
    @categories["kurashi/koseki/inkan"].id, @categories["kurashi/koseki/jyumin"].id,
    @categories["kurashi/koseki/koseki"].id, @categories["kurashi/sodan"].id,
    @categories["kurashi/zeikin"].id
  ],
  contact_group_id: g("シラサギ市/総務部/市民課").id, contact_group_relation: "related",
  contact_sub_group_ids: [g("シラサギ市/総務部/財産管理課/電算管理係").id], group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page15.html", name: "住民票記載事項証明書様式",
  layout_id: @layouts["pages"].id, keywords: %w(記事 住民登録),
  category_ids: [@categories["kurashi/koseki/jyumin"].id],
  contact_group_id: g("シラサギ市/総務部/市民課").id, contact_group_relation: "related",
  contact_sub_group_ids: [g("シラサギ市/総務部/市民課/戸籍係").id],
  group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page16.html", name: "住所変更の証明書について",
  layout_id: @layouts["pages"].id, keywords: %w(記事 住民登録),
  category_ids: [@categories["kurashi/koseki/jyumin"].id],
  contact_group_id: g("シラサギ市/総務部/市民課").id, contact_group_relation: "related",
  contact_sub_group_ids: [g("シラサギ市/総務部/市民課/戸籍係").id],
  group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page17.html", name: "住民票コードとは",
  layout_id: @layouts["pages"].id, keywords: %w(記事 住民登録),
  category_ids: [@categories["kurashi/koseki/jyumin"].id],
  contact_group_id: g("シラサギ市/総務部/市民課").id, contact_group_relation: "related",
  contact_sub_group_ids: [g("シラサギ市/総務部/市民課/戸籍係").id],
  group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page18.html", name: "住民票コードの変更",
  layout_id: @layouts["pages"].id, keywords: %w(記事 住民登録),
  category_ids: [@categories["kurashi/koseki/jyumin"].id],
  contact_group_id: g("シラサギ市/総務部/市民課").id, contact_group_relation: "related",
  contact_sub_group_ids: [g("シラサギ市/総務部/市民課/戸籍係").id],
  group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page19.html", name: "自動交付機・コンビニ交付サービスについて",
  layout_id: @layouts["pages"].id, keywords: %w(記事 お知らせ くらし・手続き 組織案内 企画政策部),
  category_ids: [@categories["oshirase"].id,
                 @categories["oshirase/kurashi"].id,
                 @categories["shisei/soshiki"].id,
                 @categories["shisei/soshiki/kikaku"].id,
  ],
  contact_group_id: g("シラサギ市/総務部/市民課").id, contact_group_relation: "related",
  contact_sub_group_ids: [
    g("シラサギ市/企画政策部/政策課/デジタル戦略係").id, g("シラサギ市/総務部/財産管理課/管理・営繕係").id,
    g("シラサギ市/総務部/財産管理課/電算管理係").id
  ],
  group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/tenkyo.html", name: "転居届", layout_id: @layouts["pages"].id,
  keywords: %w(記事 住民登録 お知らせ),
  category_ids: [
    @categories["faq/kurashi"].id, @categories["oshirase"].id,
    @categories["kurashi/koseki/jyumin"].id
  ],
  contact_group_id: g("シラサギ市/総務部/市民課/戸籍係").id, contact_group_relation: "related",
  group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "oshirase/kurashi/page20.html", name: "犬・猫を譲り受けたい方",
  layout_id: @layouts["pages"].id, category_ids: [@categories["oshirase"].id, @categories["oshirase/kurashi"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "oshirase/kurashi/page21.html", name: "平成26年度住宅補助金の募集について掲載しました。",
  layout_id: @layouts["pages"].id, category_ids: [@categories["oshirase"].id, @categories["oshirase/kurashi"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "oshirase/kurashi/page22.html", name: "休日臨時窓口を開設します。",
  layout_id: @layouts["pages"].id,
  category_ids: [@categories["oshirase"].id,
                 @categories["oshirase/kurashi"].id,
                 @categories["shisei/soshiki"].id,
                 @categories["shisei/soshiki/kikaku"].id,
  ],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "oshirase/kurashi/page23.html", name: "身体障害者手帳の認定基準が変更",
  layout_id: @layouts["pages"].id, category_ids: [@categories["oshirase"].id, @categories["oshirase/kurashi"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "oshirase/kurashi/page24.html", name: "平成26年4月より国民健康保険税率が改正されます",
  layout_id: @layouts["pages"].id,
  category_ids: [@categories["oshirase"].id,
                 @categories["oshirase/kurashi"].id,
  ],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "urgency/page25.html", name: "黒鷺県沖で発生した地震による当市への影響について。",
  layout_id: @layouts["oshirase"].id, category_ids: [@categories["urgency"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "urgency/page26.html", name: "黒鷺県沖で発生した地震による津波被害について。",
  layout_id: @layouts["more"].id, category_ids: [@categories["urgency"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

file_1 = save_ss_files "ss_files/article/pdf_file.pdf", filename: "pdf_file.pdf", model: "article/page"
file_2 = save_ss_files "ss_files/key-visual/small/keyvisual01.jpg", filename: "keyvisual01.jpg", name: "画像1",
  model: "article/page"
file_3 = save_ss_files "ss_files/key-visual/small/keyvisual02.jpg", filename: "keyvisual02.jpg", name: "画像2",
  model: "article/page"
file_4 = save_ss_files "ss_files/key-visual/small/keyvisual03.jpg", filename: "keyvisual03.jpg", name: "画像3",
  model: "article/page"
file_5 = save_ss_files "ss_files/key-visual/small/keyvisual04.jpg", filename: "keyvisual04.jpg", name: "画像4",
  model: "article/page"
file_6 = save_ss_files "ss_files/key-visual/small/keyvisual05.jpg", filename: "keyvisual05.jpg", name: "画像5",
  model: "article/page"
html = []
html << '<p><a class="icon-pdf" href="' + file_1.url + '">サンプルファイル (PDF 783KB)</a></p>'
html << '<p>'
[file_2, file_3, file_4, file_5, file_6].each do |file|
  html << '<a alt="' + file.name + '" href="' + file.url + '" target="_blank" rel="noopener">'
  html << '<img alt="' + file.name + '" src="' + file.thumb_url + '" title="' + file.filename + '" />'
  html << '</a>'
end
html << '</p>'
recurrence = { kind: "date", start_at: Time.zone.tomorrow, frequency: "daily", until_on: Time.zone.tomorrow + 10 }
save_page route: "article/page", filename: "docs/page27.html", name: "ふれあいフェスティバル",
  layout_id: @layouts["pages"].id, event_recurrences: [ recurrence ],
  category_ids: [@categories["oshirase"].id,
                 @categories["oshirase/event"].id,
                 @categories["shisei/soshiki"].id,
                 @categories["shisei/soshiki/kikaku"].id,
  ],
  file_ids: [file_1.id, file_2.id, file_3.id, file_4.id, file_5.id, file_6.id], html: html.join("\n"),
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id, @g_koho.id]
recurrence = { kind: "date", start_at: Time.zone.today, frequency: "daily", until_on: Time.zone.today + 20 }
save_page route: "event/page", filename: "calendar/page28.html", name: "住民相談会を開催します。",
  layout_id: @layouts["event"].id, category_ids: [@categories["calendar/kohen"].id], event_recurrences: [ recurrence ],
  schedule: "〇〇年○月〇日", venue: "○○○○○○○○○○", cost: "○○○○○○○○○○",
  content: "○○○○○○○○○○○○○○○○○○○○", related_url: @link_url,
  map_points: [{ name: 'シラサギ公民館', loc: [134.551637, 34.060768], text: '駐車場20台あり' }],
  group_ids: [@g_seisaku.id]

file_7 = save_ss_files "ss_files/key-visual/small/keyvisual01.jpg", filename: "keyvisual01.jpg", name: "keyvisual01.jpg",
                       model: "ss/temp_file"
file_8 = save_ss_files "ss_files/key-visual/small/keyvisual02.jpg", filename: "keyvisual02.jpg", name: "keyvisual02.jpg",
                       model: "ss/temp_file"
file_9 = save_ss_files "ss_files/key-visual/small/keyvisual03.jpg", filename: "keyvisual03.jpg", name: "keyvisual03.jpg",
                       model: "ss/temp_file"
file_10_1 = save_ss_files "ss_files/article/img.png", filename: "img1.jpg", name: "img.jpg",
                        model: "ss/temp_file"
file_10_2 = save_ss_files "ss_files/article/img.png", filename: "img2.jpg", name: "img.jpg",
                        model: "ss/temp_file"
file_10_3 = save_ss_files "ss_files/article/img.png", filename: "img3.jpg", name: "img.jpg",
                        model: "ss/temp_file"
file_10_4 = save_ss_files "ss_files/article/img.png", filename: "img4.jpg", name: "img.jpg",
                        model: "ss/temp_file"
file_10_5 = save_ss_files "ss_files/article/img.png", filename: "img5.jpg", name: "img.jpg",
                          model: "ss/temp_file"
file_10_6 = save_ss_files "ss_files/article/img.png", filename: "img6.jpg", name: "img.jpg",
                          model: "ss/temp_file"
file_10_7 = save_ss_files "ss_files/article/img.png", filename: "img7.jpg", name: "img.jpg",
                          model: "ss/temp_file"
file_10_8 = save_ss_files "ss_files/article/img.png", filename: "img8.jpg", name: "img.jpg",
                          model: "ss/temp_file"
file_10_9 = save_ss_files "ss_files/article/img.png", filename: "img9.jpg", name: "img.jpg",
                          model: "ss/temp_file"
file_10_10 = save_ss_files "ss_files/article/img.png", filename: "img10.jpg", name: "img.jpg",
                          model: "ss/temp_file"
file_11 = save_ss_files "ss_files/article/magazine.png", filename: "magazine.png", name: "magazine.png",
                        model: "ss/temp_file"
file_12 = save_ss_files "ss_files/article/img_min.png", filename: "img_min1.png", name: "img_min.png", model: "ss/temp_file"
file_13 = save_ss_files "ss_files/article/img_min.png", filename: "img_min2.png", name: "img_min.png", model: "ss/temp_file"
file_14 = save_ss_files "ss_files/article/file.pdf", filename: "file.pdf", name: "2019年1月号表紙", model: "ss/temp_file"
file_15 = save_ss_files "ss_files/article/file_2.pdf", filename: "file_2.pdf", name: "お知らせ", model: "ss/temp_file"
file_16 = save_ss_files "ss_files/article/file_3.pdf", filename: "file_3.pdf", name: "くらしの情報", model: "ss/temp_file"
file_17 = save_ss_files "ss_files/article/file_4.pdf", filename: "file_4.pdf", name: "まちの話題", model: "ss/temp_file"
file_18 = save_ss_files "ss_files/article/file_5.pdf", filename: "file_5.pdf", name: "トピックス", model: "ss/temp_file"
file_19 = save_ss_files "ss_files/article/file_6.pdf", filename: "file_6.pdf", name: "フォトニュース", model: "ss/temp_file"
file_20 = save_ss_files "ss_files/article/file_7.pdf", filename: "file_7.pdf", name: "保健だより", model: "ss/temp_file"
file_21 = save_ss_files "ss_files/article/file_8.pdf", filename: "file_8.pdf", name: "図書だより", model: "ss/temp_file"
file_22 = save_ss_files "ss_files/article/file_9.pdf", filename: "file_9.pdf", name: "広報SHIRASAGI 2019年1月号 ",
                        model: "ss/temp_file"
file_23 = save_ss_files "ss_files/article/file_10.pdf", filename: "file_10.pdf", name: "新年のご挨拶", model: "ss/temp_file"
file_24 = save_ss_files "ss_files/article/file_11.pdf", filename: "file_11.pdf", name: "議会だより", model: "ss/temp_file"

save_page route: "article/page", filename: "docs/page29.html", name: "シラサギ博物館",
  layout_id: @layouts["pages"].id, form_id: @form.id, category_ids: [@categories["kanko/geijyutsu"].id],
  keywords: "記事, 文化・芸術", description: "説明文を入力します。" * 6,
  column_values: [
    @form_columns[0].value_type.new(column: @form_columns[0], file_id: file_10_1.id, file_label: "メイン写真",
      image_html_type: "image"),
    @form_columns[1].value_type.new(column: @form_columns[1], value: "説明文を入力します。" * 6),
    @form_columns[2].value_type.new(column: @form_columns[2], value: "大鷺県シラサギ市小鷺町1丁目1番地1号"),
    @form_columns[3].value_type.new(column: @form_columns[3], value: "シラサギ駅から徒歩5分"),
    @form_columns[4].value_type.new(column: @form_columns[4], value: "午前10時から午後4時"),
    @form_columns[5].value_type.new(column: @form_columns[5], value: "毎週水曜日"),
    @form_columns[6].value_type.new(column: @form_columns[6], value: "大人600円、中高生500円、小学生300円"),
    @form_columns[7].value_type.new(column: @form_columns[7], value: "00-0000-0000"),
    @form_columns[8].value_type.new(column: @form_columns[8], value: "shirasagi@example.jp"),
    @form_columns[9].value_type.new(column: @form_columns[9], link_url: "http://demo.ss-proj.org/", link_target: "_blank"),
    @form_columns[10].value_type.new(column: @form_columns[10], file_id: file_10_2.id, file_label: "写真1",
      image_html_type: "image"),
    @form_columns[11].value_type.new(column: @form_columns[11], file_id: file_10_3.id, file_label: "写真2",
      image_html_type: "image"),
    @form_columns[12].value_type.new(column: @form_columns[12], file_id: file_10_4.id, file_label: "写真3",
      image_html_type: "image"),
    @form_columns[13].value_type.new(column: @form_columns[13], file_id: file_10_5.id, file_label: "写真4",
      image_html_type: "image"),
    @form_columns[14].value_type.new(column: @form_columns[14], file_id: file_10_6.id, file_label: "写真5",
      image_html_type: "image"),
  ],
  map_points: [{ "name" => "", "loc" => [139.7741203, 35.7186823], "text" => "" }],
  group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page30.html", name: "ふれあいフェスティバル開催報告",
  layout_id: @layouts["pages"].id, form_id: @form2.id, keywords: "記事, イベント",
  category_ids: [@categories["oshirase/event"].id],
  column_values: [
    @form_columns2[0].value_type.new(column: @form_columns2[0], file_id: file_10_7.id, file_label: "画像1",
      image_html_type: "image"),
    @form_columns2[1].value_type.new(column: @form_columns2[1], file_id: file_10_8.id, file_label: "画像2",
      image_html_type: "image"),
    @form_columns2[2].value_type.new(column: @form_columns2[2], file_id: file_10_9.id, file_label: "画像3",
      image_html_type: "image"),
    @form_columns2[3].value_type.new(column: @form_columns2[3], value: ["1月30日、シラサギ博物館でふれあいフェスティバルを開催しました。",
                                                                        "内容を入力します。" * 15, "内容を入力します。" * 15].join("\n")),
  ],
  group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page31.html", name: "広報SHIRASAGI 2019年1月号",
  layout_id: @layouts["pages"].id, form_id: @form3.id, category_ids: [@categories["shisei/koho/shirasagi"].id],
  keywords: "記事, 広報SHIRASAGI",
  column_values: [
    @form_columns3[0].value_type.new(column: @form_columns3[0], file_id: file_11.id,
      file_label: "広報SHIRASAGI 2019年1月号   表紙", image_html_type: "image"),
    @form_columns3[1].value_type.new(column: @form_columns3[1], file_id: file_22.id,
      file_label: "広報SHIRASAGI 2019年1月号"),
    @form_columns3[2].value_type.new(column: @form_columns3[2], file_id: file_14.id,
      file_label: "2019年1月号表紙"),
    @form_columns3[3].value_type.new(column: @form_columns3[3], file_id: file_23.id,
      file_label: "新年のご挨拶"),
    @form_columns3[4].value_type.new(column: @form_columns3[4], file_id: file_18.id,
      file_label: "トピックス"),
    @form_columns3[5].value_type.new(column: @form_columns3[5], file_id: file_16.id,
      file_label: "くらしの情報"),
    @form_columns3[6].value_type.new(column: @form_columns3[6], file_id: file_20.id,
      file_label: "保健だより"),
    @form_columns3[7].value_type.new(column: @form_columns3[7], file_id: file_17.id,
      file_label: "まちの話題"),
    @form_columns3[8].value_type.new(column: @form_columns3[8], file_id: file_19.id,
      file_label: "フォトニュース"),
    @form_columns3[9].value_type.new(column: @form_columns3[9], file_id: file_24.id,
      file_label: "議会だより"),
    @form_columns3[10].value_type.new(column: @form_columns3[10], file_id: file_15.id,
      file_label: "お知らせ"),
    @form_columns3[11].value_type.new(column: @form_columns3[11], file_id: file_21.id,
      file_label: "図書だより"),
  ],
  group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page32.html", name: "インタビュー",
  layout_id: @layouts["pages"].id, form_id: @form5.id, keywords: "記事",
  column_values: [
    # 画像
    @form_columns5[0].value_type.new(column: @form_columns5[0], order: 0, file_id: file_10_10.id,
      file_label: "画像", image_html_type: "image"),
    # 名前
    @form_columns5[1].value_type.new(column: @form_columns5[1], order: 1, value: "白鷺 太郎さん"),
    # 質問
    @form_columns5[2].value_type.new(column: @form_columns5[2], order: 2, head: "h1", text: "質問を入力します。"),
    # 画像左
    @form_columns5[4].value_type.new(column: @form_columns5[4], order: 3, file_id: file_12.id,
      file_label: "画像", image_html_type: "image"),
    # 回答
    @form_columns5[3].value_type.new(column: @form_columns5[3], order: 4, value: ["回答を入力します。" * 10,
                                                                                  "回答を入力します。" * 10,
                                                                                  "回答を入力します。" * 10,
                                                                                  "回答を入力します。" * 10].join("\n")),
    # 質問
    @form_columns5[2].value_type.new(column: @form_columns5[2], order: 5, head: "h1", text: "質問を入力します。" * 2),
    # 画像右
    @form_columns5[5].value_type.new(column: @form_columns5[5], order: 6, file_id: file_13.id,
      file_label: "画像", image_html_type: "image"),
    # 回答
    @form_columns5[3].value_type.new(column: @form_columns5[3], order: 7, value: ["回答を入力します。" * 10,
                                                                                  "回答を入力します。" * 10,
                                                                                  "回答を入力します。" * 10,
                                                                                  "回答を入力します。" * 10].join("\n")),
    # 質問
    @form_columns5[2].value_type.new(column: @form_columns5[2], order: 8, head: "h1", text: "質問を入力します。" * 2),
    # 回答
    @form_columns5[3].value_type.new(column: @form_columns5[3], order: 9, value: ["回答を入力します。" * 10,
                                                                                  "回答を入力します。" * 10,
                                                                                  "回答を入力します。" * 10,
                                                                                  "回答を入力します。" * 10].join("\n")),
  ],
  group_ids: [@g_seisaku.id]

recurrence = { kind: "date", start_at: Time.zone.tomorrow, frequency: "daily", until_on: Time.zone.tomorrow + 1 }
save_page route: "article/page", filename: "docs/page33.html", name: "第67回　小鷲町ひまわり祭りのお知らせ",
  layout_id: @layouts["pages"].id, form_id: @form4.id, keywords: %w(記事 観光 お知らせ イベント 観光・文化・スポーツ),
  column_values: [
    @form_columns4[11].value_type.new(column: @form_columns4[11], order: 0, value: ''),
  ],
  category_ids: [
    @categories["oshirase"].id, @categories["oshirase/event"].id, @categories["oshirase/kanko"].id
  ],
  event_name: '小鷲町　ひまわり祭り',
  event_recurrences: [ recurrence ],
  event_deadline: Time.zone.now.advance(days: 1).change(hour: 11),
  contact_group_id: g("シラサギ市/企画政策部/広報課").id, contact_group_relation: "related",
  map_points: [
    {
      name: 'ウェブチップス', loc: [134.5758945, 34.0612009], text: 'ウェブチップス地図説明',
      image: '/assets/img/googlemaps/marker11.png'
    }
  ],
  group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page34.html", name: "会計年度任用職員（道路維持補修作業員）を募集します",
  layout_id: @layouts["pages"].id, form_id: @form4.id,
  category_ids: [@categories["shisei/jinji"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

recurrence = { kind: "date", start_at: Time.zone.tomorrow, frequency: "daily", until_on: Time.zone.tomorrow }
save_page route: "article/page", filename: "docs/page35.html", name: "第27回シラサギハーフマラソン　イベント開催！！",
  layout_id: @layouts["pages"].id, form_id: @form4.id,
  category_ids: [@categories["oshirase/event"].id],
  event_recurrences: [ recurrence ],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page36.html", name: "令和４年度　シラサギ市職員採用試験（後期試験）を実施します",
  layout_id: @layouts["pages"].id, form_id: @form4.id,
  category_ids: [@categories["shisei/jinji"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

file_page37_1 = save_ss_files "ss_files/article/topic1.jpg", filename: "topic1.jpg",
  name: "topic1.jpg", model: "ss/temp_file"
save_page route: "article/page", filename: "docs/page37.html", name: "SHIRASAGI川堤防の桜が開花しました。",
  layout_id: @layouts["pages"].id, form_id: @form4.id, thumb_id: file_page37_1.id,
  column_values: [
    @form_columns4[2].value_type.new(
      column: @form_columns4[2], order: 0, head: 'h2', text: 'SHIRASAGI川堤防の桜が開花しました。'
    ),
    @form_columns4[1].value_type.new(
      column: @form_columns4[1], order: 1,
      value: "SHIRASAGI川堤防の桜が開花しました。\nSHIRASAGI川堤防の桜が開花しました。SHIRASAGI川堤防の桜が開花しました。"
    ),
  ],
  category_ids: [@categories["topics"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

file_page38 = save_ss_files "ss_files/article/topic2.jpg", filename: "topic2.jpg",
  name: "topic2.jpg", model: "ss/temp_file"
save_page route: "article/page", filename: "docs/page38.html", name: "シラサギ西公園の睡蓮が見頃です（7月上旬〜中頃）",
  layout_id: @layouts["pages"].id, form_id: @form4.id, thumb_id: file_page38.id,
  category_ids: [@categories["topics"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

file_page40_1 = save_ss_files "ss_files/article/koho_shirasagi.jpg", filename: "koho_shirasagi.jpg",
  name: "広報シラサギ.jpg", model: "ss/temp_file"
file_page40_2 = save_ss_files "ss_files/article/koho_shirasagi.pdf", filename: "koho_shirasagi.pdf",
  name: "広報シラサギ.pdf", model: "ss/temp_file"
save_page route: "article/page", filename: "docs/page40.html", name: "今月の広報SHIRASAGI",
  layout_id: @layouts["pages"].id, keywords: %w(記事 広報SHIRASAGI 広報シラサギ 今月の広報シラサギ),
  form_id: @form4.id,
  column_values: [
    @form_columns4[4].value_type.new(
      column: @form_columns4[4], order: 0, file_id: file_page40_1.id, file_label: "2022年4月号", image_html_type: "image"
    ),
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 1, head: 'h2', text: 'PDF版広報SHIRASAGI'),
    @form_columns4[5].value_type.new(
      column: @form_columns4[5], order: 2, file_id: file_page40_2.id, file_label: "2022年4月号"
    ),
  ],
  category_ids: [
    @categories["kohoshi"].id, @categories["kohoshi/kongetsukoho"].id,
    @categories["shisei/koho/shirasagi"].id
  ],
  contact_group_id: g("シラサギ市/企画政策部/広報課").id, contact_group_relation: "related",
  group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page41.html", name: "春の交通安全週間",
  layout_id: @layouts["pages"].id, form_id: @form4.id,
  category_ids: [@categories["kurashi/anzen"].id, @categories["kurashi/anzen/bohan"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page42.html", name: "シラサギ市地域防災計画、シラサギ市水防計画",
  layout_id: @layouts["pages"].id, form_id: @form4.id,
  category_ids: [
    @categories["kurashi/bosai"].id, @categories["kurashi/bosai/jyoho"].id, @categories["kurashi/bosai/kanri"].id,
    @categories["kurashi/bosai/keikaku"].id, @categories["kurashi/bosai/kunren"].id
  ],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page43.html", name: "Web版ハザードマップを公開しました",
  layout_id: @layouts["pages"].id, keywords: %w(記事 くらし・手続き 防災情報),
  form_id: @form4.id,
  category_ids: [
    @categories["faq/kurashi"].id, @categories["kurashi"].id,
    @categories["kurashi/bosai"].id, @categories["kurashi/bosai/jyoho"].id
  ],
  map_points: [
    {
      name: '', loc: [134.515229, 34.059931], text: '',
      image: '/assets/img/googlemaps/marker1.png'
    }
  ],
  contact_group_id: g("シラサギ市/危機管理部/防災課").id, contact_group_relation: "related",
  contact_sub_group_ids: [g("シラサギ市/危機管理部/防災課/生活安全係").id, g("シラサギ市/危機管理部/防災課/消防団係").id],
  group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page44.html", name: "【募集終了】シラサギ市地域防災推進員養成研修受講者募集",
  layout_id: @layouts["pages"].id, form_id: @form4.id,
  category_ids: [@categories["kurashi"].id, @categories["kurashi/bosai"].id, @categories["kurashi/bosai/keikaku"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

recurrence = { kind: "date", start_at: Time.zone.tomorrow, frequency: "daily", until_on: Time.zone.tomorrow + 1 }
save_page route: "article/page", filename: "docs/page45.html", name: "「シラサギ市　秋の収穫祭り」開催告知",
  layout_id: @layouts["pages"].id, form_id: @form4.id,
  category_ids: [@categories["oshirase"].id, @categories["oshirase/event"].id],
  event_name: 'シラサギ市　秋の収穫祭り',
  event_recurrences: [ recurrence ],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page46.html", name: "婚姻届（結婚するときの戸籍の届出）について",
  layout_id: @layouts["pages"].id, keywords: %w(記事 くらしのガイド 結婚・離婚),
  form_id: @form4.id,
  category_ids: [@categories["guide"].id, @categories["guide/kekkon"].id],
  contact_group_id: g("シラサギ市/総務部/市民課/戸籍係").id, contact_group_relation: "related",
  group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page47.html", name: "離婚届（離婚するときの戸籍の届出）について",
  layout_id: @layouts["pages"].id, keywords: %w(記事 くらしのガイド 結婚・離婚),
  form_id: @form4.id,
  category_ids: [@categories["guide"].id, @categories["guide/kekkon"].id],
  contact_group_id: g("シラサギ市/総務部/市民課/戸籍係").id, contact_group_relation: "related",
  group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page48.html", name: "シラサギ市結婚新生活支援事業（補助金）について",
  layout_id: @layouts["pages"].id, form_id: @form4.id,
  category_ids: [@categories["guide"].id, @categories["guide/kekkon"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page49.html", name: "妊婦健診",
  layout_id: @layouts["pages"].id, form_id: @form4.id,
  column_values: [
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 0, head: 'h2', text: '定期健診をうけましょう。'),
    @form_columns4[7].value_type.new(
      column: @form_columns4[7], order: 1,
      lists: %w(妊娠初期より妊娠23週までは4週に1回 妊娠24週より妊娠35週までは2週に1回 妊娠36週以降分娩までは1週に1回)
    ),
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 2, head: 'h3', text: '対象者'),
    @form_columns4[0].value_type.new(column: @form_columns4[0], order: 3, value: '妊婦、産婦'),
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 4, head: 'h3', text: '実施場所'),
    @form_columns4[0].value_type.new(column: @form_columns4[0], order: 5, value: '県内の委託医療機関等')
  ],
  category_ids: [
    @categories["faq/kosodate"].id, @categories["guide/ninshin"].id,
    @categories["kosodate/hoken"].id, @categories["kosodate/kenko"].id
  ],
  contact_state: "show", contact_group_id: g("シラサギ市/福祉健康部/社会福祉課").id,
  contact_group_relation: "related", group_ids: [@g_seisaku.id, g("シラサギ市/福祉健康部").id]

save_page route: "article/page", filename: "docs/page50.html", name: "予防接種について",
  layout_id: @layouts["pages"].id, form_id: @form4.id, keywords: %w(記事 子育て 母子の健康・予防接種 子育て・教育),
  column_values: [
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 0, head: 'h2', text: '乳幼児個別接種（指定医療機関）'),
    @form_columns4[1].value_type.new(
      column: @form_columns4[1], order: 1,
      value: "個別接種は、保護者が各自でかかりつけ医などの医療機関で接種を受ける方法です。
        県内の指定医療機関で1年を通して接種できます。
        接種年齢、他の予防接種との接種間隔などに注意して受けてください。"
    ),
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 2, head: 'h3', text: '各種予防接種費用'),
    @form_columns4[0].value_type.new(
      column: @form_columns4[0], order: 3, value: '乳幼児個別接種、児童生徒個別接種については、無料です。'
    ),
    @form_columns4[0].value_type.new(
      column: @form_columns4[0], order: 4, value: '厚生労働省のホームページもご参照ください'
    ),
    @form_columns4[3].value_type.new(
      column: @form_columns4[3], order: 5, link_label: '予防接種・ワクチン情報​',
      link_url: "https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/kenkou_iryou/kenkou/kekkaku-kansenshou/yobou-sesshu/index.html",
      link_target: "_blank"
    )
  ],
  category_ids: [
    @categories["faq/kosodate"].id, @categories["guide/kosodate"].id,
    @categories["oshirase/kosodate"].id, @categories["kosodate/kenko"].id
  ],
  contact_state: "show", contact_group_id: g("シラサギ市/福祉健康部/社会福祉課").id,
  contact_group_relation: "related", group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page51.html", name: "小学校一覧",
  layout_id: @layouts["pages"].id, form_id: @form4.id, keywords: %w(記事 教育 小学校・中学校 子育て・教育),
  column_values: [
    @form_columns4[11].value_type.new(column: @form_columns4[11], order: 0, value: File.read("pages/docs/page51.html"))
  ],
  category_ids: [
    @categories["faq/kosodate"].id, @categories["guide/kyoiku"].id,
    @categories["oshirase/kosodate"].id, @categories["kosodate/shogakko"].id
  ],
  contact_state: "show", contact_group_id: g("シラサギ市/福祉健康部/子育て支援課").id,
  contact_group_relation: "related", group_ids: [@g_seisaku.id, g("シラサギ市/福祉健康部/子育て支援課").id]

html_page52_1 = []
html_page52_1 << "<table>"
html_page52_1 << "  <caption>具体的な施策例</caption>"
html_page52_1 << "  <thead>"
html_page52_1 << "    <tr>"
html_page52_1 << "      <th scope=\"col\" class=\"\">分類</th>"
html_page52_1 << "      <th scope=\"col\" class=\"\">具体的な施策例</th>"
html_page52_1 << "    </tr>"
html_page52_1 << "  </thead>"
html_page52_1 << "  <tbody>"
html_page52_1 << "    <tr>"
html_page52_1 << "      <td class=\"\">住宅支援</td>"
html_page52_1 << "      <td class=\"\">空き家バンク、住宅購入・リフォーム補助、家賃補助、移住者向け公営住宅</td>"
html_page52_1 << "    </tr>"
html_page52_1 << "    <tr>"
html_page52_1 << "      <td class=\"\">就業・起業支援</td>"
html_page52_1 << "      <td class=\"\">地域おこし協力隊、就農支援、テレワーク施設整備、起業支援金、仕事紹介サービス</td>"
html_page52_1 << "    </tr>"
html_page52_1 << "    <tr>"
html_page52_1 << "      <td class=\"\">子育て・教育支援</td>"
html_page52_1 << "      <td class=\"\">子育て支援金、保育料補助、学用品補助、地域学校の紹介、通学バスの整備</td>"
html_page52_1 << "    </tr>"
html_page52_1 << "    <tr>"
html_page52_1 << "      <td class=\"\">生活環境支援</td>"
html_page52_1 << "      <td class=\"\">医療機関・買い物施設の紹介、地域生活ガイド、交通インフラ整備</td>"
html_page52_1 << "    </tr>"
html_page52_1 << "  </tbody>"
html_page52_1 << "</table>"
html_page52_1 = html_page52_1.join
save_page route: "article/page", filename: "docs/page52.html", name: "移住・定住促進",
  layout_id: @layouts["pages"].id, form_id: @form4.id, keywords: %w(記事 注目情報 引越し・住まい 住まい くらし・手続き),
  column_values: [
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 0, head: 'h2', text: '移住・定住促進について'),
    @form_columns4[1].value_type.new(
      column: @form_columns4[1], order: 1,
      value: "本市では、出生から子育て、就職・結婚、転出・Uターンに至るまでの各ライフステージに応じた総合的な人口減少対策に取り組んでいます。
        あわせて、移住・定住を希望される方に対する支援策を展開し、住みよい地域づくりを推進しています。"
    ),
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 2, head: 'h3', text: '主な施策'),
    @form_columns4[8].value_type.new(column: @form_columns4[8], order: 3, value: html_page52_1)
  ],
  category_ids: [
    @categories["attention"].id, @categories["faq/kurashi"].id,
    @categories["guide/hikkoshi"].id, @categories["oshirase/kurashi"].id,
    @categories["kurashi/sumai"].id
  ],
  contact_state: "show", contact_group_id: g("シラサギ市/総務部/市民課").id,
  contact_group_relation: "related", group_ids: [@g_seisaku.id]

html_page53_1 = []
html_page53_1 << "<ul>"
html_page53_1 << "  <li>対象者：求職者全般（新卒・転職・再就職希望者）</li>"
html_page53_1 << "  <li>主な支援内容"
html_page53_1 << "  <ul>"
html_page53_1 << "    <li>求人情報の提供</li>"
html_page53_1 << "    <li>就職相談・職業紹介</li>"
html_page53_1 << "    <li>職業訓練（無料あり）</li>"
html_page53_1 << "    <li>雇用保険（失業手当）の手続き</li>"
html_page53_1 << "  </ul>"
html_page53_1 << "  </li>"
html_page53_1 << "  <li>備考：ハローワークインターネットサービスでも求人検索が可能です。</li>"
html_page53_1 << "</ul>"
html_page53_1 = html_page53_1.join
html_page53_2 = []
html_page53_2 << "<ul>"
html_page53_2 << "  <li>対象者：市外からの移住・転入者</li>"
html_page53_2 << "  <li>主な支援内容"
html_page53_2 << "  <ul>"
html_page53_2 << "    <li>地元企業の求人紹介</li>"
html_page53_2 << "    <li>就職相談・斡旋</li>"
html_page53_2 << "    <li>地場産業の見学や体験</li>"
html_page53_2 << "  </ul>"
html_page53_2 << "  </li>"
html_page53_2 << "  <li>備考：市役所・移住定住支援センターなどに併設されている場合があります。</li>"
html_page53_2 << "</ul>"
html_page53_2 = html_page53_2.join
html_page53_3 = []
html_page53_3 << "<ul>"
html_page53_3 << "  <li>対象者：失業者、転職希望者、スキルを身につけたい人</li>"
html_page53_3 << "  <li>内容"
html_page53_3 << "  <ul>"
html_page53_3 << "    <li>IT、介護、建設、農業など分野別の無料講座</li>"
html_page53_3 << "    <li>受講中に給付金（条件あり）を受けられる制度も</li>"
html_page53_3 << "  </ul>"
html_page53_3 << "  </li>"
html_page53_3 << "  <li>実施機関：都道府県職業能力開発校、民間委託校 など</li>"
html_page53_3 << "</ul>"
html_page53_3 = html_page53_3.join
save_page route: "article/page", filename: "docs/page53.html", name: "就労を希望する方が利用できる機関と制度",
  layout_id: @layouts["pages"].id, form_id: @form4.id, keywords: %w(記事 就職・退職 相談窓口 産業・仕事 人材募集),
  column_values: [
    @form_columns4[0].value_type.new(
      column: @form_columns4[0], order: 0,
      value: '就職・転職を考えている方、移住後の仕事探しを始めたい方に向けて、以下の機関や支援制度をご利用いただけます。'
    ),
    @form_columns4[2].value_type.new(
      column: @form_columns4[2], order: 1, head: 'h2',
      text: 'ハローワーク（公共職業安定所）'
    ),
    @form_columns4[11].value_type.new(column: @form_columns4[11], order: 2, value: html_page53_1),
    @form_columns4[2].value_type.new(
      column: @form_columns4[2], order: 3, head: 'h2', text: '移住者向け就業支援窓口（自治体独自）'
    ),
    @form_columns4[11].value_type.new(column: @form_columns4[11], order: 4, value: html_page53_2),
    @form_columns4[2].value_type.new(
      column: @form_columns4[2], order: 5, head: 'h2', text: '職業訓練（公共訓練／求職者支援訓練）'
    ),
    @form_columns4[11].value_type.new(column: @form_columns4[11], order: 6, value: html_page53_3)
  ],
  category_ids: [
    @categories["faq/sangyo"].id, @categories["guide/shushoku"].id,
    @categories["oshirase/sangyo"].id, @categories["kurashi/sodan"].id,
    @categories["sangyo/jinzai"].id
  ],
  contact_state: "show", contact_group_id: g("シラサギ市/企画政策部/広報課").id,
  contact_group_relation: "related", contact_sub_group_ids: [g("シラサギ市/総務部/人事課/人材育成係").id],
  group_ids: [@g_seisaku.id]

html_page54_1 = []
html_page54_1 << "<table>"
html_page54_1 << "  <caption>高齢者福祉の相談</caption>"
html_page54_1 << "  <thead>"
html_page54_1 << "    <tr>"
html_page54_1 << "      <th scope=\"col\">内容</th>"
html_page54_1 << "      <th scope=\"col\">担当窓口・課名</th>"
html_page54_1 << "      <th scope=\"col\">電話番号</th>"
html_page54_1 << "      <th scope=\"col\">備考</th>"
html_page54_1 << "    </tr>"
html_page54_1 << "  </thead>"
html_page54_1 << "  <tbody>"
html_page54_1 << "    <tr>"
html_page54_1 << "      <td>介護保険の申請・相談</td>"
html_page54_1 << "      <td>高齢福祉課 介護保険係</td>"
html_page54_1 << "      <td>0999-xx-xxxx</td>"
html_page54_1 << "      <td>介護認定、サービス利用等</td>"
html_page54_1 << "    </tr>"
html_page54_1 << "    <tr>"
html_page54_1 << "      <td>高齢者支援全般</td>"
html_page54_1 << "      <td>地域包括支援センター</td>"
html_page54_1 << "      <td>0999-xx-xxxx</td>"
html_page54_1 << "      <td>見守り・権利擁護など総合相談</td>"
html_page54_1 << "    </tr>"
html_page54_1 << "  </tbody>"
html_page54_1 << "</table>"
html_page54_1 = html_page54_1.join
html_page54_2 = []
html_page54_2 << "<table border=\"1\" cellpadding=\"8\" cellspacing=\"0\">"
html_page54_2 << "  <caption>障がい福祉の相談</caption>"
html_page54_2 << "  <thead>"
html_page54_2 << "    <tr>"
html_page54_2 << "      <th scope=\"col\">内容</th>"
html_page54_2 << "      <th scope=\"col\">担当窓口・課名</th>"
html_page54_2 << "      <th scope=\"col\">電話番号</th>"
html_page54_2 << "      <th scope=\"col\">備考</th>"
html_page54_2 << "    </tr>"
html_page54_2 << "  </thead>"
html_page54_2 << "  <tbody>"
html_page54_2 << "    <tr>"
html_page54_2 << "      <td>身体・知的・精神障がい</td>"
html_page54_2 << "      <td>障がい福祉課 障がい支援係</td>"
html_page54_2 << "      <td>0999-xx-xxxx</td>"
html_page54_2 << "      <td>各種手帳の交付、福祉サービス等</td>"
html_page54_2 << "    </tr>"
html_page54_2 << "    <tr>"
html_page54_2 << "      <td>就労・日中活動支援</td>"
html_page54_2 << "      <td>就労支援係</td>"
html_page54_2 << "      <td>0999-xx-xxxx</td>"
html_page54_2 << "      <td>就労継続支援B型、作業所など</td>"
html_page54_2 << "    </tr>"
html_page54_2 << "    <tr>"
html_page54_2 << "      <td>発達障がいの相談</td>"
html_page54_2 << "      <td>保健センター 発達支援室</td>"
html_page54_2 << "      <td>0999-xx-xxxx</td>"
html_page54_2 << "      <td>児童の発達相談・支援も対応可能</td>"
html_page54_2 << "    </tr>"
html_page54_2 << "  </tbody>"
html_page54_2 << "</table>"
html_page54_2 = html_page54_2.join
html_page54_3 = []
html_page54_3 << "<table border=\"1\" cellpadding=\"8\" cellspacing=\"0\">"
html_page54_3 << "  <caption>子ども・家庭福祉の相談</caption>"
html_page54_3 << "  <thead>"
html_page54_3 << "    <tr>"
html_page54_3 << "      <th scope=\"col\">内容</th>"
html_page54_3 << "      <th scope=\"col\">担当窓口・課名</th>"
html_page54_3 << "      <th scope=\"col\">電話番号</th>"
html_page54_3 << "      <th scope=\"col\">備考</th>"
html_page54_3 << "    </tr>"
html_page54_3 << "  </thead>"
html_page54_3 << "  <tbody>"
html_page54_3 << "    <tr>"
html_page54_3 << "      <td>児童虐待・子育て支援</td>"
html_page54_3 << "      <td>子ども家庭支援センター</td>"
html_page54_3 << "      <td>0999-xx-xxxx</td>"
html_page54_3 << "      <td>虐待・不登校・発達相談にも対応</td>"
html_page54_3 << "    </tr>"
html_page54_3 << "    <tr>"
html_page54_3 << "      <td>ひとり親家庭の支援</td>"
html_page54_3 << "      <td>子育て支援課</td>"
html_page54_3 << "      <td>0999-xx-xxxx</td>"
html_page54_3 << "      <td>児童扶養手当、母子父子家庭支援など</td>"
html_page54_3 << "    </tr>"
html_page54_3 << "  </tbody>"
html_page54_3 << "</table>"
html_page54_3 = html_page54_3.join
save_page route: "article/page", filename: "docs/page54.html", name: "各種相談窓口",
  layout_id: @layouts["pages"].id, form_id: @form4.id,
  keywords: %w(記事 福祉・介護 子育て 高齢者福祉 障害福祉 子育て支援 健康・福祉 子育て・教育),
  column_values: [
    @form_columns4[2].value_type.new(
      column: @form_columns4[2], order: 0, head: 'h2',
      text: '高齢者福祉の相談'
    ),
    @form_columns4[11].value_type.new(column: @form_columns4[11], order: 1, value: html_page54_1),
    @form_columns4[2].value_type.new(
      column: @form_columns4[2], order: 2, head: 'h2', text: '障がい福祉の相談'
    ),
    @form_columns4[11].value_type.new(column: @form_columns4[11], order: 3, value: html_page54_2),
    @form_columns4[2].value_type.new(
      column: @form_columns4[2], order: 4, head: 'h2', text: '子ども・家庭福祉の相談'
    ),
    @form_columns4[11].value_type.new(column: @form_columns4[11], order: 5, value: html_page54_3)
  ],
  category_ids: [
    @categories["faq/kosodate"].id, @categories["faq/kenko"].id,
    @categories["guide/kosodate"].id, @categories["guide/fukushi"].id,
    @categories["oshirase/kenko"].id, @categories["oshirase/kosodate"].id,
    @categories["kosodate/shien"].id, @categories["kenko/korei"].id,
    @categories["kenko/shogai"].id
  ],
  contact_state: "show", contact_group_relation: "related",
  group_ids: [@g_seisaku.id]

html_page55_1 = []
html_page55_1 << "<table>"
html_page55_1 << "  <caption>その他の必要な手続き</caption>"
html_page55_1 << "  <thead>"
html_page55_1 << "    <tr>"
html_page55_1 << "      <th scope=\"col\">内容</th>"
html_page55_1 << "      <th scope=\"col\">担当窓口</th>"
html_page55_1 << "      <th scope=\"col\">備考</th>"
html_page55_1 << "    </tr>"
html_page55_1 << "  </thead>"
html_page55_1 << "  <tbody>"
html_page55_1 << "    <tr>"
html_page55_1 << "      <td>戸籍の死亡届</td>"
html_page55_1 << "      <td>市民課（戸籍係）</td>"
html_page55_1 << "      <td>死亡診断書を添えて7日以内に届出</td>"
html_page55_1 << "    </tr>"
html_page55_1 << "    <tr>"
html_page55_1 << "      <td>年金の手続き</td>"
html_page55_1 << "      <td>年金事務所</td>"
html_page55_1 << "      <td>未支給年金・遺族年金の申請</td>"
html_page55_1 << "    </tr>"
html_page55_1 << "    <tr>"
html_page55_1 << "      <td>障がい者手帳の返却</td>"
html_page55_1 << "      <td>福祉課</td>"
html_page55_1 << "      <td>手帳、医療証、受給者証などの返却</td>"
html_page55_1 << "    </tr>"
html_page55_1 << "    <tr>"
html_page55_1 << "      <td>医療費・福祉制度の停止</td>"
html_page55_1 << "      <td>各担当課</td>"
html_page55_1 << "      <td>高額療養費、障がい福祉等</td>"
html_page55_1 << "    </tr>"
html_page55_1 << "  </tbody>"
html_page55_1 << "</table>"
html_page55_1 = html_page55_1.join
save_page route: "article/page", filename: "docs/page55.html", name: "被保険者が亡くなられた際の手続きについて",
  layout_id: @layouts["pages"].id, form_id: @form4.id,
  keywords: %w(記事 届出・証明・法令・規制 おくやみ 国民健康保険 くらし・手続き),
  column_values: [
    @form_columns4[1].value_type.new(
      column: @form_columns4[1], order: 0,
      value: "被保険者（国民健康保険・後期高齢者医療制度・介護保険など）がお亡くなりになった場合、ご遺族の方には一定の手続きが必要です。
        速やかに関係窓口へご相談・届出をお願いいたします。"
    ),
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 1, head: 'h2', text: '必要なもの'),
    @form_columns4[7].value_type.new(
      column: @form_columns4[7], order: 2,
      lists: %w(
        死亡診断書（死亡届に印刷されています。医師の証明）
        届出人の印鑑（届書への押印は任意ですが、埋火葬許可申請に必要なためご持参ください。）
      )
    ),
    @form_columns4[2].value_type.new(
      column: @form_columns4[2], order: 3, head: 'h3', text: '国民健康保険に加入していた方が亡くなった場合'
    ),
    @form_columns4[0].value_type.new(
      column: @form_columns4[0], order: 4,
      value: '死亡を知った日から14日以内に年金手続、国民健康保険手続などを行ってください。【該当する方のみ】'
    ),
    @form_columns4[2].value_type.new(
      column: @form_columns4[2], order: 5, head: 'h3', text: 'その他必要な手続きの一例'
    ),
    @form_columns4[11].value_type.new(column: @form_columns4[11], order: 6, value: html_page55_1)
  ],
  category_ids: [
    @categories["faq/kurashi"].id, @categories["guide/okuyami"].id,
    @categories["oshirase/kurashi"].id, @categories["kurashi/nenkin/hoken"].id,
    @categories["sangyo/todokede"].id
  ],
  contact_state: "show", contact_group_relation: "related", group_ids: [@g_seisaku.id]

html_page56_1 = []
html_page56_1 << "<table>"
html_page56_1 << "  <caption>&nbsp;</caption>"
html_page56_1 << "  <tbody>"
html_page56_1 << "    <tr>"
html_page56_1 << "      <td>白鷺市 市民課</td>"
html_page56_1 << "      <td>0999-11-2345</td>"
html_page56_1 << "      <td>使用許可申請・死亡届受付</td>"
html_page56_1 << "    </tr>"
html_page56_1 << "    <tr>"
html_page56_1 << "      <td>白鷺市斎場</td>"
html_page56_1 << "      <td>0999-55-9876</td>"
html_page56_1 << "      <td>&nbsp;施設予約・空き状況確認</td>"
html_page56_1 << "    </tr>"
html_page56_1 << "  </tbody>"
html_page56_1 << "</table>"
html_page56_1 = html_page56_1.join
save_page route: "article/page", filename: "docs/page56.html", name: "葬斎場の使用",
  layout_id: @layouts["pages"].id, form_id: @form4.id,
  keywords: %w(記事 おくやみ くらし・手続き),
  column_values: [
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 0, head: 'h2', text: '利用対象者'),
    @form_columns4[7].value_type.new(
      column: @form_columns4[7], order: 1,
      lists: %w(
        市内に住民登録のある方が亡くなられた場合
        市外の方でも、一定の条件で使用可能（使用料が異なります）
      )
    ),
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 2, head: 'h2', text: '申請に必要なもの'),
    @form_columns4[7].value_type.new(
      column: @form_columns4[7], order: 3,
      lists: %w(
        火葬（斎場）使用許可申請書
        死亡届受理証明書の写し
      )
    ),
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 4, head: 'h2', text: 'お問い合わせ先'),
    @form_columns4[11].value_type.new(column: @form_columns4[11], order: 5, value: html_page56_1),
  ],
  category_ids: [
    @categories["faq/kurashi"].id, @categories["guide/okuyami"].id
  ],
  contact_state: "show", contact_group_id: g("シラサギ市/総務部/市民課").id,
  contact_group_relation: "related", group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page57.html", name: "社会福祉審議会について",
  layout_id: @layouts["pages"].id, form_id: @form4.id, keywords: %w(記事 健康・福祉 福祉・介護 よくある質問 子育て・教育),
  column_values: [
    @form_columns4[1].value_type.new(
      column: @form_columns4[1], order: 0,
      value: "社会福祉審議会は、社会福祉法に基づき、地域福祉の推進に関する重要な事項について審議・答申を行う附属機関です。
        本市の福祉施策が、公正かつ効果的に実施されることを目的とし、専門的かつ中立的な立場から意見を述べる役割を担っています。"
    ),
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 1, head: 'h2', text: '主な役割'),
    @form_columns4[7].value_type.new(
      column: @form_columns4[7], order: 2,
      lists: %w(
        地域福祉計画等に関する事項の審議
        社会福祉施設の設置・運営方針の検討
        介護・障害・子ども福祉等に関する意見聴取
      )
    )
  ],
  category_ids: [
    @categories["faq"].id, @categories["faq/kosodate"].id,
    @categories["faq/kenko"].id, @categories["guide/fukushi"].id,
    @categories["kenko"].id
  ],
  contact_state: "show", contact_group_relation: "related", group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page58.html", name: "児童手当について",
  layout_id: @layouts["pages"].id, form_id: @form4.id, keywords: %w(記事 子育て 子育て支援 子育て・教育),
  column_values: [
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 0, head: 'h2', text: '児童手当とは'),
    @form_columns4[0].value_type.new(
      column: @form_columns4[0], order: 1,
      value: '児童手当は、子どもを育てている家庭に支給される手当です。0歳から中学校卒業までの子どもが対象となります。'
    ),
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 2, head: 'h3', text: '支給方法'),
    @form_columns4[0].value_type.new(
      column: @form_columns4[0], order: 3,
      value: '児童手当は年数回に分けて支給されます。'
    ),
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 4, head: 'h3', text: '所得制限'),
    @form_columns4[0].value_type.new(
      column: @form_columns4[0], order: 5,
      value: '所得が一定以上の家庭には支給されない場合があります。'
    ),
    @form_columns4[2].value_type.new(column: @form_columns4[2], order: 6, head: 'h3', text: '申請方法'),
    @form_columns4[1].value_type.new(
      column: @form_columns4[1], order: 7,
      value: "児童手当の申請は、住んでいる市区町村の役場で行います。
        詳細は、各市区町村の福祉・子育て支援に関するページで確認できます。"
    )
  ],
  category_ids: [
    @categories["faq/kosodate"].id, @categories["guide/kosodate"].id,
    @categories["oshirase/kosodate"].id, @categories["kosodate/shien"].id
  ],
  contact_state: "show", contact_group_relation: "related", group_ids: [@g_seisaku.id]

#save_page route: "article/page", filename: "hinanjo-docs/page49.html", name: "小しらさぎ南公民館",
#  layout_id: @layouts["general"].id, form_id: @form8.id,
#  column_values: [
#    @form_columns8[0].value_type.new(column: @form_columns8[0], value: '南部'),
#    @form_columns8[1].value_type.new(column: @form_columns8[1], value: "000-0000"),
#    @form_columns8[2].value_type.new(column: @form_columns8[2], value: "大鷲県白鷺市小白鷺南町12-3")
#  ],
#  category_ids: [@categories["hinanjo/dosya"].id],
#  map_points: [
#    {
#      "name" => "小しらさぎ南公民館", "loc" => [134.560032, 33.974649], "text" => "",
#      "image" => 	"http://demo.devss6.web-tips.co.jp/img/ic-dosha.png"
#    }
#  ],
#  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
#  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
#  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
#  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
#  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
#  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

#save_page route: "article/page", filename: "hinanjo-docs/page50.html", name: "白鷺城展望台",
#  layout_id: @layouts["general"].id, form_id: @form8.id,
#  column_values: [
#    @form_columns8[0].value_type.new(column: @form_columns8[0], value: '北部'),
#    @form_columns8[1].value_type.new(column: @form_columns8[1], value: "000-0000"),
#    @form_columns8[2].value_type.new(column: @form_columns8[2], value: "大鷲県白鷺市白鷺23-1")
#  ],
#  category_ids: [@categories["hinanjo/thunami"].id],
#  map_points: [
#    {
#      "name" => "白鷺城展望台", "loc" => [134.449601, 34.047952], "text" => "",
#      "image" => "http://demo.devss6.web-tips.co.jp/img/ic-thunami.png"
#    }
#  ],
#  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
#  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
#  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
#  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
#  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
#  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

#save_page route: "article/page", filename: "hinanjo-docs/page51.html", name: "みらいシラサギ市民パーク",
#  layout_id: @layouts["general"].id, form_id: @form8.id,
#  column_values: [
#    @form_columns8[0].value_type.new(column: @form_columns8[0], value: '東部'),
#    @form_columns8[1].value_type.new(column: @form_columns8[1], value: "000-0000"),
#    @form_columns8[2].value_type.new(column: @form_columns8[2], value: "大鷲県白鷺市赤鷺町45−6")
#  ],
#  category_ids: [@categories["hinanjo/jishin"].id],
#  map_points: [
#    {
#      "name" => "みらいシラサギ市民パーク", "loc" => [134.53251, 34.038195], "text" => "",
#      "image" => "http://demo.devss6.web-tips.co.jp/img/ic-jishin.png"
#    }
#  ],
#  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
#  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
#  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
#  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
#  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
#  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "population/page52.html", name: "2022年10月3日",
  layout_id: @layouts["pages"].id, form_id: @form7.id,
  column_values: [
    @form_columns7[0].value_type.new(column: @form_columns7[0], value: '777777'),
    @form_columns7[1].value_type.new(column: @form_columns7[1], value: "123456"),
    @form_columns7[2].value_type.new(column: @form_columns7[2], value: "654321"),
    @form_columns7[3].value_type.new(column: @form_columns7[3], value: "9999")
  ],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "population/page53.html", name: "2022年9月1日",
  layout_id: @layouts["pages"].id, form_id: @form7.id,
  column_values: [
    @form_columns7[0].value_type.new(column: @form_columns7[0], value: '66666'),
    @form_columns7[1].value_type.new(column: @form_columns7[1], value: "12345"),
    @form_columns7[2].value_type.new(column: @form_columns7[2], value: "54321"),
    @form_columns7[3].value_type.new(column: @form_columns7[3], value: "1111")
  ],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "hinanjo-docs/dosya/page359.html", name: "シラサギ地域活動センター",
  layout_id: @layouts["general"].id, form_id: @form8.id,
  column_values: [
    @form_columns8[0].value_type.new(column: @form_columns8[0], value: "東部"),
    @form_columns8[1].value_type.new(column: @form_columns8[1], value: "2024ES000005"),
    @form_columns8[2].value_type.new(column: @form_columns8[2], value: "000-0004"),
    @form_columns8[3].value_type.new(column: @form_columns8[3], value: "シラサギ地域活動センター"),
    @form_columns8[4].value_type.new(column: @form_columns8[4], value: "シラサギチイキカツドウセンター"),
    @form_columns8[5].value_type.new(column: @form_columns8[5], value: "大鷲県シラサギ市小鷺町石井"),
    @form_columns8[6].value_type.new(column: @form_columns8[6], value: "0000-00-0000"),
    @form_columns8[7].value_type.new(column: @form_columns8[7], value: "525")
  ],
  category_ids: [@categories["hinanjo/dosya"].id],
  map_points: [{ name: "", loc: [134.575514, 34.065344], text: "" }]

save_page route: "article/page", filename: "hinanjo-docs/dosya/page361.html", name: "白鷺城展望台",
  layout_id: @layouts["general"].id, form_id: @form8.id,
  column_values: [
    @form_columns8[0].value_type.new(column: @form_columns8[0], value: "東部"),
    @form_columns8[1].value_type.new(column: @form_columns8[1], value: "2024ES000006"),
    @form_columns8[2].value_type.new(column: @form_columns8[2], value: "000-0005"),
    @form_columns8[3].value_type.new(column: @form_columns8[3], value: "白鷺城展望台"),
    @form_columns8[4].value_type.new(column: @form_columns8[4], value: "シラサギジョウテンボウダイ"),
    @form_columns8[5].value_type.new(column: @form_columns8[5], value: "大鷲県シラサギ市小鷺町石井"),
    @form_columns8[6].value_type.new(column: @form_columns8[6], value: "0000-00-0000"),
    @form_columns8[7].value_type.new(column: @form_columns8[7], value: "1625")
  ],
  category_ids: [@categories["hinanjo/dosya"].id],
  map_points: [{ name: "", loc: [134.577798, 34.063566], text: "" }]

save_page route: "article/page", filename: "hinanjo-docs/dosya/page362.html", name: "小しらさぎ南公民館",
  layout_id: @layouts["general"].id, form_id: @form8.id,
  column_values: [
    @form_columns8[0].value_type.new(column: @form_columns8[0], value: "南部"),
    @form_columns8[1].value_type.new(column: @form_columns8[1], value: "2024ES000009"),
    @form_columns8[2].value_type.new(column: @form_columns8[2], value: "000-0008"),
    @form_columns8[3].value_type.new(column: @form_columns8[3], value: "小しらさぎ南公民館"),
    @form_columns8[4].value_type.new(column: @form_columns8[4], value: "コシラサギミナミコウミンカイ"),
    @form_columns8[5].value_type.new(column: @form_columns8[5], value: "大鷲県シラサギ市南鷺町字中野"),
    @form_columns8[6].value_type.new(column: @form_columns8[6], value: "0000-00-0000"),
    @form_columns8[7].value_type.new(column: @form_columns8[7], value: "625")
  ],
  category_ids: [@categories["hinanjo/dosya"].id],
  map_points: [{ name: "", loc: [134.560032, 33.974649], text: "" }]

save_page route: "article/page", filename: "hinanjo-docs/jishin/page365.html", name: "小鷲西地域活動センター",
  layout_id: @layouts["general"].id, form_id: @form8.id,
  column_values: [
    @form_columns8[0].value_type.new(column: @form_columns8[0], value: "北部"),
    @form_columns8[1].value_type.new(column: @form_columns8[1], value: "2024ES000002"),
    @form_columns8[2].value_type.new(column: @form_columns8[2], value: "000-0001"),
    @form_columns8[3].value_type.new(column: @form_columns8[3], value: "小鷲西地域活動センター"),
    @form_columns8[4].value_type.new(column: @form_columns8[4], value: "コシラサギニシチイキカツドウセンター"),
    @form_columns8[5].value_type.new(column: @form_columns8[5], value: "大鷲県シラサギ市白鷺町字山瀬"),
    @form_columns8[6].value_type.new(column: @form_columns8[6], value: "0000-00-0000"),
    @form_columns8[7].value_type.new(column: @form_columns8[7], value: "1375")
  ],
  category_ids: [@categories["hinanjo/jishin"].id],
  map_points: [{ name: "", loc: [134.569323, 34.071022], text: "" }]

save_page route: "article/page", filename: "hinanjo-docs/jishin/page366.html", name: "小鷲北交流館",
  layout_id: @layouts["general"].id, form_id: @form8.id,
  column_values: [
    @form_columns8[0].value_type.new(column: @form_columns8[0], value: "東部"),
    @form_columns8[1].value_type.new(column: @form_columns8[1], value: "2024ES000004"),
    @form_columns8[2].value_type.new(column: @form_columns8[2], value: "000-0003"),
    @form_columns8[3].value_type.new(column: @form_columns8[3], value: "小鷲北交流館"),
    @form_columns8[4].value_type.new(column: @form_columns8[4], value: "コシラサギキタコウリュウカン"),
    @form_columns8[5].value_type.new(column: @form_columns8[5], value: "大鷲県シラサギ市小鷺町石井"),
    @form_columns8[6].value_type.new(column: @form_columns8[6], value: "0000-00-0000"),
    @form_columns8[7].value_type.new(column: @form_columns8[7], value: "825")
  ],
  category_ids: [@categories["hinanjo/jishin"].id],
  map_points: [{ name: "", loc: [134.574289, 34.064161], text: "" }]

save_page route: "article/page", filename: "hinanjo-docs/jishin/page367.html", name: "シラサギ防災交流センター",
  layout_id: @layouts["general"].id, form_id: @form8.id,
  column_values: [
    @form_columns8[0].value_type.new(column: @form_columns8[0], value: "南部"),
    @form_columns8[1].value_type.new(column: @form_columns8[1], value: "2024ES000007"),
    @form_columns8[2].value_type.new(column: @form_columns8[2], value: "000-0006"),
    @form_columns8[3].value_type.new(column: @form_columns8[3], value: "シラサギ防災交流センター"),
    @form_columns8[4].value_type.new(column: @form_columns8[4], value: "シラサギボウサイコウリュウセンター"),
    @form_columns8[5].value_type.new(column: @form_columns8[5], value: "大鷲県シラサギ市南鷺町字中野"),
    @form_columns8[6].value_type.new(column: @form_columns8[6], value: "0000-00-0000"),
    @form_columns8[7].value_type.new(column: @form_columns8[7], value: "125")
  ],
  category_ids: [@categories["hinanjo/jishin"].id],
  map_points: [{ name: "", loc: [134.577481, 34.064719], text: "" }]

save_page route: "article/page", filename: "hinanjo-docs/jishin/page368.html", name: "小鷲地域活動センター",
  layout_id: @layouts["general"].id, form_id: @form8.id,
  column_values: [
    @form_columns8[0].value_type.new(column: @form_columns8[0], value: "南部"),
    @form_columns8[1].value_type.new(column: @form_columns8[1], value: "2024ES000008"),
    @form_columns8[2].value_type.new(column: @form_columns8[2], value: "000-0007"),
    @form_columns8[3].value_type.new(column: @form_columns8[3], value: "小鷲地域活動センター"),
    @form_columns8[4].value_type.new(column: @form_columns8[4], value: "シラサギチイキカツドウセンター"),
    @form_columns8[5].value_type.new(column: @form_columns8[5], value: "大鷲県シラサギ市南鷺町字中野"),
    @form_columns8[6].value_type.new(column: @form_columns8[6], value: "0000-00-0000"),
    @form_columns8[7].value_type.new(column: @form_columns8[7], value: "600")
  ],
  category_ids: [@categories["hinanjo/jishin"].id],
  map_points: [{ name: "", loc: [134.577055, 34.065466], text: "" }]

save_page route: "article/page", filename: "hinanjo-docs/thunami/page360.html", name: "小鷲町市民サービスセンター",
  layout_id: @layouts["general"].id, form_id: @form8.id,
  column_values: [
    @form_columns8[0].value_type.new(column: @form_columns8[0], value: "北部"),
    @form_columns8[1].value_type.new(column: @form_columns8[1], value: "2024ES000001"),
    @form_columns8[2].value_type.new(column: @form_columns8[2], value: "000-0000"),
    @form_columns8[3].value_type.new(column: @form_columns8[3], value: "小鷲町市民サービスセンター"),
    @form_columns8[4].value_type.new(column: @form_columns8[4], value: "コシラサギチョウシミンサービスセンター"),
    @form_columns8[5].value_type.new(column: @form_columns8[5], value: "大鷲県シラサギ市白鷺町字山瀬"),
    @form_columns8[6].value_type.new(column: @form_columns8[6], value: "0000-00-0000"),
    @form_columns8[7].value_type.new(column: @form_columns8[7], value: "575")
  ],
  category_ids: [@categories["hinanjo/thunami"].id],
  map_points: [{ name: "", loc: [134.571645, 34.072568], text: "" }]

save_page route: "article/page", filename: "hinanjo-docs/thunami/page363.html", name: "小鷲東地域活動センター",
  layout_id: @layouts["general"].id, form_id: @form8.id,
  column_values: [
    @form_columns8[0].value_type.new(column: @form_columns8[0], value: "北部"),
    @form_columns8[1].value_type.new(column: @form_columns8[1], value: "2024ES000003"),
    @form_columns8[2].value_type.new(column: @form_columns8[2], value: "000-0002"),
    @form_columns8[3].value_type.new(column: @form_columns8[3], value: "小鷲東地域活動センター"),
    @form_columns8[4].value_type.new(column: @form_columns8[4], value: "コシラサギヒガシチイキカツドウセンター"),
    @form_columns8[5].value_type.new(column: @form_columns8[5], value: "大鷲県シラサギ市白鷺町字山瀬"),
    @form_columns8[6].value_type.new(column: @form_columns8[6], value: "0000-00-0000"),
    @form_columns8[7].value_type.new(column: @form_columns8[7], value: "850")
  ],
  category_ids: [@categories["hinanjo/thunami"].id],
  map_points: [{ name: "", loc: [134.569984, 34.066887], text: "" }]

save_page route: "article/page", filename: "hinanjo-docs/thunami/page364.html", name: "シラサギ市立中学校",
  layout_id: @layouts["general"].id, form_id: @form8.id,
  column_values: [
    @form_columns8[0].value_type.new(column: @form_columns8[0], value: "南部"),
    @form_columns8[1].value_type.new(column: @form_columns8[1], value: "2024ES000010"),
    @form_columns8[2].value_type.new(column: @form_columns8[2], value: "000-0009"),
    @form_columns8[3].value_type.new(column: @form_columns8[3], value: "シラサギ市立中学校"),
    @form_columns8[4].value_type.new(column: @form_columns8[4], value: "シラサギシリツチュウガッコウ"),
    @form_columns8[5].value_type.new(column: @form_columns8[5], value: "大鷲県シラサギ市南鷺町字中野"),
    @form_columns8[6].value_type.new(column: @form_columns8[6], value: "0000-00-0000"),
    @form_columns8[7].value_type.new(column: @form_columns8[7], value: "5500")
  ],
  category_ids: [@categories["hinanjo/thunami"].id],
  map_points: [{ name: "", loc: [134.580335, 34.066298], text: "" }]

save_page route: "article/page", filename: "watersupply/page349.html", name: "水道の使用開始手続き（開栓）",
  layout_id: @layouts["pages"].id, order: 10, keywords: %w(開始受付),
  category_ids: [
    @categories["faq/kurashi"].id, @categories["guide/hikkoshi"].id,
    @categories["kurashi/suido"].id, @categories["kurashi/sumai"].id
  ],
  contact_group_id: @contact_group_id, contact_group_relation: "related",
  group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "watersupply/page350.html", name: "水道の使用停止手続き（閉栓）",
  layout_id: @layouts["pages"].id, order: 20, keywords: %w(開始受付),
  category_ids: [
    @categories["faq/kurashi"].id, @categories["guide/hikkoshi"].id,
    @categories["kurashi/suido"].id, @categories["kurashi/sumai"].id
  ],
  contact_group_id: @contact_group_id, contact_group_relation: "related",
  group_ids: [@g_seisaku.id]
