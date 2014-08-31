FactoryGirl.define do
  factory :cms_layout, class: Cms::Layout, traits: [:ss_site, :ss_user] do
    sequence(:name) { |n| "name#{n}" }
    sequence(:filename) { |n| "file#{n}.layout.html" }
  end
end
