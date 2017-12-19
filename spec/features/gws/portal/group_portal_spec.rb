require 'spec_helper'

describe "gws_portal_group_portal", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:group) { gws_user.groups.first }
  let(:index_path) { gws_portal_group_path(site: site, group: group) }
  let(:portal) { group.find_portal_setting(cur_user: user, cur_site: site).tap(&:save) }
  let(:portlets) do
    Gws::Portal::GroupPortlet.new.portlet_model_options.map do |label, val|
      create(:gws_portal_group_portlet, setting_id: portal.id, portlet_model: val)
    end
  end

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      # default portlets
      visit index_path
      SS.config.gws['portal']['group_portlets'].each do |data|
        expect(page).to have_css(".portlet-model-#{data['model']}")
      end

      # all portlets
      portlets
      visit index_path
      portlets.each do |portlet|
        expect(page).to have_css(".#{portlet.portlet_model_class}")
      end

      first('.nav-management-menu a').click
      expect(current_path).to eq gws_portal_group_layouts_path(site: site, group: group)

      first('a', text: I18n.t("gws/portal.links.manage_portlets")).click
      expect(current_path).to eq gws_portal_group_portlets_path(site: site, group: group)

      first('a', text: I18n.t("gws/portal.links.settings")).click
      expect(current_path).to eq gws_portal_group_settings_path(site: site, group: group)

      first('#menu a', text: I18n.t("ss.links.edit")).click
      expect(current_path).to eq edit_gws_portal_group_settings_path(site: site, group: group)

      click_button I18n.t('ss.buttons.save')
      expect(current_path).to eq gws_portal_group_settings_path(site: site, group: group)
    end
  end
end
