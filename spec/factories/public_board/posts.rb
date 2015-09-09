FactoryGirl.define do
  factory :public_board_post, class: PublicBoard::Post do
    site_id { cms_site.id }
    name "post"
    poster "poster"
    text "post"
    delete_key "pass"
  end
end
