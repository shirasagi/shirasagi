FactoryBot.define do
  factory :gws_discussion_forum, class: Gws::Discussion::Forum do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }

    member_ids { [cur_user.id] }
    user_ids { [cur_user.id] }
  end
end
