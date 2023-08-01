puts "# faq"

save_page route: "faq/page", filename: "faq/docs/page29.html", name: "休日や夜間の戸籍の届出について",
  layout_id: @layouts["faq"].id, category_ids: [@categories["faq"].id, @categories["faq/kurashi"].id],
  question: "<p>休日や夜間でも戸籍の届出は可能でしょうか。</p>",
  html: "<p>戸籍の届け出は24時間、年中無休で受け付けております。<br />業務時間外の届け出は当直室にてお預かりしております。</p>"
