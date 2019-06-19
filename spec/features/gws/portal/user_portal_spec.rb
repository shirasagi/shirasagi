require 'spec_helper'

describe 'gws_portal_user_portal', type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { create :gws_user }
  let(:index_path) { gws_portal_user_path(site: site, user: user) }
  let(:portal) { user.find_portal_setting(cur_user: user, cur_site: site).tap(&:save) }
  let(:default_portlets) { SS.config.gws['portal']['user_portlets'] }

  context 'without permission' do
    before do
      login_gws_user

      # remove permissions
      role = gws_user.gws_roles.first
      permissions = role.permissions.reject { |name| name =~ /_other_gws_portal_/ }
      role.update_attributes(permissions: permissions)
    end

    it '#index 403' do
      visit index_path
      expect(current_path).to eq index_path

      # not have permissions
      expect(page).to have_no_css('.nav-management-menu a')

      visit gws_portal_user_portlets_path(site: site, user: user)
      expect(page).to have_no_css('.gws')

      visit gws_portal_user_settings_path(site: site, user: user)
      expect(page).to have_no_css('.gws')
    end
  end

  context 'with auth' do
    before { login_gws_user }

    it '#index' do
      visit index_path
      default_portlets.each do |data|
        expect(page).to have_css(".portlet-model-#{data['model']}")
      end
      expect(Gws::Portal::UserPortlet.all.size).to eq(0)

      first('.current-navi a.management').click
      expect(current_path).to eq gws_portal_user_layouts_path(site: site, user: user)
      expect(Gws::Portal::UserPortlet.all.size).to eq(default_portlets.size)

      # setting
      first('#navi a', text: I18n.t('gws/portal.links.settings')).click
      expect(current_path).to eq gws_portal_user_settings_path(site: site, user: user)

      first('#menu a', text: I18n.t('ss.links.edit')).click
      expect(current_path).to eq edit_gws_portal_user_settings_path(site: site, user: user)

      click_button I18n.t('ss.buttons.save')
      expect(current_path).to eq gws_portal_user_settings_path(site: site, user: user)

      # layout
      first('#navi a', text: I18n.t('gws/portal.links.arrange_portlets')).click
      click_button I18n.t('ss.buttons.reset')
      click_button I18n.t('gws/portal.buttons.save_layouts')

      # portlets
      first('#navi a', text: I18n.t('gws/portal.links.manage_portlets')).click
      expect(current_path).to eq gws_portal_user_portlets_path(site: site, user: user)

      first('.list-items a', text: default_portlets.first['name']).click
      first('#menu a', text: I18n.t('ss.links.edit')).click
      click_button I18n.t('ss.buttons.save')

      first('#menu a', text: I18n.t('ss.links.delete')).click
      click_button I18n.t('ss.buttons.delete')
      expect(Gws::Portal::UserPortlet.all.size).not_to eq(default_portlets.size)

      first('a', text: I18n.t('ss.links.initialize')).click
      click_button I18n.t('ss.buttons.initialize')
      expect(Gws::Portal::UserPortlet.all.size).to eq(default_portlets.size)
    end
  end
end
