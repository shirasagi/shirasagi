FactoryBot.define do
  factory :gws_workload_category, class: Gws::Workload::Category do
    cur_site { gws_site }
    cur_user { gws_user }

    name { unique_id }
    year { gws_site.fiscal_year }
    member_group_id { gws_user.gws_default_group.id }
  end
end
