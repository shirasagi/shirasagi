FactoryBot.define do
  factory :gws_portal_user_setting, class: Gws::Portal::UserSetting do
    cur_site { gws_site }
    cur_user { gws_user }

    portal_user { cur_user }
  end
end
