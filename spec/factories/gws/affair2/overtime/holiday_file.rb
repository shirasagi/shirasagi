FactoryBot.define do
  factory :gws_affair2_overtime_holiday_file, class: Gws::Affair2::Overtime::HolidayFile do
    cur_site { gws_site }
    name { unique_id }
  end
end
