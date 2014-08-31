FactoryGirl.define do
  factory :cms_member, class: Cms::Member, traits: [:ss_site, :ss_user] do
    sequence(:name) { |n| "name#{n}" }
    sequence(:email) { |n| "name#{n}@example.jp" }
    in_password "pass"
  end
end
