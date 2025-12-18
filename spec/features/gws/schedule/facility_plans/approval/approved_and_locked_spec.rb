require 'spec_helper'

describe "gws_schedule_facility_plans", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:user1) { create :gws_user, group_ids: user.group_ids, gws_role_ids: [role.id] }
  let!(:user2) { create :gws_user, group_ids: user.group_ids, gws_role_ids: [role.id] }
  let!(:role) { create :gws_role, permissions: (Gws::Role.permission_names - %w(duplicate_private_gws_facility_plans)) }

  let!(:title1) { unique_id }
  let!(:title2) { unique_id }
  let!(:title3) { unique_id }

  before do
    site.update facility_min_hour: 0, facility_max_hour: 24
  end

  context "update_approved_state disbaled" do
    let!(:facility) do
      create(:gws_facility_item, user_ids: [ user2.id ],
        approval_check_state: "enabled")
    end

    it do
      login_user(user1, to: gws_schedule_facilities_path(site: site))

      # create
      within ".gws-schedule-box .calendar-multiple-header" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end
      wait_for_js_ready
      within "form#item-form" do
        fill_in "item[name]", with: title1
      end
      click_button I18n.t('ss.buttons.save')

      wait_for_notice I18n.t('ss.notice.saved')
      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-approval-request", text: title1)
      end

      # approve
      login_user(user2, to: gws_schedule_facilities_path(site: site))

      within ".fc-event:not(.fc-holiday)" do
        first(".fc-title").click
      end
      wait_for_js_ready
      within "#addon-gws-agents-addons-schedule-approval" do
        within "span[data-facility-id='#{facility.id}']" do
          wait_for_cbox_opened { first("input[value='approve']").click }
        end
      end
      within_cbox do
        within "#ajax-box form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end
      end
      wait_for_notice I18n.t('ss.notice.saved')

      # able to edit within user2
      login_user(user2, to: gws_schedule_facilities_path(site: site))

      within ".fc-event:not(.fc-holiday)" do
        first(".fc-title").click
      end
      within "#menu" do
        expect(page).to have_link I18n.t("ss.links.edit")
        expect(page).to have_no_text(I18n.t("errors.messages.edit_approved"))
        click_on I18n.t("ss.links.edit")
      end
      wait_for_js_ready

      within "form#item-form" do
        fill_in "item[name]", with: title2
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-approval-approve", text: title2)
      end

      # able to edit within user1
      login_user(user1, to: gws_schedule_facilities_path(site: site))

      within ".fc-event:not(.fc-holiday)" do
        first(".fc-title").click
      end
      wait_for_js_ready
      within "#menu" do
        expect(page).to have_link I18n.t("ss.links.edit")
        expect(page).to have_no_text(I18n.t("errors.messages.edit_approved"))
        click_on I18n.t("ss.links.edit")
      end
      wait_for_js_ready

      within "form#item-form" do
        fill_in "item[name]", with: title3
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-approval-request", text: title3)
      end
    end
  end

  context "update_approved_state enabled" do
    let!(:facility) do
      create(:gws_facility_item, user_ids: [ user2.id ],
        approval_check_state: "enabled", update_approved_state: "enabled")
    end

    it do
      login_user(user1, to: gws_schedule_facilities_path(site: site))

      # create
      within ".gws-schedule-box .calendar-multiple-header" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end
      wait_for_js_ready
      within "form#item-form" do
        fill_in "item[name]", with: title1
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-approval-request", text: title1)
      end

      # approve
      login_user(user2, to: gws_schedule_facilities_path(site: site))

      within ".fc-event:not(.fc-holiday)" do
        first(".fc-title").click
      end
      wait_for_js_ready
      within "#addon-gws-agents-addons-schedule-approval" do
        within "span[data-facility-id='#{facility.id}']" do
          wait_for_cbox_opened { first("input[value='approve']").click }
        end
      end
      within_cbox do
        within "#ajax-box form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end
      end
      wait_for_notice I18n.t('ss.notice.saved')

      # able to edit within user2
      login_user(user2, to: gws_schedule_facilities_path(site: site))

      within ".fc-event:not(.fc-holiday)" do
        first(".fc-title").click
      end
      wait_for_js_ready
      within "#menu" do
        expect(page).to have_link I18n.t("ss.links.edit")
        expect(page).to have_no_text(I18n.t("errors.messages.edit_approved"))
        click_on I18n.t("ss.links.edit")
      end
      wait_for_js_ready

      within "form#item-form" do
        fill_in "item[name]", with: title2
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-approval-approve", text: title2)
      end

      # disable edit within user1
      login_user(user1, to: gws_schedule_facilities_path(site: site))

      within ".fc-event:not(.fc-holiday)" do
        first(".fc-title").click
      end
      wait_for_js_ready
      within "#menu" do
        expect(page).to have_text(I18n.t("errors.messages.edit_approved"))
        expect(page).to have_no_link I18n.t("ss.links.edit")
      end
    end
  end
end
