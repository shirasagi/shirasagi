require 'spec_helper'

describe "gws_sites", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let(:notice_new_days) { rand(1..7) }
  let(:notice_severity) { %w(all high normal).sample }
  let(:notice_severity_label) { I18n.t("gws/notice.options.severity.#{notice_severity}") }
  let(:notice_browsed_state) { %w(both unread read).sample }
  let(:notice_browsed_state_label) { I18n.t("gws/board.options.browsed_state.#{notice_browsed_state}") }
  let(:notice_toggle_browsed) { %w(button read).sample }
  let(:notice_toggle_browsed_label) { I18n.t("gws/notice.options.toggle_browsed.#{notice_toggle_browsed}") }
  let(:notice_folder_navi_open_state) { %w(default expand_all).sample }
  let(:notice_folder_navi_open_state_label) do
    I18n.t("gws/notice.options.notice_folder_navi_open_state.#{notice_folder_navi_open_state}")
  end
  let(:notice_back_number_menu_state) { %w(show hide).sample }
  let(:notice_back_number_menu_state_label) { I18n.t("ss.options.state.#{notice_back_number_menu_state}") }
  let(:notice_back_number_menu_label) { "back_number-#{unique_id}" }
  let(:notice_calendar_menu_state) { %w(show hide).sample }
  let(:notice_calendar_menu_state_label) { I18n.t("ss.options.state.#{notice_back_number_menu_state}") }
  let(:notice_calendar_menu_label) { "calendar-#{unique_id}" }

  context "basic crud" do
    it do
      login_user user, to: gws_site_path(site: site)
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        # open addon
        ensure_addon_opened("#addon-gws-agents-addons-notice-group_setting")

        # fill form
        within "#addon-gws-agents-addons-notice-group_setting" do
          fill_in "item[notice_new_days]", with: notice_new_days
          select notice_severity_label, from: "item[notice_severity]"
          select notice_browsed_state_label, from: "item[notice_browsed_state]"
          select notice_toggle_browsed_label, from: "item[notice_toggle_browsed]"
          select notice_folder_navi_open_state_label, from: "item[notice_folder_navi_open_state]"
          select notice_back_number_menu_state_label, from: "item[notice_back_number_menu_state]"
          fill_in "item[notice_back_number_menu_label]", with: notice_back_number_menu_label
          select notice_calendar_menu_state_label, from: "item[notice_calendar_menu_state]"
          fill_in "item[notice_calendar_menu_label]", with: notice_calendar_menu_label
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      site.reload
      expect(site.notice_severity).to eq notice_severity
      expect(site.notice_browsed_state).to eq notice_browsed_state
      expect(site.notice_toggle_browsed).to eq notice_toggle_browsed
      expect(site.notice_folder_navi_open_state).to eq notice_folder_navi_open_state
      expect(site.notice_back_number_menu_state).to eq notice_back_number_menu_state
      expect(site.notice_back_number_menu_label).to eq notice_back_number_menu_label
      expect(site.notice_calendar_menu_state).to eq notice_calendar_menu_state
      expect(site.notice_calendar_menu_label).to eq notice_calendar_menu_label

      # edit again
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      site.reload
      expect(site.notice_severity).to eq notice_severity
      expect(site.notice_browsed_state).to eq notice_browsed_state
      expect(site.notice_toggle_browsed).to eq notice_toggle_browsed
      expect(site.notice_folder_navi_open_state).to eq notice_folder_navi_open_state
      expect(site.notice_back_number_menu_state).to eq notice_back_number_menu_state
      expect(site.notice_back_number_menu_label).to eq notice_back_number_menu_label
      expect(site.notice_calendar_menu_state).to eq notice_calendar_menu_state
      expect(site.notice_calendar_menu_label).to eq notice_calendar_menu_label
    end
  end
end
