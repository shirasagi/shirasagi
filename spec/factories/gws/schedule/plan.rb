FactoryGirl.define do
  factory :gws_schedule_plan, class: Gws::Schedule::Plan do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }
    member_ids { [gws_user.id] }
  end

  factory :gws_schedule_facility_plan, class: Gws::Schedule::Plan do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }
    member_ids { [gws_user.id] }
    start_at { Time.zone.now }
    end_at { Time.zone.now + 5.minutes }
  end
end
