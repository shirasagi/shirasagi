puts "# body_layouts"
contact_group = SS::Group.where(name: "シラサギ市/企画政策部/政策課").first
contact_group_id = contact_group.id rescue nil
@contact_email = contact_group_id ? "kikakuseisaku@example.jp" : nil
@contact_tel = contact_group_id ? "000-000-0000" : nil
@contact_fax = contact_group_id ? "000-000-0000" : nil
@contact_link_url = contact_group_id ? @link_url : nil
@contact_link_name = contact_group_id ? @link_url : nil

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
  parts: %W(本文1 本文2 本文3),
  site_id: @site.id
#save_page route: "article/page", filename: "docs/body_layout.html", name: "本文レイアウト",
#  layout_id: layouts["pages"].id, body_layout_id: body_layout.id, body_parts: %W(本文1 本文2 本文3),
#  contact_group_id: contact_group_id, contact_email: contact_email, contact_tel: contact_tel, contact_fax: contact_fax
