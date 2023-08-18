puts "# contrast"

def create_contrast(data)
  create_item(Gws::Contrast, data)
end

@site.menu_contrast_state = 'show'
@site.save

@contrast = [
  create_contrast(site_id: @site._id, name: '白/青', color: '#0066cc', text_color: '#ffffff', order: 10, state: "public"),
  create_contrast(site_id: @site._id, name: '白/黒', color: '#000000', text_color: '#ffffff', order: 20, state: "public")
]
