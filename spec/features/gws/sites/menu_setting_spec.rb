require 'spec_helper'

describe "gws_sites", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  context "ss-5070" do
    let(:menu_portal_state) { %w(show hide).sample }
    let(:menu_portal_state_label) { I18n.t("ss.options.state.#{menu_portal_state}") }
    let(:menu_portal_label) { unique_id }

    before { login_gws_user }

    it do
      # set alternative menu label
      visit gws_site_path(site: site)
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")
        within "#addon-gws-agents-addons-system-menu_setting" do
          select menu_portal_state_label, from: "item[menu_portal_state]"
          fill_in "item[menu_portal_label]", with: menu_portal_label
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      site.reload
      expect(site.menu_portal_state).to eq menu_portal_state
      expect(site.menu_portal_label).to eq menu_portal_label

      # open edit and simple click save
      visit gws_site_path(site: site)
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      site.reload
      expect(site.menu_portal_state).to eq menu_portal_state
      expect(site.menu_portal_label).to eq menu_portal_label
    end
  end
end
