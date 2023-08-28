FactoryBot.define do
  factory :gws_workload_work_comment, class: Gws::Workload::WorkComment do
    cur_site { gws_site }
    cur_user { gws_user }

    text { unique_id }
  end
end
