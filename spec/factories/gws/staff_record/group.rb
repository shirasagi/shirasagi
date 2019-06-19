FactoryBot.define do
  factory :gws_staff_record_group, class: Gws::StaffRecord::Group do
    cur_site { gws_site }
    cur_user { gws_user }

    #year_id { create(:gws_staff_record_year).id }

    name { "name-#{unique_id}" }
    seating_chart_url { 'http://example.jp' }
  end
end
