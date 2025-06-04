FactoryBot.define do
  factory :gws_affair2_leave_setting, class: Gws::Affair2::LeaveSetting do
    cur_site { gws_site }
    cur_user { gws_user }
    name { unique_id }
  end
end
