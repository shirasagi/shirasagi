require 'spec_helper'

describe "gws_portal_affair2", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:affair2) { gws_affair2 }

  context "basic" do
    let(:now) { Time.zone.now.change(hour: 8, minute: 0) }
    around do |example|
      travel_to(now) { example.run }
    end

    context "denied with no attendance setting" do
      let!(:user) { gws_user }

      before { login_gws_user }

      it "#index" do
        visit gws_portal_user_path(site, user)
        wait_for_ajax

        click_on I18n.t('gws/portal.links.manage_portlets')
        # destroy default portlet
        wait_for_event_fired("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
        within ".list-head-action" do
          page.accept_alert do
            click_button I18n.t('ss.buttons.delete')
          end
        end
        wait_for_notice I18n.t("ss.notice.deleted")

        # create portlet
        click_on I18n.t('ss.links.new')
        within '.main-box' do
          click_on I18n.t('gws/portal.portlets.affair2.name')
        end
        within 'form#item-form' do
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        # visit portal agein
        visit gws_portal_user_path(site, user)
        within ".portlets .gws-affair2" do
          expect(page).to have_text(I18n.t("gws/affair2.notice.no_attendance_setting", user: user.long_name))
        end
      end
    end

    context "regular user" do
      let(:user) { affair2.users.u3 }
      let(:hour) { 9 }
      let(:minute) { 10 }
      let(:time_text) { "9:10" }

      let(:break_minutes) { 60 }
      let(:minutes_text) { "1:00" }

      let(:reason) { unique_id }
      let(:memo) { unique_id }

      before { login_user(user) }

      it "#index" do
        visit gws_portal_user_path(site, user)
        wait_for_ajax

        click_on I18n.t('gws/portal.links.manage_portlets')
        # destroy default portlet
        wait_for_event_fired("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
        within ".list-head-action" do
          page.accept_alert do
            click_button I18n.t('ss.buttons.delete')
          end
        end
        wait_for_notice I18n.t("ss.notice.deleted")

        # create portlet
        click_on I18n.t('ss.links.new')
        within '.main-box' do
          click_on I18n.t('gws/portal.portlets.affair2.name')
        end
        within 'form#item-form' do
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        # visit portal agein
        visit gws_portal_user_path(site, user)
        wait_for_ajax

        # punch
        within ".portlets .gws-affair2" do
          expect(page).to have_css('.today .info .enter', text: '--:--')
          within '.today .action .enter' do
            page.accept_confirm do
              click_on I18n.t('gws/attendance.buttons.punch')
            end
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('gws/attendance.notice.punched'))
        expect(page).to have_css('.today .info .enter', text: format('%d:%02d', now.hour, now.min))

        within ".portlets .gws-affair2" do
          expect(page).to have_css('.today .info .leave', text: '--:--')
          within '.today .action .leave' do
            page.accept_confirm do
              click_on I18n.t('gws/attendance.buttons.punch')
            end
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('gws/attendance.notice.punched'))
        expect(page).to have_css('.today .info .leave', text: format('%d:%02d', now.hour, now.min))

        # edit
        within ".portlets .gws-affair2" do
          within '.today .action .enter' do
            wait_for_cbox_opened { click_on I18n.t('ss.buttons.edit') }
          end
        end
        within_cbox do
          select I18n.t("gws/attendance.hour", count: hour), from: 'item[hour]'
          select I18n.t("gws/attendance.minute", count: minute), from: 'item[minute]'
          fill_in 'item[reason]', with: reason
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('#notice', text: I18n.t("ss.notice.saved"))
        expect(page).to have_css('.today .info .enter', text: time_text)

        within ".portlets .gws-affair2" do
          within '.today .action .leave' do
            wait_for_cbox_opened { click_on I18n.t('ss.buttons.edit') }
          end
        end
        within_cbox do
          select I18n.t("gws/attendance.hour", count: hour), from: 'item[hour]'
          select I18n.t("gws/attendance.minute", count: minute), from: 'item[minute]'
          fill_in 'item[reason]', with: reason
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('#notice', text: I18n.t("ss.notice.saved"))
        expect(page).to have_css('.today .info .leave', text: time_text)

        within ".portlets .gws-affair2" do
          within '.today .action .break-time' do
            wait_for_cbox_opened { click_on I18n.t('ss.buttons.edit') }
          end
        end
        within_cbox do
          select I18n.t("gws/attendance.minute", count: break_minutes), from: 'item[minutes]'
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('#notice', text: I18n.t("ss.notice.saved"))
        expect(page).to have_css('.today .info .break-time', text: minutes_text)

        # memo
        within ".portlets .gws-affair2" do
          expect(page).to have_css('.today .info .memo', text: '')
          within '.today .action .memo' do
            wait_for_cbox_opened { click_on I18n.t('ss.buttons.edit') }
          end
        end
        within_cbox do
          fill_in 'item[memo]', with: memo
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('#notice', text: I18n.t("ss.notice.saved"))
        expect(page).to have_css('.today .info .memo', text: memo)
      end
    end
  end
end
