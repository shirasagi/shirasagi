FactoryBot.define do
  factory :gws_affair2_attendance_time_card, class: Gws::Affair2::Attendance::TimeCard do
    cur_site { gws_site }
    cur_user { gws_user }
    date { Time.zone.today.beginning_of_month }
  end
end
