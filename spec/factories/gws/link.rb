FactoryBot.define do
  factory :gws_link, class: Gws::Link do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    links { [ { "name" => "SHIRASAGI", "url" => "http://ss-proj.org/" } ] }
  end
end
