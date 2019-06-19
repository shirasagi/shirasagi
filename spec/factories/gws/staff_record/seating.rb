FactoryBot.define do
  factory :gws_staff_record_seating, class: Gws::StaffRecord::Seating do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    url { 'http://example.jp' }
    remark { "remark-#{unique_id}" }
  end
end
