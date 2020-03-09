FactoryBot.define do
  factory :gws_schedule_plan, class: Gws::Schedule::Plan do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }
    member_ids { [gws_user.id] }
    start_at { Time.zone.now.change(hour: 10, minute: 0, second: 0) }
    end_at { start_at + 1.hour }
  end

  factory :gws_schedule_facility_plan, class: Gws::Schedule::Plan do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }
    member_ids { [gws_user.id] }
    start_at { Time.zone.now.change(hour: 10, minute: 0, second: 0) }
    end_at { start_at + 1.hour }
  end
end
