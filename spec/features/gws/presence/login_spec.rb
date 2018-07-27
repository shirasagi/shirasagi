require 'spec_helper'

describe 'gws_presence_users', type: :feature, dbscope: :example do
  context "login with setting", js: true do
    let!(:site) { gws_site }
    let!(:user_setting_path) { gws_presence_user_setting_path site }
    let!(:index_path) { gws_presence_users_path site }

    before { login_gws_user }

    it "both state disabled" do
      visit user_setting_path

      click_link I18n.t("ss.links.edit")

      within "form#item-form" do
        select I18n.t("ss.options.state.disabled"), from: 'item[sync_available_state]'
        select I18n.t("ss.options.state.disabled"), from: 'item[sync_unavailable_state]'
        click_button I18n.t("ss.buttons.save")
      end
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq nil

      find("#head .user .name", text: gws_user.name).click
      click_link I18n.t("ss.logout")
      expect(current_path).to eq sns_login_path
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq nil

      login_gws_user
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq nil
    end

    it "both state enabled" do
      visit user_setting_path

      click_link I18n.t("ss.links.edit")

      within "form#item-form" do
        select I18n.t("ss.options.state.enabled"), from: 'item[sync_available_state]'
        select I18n.t("ss.options.state.enabled"), from: 'item[sync_unavailable_state]'
        click_button I18n.t("ss.buttons.save")
      end
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "available"

      find("#head .user .name", text: gws_user.name).click
      click_link I18n.t("ss.logout")
      expect(current_path).to eq sns_login_path
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "unavailable"

      login_gws_user
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "available"
    end

    it "sync_available_state enabled" do
      visit user_setting_path

      click_link I18n.t("ss.links.edit")

      within "form#item-form" do
        select I18n.t("ss.options.state.enabled"), from: 'item[sync_available_state]'
        select I18n.t("ss.options.state.disabled"), from: 'item[sync_unavailable_state]'
        click_button I18n.t("ss.buttons.save")
      end
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "available"

      find("#head .user .name", text: gws_user.name).click
      click_link I18n.t("ss.logout")
      expect(current_path).to eq sns_login_path
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "available"

      login_gws_user
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "available"
    end

    it "sync_unavailable_state enabled" do
      visit user_setting_path

      click_link I18n.t("ss.links.edit")

      within "form#item-form" do
        select I18n.t("ss.options.state.disabled"), from: 'item[sync_available_state]'
        select I18n.t("ss.options.state.enabled"), from: 'item[sync_unavailable_state]'
        click_button I18n.t("ss.buttons.save")
      end
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq nil
      visit index_path

      find(".editable-users").click_on gws_user.name
      find('.editable-users span', text: I18n.t("gws/presence.options.presence_state.available")).click
      wait_for_ajax

      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "available"

      find("#head .user .name", text: gws_user.name).click
      click_link I18n.t("ss.logout")
      expect(current_path).to eq sns_login_path
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "unavailable"

      login_gws_user
      expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "unavailable"
    end
  end
end
