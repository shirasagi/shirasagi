FactoryBot.define do
  factory :gws_staff_record_year, class: Gws::StaffRecord::Year do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "H29" }
    code { 2017 }
    start_date { Time.zone.now - 1.year }
    close_date { Time.zone.now + 1.year }
  end
end
