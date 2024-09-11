# rubocop:disable Naming/VariableNumber

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

  item.attributes = data
  item.cur_user = @user
  item.save
  item.add_to_set group_ids: @site.group_ids

  item
end

save_page route: "article/page", filename: "docs/page1.html", name: "インフルエンザによる学級閉鎖状況",
  layout_id: @layouts["pages"].id, category_ids: [@categories["attention"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id],
  contact_sub_group_ids: @contact_sub_group_ids1
save_page route: "article/page", filename: "docs/page2.html", name: "コンビニ納付のお知らせ",
  layout_id: @layouts["pages"].id,
  category_ids: [@categories["attention"].id, @categories["shisei/soshiki"].id, @categories["shisei/soshiki/kikaku"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id],
  contact_sub_group_ids: @contact_sub_group_ids1
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
  layout_id: @layouts["pages"].id, category_ids: [@categories["attention"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id],
  contact_sub_group_ids: @contact_sub_group_ids1
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
  layout_id: @layouts["pages"].id, form_id: @form4.id,
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
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id],
  contact_sub_group_ids: @contact_sub_group_ids2
save_page route: "article/page", filename: "docs/page6.html", name: "還付金詐欺と思われる不審な電話にご注意ください",
  layout_id: @layouts["pages"].id,
  category_ids: [@categories["oshirase"].id, @categories["shisei/soshiki"].id, @categories["shisei/soshiki/kikaku"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id],
  contact_sub_group_ids: @contact_sub_group_ids2
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
  layout_id: @layouts["pages"].id, category_ids: [@categories["kurashi/koseki/jyumin"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page12.html", name: "転入届",
  layout_id: @layouts["pages"].id, category_ids: [@categories["kurashi/koseki/jyumin"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page13.html", name: "世帯または世帯主を変更するとき",
  layout_id: @layouts["pages"].id, category_ids: [@categories["kurashi/koseki/jyumin"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page14.html", name: "証明書発行窓口",
  layout_id: @layouts["pages"].id, category_ids: [@categories["kurashi/koseki/jyumin"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page15.html", name: "住民票記載事項証明書様式",
  layout_id: @layouts["pages"].id, category_ids: [@categories["kurashi/koseki/jyumin"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page16.html", name: "住所変更の証明書について",
  layout_id: @layouts["pages"].id, category_ids: [@categories["kurashi/koseki/jyumin"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page17.html", name: "住民票コードとは",
  layout_id: @layouts["pages"].id, category_ids: [@categories["kurashi/koseki/jyumin"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page18.html", name: "住民票コードの変更",
  layout_id: @layouts["pages"].id, category_ids: [@categories["kurashi/koseki/jyumin"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page19.html", name: "自動交付機・コンビニ交付サービスについて",
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
save_page route: "article/page", filename: "docs/tenkyo.html", name: "転居届", layout_id: @layouts["pages"].id,
  category_ids: [@categories["oshirase"].id, @categories["kurashi/koseki/jyumin"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]
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
  layout_id: @layouts["pages"].id, form_id: @form4.id,
  column_values: [
    @form_columns4[11].value_type.new(column: @form_columns4[11], order: 0, value: ''),
  ],
  category_ids: [
    @categories["oshirase"].id, @categories["oshirase/event"].id, @categories["oshirase/kanko"].id
  ],
  event_name: '小鷲町　ひまわり祭り',
  event_recurrences: [ recurrence ],
  event_deadline: Time.zone.now.advance(days: 1).change(hour: 11),
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name,
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
  layout_id: @layouts["pages"].id, form_id: @form4.id,
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
    @categories["kohoshi"].id, @categories["kohoshi/kongetsukoho"].id
  ],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

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
  layout_id: @layouts["pages"].id, form_id: @form4.id,
  category_ids: [@categories["kurashi"].id, @categories["kurashi/bosai"].id, @categories["kurashi/bosai/jyoho"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

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
  layout_id: @layouts["pages"].id, form_id: @form4.id,
  category_ids: [@categories["guide"].id, @categories["guide/kekkon"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page47.html", name: "離婚届（離婚するときの戸籍の届出）について",
  layout_id: @layouts["pages"].id, form_id: @form4.id,
  category_ids: [@categories["guide"].id, @categories["guide/kekkon"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page48.html", name: "シラサギ市結婚新生活支援事業（補助金）について",
  layout_id: @layouts["pages"].id, form_id: @form4.id,
  category_ids: [@categories["guide"].id, @categories["guide/kekkon"].id],
  contact_group_id: @contact_group_id, contact_group_contact_id: @contact.id, contact_group_relation: "related",
  contact_group_name: @contact.contact_group_name, contact_charge: @contact.contact_charge,
  contact_tel: @contact.contact_tel, contact_fax: @contact.contact_fax,
  contact_email: @contact.contact_email, contact_postal_code: @contact.contact_postal_code,
  contact_address: @contact.contact_address, contact_link_url: @contact.contact_link_url,
  contact_link_name: @contact.contact_link_name, group_ids: [@g_seisaku.id]

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

# rubocop:enable Naming/VariableNumber
