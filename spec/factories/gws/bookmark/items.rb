FactoryBot.define do
  factory :gws_bookmark_item, class: Gws::Bookmark::Item do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    url { "http://#{unique_id}.example.jp/" }
    bookmark_model { Gws::Bookmark::Item::BOOKMARK_MODEL_TYPES.sample }
    folder { gws_user.bookmark_root_folder(gws_site) }
  end
end
