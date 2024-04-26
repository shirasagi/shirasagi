FactoryBot.define do
  factory :gws_discussion_post, class: Gws::Discussion::Post do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }

    # topic {}
    # parent {}
  end
end
