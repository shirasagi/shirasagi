FactoryGirl.define do
  factory :cms_role, class: Cms::Role, traits: [:ss_site, :ss_user] do
    sequence(:name) { |n| "name#{n}" }
    permissions ["release_private_cms_pages"]
    permission_level 1
  end
end
