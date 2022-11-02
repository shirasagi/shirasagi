FactoryBot.define do
  factory :gws_workload_load, class: Gws::Workload::Load do
    cur_site { gws_site }
    cur_user { gws_user }

    name { unique_id }
    year { gws_site.fiscal_year }
    coefficient { [166320, 55440, 27720].sample }
  end
end
