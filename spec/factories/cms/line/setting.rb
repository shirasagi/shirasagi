FactoryBot.define do
  factory :cms_line_setting, class: Cms::Line::Setting do
    site { cms_site }
  end
end
