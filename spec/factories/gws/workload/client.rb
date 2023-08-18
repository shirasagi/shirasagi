FactoryBot.define do
  factory :gws_workload_client, class: Gws::Workload::Client do
    cur_site { gws_site }
    cur_user { gws_user }

    name { unique_id }
    year { gws_site.fiscal_year }
  end
end
