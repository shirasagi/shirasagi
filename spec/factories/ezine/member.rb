FactoryGirl.define do
  factory :ezine_member, class: Ezine::Member do
    sequence(:email) { |n| "#{n}@example.jp" }
    email_type "text"
    state "enabled"
    site_id { cms_site.id }
  end
end
