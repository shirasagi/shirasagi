FactoryGirl.define do
  factory :gws_schedule_category, class: Gws::Schedule::Category do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    color { "#000000" }
  end
end
