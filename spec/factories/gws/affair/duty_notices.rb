FactoryBot.define do
  factory :gws_affair_duty_notice, class: Gws::Affair::DutyNotice do
    cur_site { gws_site }
    cur_user { gws_user }
    name { unique_id }
    notice_type { "month_time_limit" }
    threshold_hour { 60 }
    body { unique_id }
  end
end
