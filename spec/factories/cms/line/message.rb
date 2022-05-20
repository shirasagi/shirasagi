FactoryBot.define do
  factory :cms_line_message, class: Cms::Line::Message do
    site { cms_site }
    name { unique_id }
    deliver_condition_state { "multicast_with_no_condition" }
  end
end
