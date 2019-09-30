require 'spec_helper'

describe "gws_attendance_time_card", type: :feature, dbscope: :example, js: true do
  # 勤務体系は 8:30 - 17:15 | 3:00

  let(:site) { gws_site }
  let(:day_0830) { Time.zone.parse("2020/8/30") } #平日
  let(:day_0831) { Time.zone.parse("2020/8/31") } #平日
  let(:day_0901) { Time.zone.parse("2020/9/1") } #平日
  let(:reason) { unique_id }
  let(:memo) { unique_id }

  def punch_enter(now)
    expect(page).to have_css('.today-box .today .info .enter', text: '--:--')
    within '.today-box .today .action .enter' do
      page.accept_confirm do
        click_on I18n.t('gws/attendance.buttons.punch')
      end
    end
    expect(page).to have_css('#notice', text: I18n.t('gws/attendance.notice.punched'))

    hour = now.hour > 3 ? now.hour : now.hour + 24
    min = now.min
    expect(page).to have_css('.today-box .today .info .enter', text: format('%d:%02d', hour, min))
  end

  def punch_leave(now)
    expect(page).to have_css('.today-box .today .info .leave', text: '--:--')
    within '.today-box .today .action .leave' do
      page.accept_confirm do
        click_on I18n.t('gws/attendance.buttons.punch')
      end
    end
    expect(page).to have_css('#notice', text: I18n.t('gws/attendance.notice.punched'))

    hour = now.hour > 3 ? now.hour : now.hour + 24
    min = now.min
    expect(page).to have_css('.today-box .today .info .leave', text: format('%d:%02d', hour, min))
  end

  def check_time_card_record(date)
    Gws::Attendance::TimeCard.where(date: date.change(day: 1).beginning_of_day).first.tap do |time_card|
      expect(time_card.records.where(date: date).count).to eq 1
      time_card.records.where(date: date).first.tap do |record|
        expect(record.date).to eq date
        expect(record.enter).to eq now
        expect(record.leave).to eq now
      end
    end
  end

  context 'basic today crud' do
    context 'punch at 8/31 8:10' do
      let(:now) { day_0831.change(hour: 8, min: 10) }

      it do
        Timecop.freeze(now) do
          login_gws_user
          visit gws_affair_attendance_time_card_main_path(site)

          expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(now, format: :iso)}\"]")
          expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day_0831, format: :iso)}\"]")
          expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day_0830, format: :iso)}\"]")

          expect(page).to have_css(".day-31.current")

          punch_enter(now)
          punch_leave(now)

          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_record(day_0831)
        end
      end
    end

    context 'punch at 8/31 8:30' do
      let(:now) { day_0831.change(hour: 8, min: 30) }

      it do
        Timecop.freeze(now) do
          login_gws_user

          visit gws_affair_attendance_time_card_main_path(site)

          expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(now, format: :iso)}\"]")
          expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day_0831, format: :iso)}\"]")
          expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day_0830, format: :iso)}\"]")

          expect(page).to have_css(".day-31.current")

          punch_enter(now)
          punch_leave(now)

          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_record(day_0831)
        end
      end
    end

    context 'punch at 8/31 13:00' do
      let(:now) { day_0831.change(hour: 13, min: 00) }

      it do
        Timecop.freeze(now) do
          login_gws_user

          visit gws_affair_attendance_time_card_main_path(site)

          expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(now, format: :iso)}\"]")
          expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day_0831, format: :iso)}\"]")
          expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day_0830, format: :iso)}\"]")

          expect(page).to have_css(".day-31.current")

          punch_enter(now)
          punch_leave(now)

          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_record(day_0831)
        end
      end
    end

    context 'punch at 8/31 17:15' do
      let(:now) { day_0831.change(hour: 17, min: 15) }

      it do
        Timecop.freeze(now) do
          login_gws_user

          visit gws_affair_attendance_time_card_main_path(site)

          expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(now, format: :iso)}\"]")
          expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day_0831, format: :iso)}\"]")
          expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day_0830, format: :iso)}\"]")

          expect(page).to have_css(".day-31.current")

          punch_enter(now)
          punch_leave(now)

          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_record(day_0831)
        end
      end
    end

    context 'punch at 8/31 22:30' do
      let(:now) { day_0831.change(hour: 22, min: 30) }

      it do
        Timecop.freeze(now) do
          login_gws_user

          visit gws_affair_attendance_time_card_main_path(site)

          expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(now, format: :iso)}\"]")
          expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day_0831, format: :iso)}\"]")
          expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day_0830, format: :iso)}\"]")

          expect(page).to have_css(".day-31.current")

          punch_enter(now)
          punch_leave(now)

          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_record(day_0831)
        end
      end
    end

    context 'punch at 9/1 2:50' do
      let(:now) { day_0901.change(hour: 2, min: 50) }

      it do
        Timecop.freeze(now) do
          login_gws_user
          visit gws_affair_attendance_time_card_main_path(site)

          expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(now, format: :iso)}\"]")
          expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day_0831, format: :iso)}\"]")
          expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day_0830, format: :iso)}\"]")

          expect(page).to have_css(".day-31.current")

          punch_enter(now)
          punch_leave(now)

          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_record(day_0831)
        end
      end
    end

    context 'punch at 9/1 4:00 (not punched yesterday time card)' do
      let(:now) { day_0901.change(hour: 4, min: 00) }

      it do
        Timecop.freeze(now) do
          login_gws_user
          visit gws_affair_attendance_time_card_main_path(site)

          expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(now, format: :iso)}\"]")
          expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day_0901, format: :iso)}\"]")
          expect(page).to have_no_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day_0831, format: :iso)}\"]")

          expect(page).to have_css(".day-1.current")

          punch_enter(now)

          expect(Gws::Attendance::TimeCard.count).to eq 1
        end
      end
    end

    context 'punch at 9/1 4:00' do
      let(:now) { day_0901.change(hour: 4, min: 00) }
      let(:yesterday) { now.yesterday }

      it do
        Timecop.freeze(yesterday) do
          login_gws_user
          visit gws_affair_attendance_time_card_main_path(site)
        end

        Timecop.freeze(now) do
          login_gws_user
          visit gws_affair_attendance_time_card_main_path(site)

          expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(now, format: :iso)}\"]")
          expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day_0901, format: :iso)}\"]")
          expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day_0831, format: :iso)}\"]")

          expect(page).to have_css(".day-1.current")

          punch_enter(now)
          punch_leave(now)

          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_record(day_0901)
        end
      end
    end
  end
end
