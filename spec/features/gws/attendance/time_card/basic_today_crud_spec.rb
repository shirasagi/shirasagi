require 'spec_helper'

describe "gws_attendance_time_card", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let(:reason) { unique_id }
  let(:memo) { unique_id }

  before do
    login_gws_user

    site.attendance_break_time1_state = 'show'
    site.attendance_break_time2_state = 'show'
    site.attendance_break_time3_state = 'show'
    site.save!
  end

  context 'basic today crud' do
    context 'punch and edit' do
      let(:now) { Time.zone.now.change(hour: 8, minute: 0) }

      around do |example|
        travel_to(now) { example.run }
      end

      it do
        # punch
        visit gws_attendance_main_path(site)
        expect(page).to have_css('.today .info .enter', text: '--:--')

        within '.today .action .enter' do
          page.accept_confirm do
            click_on I18n.t('gws/attendance.buttons.punch')
          end
        end
        wait_for_notice I18n.t('gws/attendance.notice.punched')
        expect(page).to have_css('.today .info .enter', text: format('%d:%02d', now.hour, now.min))

        expect(Gws::Attendance::TimeCard.count).to eq 1
        Gws::Attendance::TimeCard.first.tap do |time_card|
          expect(time_card.records.where(date: now.beginning_of_day).count).to eq 1
          time_card.records.where(date: now.beginning_of_day).first.tap do |record|
            expect(record.enter).to eq now
          end
        end

        # edit
        within '.today .action .enter' do
          wait_for_cbox_opened { click_on I18n.t('ss.buttons.edit') }
        end
        within_cbox do
          select I18n.t("gws/attendance.hour", count: 8), from: 'cell[in_hour]'
          select I18n.t("gws/attendance.minute", count: 32), from: 'cell[in_minute]'
          fill_in 'cell[in_reason]', with: reason
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('.today .info .enter', text: '8:32')

        expect(Gws::Attendance::TimeCard.count).to eq 1
        Gws::Attendance::TimeCard.first.tap do |time_card|
          expect(time_card.records.where(date: now.beginning_of_day).count).to eq 1
          time_card.records.where(date: now.beginning_of_day).first.tap do |record|
            expect(record.enter).to eq now.change(hour: 8, min: 32)
          end
        end

        # clear
        within '.today .action .enter' do
          wait_for_cbox_opened { click_on I18n.t('ss.buttons.edit') }
        end
        within_cbox do
          click_on I18n.t('ss.buttons.clear')
          fill_in 'cell[in_reason]', with: reason
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('.today .info .enter', text: '--:--')

        expect(Gws::Attendance::TimeCard.count).to eq 1
        Gws::Attendance::TimeCard.first.tap do |time_card|
          expect(time_card.records.where(date: now.beginning_of_day).count).to eq 1
          time_card.records.where(date: now.beginning_of_day).first.tap do |record|
            expect(record.enter).to be_nil
          end
        end
      end
    end

    context 'punch on midnight' do
      let(:now) { Time.zone.now.beginning_of_minute.change(hour: 1) }

      around do |example|
        travel_to(now) { example.run }
      end

      it do
        visit gws_attendance_main_path(site)
        expect(page).to have_css('.today .info .enter', text: '--:--')

        within '.today .action .enter' do
          page.accept_confirm do
            click_on I18n.t('gws/attendance.buttons.punch')
          end
        end
        expect(page).to have_css('.today .info .enter', text: '--:--')
      end
    end
  end
end
