FactoryGirl.define do
  trait :cms_role do
    site_id { cms_site.id }
    user_id { cms_user.id }
    name "cms_role"
    permissions []
    permission_level 1
  end

  factory :cms_role, class: Cms::Role, traits: [:cms_role] do
    permissions ["release_private_cms_pages"]
  end

  factory :cms_user_role, class: Cms::Role do
    name "cms_user_role"
    permissions Cms::Role.permission_names
    site_id 1
  end
end
