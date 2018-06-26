require 'spec_helper'

describe "gws_portal_permissions", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }

  context "with auth", js: true do
    before { login_gws_user }

    it "visible portals" do
      visit gws_portal_path(site: site)
      expect(page).to have_content(user.name)

      visit gws_portal_user_path(site: site, user: user)
      expect(page).to have_content(user.name)
      visit gws_portal_user_layouts_path(site: site, user: user)
      expect(page).to have_content(user.name)
      visit gws_portal_user_portlets_path(site: site, user: user)
      expect(page).to have_content(user.name)
      visit gws_portal_user_settings_path(site: site, user: user)
      expect(page).to have_content(user.name)

      visit gws_portal_group_path(site: site, group: user.groups.first)
      expect(page).to have_content(user.name)
      visit gws_portal_group_layouts_path(site: site, group: user.groups.first)
      expect(page).to have_content(user.name)
      visit gws_portal_group_portlets_path(site: site, group: user.groups.first)
      expect(page).to have_content(user.name)
      visit gws_portal_group_settings_path(site: site, group: user.groups.first)
      expect(page).to have_content(user.name)

      visit gws_portal_group_path(site: site, group: site)
      expect(page).to have_content(user.name)
      visit gws_portal_group_layouts_path(site: site, group: site)
      expect(page).to have_content(user.name)
      visit gws_portal_group_portlets_path(site: site, group: site)
      expect(page).to have_content(user.name)
      visit gws_portal_group_settings_path(site: site, group: site)
      expect(page).to have_content(user.name)
    end

    it "secured portals" do
      role = user.gws_roles[0]
      role.update_attributes(permissions: [])
      user.clear_gws_role_permissions

      visit gws_portal_path(site: site)
      expect(page).to have_content(I18n.t('gws/portal.portlets.board.name'))

      visit gws_portal_user_path(site: site, user: user)
      expect(page).to have_content(I18n.t('gws/portal.portlets.board.name'))
      visit gws_portal_user_layouts_path(site: site, user: user)
      expect(page).to have_no_content(user.name)
      visit gws_portal_user_portlets_path(site: site, user: user)
      expect(page).to have_no_content(user.name)
      visit gws_portal_user_settings_path(site: site, user: user)
      expect(page).to have_no_content(user.name)

      visit gws_portal_group_path(site: site, group: user.groups.first)
      expect(page).to have_no_content(I18n.t('gws/portal.portlets.board.name'))
      visit gws_portal_group_layouts_path(site: site, group: user.groups.first)
      expect(page).to have_no_content(user.name)
      visit gws_portal_group_portlets_path(site: site, group: user.groups.first)
      expect(page).to have_no_content(user.name)
      visit gws_portal_group_settings_path(site: site, group: user.groups.first)
      expect(page).to have_no_content(user.name)

      visit gws_portal_group_path(site: site, group: site)
      expect(page).to have_no_content(I18n.t('gws/portal.portlets.board.name'))
      visit gws_portal_group_layouts_path(site: site, group: site)
      expect(page).to have_no_content(user.name)
      visit gws_portal_group_portlets_path(site: site, group: site)
      expect(page).to have_no_content(user.name)
      visit gws_portal_group_settings_path(site: site, group: site)
      expect(page).to have_no_content(user.name)
    end
  end
end
