FactoryBot.define do
  factory :cms_line_richmenu_group, class: Cms::Line::Richmenu::Group do
    site { cms_site }
    name { unique_id }
    state { "public" }
  end
end
