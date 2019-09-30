require 'spec_helper'

describe "gws_attendance_time_card", type: :feature, dbscope: :example, js: true do
  # 勤務体系は 8:30 - 17:15 | 3:00

  let(:site) { gws_site }
  let(:day_0830) { Time.zone.parse("2020/8/30") } #平日
  let(:day_0831) { Time.zone.parse("2020/8/31") } #平日
  let(:day_0901) { Time.zone.parse("2020/9/1") } #平日
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

  def edit_enter(before_hour, before_min, after_hour, after_min)
    before_label = "#{before_hour}:#{format('%02d', before_min)}"
    after_label = "#{after_hour}:#{format('%02d', after_min)}"

    expect(page).to have_css('.today-box .today .info .enter', text: before_label)
    within '.today-box .today .action .enter' do
      click_on I18n.t('ss.buttons.edit')
    end
    wait_for_cbox do
      expect(page).to have_css('[name="cell[in_hour]"] [selected]', text: "#{before_hour}時")
      expect(page).to have_css('[name="cell[in_minute]"] [selected]', text: "#{before_min}分")

      select "#{after_hour}時", from: 'cell[in_hour]'
      select "#{after_min}分", from: 'cell[in_minute]'
      select reason_type, from: 'cell[in_reason_type]'
      click_on I18n.t('ss.buttons.save')
    end
    expect(page).to have_css('.today-box .today .info .enter', text: after_label)
  end

  def edit_leave(before_day, before_hour, before_min, after_day, after_hour, after_min)
    before_label = (before_day == "翌日") ? "翌#{before_hour}:#{format('%02d', before_min)}" : "#{before_hour}:#{format('%02d', before_min)}"
    after_label = (after_day == "翌日") ? "翌#{after_hour}:#{format('%02d', after_min)}" : "#{after_hour}:#{format('%02d', after_min)}"

    expect(page).to have_css('.today-box .today .info .leave', text: before_label)
    within '.today-box .today .action .leave' do
      click_on I18n.t('ss.buttons.edit')
    end
    wait_for_cbox do
      expect(page).to have_css('[name="cell[in_day]"] [selected]', text: before_day)
      expect(page).to have_css('[name="cell[in_hour]"] [selected]', text: "#{before_hour}時")
      expect(page).to have_css('[name="cell[in_minute]"] [selected]', text: "#{before_min}分")

      select after_day, from: 'cell[in_day]'
      select "#{after_hour}時", from: 'cell[in_hour]'
      select "#{after_min}分", from: 'cell[in_minute]'
      select reason_type, from: 'cell[in_reason_type]'
      click_on I18n.t('ss.buttons.save')
    end
    expect(page).to have_css('.today-box .today .info .leave', text: after_label)
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

          edit_enter(8, 10, 8, 32)
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_enter(day_0831, Time.zone.parse("2020/8/31 08:32"))

          edit_enter(8, 32, 13, 35)
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_enter(day_0831, Time.zone.parse("2020/8/31 13:35"))

          edit_enter(13, 35,26, 55)
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_enter(day_0831, Time.zone.parse("2020/9/1 2:55"))

          edit_enter(26, 55,8, 10)
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_enter(day_0831, Time.zone.parse("2020/8/31 8:10"))
        end
      end
    end

    context 'edit at 9/1 2:55' do
      let(:now) { day_0901.change(hour: 2, min: 55) }

      it do
        Timecop.freeze(now) do
          login_gws_user
          visit gws_affair_attendance_time_card_main_path(site)

          expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(now, format: :iso)}\"]")
          expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day_0831, format: :iso)}\"]")
          expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day_0830, format: :iso)}\"]")

          expect(page).to have_css(".day-31.current")

          punch_enter(now)

          edit_enter(26, 55,8, 32)
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_enter(day_0831, Time.zone.parse("2020/8/31 08:32"))

          edit_enter(8, 32,13, 35)
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_enter(day_0831, Time.zone.parse("2020/8/31 13:35"))

          edit_enter(13, 35,26, 55)
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_enter(day_0831, Time.zone.parse("2020/9/1 2:55"))

          edit_enter(26, 55,8, 10)
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_enter(day_0831, Time.zone.parse("2020/8/31 8:10"))
        end
      end
    end

    context 'edit at 9/1 4:20' do
      let(:now) { day_0901.change(hour: 4, min: 20) }
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

          edit_enter(4, 20,8, 32)
          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_enter(day_0901, Time.zone.parse("2020/9/1 08:32"))

          edit_enter(8, 32,13, 35)
          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_enter(day_0901, Time.zone.parse("2020/9/1 13:35"))

          edit_enter(13, 35,26, 55)
          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_enter(day_0901, Time.zone.parse("2020/9/2 2:55"))

          edit_enter(26, 55,8, 10)
          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_enter(day_0901, Time.zone.parse("2020/9/1 8:10"))
        end
      end
    end
  end

  context 'edit leave' do
    context 'edit at 8/31 8:10' do
      let(:now) { day_0831.change(hour: 8, min: 10) }

      it do
        Timecop.freeze(now) do
          login_gws_user
          visit gws_affair_attendance_time_card_main_path(site)

          expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(now, format: :iso)}\"]")
          expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day_0831, format: :iso)}\"]")
          expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day_0830, format: :iso)}\"]")

          expect(page).to have_css(".day-31.current")

          punch_leave(now)

          edit_leave("当日", 8, 10, "当日", 8, 32)
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day_0831, Time.zone.parse("2020/8/31 08:32"))

          edit_leave("当日", 8, 32, "当日", 13, 35)
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day_0831, Time.zone.parse("2020/8/31 13:35"))

          edit_leave("当日", 13, 35, "当日", 26, 55)
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day_0831, Time.zone.parse("2020/9/1 2:55"))

          edit_leave("当日", 26, 55, "翌日", 6, 1)
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day_0831, Time.zone.parse("2020/9/1 6:01"))

          edit_leave("翌日", 6, 1, "当日", 8, 10)
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day_0831, Time.zone.parse("2020/8/31 8:10"))
        end
      end
    end

    context 'edit at 9/1 2:55' do
      let(:now) { day_0901.change(hour: 2, min: 55) }

      it do
        Timecop.freeze(now) do
          login_gws_user
          visit gws_affair_attendance_time_card_main_path(site)

          expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(now, format: :iso)}\"]")
          expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day_0831, format: :iso)}\"]")
          expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day_0830, format: :iso)}\"]")

          expect(page).to have_css(".day-31.current")

          punch_leave(now)

          edit_leave("当日", 26, 55, "当日", 8, 32)
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day_0831, Time.zone.parse("2020/8/31 08:32"))

          edit_leave("当日", 8, 32, "当日", 13, 35)
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day_0831, Time.zone.parse("2020/8/31 13:35"))

          edit_leave("当日", 13, 35, "当日", 26, 55)
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day_0831, Time.zone.parse("2020/9/1 2:55"))

          edit_leave("当日", 26, 55, "翌日", 6, 1)
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day_0831, Time.zone.parse("2020/9/1 6:01"))

          edit_leave("翌日", 6, 1, "当日", 8, 10)
          expect(Gws::Attendance::TimeCard.count).to eq 1
          check_time_card_leave(day_0831, Time.zone.parse("2020/8/31 8:10"))
        end
      end
    end

    context 'edit at 9/1 4:20' do
      let(:now) { day_0901.change(hour: 4, min: 20) }
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

          punch_leave(now)

          edit_leave("当日", 4, 20, "当日", 8, 32)
          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_leave(day_0901, Time.zone.parse("2020/9/1 08:32"))

          edit_leave("当日", 8, 32, "当日", 13, 35)
          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_leave(day_0901, Time.zone.parse("2020/9/1 13:35"))

          edit_leave("当日", 13, 35, "当日", 26, 55)
          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_leave(day_0901, Time.zone.parse("2020/9/2 2:55"))

          edit_leave("当日", 26, 55, "翌日", 6, 1)
          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_leave(day_0901, Time.zone.parse("2020/9/2 6:01"))

          edit_leave("翌日", 6, 1, "当日", 8, 10)
          expect(Gws::Attendance::TimeCard.count).to eq 2
          check_time_card_leave(day_0901, Time.zone.parse("2020/9/1 8:10"))
        end
      end
    end
  end
end
