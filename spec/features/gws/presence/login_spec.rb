require 'spec_helper'

describe 'gws_presence_users', type: :feature, dbscope: :example, js: true do
  context "login with setting" do
    let!(:site) { gws_site }
    let!(:user_setting_path) { gws_presence_user_setting_path site }
    let!(:index_path) { gws_presence_users_path site }
    let!(:presence_states) { Gws::UserPresence.new.state_options.map(&:reverse).to_h }

    before { login_gws_user }

    it "both state disabled" do
      visit index_path
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq ""

      visit user_setting_path
      click_link I18n.t("ss.links.edit")

      within "form#item-form" do
        select I18n.t("ss.options.state.disabled"), from: 'item[sync_available_state]'
        select I18n.t("ss.options.state.disabled"), from: 'item[sync_unavailable_state]'
        click_button I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit sns_logout_path
      expect(page).to have_css(".login-box")
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq ""

      login_gws_user
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq ""
    end

    it "both state enabled" do
      visit index_path
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq ""

      within ".editable-users" do
        click_on gws_user.name
        find('span', text: presence_states["available"]).click
        expect(page).to have_css(".presence-state", text: presence_states["available"])
      end
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "available"

      visit user_setting_path
      click_link I18n.t("ss.links.edit")

      within "form#item-form" do
        select I18n.t("ss.options.state.enabled"), from: 'item[sync_available_state]'
        select I18n.t("ss.options.state.enabled"), from: 'item[sync_unavailable_state]'
        click_button I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit sns_logout_path
      expect(page).to have_css(".login-box")
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "unavailable"

      login_gws_user
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "available"
    end

    it "sync_available_state enabled" do
      visit index_path
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq ""

      within ".editable-users" do
        click_on gws_user.name
        find('span', text: presence_states["available"]).click
        expect(page).to have_css(".presence-state", text: presence_states["available"])
      end
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "available"

      visit user_setting_path
      click_link I18n.t("ss.links.edit")

      within "form#item-form" do
        select I18n.t("ss.options.state.enabled"), from: 'item[sync_available_state]'
        select I18n.t("ss.options.state.disabled"), from: 'item[sync_unavailable_state]'
        click_button I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit sns_logout_path
      expect(page).to have_css(".login-box")
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "available"

      login_gws_user
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "available"
    end

    it "sync_unavailable_state enabled" do
      visit index_path
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq ""

      within ".editable-users" do
        click_on gws_user.name
        find('span', text: presence_states["available"]).click
        expect(page).to have_css(".presence-state", text: presence_states["available"])
      end
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "available"

      visit user_setting_path
      click_link I18n.t("ss.links.edit")

      within "form#item-form" do
        select I18n.t("ss.options.state.disabled"), from: 'item[sync_available_state]'
        select I18n.t("ss.options.state.enabled"), from: 'item[sync_unavailable_state]'
        click_button I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit sns_logout_path
      expect(page).to have_css(".login-box")
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "unavailable"

      login_gws_user
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "unavailable"
    end
  end
end
