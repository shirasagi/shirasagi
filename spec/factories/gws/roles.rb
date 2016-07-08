FactoryGirl.define do
  trait :gws_role do
    cur_site { gws_site }
    cur_user { gws_user }
    name { "role-#{unique_id}" }
    permissions []
    permission_level 1
  end

  factory :gws_role, class: Gws::Role, traits: [:gws_role] do
  end
end
