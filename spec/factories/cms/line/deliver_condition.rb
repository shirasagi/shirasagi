FactoryBot.define do
  factory :cms_line_deliver_condition, class: Cms::Line::DeliverCondition do
    site { cms_site }
    name { unique_id }
  end
end
