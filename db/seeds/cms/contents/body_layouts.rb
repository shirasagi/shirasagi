puts "# body_layouts"

def save_body_layouts(data)
  puts data[:name]
  cond = { site_id: data[:site_id], node_id: data[:node_id], name: data[:name], poster: data[:poster] }
  item = Cms::BodyLayout.where(cond).first || Cms::BodyLayout.new
  item.attributes = data
  item.save

  item
end

body_layout_html = File.read("body_layouts/layout.layout.html") rescue nil
body_layout = save_body_layouts name: "本文レイアウト",
  html: body_layout_html,
  parts: %w(本文1 本文2 本文3),
  site_id: @site.id
#save_page route: "article/page", filename: "docs/body_layout.html", name: "本文レイアウト",
#  layout_id: layouts["pages"].id, body_layout_id: body_layout.id, body_parts: %W(本文1 本文2 本文3),
#  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
