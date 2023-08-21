FactoryBot.define do
  factory :gws_shared_address_group, class: Gws::SharedAddress::Group do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
  end
end
