FactoryBot.define do
  factory :gws_affair2_attendance_setting, class: Gws::Affair2::AttendanceSetting do
    cur_site { gws_site }
    cur_user { gws_user }
    in_start_year { Time.zone.today.year }
    in_start_month { Time.zone.today.month }
  end
end
