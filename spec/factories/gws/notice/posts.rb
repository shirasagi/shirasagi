FactoryBot.define do
  factory :gws_notice_post, class: Gws::Notice::Post do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }
  end
end
