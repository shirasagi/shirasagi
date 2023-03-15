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

  context 'basic monthly crud' do
    before { login_gws_user }

    context 'punch and clear at 8th day' do
      let(:the_day) { now.day == 8 ? 7 : 8 }

      it do
        visit gws_attendance_main_path(site)
        expect(page).to have_css(".monthly td.leave[data-day='#{the_day}']", text: '--:--')

        # edit
        find(".monthly td.leave[data-day='#{the_day}']").click
        within '.cell-toolbar' do
          wait_cbox_open { click_on I18n.t('ss.links.edit') }
        end
        wait_for_cbox do
          select I18n.t("gws/attendance.hour", count: 25), from: 'cell[in_hour]'
          select I18n.t("gws/attendance.minute", count: 48), from: 'cell[in_minute]'
          fill_in 'cell[in_reason]', with: reason
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css(".monthly td.leave[data-day='#{the_day}']", text: '25:48')

        expect(Gws::Attendance::TimeCard.count).to eq 1
        Gws::Attendance::TimeCard.first.tap do |time_card|
          expect(time_card.records.where(date: now.change(day: the_day).beginning_of_day).count).to eq 1
          time_card.records.where(date: now.change(day: the_day).beginning_of_day).first.tap do |record|
            # leave has next day at 1:48
            expect(record.leave).to eq now.change(day: the_day + 1, hour: 1, min: 48)
          end
        end

        find(".monthly td.leave[data-day='#{the_day}']").click
        within '.cell-toolbar' do
          wait_cbox_open { click_on I18n.t('ss.links.edit') }
        end
        wait_for_cbox do
          click_on I18n.t('ss.buttons.clear')
          fill_in 'cell[in_reason]', with: reason
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css(".monthly td.leave[data-day='#{the_day}']", text: '--:--')

        expect(Gws::Attendance::TimeCard.count).to eq 1
        Gws::Attendance::TimeCard.first.tap do |time_card|
          expect(time_card.records.where(date: now.change(day: the_day).beginning_of_day).count).to eq 1
          time_card.records.where(date: now.change(day: the_day).beginning_of_day).first.tap do |record|
            expect(record.leave).to be_nil
          end
        end
      end
    end

    context 'edit memo at 23th day' do
      let(:the_day) { now.day == 23 ? 22 : 23 }

      it do
        visit gws_attendance_main_path(site)
        expect(page).to have_css(".monthly td.memo[data-day='#{the_day}']", text: '')

        find(".monthly td.memo[data-day='#{the_day}']").click
        within '.cell-toolbar' do
          wait_cbox_open { click_on I18n.t('ss.links.edit') }
        end
        wait_for_cbox do
          fill_in 'record[memo]', with: memo
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css(".monthly td.memo[data-day='#{the_day}']", text: memo)

        expect(Gws::Attendance::TimeCard.count).to eq 1
        Gws::Attendance::TimeCard.first.tap do |time_card|
          expect(time_card.records.where(date: now.change(day: the_day).beginning_of_day).count).to eq 1
          time_card.records.where(date: now.change(day: the_day).beginning_of_day).first.tap do |record|
            expect(record.memo).to eq memo
          end
        end
      end
    end

    context 'navigate to prev month' do
      it do
        visit gws_attendance_main_path(site)

        within '.monthly .nav-menu' do
          click_on I18n.t('gws/attendance.prev_month')
        end

        within '.monthly' do
          expect(page).to have_content(I18n.t('gws/attendance.no_time_cards'))
        end
      end
    end

    context 'navigate to next month' do
      it do
        visit gws_attendance_main_path(site)

        within '.monthly .nav-menu' do
          click_on I18n.t('gws/attendance.next_month')
        end

        within '.monthly' do
          expect(page).to have_content(I18n.t('gws/attendance.no_time_cards'))
        end
      end
    end

    context 'download' do
      it do
        visit gws_attendance_main_path(site)

        within '.monthly .nav-operation' do
          click_on I18n.t('ss.buttons.download')
        end
      end
    end

    context 'print' do
      it do
        visit gws_attendance_main_path(site)

        within '.monthly .nav-operation' do
          click_on I18n.t('ss.buttons.print')
        end

        within '.sheet' do
          title = I18n.t(
            'gws/attendance.formats.time_card_full_name',
            user_name: gws_user.name,
            month: I18n.l(now.to_date, format: :attendance_year_month)
          )
          expect(page).to have_css('.attendance-box-title', text: title)
        end
      end
    end
  end
end
