FactoryBot.define do
  trait :cms_layout do
    cur_site { cms_site }
    cur_user { cms_user }
    name { unique_id.to_s }
    filename { "#{unique_id}.layout.html" }
    html { "<html><head></head><body></ yield /></body></html>" }
  end

  factory :cms_layout, class: Cms::Layout, traits: [:cms_layout] do
    factory :cms_layout_basename_invalid do
      basename { "lay/out" }
    end
  end

  factory :cms_layout_with_meta, class: Cms::Layout, traits: [:cms_layout] do
    html do
      <<~HTML
        <html>
        <head>
          <meta charset="UTF-8" />
          <title>#{name}</title>
          <!-- メタタグは自動的に挿入される位置 -->
        </head>
        <body>
          </ yield />
        </body>
        </html>
      HTML
    end
  end
end
