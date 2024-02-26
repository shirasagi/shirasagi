require 'spec_helper'

describe "gws_schedule_facilities_approval_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:facility1) { create :gws_facility_item, approval_check_state: "enabled", user_ids: [user.id] }
  let!(:facility2) { create :gws_facility_item, user_ids: [user.id] }

  let(:item1) { create :gws_schedule_facility_plan, facility_ids: [facility1.id] }
  let(:item2) { create :gws_schedule_facility_plan, facility_ids: [facility2.id] }

  let(:facilities_path) { gws_schedule_facilities_path site }
  let(:facility1_path) { gws_schedule_facility_plans_path site, facility1 }
  let(:facility2_path) { gws_schedule_facility_plans_path site, facility2 }
  let(:index_path) { gws_schedule_facility_approval_plans_path site }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit facilities_path
      wait_for_ajax
      within ".gws-schedule-box" do
        expect(page).to have_css(".approval-check", text: I18n.t("gws/facility.views.required_approval"))
        expect(page).to have_selector(".approval-check", count: 1)
      end
    end

    it "#index" do
      visit facility1_path
      wait_for_ajax
      within ".gws-schedule-box" do
        expect(page).to have_css(".approval-check", text: I18n.t("gws/facility.views.required_approval"))
      end
    end

    it "#index" do
      visit facility2_path
      wait_for_ajax
      within ".gws-schedule-box" do
        expect(page).to have_no_css(".approval-check", text: I18n.t("gws/facility.views.required_approval"))
      end
    end

    it "#index" do
      item1.reset_approvals
      item1.update
      item1.reload

      item2.reset_approvals
      item2.update
      item2.reload

      expect(item1.approval_state).to eq "request"
      expect(item2.approval_state).to eq nil

      visit index_path
      wait_for_ajax

      within ".list-items" do
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)
        click_on item1.name
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        choose "item_approvals_facility-#{facility1.id}_state_approve"
      end
      wait_for_cbox do
        fill_in "comment[text]", with: unique_id
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item1.reload
      expect(item1.approval_state).to eq "approve"

      visit index_path
      wait_for_ajax

      within ".list-items" do
        expect(page).to have_no_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)
      end
      within ".list-head-search" do
        select I18n.t("gws/schedule.options.approved_state.approve"), from: "s[approval_state]"
      end
      within ".list-items" do
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)
      end
    end

    it "#index" do
      item1.reset_approvals
      item1.update
      item1.reload

      item2.reset_approvals
      item2.update
      item2.reload

      expect(item1.approval_state).to eq "request"
      expect(item2.approval_state).to eq nil

      visit index_path
      wait_for_ajax

      within ".list-items" do
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)
        click_on item1.name
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        choose "item_approvals_facility-#{facility1.id}_state_deny"
      end
      wait_for_cbox do
        fill_in "comment[text]", with: unique_id
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item1.reload
      expect(item1.approval_state).to eq "deny"

      visit index_path
      wait_for_ajax

      within ".list-items" do
        expect(page).to have_no_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)
      end
      within ".list-head-search" do
        select I18n.t("gws/schedule.options.approved_state.deny"), from: "s[approval_state]"
      end
      within ".list-items" do
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)
      end
    end
  end
end
