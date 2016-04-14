FactoryGirl.define do
  factory :gws_custom_group, class: Gws::CustomGroup do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    member_ids { [gws_user.id] }
  end
end
