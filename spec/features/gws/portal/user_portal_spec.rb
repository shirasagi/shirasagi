require 'spec_helper'

describe "gws_portal_user_portal", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { create :gws_user }
  let(:index_path) { gws_portal_user_path(site: site, user: user) }
  let(:portal) { user.find_portal_setting(cur_user: user, cur_site: site).tap(&:save) }
  let(:portlets) do
    Gws::Portal::UserPortlet.new.portlet_model_options.map do |label, val|
      create(:gws_portal_user_portlet, setting_id: portal.id, portlet_model: val)
    end
  end

  context "without permission" do
    before do
      login_gws_user

      # remove permissions
      role = gws_user.gws_roles.first
      permissions = role.permissions.reject { |name| name =~ /_other_gws_portal_/ }
      role.update_attributes(permissions: permissions)
    end

    it "#index 403" do
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

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      # default portlets
      visit index_path
      SS.config.gws['portal']['user_portlets'].each do |data|
        expect(page).to have_css(".portlet-model-#{data['model']}")
      end

      # all portlets
      portlets
      visit index_path
      portlets.each do |portlet|
        expect(page).to have_css(".#{portlet.portlet_model_class}")
      end

      first('.nav-management-menu a').click
      expect(current_path).to eq gws_portal_user_layouts_path(site: site, user: user)

      first('a', text: I18n.t("gws/portal.links.manage_portlets")).click
      expect(current_path).to eq gws_portal_user_portlets_path(site: site, user: user)

      first('a', text: I18n.t("gws/portal.links.settings")).click
      expect(current_path).to eq gws_portal_user_settings_path(site: site, user: user)

      first('#menu a', text: I18n.t("ss.links.edit")).click
      expect(current_path).to eq edit_gws_portal_user_settings_path(site: site, user: user)

      click_button I18n.t('ss.buttons.save')
      expect(current_path).to eq gws_portal_user_settings_path(site: site, user: user)
    end
  end
end
