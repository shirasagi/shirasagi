FactoryGirl.define do
  factory :cms_theme_template, class: Cms::ThemeTemplate do
    transient do
      site nil
    end

    cur_site { site ? site : cms_site }
    name { "name-#{unique_id}" }
    class_name { "class-#{unique_id}" }
  end
end
