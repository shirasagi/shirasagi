FactoryBot.define do
  factory :gws_discussion_topic, class: Gws::Discussion::Topic do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }

    # forum {}
    # parent {}
  end
end
