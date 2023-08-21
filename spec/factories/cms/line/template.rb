FactoryBot.define do
  factory :cms_line_template_text, class: Cms::Line::Template::Text do
    site { cms_site }
    order { 10 }
    text { unique_id }
  end

  factory :cms_line_template_image, class: Cms::Line::Template::Image do
    site { cms_site }
    order { 20 }
  end

  factory :cms_line_template_page, class: Cms::Line::Template::Page do
    site { cms_site }
    order { 30 }
    title { unique_id }
    summary { unique_id }
  end

  factory :cms_line_template_json_body, class: Cms::Line::Template::JsonBody do
    site { cms_site }
    order { 40 }
    json_body { '{ "type": "text", "text": "hello" }' }
  end
end
