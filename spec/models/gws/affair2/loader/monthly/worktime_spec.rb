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

  # day1 465m
  let(:day1) { Time.zone.parse("2025/1/6") }
  let(:enter_day1) { Time.zone.parse("2025/1/6 8:30") }
  let(:leave_day1) { Time.zone.parse("2025/1/6 17:15") }
  let(:break_minutes_day1) { 60 }
  let(:memo1) { unique_id }
  let(:record_day1) do
    record = time_card.records.find_by(date: day1)
    record.enter = enter_day1
    record.leave = leave_day1
    record.break_minutes = break_minutes_day1
    record.memo = memo1
    record.save!
    record.reload
    record
  end

  # day2 465m
  let(:day2) { Time.zone.parse("2025/1/7") }
  let(:enter_day2) { Time.zone.parse("2025/1/7 8:30") }
  let(:leave_day2) { Time.zone.parse("2025/1/7 19:00") }
  let(:break_minutes_day2) { 60 }
  let(:memo2) { unique_id }
  let(:record_day2) do
    record = time_card.records.find_by(date: day2)
    record.enter = enter_day2
    record.leave = leave_day2
    record.break_minutes = break_minutes_day2
    record.memo = memo2
    record.save!
    record.reload
    record
  end

  # day3 210m
  let(:day3) { Time.zone.parse("2025/1/8") }
  let(:enter_day3) { Time.zone.parse("2025/1/8 7:00") }
  let(:leave_day3) { Time.zone.parse("2025/1/8 12:00") }
  let(:break_minutes_day3) { 0 }
  let(:memo3) { unique_id }
  let(:record_day3) do
    record = time_card.records.find_by(date: day3)
    record.enter = enter_day3
    record.leave = leave_day3
    record.break_minutes = break_minutes_day3
    record.memo = memo3
    record.save!
    record.reload
    record
  end

  it do
    Timecop.travel(month) do
      attendance_setting
      time_card
      expect(time_card.date).to eq month

      record_day1
      record_day2
      record_day3

      expect(record_day1.regular_holiday).to eq "workday"
      expect(record_day1.regular_start).to eq Time.zone.parse("2025/1/6 8:30")
      expect(record_day1.regular_close).to eq Time.zone.parse("2025/1/6 17:15")
      expect(record_day1.work_minutes).to eq 465

      expect(record_day2.regular_holiday).to eq "workday"
      expect(record_day2.regular_start).to eq Time.zone.parse("2025/1/7 8:30")
      expect(record_day2.regular_close).to eq Time.zone.parse("2025/1/7 17:15")
      expect(record_day2.work_minutes).to eq 465

      expect(record_day3.regular_holiday).to eq "workday"
      expect(record_day3.regular_start).to eq Time.zone.parse("2025/1/8 8:30")
      expect(record_day3.regular_close).to eq Time.zone.parse("2025/1/8 17:15")
      expect(record_day3.work_minutes).to eq 210

      item = described_class.new(time_card)
      item.load

      expect(item.work_minutes1).to eq (465 + 465 + 210)
      expect(item.work_minutes2).to eq (465 + 465 + 210)
    end
  end
end
