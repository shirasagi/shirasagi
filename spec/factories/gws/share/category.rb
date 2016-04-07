FactoryGirl.define do
  factory :gws_share_category, class: Gws::Share::Category do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    color { "#556677" }
    target { "all" }
  end
end
