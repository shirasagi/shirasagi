FactoryBot.define do
  factory :gws_affair2_overtime_workday_file, class: Gws::Affair2::Overtime::WorkdayFile do
    cur_site { gws_site }
    name { unique_id }
  end
end
