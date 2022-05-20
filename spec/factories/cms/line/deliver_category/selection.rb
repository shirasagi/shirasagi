FactoryBot.define do
  factory :cms_line_deliver_category_selection, class: Cms::Line::DeliverCategory::Selection do
    site { cms_site }
    name { unique_id }
  end
end
