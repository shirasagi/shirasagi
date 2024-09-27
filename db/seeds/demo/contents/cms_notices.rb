def save_cms_notice(data)
  puts data[:name]
  cond = { site_id: data[:site_id], name: data[:name] }

  item = Cms::Notice.find_or_create_by(cond)
  item.attributes = data
  item.update
  item
end

puts "# cms_notices"
html = [
  "<p>下記の日時にホームページのメンテナンスを行います。</p>",
  "<p><strong>管理画面にアクセスできなくなりますのでご注意ください。</strong></p>",
  "<p>⚪︎月⚪︎⚪︎日（水）18:00 ~</p>"].join("\n")
save_cms_notice name: "⚪︎月⚪︎⚪︎日18:00 ~　メンテナンスのお知らせ", site_id: @site.id,
  notice_severity: Cms::Notice::NOTICE_SEVERITY_HIGH, html: html

html = [
  "<p>シラサギ公式サイトの",
  "<a href=\"https://www.ss-proj.org/download/manual.html\">オンラインマニュアル</a>",
  "をご確認ください。</p>"].join("\n")
save_cms_notice name: "操作方法マニュアル", site_id: @site.id,
  notice_severity: Cms::Notice::NOTICE_SEVERITY_NORMAL, html: html
