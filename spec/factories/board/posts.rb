FactoryGirl.define do
  factory :board_post, class: Board::Post do
    site_id { cms_site.id }
    name "post"
    poster "poster"
    text "post"
    delete_key "pass"
  end
end
