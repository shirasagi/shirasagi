require 'spec_helper'

describe "gws_schedule_plans tab", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let!(:custom_group1) { create :gws_custom_group }
  let!(:custom_group2) { create :gws_custom_group }
  let(:index_path) { gws_schedule_plans_path site }
  before { login_gws_user }

  it "#index" do
    visit index_path
    expect(current_path).not_to eq sns_login_path
    expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
    expect(page).to have_css('a.group', text: gws_user.gws_default_group.trailing_name)
    expect(page).to have_css('a.custom-group', count: 2)
    expect(page).to have_css('a.group-all', text: I18n.t("gws/schedule.tabs.group"))
    expect(page).to have_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
  end

  context "when schedule_personal_tab_state is hide" do
    let(:site) { gws_site.set(schedule_personal_tab_state: 'hide') }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
      expect(page).to have_css('a.group', text: gws_user.gws_default_group.trailing_name)
      expect(page).to have_css('a.custom-group', count: 2)
      expect(page).to have_css('a.group-all', text: I18n.t("gws/schedule.tabs.group"))
      expect(page).to have_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
    end
  end

  context "when schedule_personal_tab_label is personal" do
    let(:site) { gws_site.set(schedule_personal_tab_label: 'personal') }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_css('a.personal', text: 'personal')
      expect(page).to have_css('a.group', text: gws_user.gws_default_group.trailing_name)
      expect(page).to have_css('a.custom-group', count: 2)
      expect(page).to have_css('a.group-all', text: I18n.t("gws/schedule.tabs.group"))
      expect(page).to have_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
    end
  end

  context "when schedule_custom_group_tab_state is hide" do
    let(:site) { gws_site.set(schedule_custom_group_tab_state: 'hide') }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
      expect(page).to have_css('a.group', text: gws_user.gws_default_group.trailing_name)
      expect(page).to have_no_css('a.custom-group')
      expect(page).to have_css('a.group-all', text: I18n.t("gws/schedule.tabs.group"))
      expect(page).to have_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
    end
  end
end
