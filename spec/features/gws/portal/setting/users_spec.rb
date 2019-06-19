require 'spec_helper'

describe "gws_portal_setting_users", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      visit gws_portal_path(site: site)
      expect(page).to have_no_content(I18n.t('gws/portal.user_portal'))

      visit gws_portal_user_path(site: site, user: user)
      expect(page).to have_content(I18n.t('gws/portal.user_portal'))

      visit gws_portal_setting_users_path(site: site)
      expect(page).to have_content(user.name)

      # secured
      role = user.gws_roles[0]
      role.update_attributes(permissions: [])
      user.clear_gws_role_permissions

      visit gws_site_path(site: site)
      expect(page).to have_no_content(I18n.t('gws/portal.user_portal'))

      visit gws_portal_setting_users_path(site: site)
      expect(page).to have_no_content(user.name)
    end
  end
end
