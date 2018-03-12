require 'spec_helper'

describe 'gws_portal_group_portal', type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:group) { gws_user.groups.first }
  let(:index_path) { gws_portal_group_path(site: site, group: group) }
  let(:portal) { group.find_portal_setting(cur_user: user, cur_site: site).tap(&:save) }
  let(:default_portlets) { SS.config.gws['portal']['group_portlets'] }

  context 'with auth' do
    before { login_gws_user }

    it '#index' do
      visit index_path
      default_portlets.each do |data|
        expect(page).to have_css(".portlet-model-#{data['model']}")
      end
      expect(Gws::Portal::GroupPortlet.all.size).to eq(0)

      first('.current-navi a.management').click
      expect(current_path).to eq gws_portal_group_layouts_path(site: site, group: group)
      expect(Gws::Portal::GroupPortlet.all.size).to eq(default_portlets.size)

      # setting
      first('#navi a', text: I18n.t('gws/portal.links.settings')).click
      expect(current_path).to eq gws_portal_group_settings_path(site: site, group: group)

      first('#menu a', text: I18n.t('ss.links.edit')).click
      expect(current_path).to eq edit_gws_portal_group_settings_path(site: site, group: group)

      click_button I18n.t('ss.buttons.save')
      expect(current_path).to eq gws_portal_group_settings_path(site: site, group: group)

      # layout
      first('#navi a', text: I18n.t('gws/portal.links.arrange_portlets')).click
      click_button I18n.t('ss.buttons.reset')
      click_button I18n.t('gws/portal.buttons.save_layouts')

      # portlets
      first('#navi a', text: I18n.t('gws/portal.links.manage_portlets')).click
      expect(current_path).to eq gws_portal_group_portlets_path(site: site, group: group)

      first('.list-items a', text: default_portlets.first['name']).click
      first('#menu a', text: I18n.t('ss.links.edit')).click
      click_button I18n.t('ss.buttons.save')

      first('#menu a', text: I18n.t('ss.links.delete')).click
      click_button I18n.t('ss.buttons.delete')
      expect(Gws::Portal::GroupPortlet.all.size).not_to eq(default_portlets.size)

      first('a', text: I18n.t('ss.links.initialize')).click
      click_button I18n.t('ss.buttons.initialize')
      expect(Gws::Portal::GroupPortlet.all.size).to eq(default_portlets.size)
    end
  end
end
