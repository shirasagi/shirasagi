require 'spec_helper'

describe "gws_portal_user_portal", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { create :gws_user }
  let(:index_path) { gws_portal_user_path(site: site, user: user) }

  context "with auth" do
    before do
      login_gws_user

      # remove permissions
      role = gws_user.gws_roles.first
      permissions = role.permissions.reject { |name| name =~ /_other_gws_portal_/ }
      role.update_attributes(permissions: permissions)
    end

    it "#index" do
      visit index_path
      expect(current_path).to eq index_path

      # not have permissions
      expect(page).not_to have_css('.nav-management-menu a')

      visit gws_portal_user_portlets_path(site: site, user: user)
      expect(page).not_to have_css('.gws')

      visit gws_portal_user_settings_path(site: site, user: user)
      expect(page).not_to have_css('.gws')
    end
  end
end
