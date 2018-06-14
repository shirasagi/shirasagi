require 'spec_helper'

describe "sys_menu_settings", type: :feature, dbscope: :example do
  let(:index_path) { sys_menu_settings_path }

  context "with auth" do
    before { login_sys_user }

    it "#crud" do
      visit sns_mypage_path
      expect(page).to have_css('.main-navi a', text: I18n.t("sns.file"))
      expect(page).to have_css('.main-navi a', text: I18n.t("sns.connection"))

      # show
      visit index_path
      first('#menu a', text: I18n.t('ss.links.edit')).click
      within "form#item-form" do
        select I18n.t("ss.options.state.show"), from: "item[menu_file_state]"
        select I18n.t("ss.options.state.show"), from: "item[menu_connection_state]"
        click_button I18n.t('ss.buttons.save')
      end
      visit sns_mypage_path
      expect(page).to have_css('.main-navi a', text: I18n.t("sns.file"))
      expect(page).to have_css('.main-navi a', text: I18n.t("sns.connection"))

      # hide
      visit index_path
      first('#menu a', text: I18n.t('ss.links.edit')).click
      within "form#item-form" do
        select I18n.t("ss.options.state.hide"), from: "item[menu_file_state]"
        select I18n.t("ss.options.state.hide"), from: "item[menu_connection_state]"
        click_button I18n.t('ss.buttons.save')
      end
      visit sns_mypage_path
      expect(page).to have_no_css('.main-navi a', text: I18n.t("sns.file"))
      expect(page).to have_no_css('.main-navi a', text: I18n.t("sns.connection"))
    end
  end
end
