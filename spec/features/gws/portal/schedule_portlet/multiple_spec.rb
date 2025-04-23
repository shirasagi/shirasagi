require 'spec_helper'

describe "gws_portal_portlet", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:sys_user) { gws_sys_user }
  let(:group) { gws_user.groups.first }
  let(:user_portal_path) { gws_portal_user_path(site: site, user: user) }
  let(:group_portal_path) { gws_portal_group_path(site: site, group: group) }

  let!(:next_week) { Time.zone.now.change(hour: 10, minute: 0, second: 0).advance(weeks: 1) }
  let!(:item1) { create :gws_schedule_plan }
  let!(:item2) { create :gws_schedule_plan, start_at: next_week, end_at: next_week + 1.hour }
  let!(:item3) { create :gws_schedule_plan, member_ids: [sys_user.id] }
  let!(:item4) do
    create :gws_schedule_plan, member_ids: [sys_user.id], start_at: next_week, end_at: next_week + 1.hour
  end

  before do
    login_gws_user
  end

  context "multiple" do
    it do
      visit user_portal_path
      wait_for_ajax

      # destroy default portlet
      click_on I18n.t('gws/portal.links.manage_portlets')
      wait_for_event_fired("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action" do
        page.accept_alert do
          click_button I18n.t('ss.buttons.delete')
        end
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      # create first portlet
      click_on I18n.t('ss.links.new')
      within '.main-box' do
        click_on I18n.t('gws/portal.portlets.schedule.name')
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      # create second portlet
      click_on I18n.t('ss.links.back_to_index')
      click_on I18n.t('ss.links.new')
      within '.main-box' do
        click_on I18n.t('gws/portal.portlets.schedule.name')
      end
      within '#addon-gws-agents-addons-portal-portlet-schedule' do
        choose "item_schedule_member_mode_specific"
        wait_for_cbox_opened { click_on I18n.t("ss.apis.users.index") }
      end
      within_cbox do
        wait_for_cbox_closed { click_on sys_user.long_name }
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      # visit portal
      visit user_portal_path
      wait_for_ajax

      within ".portlets" do
        expect(all(".portlet-model-schedule").size).to eq 2
        within all(".portlet-model-schedule")[0] do
          expect(page).to have_css(".calendar-name", text: user.long_name)
          expect(page).to have_no_css(".calendar-name", text: sys_user.long_name)

          expect(page).to have_css(".fc-content", text: item1.name)
          expect(page).to have_no_css(".fc-content", text: item2.name)
          expect(page).to have_no_css(".fc-content", text: item3.name)
          expect(page).to have_no_css(".fc-content", text: item4.name)
        end
        within all(".portlet-model-schedule")[1] do
          expect(page).to have_no_css(".calendar-name", text: user.long_name)
          expect(page).to have_css(".calendar-name", text: sys_user.long_name)

          expect(page).to have_no_css(".fc-content", text: item1.name)
          expect(page).to have_no_css(".fc-content", text: item2.name)
          expect(page).to have_css(".fc-content", text: item3.name)
          expect(page).to have_no_css(".fc-content", text: item4.name)
        end

        # next week
        within all(".portlet-model-schedule")[0] do
          first(".fc-icon-right-single-arrow").click
          wait_for_ajax

          expect(page).to have_no_css(".fc-content", text: item1.name)
          expect(page).to have_css(".fc-content", text: item2.name)
          expect(page).to have_no_css(".fc-content", text: item3.name)
          expect(page).to have_no_css(".fc-content", text: item4.name)
        end
        within all(".portlet-model-schedule")[1] do
          first(".fc-icon-right-single-arrow").click
          wait_for_ajax

          expect(page).to have_no_css(".fc-content", text: item1.name)
          expect(page).to have_no_css(".fc-content", text: item2.name)
          expect(page).to have_no_css(".fc-content", text: item3.name)
          expect(page).to have_css(".fc-content", text: item4.name)
        end
      end
    end
  end
end
