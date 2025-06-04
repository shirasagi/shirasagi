FactoryBot.define do
  factory :gws_affair2_special_leave, class: Gws::Affair2::SpecialLeave do
    cur_site { gws_site }
    cur_user { gws_user }
    name { unique_id }
  end
end
