FactoryGirl.define do
  factory :board_post, class: Board::Post do
    cur_site { cms_site }
    name "post"
    poster "poster"
    text "post"
    delete_key "pass"
  end
end
