FactoryGirl.define do
  factory :gws_schedule_holiday, class: Gws::Schedule::Holiday do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
  end
end
