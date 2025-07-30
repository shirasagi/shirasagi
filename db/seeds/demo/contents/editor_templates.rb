def save_editor_template(data)
  puts data[:name]
  cond = { site_id: data[:site_id], name: data[:name] }

  item = Cms::EditorTemplate.find_or_create_by(cond)
  item.attributes = data
  item.update

  item
end

puts "# editor_templates"
thumb_column2 = save_ss_files("editor_templates/column2.png", filename: "column2.png", model: "cms/editor_template")
thumb_column3 = save_ss_files("editor_templates/column3.png", filename: "column3.png", model: "cms/editor_template")
thumb_left = save_ss_files("editor_templates/float-left.jpg", filename: "float-left.jpg", model: "cms/editor_template")
thumb_right = save_ss_files("editor_templates/float-right.jpg", filename: "float-right.jpg", model: "cms/editor_template")

editor_template_html = File.read("editor_templates/column2.html") rescue nil
save_editor_template name: "画像（2カラム）",
  description: "画像を横並びで２枚並べます。ダミー画像を選択後、ファイルから貼り付けたい画像を「画像貼付」してください。",
  html: editor_template_html, thumb_id: thumb_column2.id, order: 10, site_id: @site.id

editor_template_html = File.read("editor_templates/column3.html") rescue nil
save_editor_template name: "画像（3カラム）",
  description: "画像を横並びで3枚並べます。ダミー画像を選択後、ファイルから貼り付けたい画像を「画像貼付」してください。",
  html: editor_template_html, thumb_id: thumb_column3.id, order: 20, site_id: @site.id

editor_template_html = File.read("editor_templates/float-left.html") rescue nil
save_editor_template name: "画像左回り込み",
  description: "画像が左に回り込み右側がテキストになります",
  html: editor_template_html, thumb_id: thumb_left.id, order: 30, site_id: @site.id

editor_template_html = File.read("editor_templates/float-right.html") rescue nil
save_editor_template name: "画像右回り込み",
  description: "画像が右に回り込み左側がテキストになります",
  html: editor_template_html, thumb_id: thumb_right.id, order: 40, site_id: @site.id

editor_template_html = File.read("editor_templates/clear.html") rescue nil
save_editor_template name: "回り込み解除",
  description: "回り込みを解除します",
  html: editor_template_html, order: 30, site_id: @site.id
