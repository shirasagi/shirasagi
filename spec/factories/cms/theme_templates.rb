FactoryBot.define do
  factory :cms_theme_template, class: Cms::ThemeTemplate do
    transient do
      site { nil }
    end

    cur_site { site || cms_site }
    name { "name-#{unique_id}" }
    class_name { "class-#{unique_id}" }
    css_path { "/#{unique_id}/#{unique_id}" }
    order { rand(10..20) }
    state { %w(public closed).sample }
    default_theme { %w(enabled disabled).sample }
    high_contrast_mode { %w(enabled disabled).sample }
    font_color { unique_color }
    background_color { unique_color }
  end
end
