FactoryBot.define do
  factory :gws_portal_group_setting, class: Gws::Portal::GroupSetting do
    cur_site { gws_site }
    cur_user { gws_user }

    name { cur_user.long_name }
    portal_group { cur_user.groups.first }
  end
end
