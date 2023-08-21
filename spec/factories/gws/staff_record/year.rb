FactoryBot.define do
  factory :gws_staff_record_year, class: Gws::StaffRecord::Year do
    cur_site { gws_site }
    cur_user { gws_user }

    name { Date.new(code, 4, 1).to_wareki_date.strftime("%Jy") + "年度" }
    code { 2017 }
    start_date { Date.new(code, 4, 1).in_time_zone }
    close_date { Date.new(code + 1, 3, 31).in_time_zone }
  end
end
