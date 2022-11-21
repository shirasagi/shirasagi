require 'spec_helper'

describe "gws_attendance_time_card", type: :feature, dbscope: :example, js: true do
  before { create_affair_users }

  let(:site) { affair_site }
  let(:user_638) { affair_user(638) }
  let(:user_545) { affair_user(545) }

  let(:user_638_group) { user_638.groups.first }
  let(:user_545_group) { user_545.groups.first }

  let(:user_638_enter) { Time.zone.parse("2020/8/30 8:30") }
  let(:user_638_leave) { Time.zone.parse("2020/8/30 17:00") }

  let(:user_545_enter) { Time.zone.parse("2020/8/30 8:12") }
  let(:user_545_leave) { Time.zone.parse("2020/8/30 20:32") }

  let(:index_path) { gws_affair_attendance_time_card_groups_main_path(site: site) }

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

  def time_card_title(date, group)
    I18n.t('gws/attendance.formats.time_card_daily_name', day: I18n.l(date.to_date, format: :attendance_day), group: group.trailing_name)
  end

  it do
    login_user(user_638)
    visit index_path

    within "form select" do
      user_638.groups.each do |group|
        expect(page).to have_css("option[value=\"#{group.id}\"]")
      end
      user_545.groups.each do |group|
        expect(page).to have_no_css("option[value=\"#{group.id}\"]")
      end
    end

    login_user(user_545)
    visit index_path
    within "form select" do
      user_638.groups.each do |group|
        expect(page).to have_css("option[value=\"#{group.id}\"]")
      end
      user_545.groups.each do |group|
        expect(page).to have_css("option[value=\"#{group.id}\"]")
      end
    end
  end

  it do
    Timecop.freeze(user_638_enter) do
      login_user(user_638)
      visit gws_affair_attendance_time_card_main_path(site)
      punch_enter(user_638_enter)
    end

    Timecop.freeze(user_545_enter) do
      login_user(user_545)
      visit gws_affair_attendance_time_card_main_path(site)
      punch_enter(user_545_enter)
    end

    Timecop.freeze(user_638_leave) do
      login_user(user_638)
      visit gws_affair_attendance_time_card_main_path(site)
      punch_leave(user_638_leave)
    end

    Timecop.freeze(user_545_leave) do
      login_user(user_545)
      visit gws_affair_attendance_time_card_main_path(site)
      punch_leave(user_545_leave)
    end

    login_user(user_638)
    visit index_path
    # change group
    within "form" do
      select user_638_group.name, from: 'group_id'
      click_on "検索"
    end

    within ".attendance-box.daily" do
      expect(page).to have_css(".attendance-box-title", text: time_card_title(Time.zone.today, user_638_group))

      # change year month
      select "2020年8月", from: 'year_month'
      expect(page).to have_css(".attendance-box-title", text: time_card_title(Time.zone.parse("2020/8/#{Time.zone.today.day}"), user_638_group))

      # change day
      select "30日", from: 'day'
      expect(page).to have_css(".attendance-box-title", text: time_card_title(Time.zone.parse("2020/8/30"), user_638_group))

      within ".time-card" do
        expect(page).to have_css(".time.enter", text: "8:30")
        expect(page).to have_css(".time.leave", text: "17:00")
        expect(page).to have_css(".time.working-time", text: "7:45")
      end
    end

    login_user(user_545)
    visit index_path
    # change group
    within "form" do
      select user_638_group.name, from: 'group_id'
      click_on "検索"
    end

    within ".attendance-box.daily" do
      expect(page).to have_css(".attendance-box-title", text: time_card_title(Time.zone.today, user_638_group))

      # change year month
      select "2020年8月", from: 'year_month'
      expect(page).to have_css(".attendance-box-title", text: time_card_title(Time.zone.parse("2020/8/#{Time.zone.today.day}"), user_638_group))

      # change day
      select "30日", from: 'day'
      expect(page).to have_css(".attendance-box-title", text: time_card_title(Time.zone.parse("2020/8/30"), user_638_group))

      within ".time-card" do
        expect(page).to have_css(".time.enter", text: "8:30")
        expect(page).to have_css(".time.leave", text: "17:00")
        expect(page).to have_css(".time.working-time", text: "7:45")
      end
    end

    # change group
    within "form" do
      select user_545_group.name, from: 'group_id'
      click_on "検索"
    end

    within ".attendance-box.daily" do
      expect(page).to have_css(".attendance-box-title", text: time_card_title(Time.zone.parse("2020/8/30"), user_545_group))
      within ".time-card" do
        expect(page).to have_css(".time.enter", text: "8:12")
        expect(page).to have_css(".time.leave", text: "20:32")
        expect(page).to have_css(".time.working-time", text: "7:45")
      end
    end
  end
end
