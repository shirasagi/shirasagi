FactoryBot.define do
  factory :gws_staff_record_user, class: Gws::StaffRecord::User do
    cur_site { gws_site }
    cur_user { gws_user }

    #year_id { create(:gws_staff_record_year).id }
    #section_name { create(:gws_staff_record_group).name }

    name { "name-#{unique_id}" }
    code { "code-#{unique_id}" }
    order { rand(101..200) }
    kana { "kana-#{unique_id}" }
    section_name { "section_name-#{unique_id}" }
    section_order { rand(201..300) }
    tel_ext { "tel_ext-#{unique_id}" }
    charge_name { "charge_name-#{unique_id}" }
    charge_address { "charge_address-#{unique_id}" }
    charge_tel { "charge_tel-#{unique_id}" }
    divide_duties { Array.new(2) { "divide_duties-#{unique_id}" }.join("\n") }
    remark { Array.new(2) { "remark-#{unique_id}" }.join("\n") }
    staff_records_view { %w(show hide).sample }
    divide_duties_view { %w(show hide).sample }
  end
end
