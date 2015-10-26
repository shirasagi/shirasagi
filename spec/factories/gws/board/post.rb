FactoryGirl.define do
  factory :gws_board_post, class: Gws::Board::Post do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }

    factory :gws_board_topic do
      parent nil
    end

    factory :gws_board_comment do
      association :parent, factory: :gws_board_topic
    end

    factory :gws_board_comment_to_comment do
      association :parent, factory: :gws_board_comment
    end
  end
end
