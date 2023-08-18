FactoryBot.define do
  factory :gws_affair_leave_setting, class: Gws::Affair::LeaveSetting do
    cur_site { gws_site }
    cur_user { gws_user }
    target_user { gws_user }
  end
end
