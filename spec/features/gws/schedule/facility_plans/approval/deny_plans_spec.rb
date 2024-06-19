require 'spec_helper'

describe "gws_schedule_facility_plans", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:user1) { create :gws_user, group_ids: user.group_ids, gws_role_ids: [role1.id] }
  let!(:role1) { create :gws_role, permissions: (Gws::Role.permission_names - %w(duplicate_private_gws_facility_plans)) }
  let(:title1) { unique_id }
  let(:title2) { unique_id }

  let!(:facility) { create :gws_facility_item, approval_check_state: "enabled", user_ids: [ user.id ] }

  context "have duplicate_private_gws_facility_plans" do
    it do
      login_user(user)
      visit gws_schedule_facilities_path(site: site)

      # create title1
      within ".gws-schedule-box .calendar-multiple-header" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end
      within "form#item-form" do
        fill_in "item[name]", with: title1
      end
      click_button I18n.t('ss.buttons.save')

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-approval-request", text: title1)
      end
      wait_for_ajax

      # create title2
      within ".gws-schedule-box .calendar-multiple-header" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end
      within "form#item-form" do
        fill_in "item[name]", with: title2
      end
      click_button I18n.t('ss.buttons.save')


      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-approval-request", text: title1)
        expect(page).to have_css(".fc-event-approval-request", text: title2)
      end
      wait_for_ajax
    end
  end

  context "have no duplicate_private_gws_facility_plans" do
    it do
      login_user(user1)
      visit gws_schedule_facilities_path(site: site)

      # create title1
      within ".gws-schedule-box .calendar-multiple-header" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end
      within "form#item-form" do
        fill_in "item[name]", with: title1
      end
      click_button I18n.t('ss.buttons.save')

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-approval-request", text: title1)
      end
      wait_for_ajax

      # create faild title2
      within ".gws-schedule-box .calendar-multiple-header" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end
      within "form#item-form" do
        fill_in "item[name]", with: title2
      end
      click_button I18n.t('ss.buttons.save')

      wait_for_cbox do
        expect(page).to have_text(I18n.t("gws/schedule.facility_reservation.exist"))
        click_on I18n.t("ss.buttons.close")
      end
    end

    it do
      login_user(user1)
      visit gws_schedule_facilities_path(site: site)

      # create title1
      within ".gws-schedule-box .calendar-multiple-header" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end
      within "form#item-form" do
        fill_in "item[name]", with: title1
      end
      click_button I18n.t('ss.buttons.save')

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-approval-request", text: title1)
      end
      wait_for_ajax

      # approve title1
      login_user(user)
      visit gws_schedule_facilities_path(site: site)

      within ".fc-event:not(.fc-holiday)" do
        first(".fc-title").click
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        within "span[data-facility-id='#{facility.id}']" do
          wait_cbox_open { first("input[value='approve']").click }
        end
      end
      wait_for_cbox do
        within "#ajax-box form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end
      end
      wait_for_notice I18n.t('ss.notice.saved')

      # create faild title2
      login_user(user1)
      visit gws_schedule_facilities_path(site: site)

      within ".gws-schedule-box .calendar-multiple-header" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end
      within "form#item-form" do
        fill_in "item[name]", with: title2
      end
      click_button I18n.t('ss.buttons.save')

      wait_for_cbox do
        expect(page).to have_text(I18n.t("gws/schedule.facility_reservation.exist"))
        click_on I18n.t("ss.buttons.close")
      end
    end

    it do
      login_user(user1)
      visit gws_schedule_facilities_path(site: site)

      # create title1
      within ".gws-schedule-box .calendar-multiple-header" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end
      within "form#item-form" do
        fill_in "item[name]", with: title1
      end
      click_button I18n.t('ss.buttons.save')

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-approval-request", text: title1)
      end
      wait_for_ajax

      # deny title1
      login_user(user)
      visit gws_schedule_facilities_path(site: site)

      within ".fc-event:not(.fc-holiday)" do
        first(".fc-title").click
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        within "span[data-facility-id='#{facility.id}']" do
          wait_cbox_open { first("input[value='deny']").click }
        end
      end
      wait_for_cbox do
        within "#ajax-box form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end
      end
      wait_for_notice I18n.t('ss.notice.saved')

      # create title2
      login_user(user1)
      visit gws_schedule_facilities_path(site: site)

      within ".gws-schedule-box .calendar-multiple-header" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end
      within "form#item-form" do
        fill_in "item[name]", with: title2
      end
      click_button I18n.t('ss.buttons.save')

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      within ".gws-schedule-box" do
        expect(page).to have_no_css(".fc-event-approval-deny", text: title1)
        expect(page).to have_css(".fc-event-approval-request", text: title2)
      end
      wait_for_ajax

      # search denied plan
      within ".gws-schedule-box" do
        within "form.search" do
          select I18n.t("gws/schedule.views.deny"), from: "s[approval]"
          click_on I18n.t("ss.buttons.search")
        end
      end
      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-approval-deny", text: title1)
        expect(page).to have_no_css(".fc-event-approval-request", text: title2)
      end
      wait_for_ajax
    end
  end
end
