FactoryBot.define do
  factory :gws_staff_record_user, class: Gws::StaffRecord::User do
    cur_site { gws_site }
    cur_user { gws_user }

    #year_id { create(:gws_staff_record_year).id }
    #section_name { create(:gws_staff_record_group).name }

    name { "name-#{unique_id}" }
    code { "code-#{unique_id}" }
    kana { "kana-#{unique_id}" }
    tel_ext { "tel_ext-#{unique_id}" }
    charge_name { "charge_name-#{unique_id}" }
    charge_address { "charge_address-#{unique_id}" }
    charge_tel { "charge_tel-#{unique_id}" }
    divide_duties { "divide_duties-#{unique_id}" }
    remark { "remark-#{unique_id}" }
  end
end
