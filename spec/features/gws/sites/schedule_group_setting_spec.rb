require 'spec_helper'

describe "gws_sites", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  # let(:notice_new_days) { rand(1..7) }
  let(:schedule_max_month) { (1..12).to_a.sample }
  let(:schedule_max_years) { (0..10).to_a.sample }
  let(:schedule_max_years_label) { "+#{schedule_max_years}" }
  let(:schedule_min_hour) { (6..12).to_a.sample }
  let(:schedule_max_hour) { (15..21).to_a.sample }
  let(:schedule_first_wday) { [ -1, 0, 1, 2, 3, 4, 5, 6 ].sample }
  let(:schedule_first_wday_label) do
    if schedule_first_wday == -1
      I18n.t("gws/schedule.today_wday")
    else
      I18n.t("date.day_names")[schedule_first_wday]
    end
  end
  let(:schedule_attachment_state) { %w(allow deny).sample }
  let(:schedule_attachment_state_label) { I18n.t("gws/schedule.options.schedule_attachment_state.#{schedule_attachment_state}") }
  let(:schedule_drag_drop_state) { %w(allow deny).sample }
  let(:schedule_drag_drop_state_label) { I18n.t("gws/schedule.options.schedule_drag_drop_state.#{schedule_drag_drop_state}") }
  let(:schedule_max_file_size_mb) { rand(0..10) }
  let(:schedule_max_file_size) { schedule_max_file_size_mb * 1_024 * 1_024 }
  let(:schedule_personal_tab_state) { %w(show hide).sample }
  let(:schedule_personal_tab_state_label) { I18n.t("ss.options.state.#{schedule_personal_tab_state}") }
  let(:schedule_personal_tab_label) { "personal-#{unique_id}" }
  let(:schedule_group_tab_state) { %w(show hide).sample }
  let(:schedule_group_tab_state_label) { I18n.t("ss.options.state.#{schedule_group_tab_state}") }
  let(:schedule_custom_group_tab_state) { %w(show hide).sample }
  let(:schedule_custom_group_tab_state_label) { I18n.t("ss.options.state.#{schedule_custom_group_tab_state}") }
  let(:schedule_custom_group_extra_state) { [ nil, "creator_name" ].sample }
  let(:schedule_custom_group_extra_state_label) do
    if schedule_custom_group_extra_state
      I18n.t("gws/schedule.options.schedule_custom_group_extra_state.#{schedule_custom_group_extra_state}")
    else
      ""
    end
  end
  let(:schedule_group_all_tab_state) { %w(show hide).sample }
  let(:schedule_group_all_tab_state_label) { I18n.t("ss.options.state.#{schedule_group_all_tab_state}") }
  let(:schedule_group_all_tab_label) { "group_all-#{unique_id}" }
  let(:schedule_facility_tab_state) { %w(show hide).sample }
  let(:schedule_facility_tab_state_label) { I18n.t("ss.options.state.#{schedule_facility_tab_state}") }
  let(:schedule_facility_tab_label) { "facility-#{unique_id}" }

  context "basic crud" do
    it do
      login_user user, to: gws_site_path(site: site)
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        # open addon
        ensure_addon_opened("#addon-gws-agents-addons-schedule-group_setting")

        # fill form
        within "#addon-gws-agents-addons-schedule-group_setting" do
          select schedule_max_month, from: "item[schedule_max_month]"
          select schedule_max_years_label, from: "item[schedule_max_years]"
          select schedule_min_hour, from: "item[schedule_min_hour]"
          select schedule_max_hour, from: "item[schedule_max_hour]"
          select schedule_first_wday_label, from: "item[schedule_first_wday]"
          select schedule_attachment_state_label, from: "item[schedule_attachment_state]"
          fill_in "item[in_schedule_max_file_size_mb]", with: schedule_max_file_size_mb
          select schedule_drag_drop_state_label, from: "item[schedule_drag_drop_state]"
          select schedule_personal_tab_state_label, from: "item[schedule_personal_tab_state]"
          fill_in "item[schedule_personal_tab_label]", with: schedule_personal_tab_label
          select schedule_group_tab_state_label, from: "item[schedule_group_tab_state]"
          select schedule_custom_group_tab_state_label, from: "item[schedule_custom_group_tab_state]"
          select schedule_custom_group_extra_state_label, from: "item[schedule_custom_group_extra_state]"
          select schedule_group_all_tab_state_label, from: "item[schedule_group_all_tab_state]"
          fill_in "item[schedule_group_all_tab_label]", with: schedule_group_all_tab_label
          select schedule_facility_tab_state_label, from: "item[schedule_facility_tab_state]"
          fill_in "item[schedule_facility_tab_label]", with: schedule_facility_tab_label
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      site.reload
      expect(site.schedule_max_month).to eq schedule_max_month
      expect(site.schedule_max_years).to eq schedule_max_years
      expect(site.schedule_min_hour).to eq schedule_min_hour
      expect(site.schedule_max_hour).to eq schedule_max_hour
      expect(site.schedule_first_wday).to eq schedule_first_wday
      expect(site.schedule_attachment_state).to eq schedule_attachment_state
      expect(site.schedule_max_file_size).to eq schedule_max_file_size
      expect(site.schedule_drag_drop_state).to eq schedule_drag_drop_state
      expect(site.schedule_personal_tab_state).to eq schedule_personal_tab_state
      expect(site.schedule_personal_tab_label).to eq schedule_personal_tab_label
      expect(site.schedule_group_tab_state).to eq schedule_group_tab_state
      expect(site.schedule_custom_group_tab_state).to eq schedule_custom_group_tab_state
      expect(site.schedule_custom_group_extra_state).to eq schedule_custom_group_extra_state
      expect(site.schedule_group_all_tab_state).to eq schedule_group_all_tab_state
      expect(site.schedule_group_all_tab_label).to eq schedule_group_all_tab_label
      expect(site.schedule_facility_tab_state).to eq schedule_facility_tab_state
      expect(site.schedule_facility_tab_label).to eq schedule_facility_tab_label

      # edit again
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      site.reload
      expect(site.schedule_max_month).to eq schedule_max_month
      expect(site.schedule_max_years).to eq schedule_max_years
      expect(site.schedule_min_hour).to eq schedule_min_hour
      expect(site.schedule_max_hour).to eq schedule_max_hour
      expect(site.schedule_first_wday).to eq schedule_first_wday
      expect(site.schedule_attachment_state).to eq schedule_attachment_state
      expect(site.schedule_max_file_size).to eq schedule_max_file_size
      expect(site.schedule_drag_drop_state).to eq schedule_drag_drop_state
      expect(site.schedule_personal_tab_state).to eq schedule_personal_tab_state
      expect(site.schedule_personal_tab_label).to eq schedule_personal_tab_label
      expect(site.schedule_group_tab_state).to eq schedule_group_tab_state
      expect(site.schedule_custom_group_tab_state).to eq schedule_custom_group_tab_state
      expect(site.schedule_custom_group_extra_state).to eq schedule_custom_group_extra_state
      expect(site.schedule_group_all_tab_state).to eq schedule_group_all_tab_state
      expect(site.schedule_group_all_tab_label).to eq schedule_group_all_tab_label
      expect(site.schedule_facility_tab_state).to eq schedule_facility_tab_state
      expect(site.schedule_facility_tab_label).to eq schedule_facility_tab_label
    end
  end
end
