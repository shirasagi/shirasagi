FactoryGirl.define do
  factory :gws_discussion_forum, class: Gws::Discussion::Forum do
    cur_site { gws_site }
    cur_user { gws_user }

    user_ids { [cur_user.id] }

    name { "name-#{unique_id}" }
  end
end
