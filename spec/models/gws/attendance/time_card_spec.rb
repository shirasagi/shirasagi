require 'spec_helper'

describe Gws::Attendance::TimeCard, type: :model, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  subject! { create :gws_attendance_time_card, cur_site: site, cur_user: user }

  before do
    site.attendance_break_time1_state = 'show'
    site.attendance_break_time2_state = 'show'
    site.attendance_break_time3_state = 'show'
    site.save!
  end

  its(:locked?) { is_expected.to be_falsey }
  its(:unlocked?) { is_expected.to be_truthy }

  describe ".search" do
    describe "with empty" do
      it do
        expect(Gws::Attendance::TimeCard.search).to have(1).items
      end
    end

    describe "with name" do
      it do
        expect(Gws::Attendance::TimeCard.search(name: subject.name)).to have(1).items
      end
    end

    describe "with keyword" do
      it do
        expect(Gws::Attendance::TimeCard.search(keyword: subject.name)).to have(1).items
      end
    end

    describe "with group" do
      it do
        expect(Gws::Attendance::TimeCard.search(group: user.groups.first)).to have(1).items
      end
    end
  end

  describe ".in_groups" do
    it do
      expect(Gws::Attendance::TimeCard.in_groups(user.groups)).to have(1).items
    end
  end

  describe ".and_unlocked" do
    it do
      expect(Gws::Attendance::TimeCard.and_unlocked).to have(1).items
    end
  end

  describe ".and_locked" do
    it do
      expect(Gws::Attendance::TimeCard.and_locked).to have(0).items
    end
  end

  describe ".lock_all" do
    it do
      Gws::Attendance::TimeCard.lock_all
      subject.reload
      expect(subject.locked?).to be_truthy
    end
  end

  describe ".unlock_all" do
    before do
      Gws::Attendance::TimeCard.lock_all
      subject.reload
      expect(subject.locked?).to be_truthy
    end

    it do
      Gws::Attendance::TimeCard.unlock_all
      subject.reload
      expect(subject.unlocked?).to be_truthy
    end
  end

  describe "enum csv" do
    subject! { create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user }
    let(:headers) do
      [
        Gws::User.t(:uid), Gws::User.t(:name),
        Gws::Attendance::Record.t(:date), Gws::Attendance::Record.t(:enter), Gws::Attendance::Record.t(:leave)
      ]
    end

    before do
      # special punch
      subject.punch("break_enter1", subject.date.in_time_zone + 3.days + 25.hours)
      subject.punch("break_leave1", subject.date.in_time_zone + 3.days + 25.hours + 30.minutes)

      cell = Gws::Attendance::TimeEdit.new(in_hour: 17, in_minute: 29, in_reason: unique_id)
      record = subject.records.sample
      date = record.date.in_time_zone
      time = cell.calc_time(date)
      subject.histories.create(date: date, field_name: "enter", action: 'modify', time: time, reason: cell.in_reason)
      record.enter = time
      record.save!
    end

    describe ".enum_csv" do
      describe "with Shift_JIS encoding" do
        let!(:csv) { Gws::Attendance::TimeCard.enum_csv(site, OpenStruct.new({ encoding: 'Shift_JIS'})).to_a }
        it do
          expect(csv).to have(subject.date.in_time_zone.end_of_month.day + 1).items
          expect(csv[0].encode("UTF-8")).to include(*headers)
          expect(csv[1].encode("UTF-8")).to include(user.uid, user.name, subject.date.in_time_zone.to_date.iso8601)
        end
      end

      describe "with UTF-8 encoding" do
        let!(:csv) { Gws::Attendance::TimeCard.enum_csv(site, OpenStruct.new({ encoding: 'UTF-8'})).to_a }
        it do
          expect(csv).to have(subject.date.in_time_zone.end_of_month.day + 1).items
          expect(csv[0]).to include(*headers)
          expect(csv[1]).to include(user.uid, user.name, subject.date.in_time_zone.to_date.iso8601)
        end
      end
    end

    describe "#enum_csv" do
      describe "with Shift_JIS encoding" do
        let!(:csv) { subject.enum_csv(OpenStruct.new({ encoding: 'Shift_JIS'})).to_a }
        it do
          expect(csv).to have(subject.date.in_time_zone.end_of_month.day + 1).items
          expect(csv[0].encode("UTF-8")).to include(*headers)
          expect(csv[1].encode("UTF-8")).to include(user.uid, user.name, subject.date.in_time_zone.to_date.iso8601)
        end
      end

      describe "with UTF-8 encoding" do
        let!(:csv) { subject.enum_csv(OpenStruct.new({ encoding: 'UTF-8'})).to_a }
        it do
          expect(csv).to have(subject.date.in_time_zone.end_of_month.day + 1).items
          expect(csv[0]).to include(*headers)
          expect(csv[1]).to include(user.uid, user.name, subject.date.in_time_zone.to_date.iso8601)
        end
      end
    end
  end
end
