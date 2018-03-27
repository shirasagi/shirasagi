require 'spec_helper'

describe "gws_attendance_time_card", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let(:reason) { unique_id }
  let(:memo) { unique_id }

  before do
    site.attendance_break_time1_state = 'show'
    site.attendance_break_time2_state = 'show'
    site.attendance_break_time3_state = 'show'
    site.save!
  end

  context 'basic today crud' do
    before { login_gws_user }

    context 'punch and edit' do
      it do
        visit gws_attendance_main_path(site)
        expect(page).to have_css('.today .info .enter', text: '--:--')

        # punch
        Timecop.freeze(now) do
          within '.today .action .enter' do
            page.accept_confirm do
              click_on I18n.t('gws/attendance.buttons.punch')
            end
          end
          expect(page).to have_css('.today .info .enter', text: format('%d:%02d', now.hour, now.min))
        end

        expect(Gws::Attendance::TimeCard.count).to eq 1
        Gws::Attendance::TimeCard.first.tap do |time_card|
          expect(time_card.records.where(date: now.beginning_of_day).count).to eq 1
          time_card.records.where(date: now.beginning_of_day).first.tap do |record|
            expect(record.enter).to eq now
          end
        end

        # edit
        within '.today .action .enter' do
          click_on I18n.t('ss.buttons.edit')
        end
        within '#cboxLoadedContent form.cell-edit' do
          select '8時', from: 'cell[in_hour]'
          select '32分', from: 'cell[in_minute]'
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
      end
    end

    context 'punch and clear' do
      it do
        visit gws_attendance_main_path(site)

        # punch
        Timecop.freeze(now) do
          within '.today .action .enter' do
            page.accept_confirm do
              click_on I18n.t('gws/attendance.buttons.punch')
            end
          end
          expect(page).to have_css('.today .info .enter', text: format('%d:%02d', now.hour, now.min))
        end

        # edit
        within '.today .action .enter' do
          click_on I18n.t('ss.buttons.edit')
        end
        within '#cboxLoadedContent form.cell-edit' do
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

    context 'memo' do
      it do
        visit gws_attendance_main_path(site)
        within '.today .action .memo' do
          click_on I18n.t('ss.buttons.edit')
        end
        within '#cboxLoadedContent form' do
          fill_in 'record[memo]', with: memo
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('.today .info .memo', text: memo)

        expect(Gws::Attendance::TimeCard.count).to eq 1
        Gws::Attendance::TimeCard.first.tap do |time_card|
          expect(time_card.records.where(date: now.beginning_of_day).count).to eq 1
          time_card.records.where(date: now.beginning_of_day).first.tap do |record|
            expect(record.memo).to eq memo
          end
        end
      end
    end
  end
end
