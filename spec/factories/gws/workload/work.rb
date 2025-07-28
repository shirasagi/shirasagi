FactoryBot.define do
  factory :gws_workload_work, class: Gws::Workload::Work do
    cur_site { gws_site }
    cur_user { gws_user }

    name { unique_id }
    year { gws_site.fiscal_year }
    due_date { Time.zone.today + 7 }
    due_start_on { Time.zone.today }
    due_end_on { Time.zone.today + 7 }

    member_group_id { gws_user.gws_default_group.id }
    member_ids { [ gws_user.id ] }
    readable_group_ids { [ gws_user.gws_default_group.id] }
    group_ids { [ gws_user.gws_default_group.id ] }
  end
end
