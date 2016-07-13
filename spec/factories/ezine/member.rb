FactoryGirl.define do
  factory :ezine_member, class: Ezine::Member do
    sequence(:email) { |n| "#{n}@example.jp" }
    email_type "text"
    state "enabled"
    cur_site { cms_site }
    association :node, factory: :ezine_node_page
  end
end
