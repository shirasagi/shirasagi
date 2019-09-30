FactoryBot.define do
  factory :gws_affair_duty_calendar, class: Gws::Affair::DutyCalendar do
    cur_site { gws_site }
    cur_user { gws_user }
    name { unique_id }
    holiday_type { "system" }
  end
end
