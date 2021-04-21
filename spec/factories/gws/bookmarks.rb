FactoryBot.define do
  factory :gws_bookmark, class: Gws::Bookmark do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    url { "http://#{unique_id}.example.jp/" }
    bookmark_model { Gws::Bookmark::BOOKMARK_MODEL_TYPES.sample }
  end
end
