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
  let(:day1) { Time.zone.parse("2025/1/5") }
  let(:enter_day1) { Time.zone.parse("2025/1/5 8:30") }
  let(:leave_day1) { Time.zone.parse("2025/1/5 17:15") }
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

  # overtime_file
  let(:day_leave_minutes) { duty_setting.day_leave_minutes }
  let(:overtime_file) do
    file = create(:gws_affair2_overtime_holiday_file,
      cur_user: user,
      in_date: "2025/1/5",
      in_start_hour: 8,
      in_start_minute: 30,
      in_close_hour: 17,
      in_close_minute: 15,
      expense: "compens",
      compens_date: "2025/1/7",
      state: "approve",
      workflow_user: user,
      workflow_state: "approve",
      workflow_required_counts: [false],
      workflow_approvers: [{ level: 1, user_id: user.id, editable: "", state: "approve", comment: "" }])
    file.reload
    file
  end

  # aggregation
  let(:item) { described_class.new(time_card) }
  let(:aggregation_month) { time_card.aggregation_month }

  it do
    Timecop.travel(month) do
      attendance_setting
      time_card
      record_day1
      overtime_file

      expect(overtime_file.record).to be_present
      expect(overtime_file.compens_record).to be_present

      # 結果入力
      record = overtime_file.record
      record.start_at = overtime_file.start_at
      record.close_at = overtime_file.close_at
      record.break_start_at = Time.zone.parse("2025/1/5 12:00")
      record.break_close_at = Time.zone.parse("2025/1/5 13:00")
      record.entered_at = Time.zone.now
      record.save!
      record.reload
      expect(record.entered?).to be_truthy

      item = described_class.new(time_card)
      item.load

      expect(item.work_minutes2).to eq 0
      expect(item.overtime_minutes).to eq 465
      expect(item.leave_minutes).to eq day_leave_minutes

      expect(item.leave_minutes_hash.size).to eq 1
      expect(item.leave_minutes_hash["compens"]).to eq day_leave_minutes
    end
  end
end
