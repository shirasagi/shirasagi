FactoryGirl.define do
  factory :cms_page, class: Cms::Page, traits: [:ss_site, :ss_user] do
    sequence(:name) { |n| "name#{n}" }
    sequence(:filename) { |n| "file#{n}.html" }
    route "cms/page"
  end
end
