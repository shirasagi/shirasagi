require 'spec_helper'

describe "gws_schedule_facility_plans", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:user1) { create :gws_user, group_ids: user.group_ids, gws_role_ids: [role1.id] }
  let!(:role1) { create :gws_role, permissions: (Gws::Role.permission_names - %w(duplicate_private_gws_facility_plans)) }

  let!(:facility) { create :gws_facility_item, approval_check_state: "enabled", user_ids: [ user.id, user1.id ] }
  let!(:item) { create :gws_schedule_facility_plan, facility_ids: [ facility.id ] }

  before do
    item.reset_approvals
    item.update
    item.reload
  end

  context "have no duplicate_private_gws_facility_plans" do
    it do
      # approve by user
      login_user(user)
      visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)

      within "#addon-basic" do
        expect(page).to have_text(I18n.t("gws/schedule.options.approved_state.request"))
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        expect(page).to have_no_text(user.long_name)
        expect(page).to have_no_text(user1.long_name)
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
      within "#addon-basic" do
        expect(page).to have_text(I18n.t("gws/schedule.options.approved_state.approve"))
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        expect(page).to have_text(user.long_name)
        expect(page).to have_no_text(user1.long_name)
      end

      # reset by user1
      login_user(user1)
      visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)

      within "#addon-basic" do
        expect(page).to have_text(I18n.t("gws/schedule.options.approved_state.approve"))
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        expect(page).to have_text(user.long_name)
        expect(page).to have_no_text(user1.long_name)
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        within "span[data-facility-id='#{facility.id}']" do
          wait_cbox_open { first("input[value='unknown']").click }
        end
      end
      wait_for_cbox do
        within "#ajax-box form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end
      end
      wait_for_notice I18n.t('ss.notice.saved')
      within "#addon-basic" do
        expect(page).to have_text(I18n.t("gws/schedule.options.approved_state.request"))
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        expect(page).to have_no_text(user.long_name)
        expect(page).to have_no_text(user1.long_name)
      end

      # approve by user
      login_user(user)
      visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)

      within "#addon-basic" do
        expect(page).to have_text(I18n.t("gws/schedule.options.approved_state.request"))
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        expect(page).to have_no_text(user.long_name)
        expect(page).to have_no_text(user1.long_name)
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
      within "#addon-basic" do
        expect(page).to have_text(I18n.t("gws/schedule.options.approved_state.approve"))
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        expect(page).to have_text(user.long_name)
        expect(page).to have_no_text(user1.long_name)
      end

      # deny by user1
      login_user(user1)
      visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)

      within "#addon-basic" do
        expect(page).to have_text(I18n.t("gws/schedule.options.approved_state.approve"))
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        expect(page).to have_text(user.long_name)
        expect(page).to have_no_text(user1.long_name)
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
      within "#addon-basic" do
        expect(page).to have_text(I18n.t("gws/schedule.options.approved_state.deny"))
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        expect(page).to have_no_text(user.long_name)
        expect(page).to have_no_text(user1.long_name)
      end

      # approve by user1
      login_user(user1)
      visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)

      within "#addon-basic" do
        expect(page).to have_text(I18n.t("gws/schedule.options.approved_state.deny"))
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        expect(page).to have_no_text(user.long_name)
        expect(page).to have_no_text(user1.long_name)
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
      within "#addon-basic" do
        expect(page).to have_text(I18n.t("gws/schedule.options.approved_state.approve"))
      end
      within "#addon-gws-agents-addons-schedule-approval" do
        expect(page).to have_no_text(user.long_name)
        expect(page).to have_text(user1.long_name)
      end
    end
  end
end
