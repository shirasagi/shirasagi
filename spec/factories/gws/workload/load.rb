FactoryBot.define do
  factory :gws_workload_load, class: Gws::Workload::Load do
    cur_site { gws_site }
    cur_user { gws_user }

    name { unique_id }
    year { gws_site.fiscal_year }
    coefficient { [166_320, 55_440, 27_720].sample }
  end
end
