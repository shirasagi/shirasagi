FactoryBot.define do
  trait :duty_hour do
    cur_site { gws_site }
    cur_user { gws_user }
    name { unique_id }
  end

  factory :gws_affair_duty_hour, class: Gws::Affair::DutyHour, traits: [:duty_hour] do
    affair_start_at_hour { 8 }
    affair_start_at_minute { 30 }
    affair_end_at_hour { 17 }
    affair_end_at_minute { 0 }
    affair_on_duty_working_minute { 360 }
    affair_on_duty_break_minute { 45 }
  end

  factory :gws_affair_duty_hour_short, class: Gws::Affair::DutyHour, traits: [:duty_hour] do
    affair_start_at_hour { 8 }
    affair_start_at_minute { 0 }
    affair_end_at_hour { 12 }
    affair_end_at_minute { 0 }
    affair_on_duty_working_minute { nil }
    affair_on_duty_break_minute { nil }
  end
end
