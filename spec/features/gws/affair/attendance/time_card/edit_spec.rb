require 'spec_helper'

describe "gws_attendance_time_card", type: :feature, dbscope: :example, js: true do
  # 勤務時間は 8:30 - 17:15 | 3:00

  let(:site) { gws_site }
  let(:day0830) { Time.zone.parse("2020/8/30") } #平日
  let(:day0831) { Time.zone.parse("2020/8/31") } #平日
  let(:day0901) { Time.zone.parse("2020/9/1") } #平日
  let(:reason_type) { I18n.t("gws/attendance.options.reason_type.mistake") }
  let(:memo) { unique_id }

  def punch_enter(now)
    expect(page).to have_css('.today-box .today .info .enter', text: '--:--')
    within '.today-box .today .action .enter' do
      page.accept_confirm do
        click_on I18n.t('gws/attendance.buttons.punch')
      end
    end
    expect(page).to have_css('#notice', text: I18n.t('gws/attendance.notice.punched'))
    wait_for_js_ready

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
    wait_for_js_ready

    hour = now.hour > 3 ? now.hour : now.hour + 24
    min = now.min
    expect(page).to have_css('.today-box .today .info .leave', text: format('%d:%02d', hour, min))
  end

  def edit_enter(before_value, after_value)
    expect(page).to have_css('.today-box .today .info .enter', text: before_value)
    within '.today-box .today .action .enter' do
      wait_cbox_open { click_on I18n.t('ss.buttons.edit') }
    end
    wait_for_cbox do
      hour, min = before_value.split(":")
      expect(page).to have_css('[name="cell[in_hour]"] [selected]', text: I18n.t("gws/attendance.hour", count: hour))
      expect(page).to have_css('[name="cell[in_minute]"] [selected]', text: I18n.t("gws/attendance.minute", count: min))

      hour, min = after_value.split(":")
      select I18n.t("gws/attendance.hour", count: hour), from: 'cell[in_hour]'
      select I18n.t("gws/attendance.minute", count: min), from: 'cell[in_minute]'
      select reason_type, from: 'cell[in_reason_type]'
      click_on I18n.t('ss.buttons.save')
    end
    expect(page).to have_css('.today-box .today .info .enter', text: after_value)
  end

  def edit_leave(before_day, before_value, after_day, after_value)
    expect(page).to have_css('.today-box .today .info .leave', text: before_value)
    within '.today-box .today .action .leave' do
      wait_cbox_open { click_on I18n.t('ss.buttons.edit') }
    end
    wait_for_cbox do
      hour, min = before_value.split(":")
      expect(page).to have_css('[name="cell[in_day]"] [selected]', text: before_day)
      expect(page).to have_css('[name="cell[in_hour]"] [selected]', text: I18n.t("gws/attendance.hour", count: hour))
      expect(page).to have_css('[name="cell[in_minute]"] [selected]', text: I18n.t("gws/attendance.minute", count: min))

      hour, min = after_value.split(":")
      select after_day, from: 'cell[in_day]'
      select I18n.t("gws/attendance.hour", count: hour), from: 'cell[in_hour]'
      select I18n.t("gws/attendance.minute", count: min), from: 'cell[in_minute]'
      select reason_type, from: 'cell[in_reason_type]'
      click_on I18n.t('ss.buttons.save')
    end
    expect(page).to have_css('.today-box .today .info .leave', text: after_value)
  end

  def check_time_card_leave(date, now)
    Gws::Attendance::TimeCard.where(date: date.change(day: 1).beginning_of_day).first.tap do |time_card|
      expect(time_card.records.where(date: date).count).to eq 1
      time_card.records.where(date: date).first.tap do |record|
        expect(record.date).to eq date
        expect(record.leave).to eq now
      end
    end
  end

  def check_time_card_enter(date, now)
    Gws::Attendance::TimeCard.where(date: date.change(day: 1).beginning_of_day).first.tap do |time_card|
      expect(time_card.records.where(date: date).count).to eq 1
      time_card.records.where(date: date).first.tap do |record|
        expect(record.date).to eq date
        expect(record.enter).to eq now
      end
    end
  end

  context 'edit enter' do
    context 'edit at 8/31 8:10' do
      let(:now) { day0831.change(hour: 8, min: 10) }

      it do
        Timecop.freeze(now) do
          login_gws_user
          visit gws_affair_attendance_main_path(site)

          expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(now, format: :iso)}\"]")
          expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day0831, format: :iso)}\"]")
          expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day0830, format: :iso)}\"]")
          expect(page).to have_css(".day-31.current")

          punch_enter(now)

          edit_enter("8:10", "8:32")
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_enter(day0831, Time.zone.parse("2020/8/31 08:32"))

          edit_enter("8:32", "13:35")
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_enter(day0831, Time.zone.parse("2020/8/31 13:35"))

          edit_enter("13:35", "26:55")
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_enter(day0831, Time.zone.parse("2020/9/1 2:55"))

          edit_enter("26:55", "8:10")
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_enter(day0831, Time.zone.parse("2020/8/31 8:10"))
        end
      end
    end

    context 'edit at 9/1 2:55' do
      let(:now) { day0901.change(hour: 2, min: 55) }

      it do
        Timecop.freeze(now) do
          login_gws_user
          visit gws_affair_attendance_main_path(site)

          expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(now, format: :iso)}\"]")
          expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day0831, format: :iso)}\"]")
          expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day0830, format: :iso)}\"]")
          expect(page).to have_css(".day-31.current")

          punch_enter(now)

          edit_enter("26:55", "8:32")
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_enter(day0831, Time.zone.parse("2020/8/31 08:32"))

          edit_enter("8:32", "13:35")
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_enter(day0831, Time.zone.parse("2020/8/31 13:35"))

          edit_enter("13:35", "26:55")
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_enter(day0831, Time.zone.parse("2020/9/1 2:55"))

          edit_enter("26:55", "8:10")
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_enter(day0831, Time.zone.parse("2020/8/31 8:10"))
        end
      end
    end

    context 'edit at 9/1 4:20' do
      let(:now) { day0901.change(hour: 4, min: 20) }
      let(:yesterday) { now.yesterday }

      it do
        Timecop.freeze(yesterday) do
          login_gws_user
          visit gws_affair_attendance_main_path(site)
        end

        Timecop.freeze(now) do
          login_gws_user
          visit gws_affair_attendance_main_path(site)

          expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(now, format: :iso)}\"]")
          expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day0901, format: :iso)}\"]")
          expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day0831, format: :iso)}\"]")
          expect(page).to have_css(".day-1.current")

          punch_enter(now)

          edit_enter("4:20", "8:32")
          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_enter(day0901, Time.zone.parse("2020/9/1 08:32"))

          edit_enter("8:32", "13:35")
          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_enter(day0901, Time.zone.parse("2020/9/1 13:35"))

          edit_enter("13:35", "26:55")
          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_enter(day0901, Time.zone.parse("2020/9/2 2:55"))

          edit_enter("26:55", "8:10")
          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_enter(day0901, Time.zone.parse("2020/9/1 8:10"))
        end
      end
    end
  end

  context 'edit leave' do
    context 'edit at 8/31 8:10' do
      let(:now) { day0831.change(hour: 8, min: 10) }
      let(:in_today) { I18n.t("gws/attendance.options.in_day.today") }
      let(:in_tomorrow) { I18n.t("gws/attendance.options.in_day.tomorrow") }

      it do
        Timecop.freeze(now) do
          login_gws_user
          visit gws_affair_attendance_main_path(site)

          expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(now, format: :iso)}\"]")
          expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day0831, format: :iso)}\"]")
          expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day0830, format: :iso)}\"]")
          expect(page).to have_css(".day-31.current")

          punch_leave(now)

          edit_leave(in_today, "8:10", in_today, "8:32")
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day0831, Time.zone.parse("2020/8/31 08:32"))

          edit_leave(in_today, "8:32", in_today, "13:35")
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day0831, Time.zone.parse("2020/8/31 13:35"))

          edit_leave(in_today, "13:35", in_today, "26:55")
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day0831, Time.zone.parse("2020/9/1 2:55"))

          edit_leave(in_today, "26:55", in_tomorrow, "6:11")
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day0831, Time.zone.parse("2020/9/1 6:11"))

          edit_leave(in_tomorrow, "6:11", in_today, "8:10")
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day0831, Time.zone.parse("2020/8/31 8:10"))
        end
      end
    end

    context 'edit at 9/1 2:55' do
      let(:now) { day0901.change(hour: 2, min: 55) }
      let(:in_today) { I18n.t("gws/attendance.options.in_day.today") }
      let(:in_tomorrow) { I18n.t("gws/attendance.options.in_day.tomorrow") }

      it do
        Timecop.freeze(now) do
          login_gws_user
          visit gws_affair_attendance_main_path(site)

          expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(now, format: :iso)}\"]")
          expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day0831, format: :iso)}\"]")
          expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day0830, format: :iso)}\"]")
          expect(page).to have_css(".day-31.current")

          punch_leave(now)

          edit_leave(in_today, "26:55", in_today, "8:32")
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day0831, Time.zone.parse("2020/8/31 08:32"))

          edit_leave(in_today, "8:32", in_today, "13:35")
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day0831, Time.zone.parse("2020/8/31 13:35"))

          edit_leave(in_today, "13:35", in_today, "26:55")
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day0831, Time.zone.parse("2020/9/1 2:55"))

          edit_leave(in_today, "26:55", in_tomorrow, "6:11")
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day0831, Time.zone.parse("2020/9/1 6:11"))

          edit_leave(in_tomorrow, "6:11", in_today, "8:10")
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day0831, Time.zone.parse("2020/8/31 8:10"))
        end
      end
    end

    context 'edit at 9/1 4:20' do
      let(:now) { day0901.change(hour: 4, min: 20) }
      let(:yesterday) { now.yesterday }
      let(:in_today) { I18n.t("gws/attendance.options.in_day.today") }
      let(:in_tomorrow) { I18n.t("gws/attendance.options.in_day.tomorrow") }

      it do
        Timecop.freeze(yesterday) do
          login_gws_user
          visit gws_affair_attendance_main_path(site)
        end

        Timecop.freeze(now) do
          login_gws_user
          visit gws_affair_attendance_main_path(site)

          expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(now, format: :iso)}\"]")
          expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day0901, format: :iso)}\"]")
          expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day0831, format: :iso)}\"]")
          expect(page).to have_css(".day-1.current")

          punch_leave(now)

          edit_leave(in_today, "4:20", in_today, "8:32")
          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_leave(day0901, Time.zone.parse("2020/9/1 08:32"))

          edit_leave(in_today, "8:32", in_today, "13:35")
          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_leave(day0901, Time.zone.parse("2020/9/1 13:35"))

          edit_leave(in_today, "13:35", in_today, "26:55")
          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_leave(day0901, Time.zone.parse("2020/9/2 2:55"))

          edit_leave(in_today, "26:55", in_tomorrow, "6:11")
          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_leave(day0901, Time.zone.parse("2020/9/2 6:11"))

          edit_leave(in_tomorrow, "6:11", in_today, "8:10")
          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_leave(day0901, Time.zone.parse("2020/9/1 8:10"))
        end
      end
    end
  end
end
