FactoryBot.define do
  factory :gws_affair2_duty_setting, class: Gws::Affair2::DutySetting do
    cur_site { gws_site }
    cur_user { gws_user }
    name { unique_id }
    employee_type { "regular" }
    worktime_type { "constant" }
  end
end
