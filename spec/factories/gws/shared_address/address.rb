FactoryBot.define do
  factory :gws_shared_address_address, class: Gws::SharedAddress::Address do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    kana { "kana-#{unique_id}" }
    email { "email-#{unique_id}@example.jp" }
  end
end
