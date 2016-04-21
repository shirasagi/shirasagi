FactoryGirl.define do
  factory :gws_board_category, class: Gws::Board::Category do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    color { "#aabbcc" }
  end
end
