FactoryBot.define do
  factory :board_post, class: Board::Post do
    cur_site { cms_site }
    name "post"
    poster "poster"
    email { unique_email }
    poster_url { unique_url }
    text "post"
    delete_key "pass"
  end
end
