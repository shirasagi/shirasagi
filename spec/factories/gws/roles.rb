FactoryGirl.define do
  trait :gws_role do
    site_id { gws_site.id }
    user_id { gws_user.id }
    name { "role-#{unique_id}" }
    permissions []
    permission_level 1
  end

  factory :gws_role, class: Gws::Role, traits: [:gws_role] do
  end
end
