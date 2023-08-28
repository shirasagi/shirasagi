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

  def punch_yesterday_leave(now)
    expect(page).to have_css('.yesterday-box .today .info .leave', text: '--:--')
    within '.yesterday-box .today .action .leave' do
      page.accept_confirm do
        click_on I18n.t('gws/attendance.buttons.punch')
      end
    end
    expect(page).to have_css('#notice', text: I18n.t('gws/attendance.notice.punched'))
    wait_for_js_ready

    hour = now.hour > 3 ? now.hour : now.hour + 24
    min = now.min
    expect(page).to have_css('.yesterday-box .today .info .leave', text: format('%d:%02d', hour, min))
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

  context 'punch at 9/1 8:10' do
    let(:now) { day0901.change(hour: 8, min: 10) }
    let(:yesterday) { now.yesterday }

    it do
      Timecop.freeze(yesterday) do
        # create 8 month's time card
        login_gws_user
        visit gws_affair_attendance_main_path(site)

        expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(yesterday, format: :iso)}\"]")
        expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day0831, format: :iso)}\"]")
        expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day0830, format: :iso)}\"]")
      end

      Timecop.freeze(now) do
        login_gws_user
        visit gws_affair_attendance_main_path(site)

        expect(page).to have_css('.yesterday-box .today .enter [name="punch"][disabled]')
        expect(page).to have_css('.yesterday-box .today .leave [name="punch"][disabled]')
      end
    end
  end

  context 'punch at 8/31 8:10' do
    let(:now) { day0901.change(hour: 8, min: 10) }
    let(:yesterday) { now.yesterday }

    it do
      Timecop.freeze(yesterday) do
        login_gws_user
        visit gws_affair_attendance_main_path(site)

        expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(yesterday, format: :iso)}\"]")
        expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day0831, format: :iso)}\"]")
        expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day0830, format: :iso)}\"]")

        expect(page).to have_css(".day-31.current")

        punch_enter(yesterday)
        punch_leave(yesterday)
      end

      Timecop.freeze(now) do
        login_gws_user
        visit gws_affair_attendance_main_path(site)

        expect(page).to have_css('.yesterday-box .today .enter [name="edit"]')
        expect(page).to have_css('.yesterday-box .today .leave [name="edit"]')
      end
    end
  end

  context 'punch at 8/31 8:10, 9/1 8:10' do
    let(:now) { day0901.change(hour: 8, min: 10) }
    let(:yesterday) { now.yesterday }

    it do
      Timecop.freeze(yesterday) do
        login_gws_user
        visit gws_affair_attendance_main_path(site)

        expect(page).to have_css(".cur-date[datetime=\"#{I18n.l(yesterday, format: :iso)}\"]")
        expect(page).to have_css(".today-box .attendance-date[datetime=\"#{I18n.l(day0831, format: :iso)}\"]")
        expect(page).to have_css(".yesterday-box .attendance-date[datetime=\"#{I18n.l(day0830, format: :iso)}\"]")

        expect(page).to have_css(".day-31.current")

        punch_enter(yesterday)
      end

      Timecop.freeze(now) do
        login_gws_user
        visit gws_affair_attendance_main_path(site)

        expect(page).to have_css('.yesterday-box .today .info .enter', text: format('%d:%02d', yesterday.hour, yesterday.min))
        expect(page).to have_no_css('.yesterday-box .today .leave [name="punch"][disabled]')

        punch_yesterday_leave(yesterday)
      end
    end
  end
end
