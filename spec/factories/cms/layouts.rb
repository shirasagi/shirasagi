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
        </head>
        <body>
          </ yield />
        </body>
        </html>
      HTML
    end
  end

  factory :cms_layout_with_title, class: Cms::Layout, traits: [:cms_layout] do
    name { "プレビュー用レイアウト" }
    html do
      <<~HTML
        <html>
        <head>
          <meta charset="UTF-8" />
          <title><%= @window_name %></title>
        </head>
        <body>
          <h1><%= @window_name %></h1>
          </ yield />
        </body>
        </html>
      HTML
    end
  end
end
