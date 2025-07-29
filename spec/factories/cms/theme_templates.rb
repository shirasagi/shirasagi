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

    trait :cms_theme_template_white do
      name { "白" }
      class_name { "white" }
      high_contrast_mode { "disabled" }
      font_color { nil }
      background_color { nil }
      css_path { nil }
    end

    trait :cms_theme_template_blue do
      name { "青" }
      class_name { "blue" }
      high_contrast_mode { "enabled" }
      font_color { "#fff" }
      background_color { "#06c" }
      css_path { nil }
    end

    trait :cms_theme_template_black do
      name { "黒" }
      class_name { "black" }
      high_contrast_mode { "disabled" }
      font_color { nil }
      background_color { nil }
      css_path { "/css/black.css" }
    end
  end
end
