puts "# faq"

save_page route: "faq/page", filename: "faq/docs/page29.html", name: "休日や夜間の戸籍の届出について",
  layout_id: @layouts["faq"].id, category_ids: [@categories["faq"].id, @categories["faq/kurashi"].id],
  question: "<p>休日や夜間でも戸籍の届出は可能でしょうか。</p>",
  html: "<p>戸籍の届け出は24時間、年中無休で受け付けております。<br />業務時間外の届け出は当直室にてお預かりしております。</p>"

file = save_ss_files "files/img/dummy.png", filename: "dummy.png", name: "dummy.png", model: "ss/temp_file"
html = []
html << '<p>回答内容</p>'
html << "<p><img alt=\"#{file.name}\" src=\"#{file.url}\" /></p>"
html = html.join
save_page route: "faq/page", filename: "faq/docs/page30.html", name: "海や河川で魚などをとりたい。",
  layout_id: @layouts["faq"].id, file_ids: [file.id],
  category_ids: [
    @categories["faq"].id, @categories["faq/kurashi"].id, @categories["faq/kosodate"].id, @categories["faq/kenko"].id,
    @categories["faq/kanko"].id, @categories["faq/sangyo"].id, @categories["faq/shisei"].id
  ],
  question: "<p>海や河川で魚などをとりたい。</p>",
  html: html

save_page route: "faq/page", filename: "faq/docs/page31.html",
  name: "道路上で動物（犬・猫等）が死んでいます。どこに連絡すればよいでしょうか。", layout_id: @layouts["faq"].id,
  category_ids: [@categories["faq"].id, @categories["faq/kurashi"].id],
  question: "<p>道路上で動物（犬・猫等）が死んでいます。どこに連絡すればよいでしょうか。</p>",
  html: '<p>回答内容</p>'
