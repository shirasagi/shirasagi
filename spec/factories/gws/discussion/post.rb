FactoryBot.define do
  factory :gws_discussion_post, class: Gws::Discussion::Post do
    cur_site { gws_site }
    cur_user { gws_user }

    name { topic.name }
    text { "text-#{unique_id}" }

    # topic {}
    # parent {}
  end
end
