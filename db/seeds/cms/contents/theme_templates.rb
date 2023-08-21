def save_theme_template(data)
  puts data[:class_name]
  cond = { site_id: data[:site_id], name: data[:class_name] }

  item = Cms::ThemeTemplate.find_or_create_by(cond)
  item.attributes = data
  item.update

  item
end

puts "# theme_templates"
save_theme_template class_name: "white", name: "白", order: 0, state: "public", site_id: @site.id,
  high_contrast_mode: "disabled"
save_theme_template class_name: "blue", name: "青", order: 10, state: "public", site_id: @site.id,
  high_contrast_mode: "enabled", font_color: '#FFFFFF', background_color: '#0066CC'
save_theme_template class_name: "black", name: "黒", order: 20, state: "public", site_id: @site.id,
  high_contrast_mode: "disabled", css_path: "/css/black.css"
