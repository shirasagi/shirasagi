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

  # leave1
  let(:day_leave_minutes) { duty_setting.day_leave_minutes }
  let(:leave_type1) { "paid" }
  let(:leave_type2) { "sick1" }
  let(:leave_type3) { "sick2" }

  let(:leave1) do
    create(:gws_affair2_leave_record,
      leave_type: leave_type1,
      state: "order",
      allday: "allday",
      date: Time.zone.parse("2025/1/6"),
      start_at: record_day1.regular_start,
      close_at: record_day1.regular_close,
      minutes: day_leave_minutes)
  end

  # leave2
  let(:leave2) do
    create(:gws_affair2_leave_record,
      leave_type: leave_type2,
      state: "order",
      allday: nil,
      date: Time.zone.parse("2025/1/7"),
      start_at: Time.zone.parse("2025/1/7 8:30"),
      close_at: Time.zone.parse("2025/1/7 10:30"),
      minutes: 120)
  end

  it do
    Timecop.travel(month) do
      attendance_setting
      time_card

      record_day1
      record_day2

      leave1
      leave2

      item = described_class.new(time_card)
      item.load

      expect(item.work_minutes2).to eq(0 + (465 - 120))
      expect(item.leave_minutes).to eq(day_leave_minutes + 120)

      expect(item.leave_minutes_hash.size).to eq 2
      expect(item.leave_minutes_hash[leave_type1]).to eq day_leave_minutes
      expect(item.leave_minutes_hash[leave_type2]).to eq 120
      expect(item.leave_minutes_hash[leave_type3]).to eq nil
    end
  end
end
