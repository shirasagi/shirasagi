require 'spec_helper'

describe Gws::Affair2::Loader::Monthly::Base, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  # settings
  let(:leave_setting) { create :gws_affair2_leave_setting }
  let(:duty_setting) { create :gws_affair2_duty_setting }
  let(:attendance_setting) do
    create(:gws_affair2_attendance_setting,
      duty_setting: duty_setting,
      leave_setting: leave_setting,
      organization_uid: user.organization_uid)
  end

  # time_card
  let(:month) { Time.zone.parse("2025/1/1").beginning_of_month }
  let(:time_card) { create :gws_affair2_attendance_time_card, attendance_setting: attendance_setting }

  # day1
  let(:day1) { Time.zone.parse("2025/1/6") }
  let(:enter_day1) { Time.zone.parse("2025/1/6 8:30") }
  let(:leave_day1) { Time.zone.parse("2025/1/6 17:15") }
  let(:break_minutes_day1) { 60 }
  let(:record_day1) do
    record = time_card.records.find_by(date: day1)
    record.enter = enter_day1
    record.leave = leave_day1
    record.break_minutes = break_minutes_day1
    record.save!
    record.reload
    record
  end

  # day2
  let(:day2) { Time.zone.parse("2025/1/7") }
  let(:record_day2) { time_card.records.find_by(date: day2) }
  let(:enter_day2) { Time.zone.parse("2025/1/7 8:30") }
  let(:leave_day2) { Time.zone.parse("2025/1/7 17:15") }
  let(:break_minutes_day2) { 60 }
  let(:record_day2) do
    record = time_card.records.find_by(date: day2)
    record.enter = enter_day2
    record.leave = leave_day2
    record.break_minutes = break_minutes_day2
    record.save!
    record.reload
    record
  end

  # day3
  let(:day3) { Time.zone.parse("2025/1/8") }
  let(:record_day3) { time_card.records.find_by(date: day3) }
  let(:enter_day3) { Time.zone.parse("2025/1/8 8:30") }
  let(:leave_day3) { Time.zone.parse("2025/1/8 12:00") }
  let(:break_minutes_day3) { 0 }
  let(:record_day3) do
    record = time_card.records.find_by(date: day3)
    record.enter = enter_day3
    record.leave = leave_day3
    record.break_minutes = break_minutes_day3
    record.save!
    record.reload
    record
  end

  # overtime1
  let(:overtime1) do
    create(:gws_affair2_overtime_record,
      state: "order",
      entered_at: Time.zone.parse("2025/1/6"),
      date: Time.zone.parse("2025/1/6"),
      start_at: Time.zone.parse("2025/1/6 17:15"),
      close_at: Time.zone.parse("2025/1/6 18:15"),
      break_start_at: Time.zone.parse("2025/1/6 17:15"),
      break_close_at: Time.zone.parse("2025/1/6 17:15"))
  end

  # overtime2
  let(:overtime2) do
    create(:gws_affair2_overtime_record,
      state: "order",
      entered_at: Time.zone.parse("2025/1/7"),
      date: Time.zone.parse("2025/1/7"),
      start_at: Time.zone.parse("2025/1/7 17:15"),
      close_at: Time.zone.parse("2025/1/8 05:00"),
      break_start_at: Time.zone.parse("2025/1/7 21:30"),
      break_close_at: Time.zone.parse("2025/1/7 22:30"))
  end

  # overtime3
  let(:overtime3) do
    create(:gws_affair2_overtime_record,
      state: "order",
      entered_at: Time.zone.parse("2025/1/8"),
      date: Time.zone.parse("2025/1/8"),
      start_at: Time.zone.parse("2025/1/8 17:15"),
      close_at: Time.zone.parse("2025/1/8 18:15"),
      break_start_at: Time.zone.parse("2025/1/8 17:15"),
      break_close_at: Time.zone.parse("2025/1/8 17:30"))
  end

  it do
    Timecop.travel(month) do
      attendance_setting
      time_card

      record_day1
      record_day2
      record_day3

      overtime1
      overtime2
      overtime3

      item = described_class.new(time_card)
      item.load

      expect(item.overtime_short_minutes1).to eq (0 + 0 + 45)
      expect(item.overtime_day_minutes1).to eq (60 + 255 + 0)
      expect(item.overtime_night_minutes1).to eq (0 + 390 + 0)
      expect(item.overtime_short_minutes2).to eq (0 + 0 + 0)
      expect(item.overtime_day_minutes2).to eq (0 + 0 + 0)
      expect(item.overtime_night_minutes2).to eq (0 + 0 + 0)
    end
  end
end
