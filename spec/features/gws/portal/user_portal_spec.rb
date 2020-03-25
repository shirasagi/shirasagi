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
      role.update(permissions: permissions)
    end

    it '#index 403' do
      visit index_path
      expect(current_path).to eq index_path

      # not have permissions
      expect(page).to have_no_css('.nav-management-menu a')

      visit gws_portal_user_portlets_path(site: site, user: user)
      expect(page).to have_css('#addon-basic .addon-head', text: I18n.t("ss.rescues.default.head"))

      visit gws_portal_user_settings_path(site: site, user: user)
      expect(page).to have_css('#addon-basic .addon-head', text: I18n.t("ss.rescues.default.head"))
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

  context 'with sns mode: only allowed use_gws_portal_user_settings permission' do
    let(:role) { create(:gws_role_portal_user_use, permissions: %w(use_gws_board read_private_gws_board_posts)) }
    let!(:user) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: [ role.id ]) }

    before do
      portal = user.find_portal_setting(cur_user: user, cur_site: site)
      portal.save!
      portal.save_default_portlets([{ "model" => "board" }])

      login_user user
    end

    it do
      visit gws_portal_path(site: site)
      within ".main-navi" do
        expect(page).to have_css("a.icon-portal[href='/.g#{site.id}']", text: I18n.t('modules.gws/portal'))
        expect(page).to have_no_css("a.icon-portal", text: I18n.t('gws/portal.self_portal'))
        expect(page).to have_no_css("a.icon-portal", text: I18n.t('gws/portal.tabs.root_portal'))
      end
      expect(page).to have_css(".gws-portlets .portlet-model-board", text: I18n.t("gws/portal.portlets.board.name"))

      visit gws_portal_user_path(site: site, user: user)
      within ".main-navi" do
        expect(page).to have_css("a.icon-portal[href='/.g#{site.id}']", text: I18n.t('modules.gws/portal'))
        expect(page).to have_no_css("a.icon-portal", text: I18n.t('gws/portal.self_portal'))
        expect(page).to have_no_css("a.icon-portal", text: I18n.t('gws/portal.tabs.root_portal'))
      end
      expect(page).to have_css(".gws-portlets .portlet-model-board", text: I18n.t("gws/portal.portlets.board.name"))
    end
  end
end
