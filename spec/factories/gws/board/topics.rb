FactoryBot.define do
  factory :gws_board_topic, class: Gws::Board::Topic do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }
    category_ids [0]
  end
end
