require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:group) { gws_user.groups.first }
  let!(:user1) { create(:gws_user, gws_role_ids: user.gws_role_ids, group_ids: [group.id]) }
  let!(:user2) { create(:gws_user, gws_role_ids: user.gws_role_ids, group_ids: [group.id]) }
  let!(:user3) { create(:gws_user, gws_role_ids: user.gws_role_ids, group_ids: [group.id]) }
  let!(:item) do
    create(:gws_schedule_plan, member_ids: [ user1.id, user2.id, user3.id ], attendance_check_state: "enabled")
  end

  before do
    item.attendances.where(user_id: user1.id).first_or_create do |attendance|
      attendance.attendance_state = 'absence'
    end
    item.attendances.where(user_id: user2.id).first_or_create do |attendance|
      attendance.attendance_state = 'attendance'
    end
  end

  shared_examples "click attendance button" do
    it do
      visit gws_schedule_group_plans_path(site: site, group: group)
      wait_for_js_ready

      within "\#cal-#{user.id} .fc-body" do
        expect(page).to have_no_css(".fc-event-name")
      end
      within "\#cal-#{user1.id} .fc-body" do
        expect(page).to have_css(".fc-event-user-attendance-absence .fc-event-name", text: item.name, visible: false)
      end
      within "\#cal-#{user2.id} .fc-body" do
        expect(page).to have_css(".fc-event-user-attendance-attendance .fc-event-name", text: item.name, visible: true)
      end
      within "\#cal-#{user3.id} .fc-body" do
        expect(page).to have_css(".fc-event-user-attendance-unknown .fc-event-name", text: item.name, visible: true)
      end

      # click button
      within "#calendar-controller" do
        click_on I18n.t("gws/schedule.calendar.buttonText.withAbsence")
      end
      wait_for_js_ready

      within "\#cal-#{user1.id} .fc-body" do
        expect(page).to have_css(".fc-event-user-attendance-absence .fc-event-name", text: item.name, visible: true)
      end
      within "\#cal-#{user2.id} .fc-body" do
        expect(page).to have_css(".fc-event-user-attendance-attendance .fc-event-name", text: item.name, visible: true)
      end
      within "\#cal-#{user3.id} .fc-body" do
        expect(page).to have_css(".fc-event-user-attendance-unknown .fc-event-name", text: item.name, visible: true)
      end

      # click button again
      within "#calendar-controller" do
        click_on I18n.t("gws/schedule.calendar.buttonText.withAbsence")
      end
      wait_for_js_ready

      within "\#cal-#{user1.id} .fc-body" do
        expect(page).to have_css(".fc-event-user-attendance-absence .fc-event-name", text: item.name, visible: false)
      end
      within "\#cal-#{user2.id} .fc-body" do
        expect(page).to have_css(".fc-event-user-attendance-attendance .fc-event-name", text: item.name, visible: true)
      end
      within "\#cal-#{user3.id} .fc-body" do
        expect(page).to have_css(".fc-event-user-attendance-unknown .fc-event-name", text: item.name, visible: true)
      end
    end
  end

  context "login user" do
    before { login_user user }

    it_behaves_like "click attendance button"
  end

  context "login user1" do
    before { login_user user1 }

    it_behaves_like "click attendance button"
  end

  context "login user2" do
    before { login_user user2 }

    it_behaves_like "click attendance button"
  end

  context "login user3" do
    before { login_user user3 }

    it_behaves_like "click attendance button"
  end
end
