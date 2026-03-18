FactoryBot.define do
  factory :gws_portal_group_setting, class: Gws::Portal::GroupSetting do
    cur_site { gws_site }
    cur_user { gws_user }

    name do
      group = cur_user.groups.first
      group.organization? ? I18n.t("gws/portal.tabs.root_portal") : group.trailing_name.truncate(20)
    end
    portal_group { cur_user.groups.first }
  end
end
