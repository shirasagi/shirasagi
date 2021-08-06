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
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page2.html", name: "コンビニ納付のお知らせ",
          layout_id: @layouts["oshirase"].id,
          category_ids: [@categories["attention"].id, @categories["shisei/soshiki"].id, @categories["shisei/soshiki/kikaku"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page3.html", name: "平成26年第1回シラサギ市議会定例会を開催します",
          layout_id: @layouts["oshirase"].id, category_ids: [@categories["attention"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page4.html", name: "放射性物質・震災関連情報",
          layout_id: @layouts["oshirase"].id, category_ids: [@categories["attention"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page5.html", name: "市内の微小粒子状物質（PM2.5）の測定データ（速報値）を公開しています。",
          layout_id: @layouts["oshirase"].id, category_ids: [@categories["attention"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page6.html", name: "還付金詐欺と思われる不審な電話にご注意ください",
          layout_id: @layouts["oshirase"].id,
          category_ids: [@categories["oshirase"].id, @categories["shisei/soshiki"].id, @categories["shisei/soshiki/kikaku"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page7.html", name: "平成26年度　シラサギ市システム構築に係るの公募型企画競争",
          layout_id: @layouts["oshirase"].id,
          category_ids: [@categories["oshirase"].id, @categories["shisei/soshiki"].id, @categories["shisei/soshiki/kikaku"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page8.html", name: "冬の感染症に備えましょう",
          layout_id: @layouts["oshirase"].id, category_ids: [@categories["oshirase"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page9.html", name: "広報SHIRASAGI3月号を掲載",
          layout_id: @layouts["oshirase"].id,
          category_ids: [@categories["oshirase"].id,
                         @categories["oshirase/kurashi"].id,
                         @categories["shisei/soshiki"].id,
                         @categories["shisei/soshiki/kikaku"].id,
          ],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page10.html", name: "インフルエンザ流行警報がでています",
          layout_id: @layouts["oshirase"].id, category_ids: [@categories["oshirase"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page11.html", name: "転出届", gravatar_screen_name: "サイト管理者",
          layout_id: @layouts["pages"].id, category_ids: [@categories["kurashi/koseki/jyumin"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page12.html", name: "転入届",
          layout_id: @layouts["pages"].id, category_ids: [@categories["kurashi/koseki/jyumin"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page13.html", name: "世帯または世帯主を変更するとき",
          layout_id: @layouts["pages"].id, category_ids: [@categories["kurashi/koseki/jyumin"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page14.html", name: "証明書発行窓口",
          layout_id: @layouts["pages"].id, category_ids: [@categories["kurashi/koseki/jyumin"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page15.html", name: "住民票記載事項証明書様式",
          layout_id: @layouts["pages"].id, category_ids: [@categories["kurashi/koseki/jyumin"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page16.html", name: "住所変更の証明書について",
          layout_id: @layouts["pages"].id, category_ids: [@categories["kurashi/koseki/jyumin"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page17.html", name: "住民票コードとは",
          layout_id: @layouts["pages"].id, category_ids: [@categories["kurashi/koseki/jyumin"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page18.html", name: "住民票コードの変更",
          layout_id: @layouts["pages"].id, category_ids: [@categories["kurashi/koseki/jyumin"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/page19.html", name: "自動交付機・コンビニ交付サービスについて",
          layout_id: @layouts["pages"].id,
          category_ids: [@categories["oshirase"].id,
                         @categories["oshirase/kurashi"].id,
                         @categories["shisei/soshiki"].id,
                         @categories["shisei/soshiki/kikaku"].id,
          ],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "docs/tenkyo.html", name: "転居届",
          layout_id: @layouts["pages"].id, category_ids: [@categories["kurashi/koseki/jyumin"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "oshirase/kurashi/page20.html", name: "犬・猫を譲り受けたい方",
          layout_id: @layouts["oshirase"].id, category_ids: [@categories["oshirase"].id, @categories["oshirase/kurashi"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "oshirase/kurashi/page21.html", name: "平成26年度住宅補助金の募集について掲載しました。",
          layout_id: @layouts["oshirase"].id, category_ids: [@categories["oshirase"].id, @categories["oshirase/kurashi"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "oshirase/kurashi/page22.html", name: "休日臨時窓口を開設します。",
          layout_id: @layouts["oshirase"].id,
          category_ids: [@categories["oshirase"].id,
                         @categories["oshirase/kurashi"].id,
                         @categories["shisei/soshiki"].id,
                         @categories["shisei/soshiki/kikaku"].id,
          ],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "oshirase/kurashi/page23.html", name: "身体障害者手帳の認定基準が変更",
          layout_id: @layouts["oshirase"].id, category_ids: [@categories["oshirase"].id, @categories["oshirase/kurashi"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "oshirase/kurashi/page24.html", name: "平成26年4月より国民健康保険税率が改正されます",
          layout_id: @layouts["oshirase"].id,
          category_ids: [@categories["oshirase"].id,
                         @categories["oshirase/kurashi"].id,
          ],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "urgency/page25.html", name: "黒鷺県沖で発生した地震による当市への影響について。",
          layout_id: @layouts["oshirase"].id, category_ids: [@categories["urgency"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]
save_page route: "article/page", filename: "urgency/page26.html", name: "黒鷺県沖で発生した地震による津波被害について。",
          layout_id: @layouts["more"].id, category_ids: [@categories["urgency"].id],
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id]

file_1 = save_ss_files "ss_files/article/pdf_file.pdf", filename: "pdf_file.pdf", model: "article/page"
file_2 = save_ss_files "ss_files/key_visual/keyvisual01.jpg", filename: "keyvisual01.jpg", name: "画像1", model: "article/page"
file_3 = save_ss_files "ss_files/key_visual/keyvisual02.jpg", filename: "keyvisual02.jpg", name: "画像2", model: "article/page"
file_4 = save_ss_files "ss_files/key_visual/keyvisual03.jpg", filename: "keyvisual03.jpg", name: "画像3", model: "article/page"
file_5 = save_ss_files "ss_files/key_visual/keyvisual04.jpg", filename: "keyvisual04.jpg", name: "画像4", model: "article/page"
file_6 = save_ss_files "ss_files/key_visual/keyvisual05.jpg", filename: "keyvisual05.jpg", name: "画像5", model: "article/page"
html = []
html << '<p><a class="icon-pdf" href="' + file_1.url + '">サンプルファイル (PDF 783KB)</a></p>'
html << '<p>'
[file_2, file_3, file_4, file_5, file_6].each do |file|
  html << '<a alt="' + file.name + '" href="' + file.url + '" target="_blank" rel="noopener">'
  html << '<img alt="' + file.name + '" src="' + file.thumb_url + '" title="' + file.filename + '" />'
  html << '</a>'
end
html << '</p>'
dates = (Time.zone.tomorrow..(Time.zone.tomorrow + 10)).map { |d| d.mongoize }
save_page route: "article/page", filename: "docs/page27.html", name: "ふれあいフェスティバル",
          layout_id: @layouts["oshirase"].id, event_dates: dates,
          category_ids: [@categories["oshirase"].id,
                         @categories["oshirase/event"].id,
                         @categories["shisei/soshiki"].id,
                         @categories["shisei/soshiki/kikaku"].id,
          ],
          file_ids: [file_1.id, file_2.id, file_3.id, file_4.id, file_5.id, file_6.id], html: html.join("\n"),
          contact_group_id: @contact_group_id, contact_email: @contact_email, contact_tel: @contact_tel,
          contact_fax: @contact_fax, contact_link_url: @contact_link_url, contact_link_name: @contact_link_name,
          group_ids: [@g_seisaku.id, @g_koho.id]
dates = (Time.zone.today..(Time.zone.today + 20)).map { |d| d.mongoize }
save_page route: "event/page", filename: "calendar/page28.html", name: "住民相談会を開催します。",
          layout_id: @layouts["event"].id, category_ids: [@categories["calendar/kohen"].id], event_dates: dates,
          schedule: "〇〇年○月〇日", venue: "○○○○○○○○○○", cost: "○○○○○○○○○○",
          content: "○○○○○○○○○○○○○○○○○○○○", related_url: @link_url,
          group_ids: [@g_seisaku.id]

file_7 = save_ss_files "ss_files/key_visual/keyvisual01.jpg", filename: "keyvisual01.jpg", name: "keyvisual01.jpg",
                       model: "ss/temp_file"
file_8 = save_ss_files "ss_files/key_visual/keyvisual02.jpg", filename: "keyvisual02.jpg", name: "keyvisual02.jpg",
                       model: "ss/temp_file"
file_9 = save_ss_files "ss_files/key_visual/keyvisual03.jpg", filename: "keyvisual03.jpg", name: "keyvisual03.jpg",
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
file_22 = save_ss_files "ss_files/article/file_9.pdf", filename: "file_9.pdf", name: "広報SHIRASAGI 2019年1月号 ", model: "ss/temp_file"
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
          map_points: [{ "name" => "", "loc" => [35.7186823, 139.7741203], "text" => "" }],
          group_ids: [@g_seisaku.id]

save_page route: "article/page", filename: "docs/page30.html", name: "ふれあいフェスティバル開催報告",
          layout_id: @layouts["pages"].id, form_id: @form2.id, keywords: "記事, イベント", released: '2019/01/30 10:52',
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

# rubocop:enable Naming/VariableNumber
