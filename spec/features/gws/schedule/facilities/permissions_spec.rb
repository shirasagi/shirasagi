require 'spec_helper'

describe "gws_schedule_facilities", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let!(:facility) do
    create :gws_facility_item, cur_site: site, reservable_group_ids: admin.group_ids, readable_setting_range: "public"
  end
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:plan) do
    create(
      :gws_schedule_plan, cur_site: site, start_at: now.change(hour: 10), end_at: now.change(hour: 12), allday: "",
      member_group_ids: admin.group_ids, facility_ids: [ facility.id ],
      readable_setting_range: "select", readable_group_ids: admin.group_ids, group_ids: admin.group_ids
    )
  end

  context "when a user have minimum permissions to show" do
    let(:minimum_permissions) do
      %w(
        use_private_gws_schedule_plans read_private_gws_schedule_plans
        use_private_gws_facility_plans read_private_gws_facility_items)
    end
    let!(:minimum_role) { create :gws_role, cur_site: site, permissions: minimum_permissions }
    let!(:user) { create :gws_user, cur_site: site, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ] }
    let!(:group) { user.gws_default_group }

    it do
      login_user user, to: gws_schedule_main_path(site: site)
      within ".current-navi" do
        expect(page).to have_link(I18n.t('gws/schedule.tabs.personal'), href: gws_schedule_plans_path(site: site))
        expect(page).to have_link(I18n.t('gws/schedule.tabs.facility'), href: gws_schedule_facilities_path(site: site))
        expect(page).to have_link(I18n.t('gws/schedule.navi.approve_facility_plan'))
        expect(page).to have_link(I18n.t('gws/schedule.tabs.search'), href: gws_schedule_search_path(site: site))
        expect(page).to have_link(I18n.t('ss.links.import'))
        expect(page).to have_no_link(I18n.t('ss.links.trash'))
        expect(page).to have_no_link(I18n.t('gws/schedule.navi.holiday'))
        expect(page).to have_no_link(I18n.t('gws/schedule.navi.category'))
        expect(page).to have_no_link(I18n.t('gws/facility.navi.category'))
        expect(page).to have_link(I18n.t('gws/facility.navi.item'), href: gws_facility_items_path(site: site))
        expect(page).to have_link(I18n.t('gws/facility.navi.usage'))
        expect(page).to have_link(I18n.t('gws/facility.navi.state'))
      end
      within ".gws-schedule-tabs" do
        expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
        expect(page).to have_css('a.group', text: group.trailing_name)
        expect(page).to have_no_css('a.custom-group')
        expect(page).to have_css('a.group-all', text: I18n.t("gws/schedule.tabs.group"))
        expect(page).to have_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
      end
      within ".fc-day-grid-container" do
        expect(page).to have_css(".fc-event:not(.fc-holiday)", text: plan.name)
      end
      within ".current-navi" do
        click_on I18n.t('gws/schedule.tabs.facility')
      end

      within ".gws-schedule-box" do
        expect(page).to have_css("h2", text: I18n.t('gws/schedule.tabs.facility'))
        within first(".fc-event-facility") do
          expect(page).to have_css(".fc-event-name", text: plan.name)
        end
        # click_on plan.name
        first(".fc-event-facility").click
      end

      expect(page).to have_css("#addon-basic", text: plan.name)
      expect(page).to have_css("#addon-gws-agents-addons-schedule-facility", text: facility.name)
    end
  end

  context "when a user have only gws/schedule/plan permissions to edit" do
    let(:minimum_permissions) do
      %w(use_private_gws_schedule_plans read_private_gws_schedule_plans edit_private_gws_schedule_plans)
    end
    let!(:minimum_role) { create :gws_role, cur_site: site, permissions: minimum_permissions }
    let!(:user) { create :gws_user, cur_site: site, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ] }
    let!(:group) { user.gws_default_group }

    it do
      login_user user, to: gws_schedule_main_path(site: site)
      within ".current-navi" do
        expect(page).to have_link(I18n.t('gws/schedule.tabs.personal'), href: gws_schedule_plans_path(site: site))
        expect(page).to have_no_link(I18n.t('gws/schedule.tabs.facility'))
        expect(page).to have_no_link(I18n.t('gws/schedule.navi.approve_facility_plan'))
        expect(page).to have_link(I18n.t('gws/schedule.tabs.search'), href: gws_schedule_search_path(site: site))
        expect(page).to have_link(I18n.t('ss.links.import'), href: gws_schedule_csv_path(site: site))
        expect(page).to have_no_link(I18n.t('ss.links.trash'))
        expect(page).to have_no_link(I18n.t('gws/schedule.navi.holiday'))
        expect(page).to have_no_link(I18n.t('gws/schedule.navi.category'))
        expect(page).to have_no_link(I18n.t('gws/facility.navi.category'))
        expect(page).to have_no_link(I18n.t('gws/facility.navi.item'))
        expect(page).to have_no_link(I18n.t('gws/facility.navi.usage'))
        expect(page).to have_no_link(I18n.t('gws/facility.navi.state'))
      end
      within ".gws-schedule-tabs" do
        expect(page).to have_css('a.personal', text: I18n.t("gws/schedule.tabs.personal"))
        expect(page).to have_css('a.group', text: group.trailing_name)
        expect(page).to have_no_css('a.custom-group')
        expect(page).to have_css('a.group-all', text: I18n.t("gws/schedule.tabs.group"))
        expect(page).to have_no_css('a.facility', text: I18n.t("gws/schedule.tabs.facility"))
      end
      within ".fc-day-grid-container" do
        within first(".fc-event:not(.fc-holiday)") do
          expect(page).to have_css(".fc-event-name", text: plan.name)
        end
        # click_on plan.name
        first(".fc-event:not(.fc-holiday)").click
      end

      expect(page).to have_css("#addon-basic", text: plan.name)
      expect(page).to have_css("#addon-gws-agents-addons-schedule-facility", text: facility.name)
      click_on I18n.t("ss.links.edit")
      wait_for_all_turbo_frames
      within "form#item-form" do
        expect(page).to have_css("#addon-basic")
        expect(page).to have_css("#addon-gws-agents-addons-schedule-facility", text: facility.name)
      end
    end
  end

  # 本ケースはバグっぽい。
  # 設備予約画面が開くが、権限 read_private_gws_schedule_plans が付与されていないので予定は表示されない。
  # 設備系の管理が可能という意味で表示しているだけ。無意味。
  context "when a user have only facilities' permissions" do
    let(:minimum_permissions) do
      %w(use_private_gws_facility_plans read_private_gws_facility_items)
    end
    let!(:minimum_role) { create :gws_role, cur_site: site, permissions: minimum_permissions }
    let!(:user) { create :gws_user, cur_site: site, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ] }
    let!(:group) { user.gws_default_group }

    it do
      login_user user, to: gws_schedule_main_path(site: site)
      within ".current-navi" do
        expect(page).to have_no_link(I18n.t('gws/schedule.tabs.personal'))
        expect(page).to have_link(I18n.t('gws/schedule.tabs.facility'))
        expect(page).to have_link(I18n.t('gws/schedule.navi.approve_facility_plan'))
        expect(page).to have_no_link(I18n.t('gws/schedule.tabs.search'))
        expect(page).to have_no_link(I18n.t('ss.links.import'))
        expect(page).to have_no_link(I18n.t('ss.links.trash'))
        expect(page).to have_no_link(I18n.t('gws/schedule.navi.holiday'))
        expect(page).to have_no_link(I18n.t('gws/schedule.navi.category'))
        expect(page).to have_no_link(I18n.t('gws/facility.navi.category'))
        expect(page).to have_link(I18n.t('gws/facility.navi.item'), href: gws_facility_items_path(site: site))
        expect(page).to have_link(I18n.t('gws/facility.navi.usage'))
        expect(page).to have_link(I18n.t('gws/facility.navi.state'))
      end
      expect(page).to have_no_css(".gws-schedule-tabs")
    end
  end
end
