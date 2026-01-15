require 'spec_helper'

describe "gws_schedule_plans tab", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let!(:custom_group1) { create :gws_custom_group, cur_site: site }
  let!(:custom_group2) { create :gws_custom_group, cur_site: site }
  let!(:facility_item) { create :gws_facility_item, cur_site: site }
  let(:index_path) { gws_schedule_plans_path site }
  before { login_gws_user }

  it do
    visit index_path
    within "#navi .current-navi" do
      expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
      expect(page).to have_no_css('a.group')
      expect(page).to have_no_css('a.custom-group')
      expect(page).to have_no_css('a.group-all')
      expect(page).to have_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
    end
    within "#main .gws-schedule-tabs" do
      expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
      expect(page).to have_css('a.group', text: gws_user.gws_default_group.trailing_name)
      expect(page).to have_css('a.custom-group', count: 2)
      expect(page).to have_css('a.group-all', text: I18n.t("gws/schedule.tabs.group"))
      expect(page).to have_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
    end
  end

  context "when schedule_personal_tab_state is hide" do
    let(:site) { gws_site.set(schedule_personal_tab_state: 'hide') }

    it do
      visit index_path
      within "#navi .current-navi" do
        expect(page).to have_no_css('a.personal')
        expect(page).to have_no_css('a.group')
        expect(page).to have_no_css('a.custom-group')
        expect(page).to have_no_css('a.group-all')
        expect(page).to have_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
      end
      within "#main .gws-schedule-tabs" do
        expect(page).to have_no_css('a.personal')
        expect(page).to have_css('a.group', text: gws_user.gws_default_group.trailing_name)
        expect(page).to have_css('a.custom-group', count: 2)
        expect(page).to have_css('a.group-all', text: I18n.t("gws/schedule.tabs.group"))
        expect(page).to have_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
      end
    end
  end

  context "when schedule_personal_tab_label is modified" do
    let(:schedule_personal_tab_label) { "personal-#{unique_id}" }
    let(:site) { gws_site.set(schedule_personal_tab_label: schedule_personal_tab_label) }

    it do
      visit gws_schedule_plans_path(site: site)
      within "#navi .current-navi" do
        expect(page).to have_css('a.personal', text: schedule_personal_tab_label)
      end
      within "#crumbs" do
        expect(page).to have_css('.active', text: schedule_personal_tab_label)
      end
      within "#main .gws-schedule-tabs" do
        expect(page).to have_css('a.personal', text: schedule_personal_tab_label)
      end
      expect(page).to have_css('a.group', text: gws_user.gws_default_group.trailing_name)
      expect(page).to have_css('a.custom-group', count: 2)
      expect(page).to have_css('a.group-all', text: I18n.t("gws/schedule.tabs.group"))
      expect(page).to have_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
    end
  end

  context "when schedule_group_tab_state is hide" do
    let(:site) { gws_site.set(schedule_group_tab_state: 'hide') }

    it do
      visit index_path
      within "#navi .current-navi" do
        expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
        expect(page).to have_no_css('a.group')
        expect(page).to have_no_css('a.custom-group')
        expect(page).to have_no_css('a.group-all')
        expect(page).to have_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
      end
      within "#main .gws-schedule-tabs" do
        expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
        expect(page).to have_no_css('a.group')
        expect(page).to have_css('a.custom-group', count: 2)
        expect(page).to have_css('a.group-all', text: I18n.t("gws/schedule.tabs.group"))
        expect(page).to have_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
      end
    end
  end

  context "when schedule_custom_group_tab_state is hide" do
    let(:site) { gws_site.set(schedule_custom_group_tab_state: 'hide') }

    it do
      visit index_path
      within "#navi .current-navi" do
        expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
        expect(page).to have_no_css('a.group')
        expect(page).to have_no_css('a.custom-group')
        expect(page).to have_no_css('a.group-all')
        expect(page).to have_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
      end
      within "#main .gws-schedule-tabs" do
        expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
        expect(page).to have_css('a.group', text: gws_user.gws_default_group.trailing_name)
        expect(page).to have_no_css('a.custom-group')
        expect(page).to have_css('a.group-all', text: I18n.t("gws/schedule.tabs.group"))
        expect(page).to have_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
      end
    end
  end

  context "when schedule_group_all_tab_state is hide" do
    let(:site) { gws_site.set(schedule_group_all_tab_state: 'hide') }

    it do
      visit index_path
      within "#navi .current-navi" do
        expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
        expect(page).to have_no_css('a.group')
        expect(page).to have_no_css('a.custom-group')
        expect(page).to have_no_css('a.group-all')
        expect(page).to have_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
      end
      within "#main .gws-schedule-tabs" do
        expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
        expect(page).to have_css('a.group', text: gws_user.gws_default_group.trailing_name)
        expect(page).to have_css('a.custom-group', count: 2)
        expect(page).to have_no_css('a.group-all')
        expect(page).to have_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
      end
    end
  end

  context "when schedule_group_all_tab_label is modified" do
    let(:schedule_group_all_tab_label) { "group_all-#{unique_id}" }
    let(:site) { gws_site.set(schedule_group_all_tab_label: schedule_group_all_tab_label) }

    it do
      visit gws_schedule_all_groups_path(site: site)
      within "#navi .current-navi" do
        expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
        expect(page).to have_no_css('a.group')
        expect(page).to have_no_css('a.custom-group')
        expect(page).to have_no_css('a.group-all')
        expect(page).to have_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
      end
      within "#crumbs" do
        expect(page).to have_css('.active', text: schedule_group_all_tab_label)
      end
      within "#main .gws-schedule-tabs" do
        expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
        expect(page).to have_css('a.group', text: gws_user.gws_default_group.trailing_name)
        expect(page).to have_css('a.custom-group', count: 2)
        expect(page).to have_css('a.group-all', text: schedule_group_all_tab_label)
        expect(page).to have_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
      end
    end
  end

  context "when schedule_facility_tab_state is hide" do
    let(:site) { gws_site.set(schedule_facility_tab_state: 'hide') }

    it do
      visit index_path
      within "#navi .current-navi" do
        expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
        expect(page).to have_no_css('a.group')
        expect(page).to have_no_css('a.custom-group')
        expect(page).to have_no_css('a.group-all')
        expect(page).to have_no_css('a.facility')
      end
      within "#main .gws-schedule-tabs" do
        expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
        expect(page).to have_css('a.group', text: gws_user.gws_default_group.trailing_name)
        expect(page).to have_css('a.custom-group', count: 2)
        expect(page).to have_css('a.group-all', text: I18n.t("gws/schedule.tabs.group"))
        expect(page).to have_no_css('a.facility')
      end
    end
  end

  context "when schedule_facility_tab_label is modified" do
    let(:schedule_facility_tab_label) { "group_all-#{unique_id}" }
    let(:site) { gws_site.set(schedule_facility_tab_label: schedule_facility_tab_label) }

    it do
      visit gws_schedule_facilities_path(site: site)
      within "#navi .current-navi" do
        expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
        expect(page).to have_no_css('a.group')
        expect(page).to have_no_css('a.custom-group')
        expect(page).to have_no_css('a.group-all')
        expect(page).to have_css('a.facility', text: schedule_facility_tab_label)
      end
      within "#crumbs" do
        expect(page).to have_css('.active', text: schedule_facility_tab_label)
      end
      within "#main .gws-schedule-tabs" do
        expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
        expect(page).to have_css('a.group', text: gws_user.gws_default_group.trailing_name)
        expect(page).to have_css('a.custom-group', count: 2)
        expect(page).to have_css('a.group-all', text: I18n.t("gws/schedule.tabs.group"))
        expect(page).to have_css('a.facility', text: schedule_facility_tab_label)
      end

      visit gws_schedule_facility_plans_path(site: site, facility: facility_item)
      within "#navi .current-navi" do
        expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
        expect(page).to have_no_css('a.group')
        expect(page).to have_no_css('a.custom-group')
        expect(page).to have_no_css('a.group-all')
        expect(page).to have_css('a.facility', text: schedule_facility_tab_label)
      end
      within "#crumbs" do
        expect(page).to have_link(schedule_facility_tab_label)
        expect(page).to have_css('.active', text: facility_item.name)
      end
      within "#main .gws-schedule-tabs" do
        expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
        expect(page).to have_css('a.group', text: gws_user.gws_default_group.trailing_name)
        expect(page).to have_css('a.custom-group', count: 2)
        expect(page).to have_css('a.group-all', text: I18n.t("gws/schedule.tabs.group"))
        expect(page).to have_css('a.facility', text: schedule_facility_tab_label)
      end
    end
  end
end
