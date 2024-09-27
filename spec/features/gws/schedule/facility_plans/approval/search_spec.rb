require 'spec_helper'

describe "gws_schedule_facility_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:facility) { create :gws_facility_item, approval_check_state: "enabled", user_ids: [ user.id ] }
  let!(:item) { create :gws_schedule_facility_plan, facility_ids: [ facility.id ] }

  before do
    item.reset_approvals
    item.update
    item.reload

    login_user user
  end

  context "have duplicate_private_gws_facility_plans" do
    it do
      expect(item.current_approval_state).to eq "request"

      visit gws_schedule_facilities_path(site: site)
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_css(".fc-event-approval-request", text: item.name)
      end
      within first(".fc-event") do
        first(".fc-title").click
      end

      # unknown
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
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      wait_for_ajax

      # search
      visit gws_schedule_facilities_path(site: site)
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_css(".fc-event-approval-request", text: item.name)
      end

      ## request
      within ".gws-schedule-box" do
        within "form.search" do
          select I18n.t("gws/schedule.views.request"), from: "s[approval]"
          click_on I18n.t("ss.buttons.search")
        end
      end
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_css(".fc-event-approval-request", text: item.name)
      end

      ## approve
      within ".gws-schedule-box" do
        within "form.search" do
          select I18n.t("gws/schedule.views.approve"), from: "s[approval]"
          click_on I18n.t("ss.buttons.search")
        end
      end
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_no_css(".fc-event-approval-request", text: item.name)
      end

      ## deny
      within ".gws-schedule-box" do
        within "form.search" do
          select I18n.t("gws/schedule.views.deny"), from: "s[approval]"
          click_on I18n.t("ss.buttons.search")
        end
      end
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_no_css(".fc-event-approval-request", text: item.name)
      end
    end

    it do
      expect(item.current_approval_state).to eq "request"

      visit gws_schedule_facilities_path(site: site)
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_css(".fc-event-approval-request", text: item.name)
      end
      within first(".fc-event") do
        first(".fc-title").click
      end

      # approve
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
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      wait_for_ajax

      # search
      visit gws_schedule_facilities_path(site: site)
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_css(".fc-event-approval-approve", text: item.name)
      end

      ## request
      within ".gws-schedule-box" do
        within "form.search" do
          select I18n.t("gws/schedule.views.request"), from: "s[approval]"
          click_on I18n.t("ss.buttons.search")
        end
      end
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_no_css(".fc-event-approval-approve", text: item.name)
      end

      ## approve
      visit gws_schedule_facilities_path(site: site)
      within ".gws-schedule-box" do
        within "form.search" do
          select I18n.t("gws/schedule.views.approve"), from: "s[approval]"
          click_on I18n.t("ss.buttons.search")
        end
      end
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_css(".fc-event-approval-approve", text: item.name)
      end

      ## deny
      within ".gws-schedule-box" do
        within "form.search" do
          select I18n.t("gws/schedule.views.deny"), from: "s[approval]"
          click_on I18n.t("ss.buttons.search")
        end
      end
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_no_css(".fc-event-approval-approve", text: item.name)
      end
    end

    it do
      expect(item.current_approval_state).to eq "request"

      visit gws_schedule_facilities_path(site: site)
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_css(".fc-event-approval-request", text: item.name)
      end
      within first(".fc-event") do
        first(".fc-title").click
      end

      # deny
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
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      wait_for_ajax

      # search
      visit gws_schedule_facilities_path(site: site)
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_no_css(".fc-event-approval-deny", text: item.name)
      end

      ## request
      within ".gws-schedule-box" do
        within "form.search" do
          select I18n.t("gws/schedule.views.request"), from: "s[approval]"
          click_on I18n.t("ss.buttons.search")
        end
      end
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_no_css(".fc-event-approval-deny", text: item.name)
      end

      ## approve
      visit gws_schedule_facilities_path(site: site)
      within ".gws-schedule-box" do
        within "form.search" do
          select I18n.t("gws/schedule.views.approve"), from: "s[approval]"
          click_on I18n.t("ss.buttons.search")
        end
      end
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_no_css(".fc-event-approval-deny", text: item.name)
      end

      ## deny
      within ".gws-schedule-box" do
        within "form.search" do
          select I18n.t("gws/schedule.views.deny"), from: "s[approval]"
          click_on I18n.t("ss.buttons.search")
        end
      end
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_css(".fc-event-approval-deny", text: item.name)
      end
    end
  end

  context "search next week" do
    let(:name) { unique_id }

    it do
      visit gws_schedule_facilities_path(site: site)

      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_css(".fc-event-approval-request", text: item.name)
      end
      within "#calendar-controller" do
        first(".fc-next-button.fc-button").click
      end
      within ".gws-schedule-box" do
        expect(page).to have_no_css(".fc-event-approval-request", text: item.name)
        click_link I18n.t("gws/schedule.links.add_plan")
      end
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # search
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_no_css(".fc-event-approval-request", text: item.name)
        expect(page).to have_css(".fc-event-approval-request", text: name)
      end

      ## request
      within ".gws-schedule-box" do
        within "form.search" do
          select I18n.t("gws/schedule.views.request"), from: "s[approval]"
          click_on I18n.t("ss.buttons.search")
        end
      end
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_no_css(".fc-event-approval-request", text: item.name)
        expect(page).to have_css(".fc-event-approval-request", text: name)
      end

      ## approve
      within ".gws-schedule-box" do
        within "form.search" do
          select I18n.t("gws/schedule.views.approve"), from: "s[approval]"
          click_on I18n.t("ss.buttons.search")
        end
      end
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_no_css(".fc-event-approval-request", text: item.name)
        expect(page).to have_no_css(".fc-event-approval-request", text: name)
      end

      ## request
      within ".gws-schedule-box" do
        within "form.search" do
          select I18n.t("gws/schedule.views.request"), from: "s[approval]"
          click_on I18n.t("ss.buttons.search")
        end
      end
      within ".gws-schedule-box" do
        wait_for_ajax
        expect(page).to have_no_css(".fc-event-approval-request", text: item.name)
        expect(page).to have_css(".fc-event-approval-request", text: name)
      end
    end
  end
end
