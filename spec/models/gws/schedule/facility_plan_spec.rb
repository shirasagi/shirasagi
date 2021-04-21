require 'spec_helper'

RSpec.describe Gws::Schedule::Plan, type: :model, dbscope: :example do
  let(:site) { gws_site }

  describe "facility_plan_with_max_hour" do
    let(:facility) { create :gws_facility_item }
    let(:item) { build :gws_schedule_plan, name: 'test', facility_ids: [facility.id] }

    before do
      site.facility_min_hour = 8
      site.facility_max_hour = 22
    end

    context 'valid hours' do
      it do
        item.start_at = '2016/1/1 08:00'
        item.end_at   = '2016/1/1 08:30'
        expect(item).to be_valid

        item.start_at = '2016/1/1 08:00'
        item.end_at   = '2016/1/1 09:00'
        expect(item).to be_valid

        item.start_at = '2016/1/1 21:00'
        item.end_at   = '2016/1/1 22:00'
        expect(item).to be_valid

        item.start_at = '2016/1/1 08:00'
        item.end_at   = '2016/1/1 22:00'
        expect(item).to be_valid

        item.start_at = '2016/1/1 08:00'
        item.end_at   = '2016/1/4 22:00'
        expect(item).to be_valid

        item.start_at = '2016/1/1 09:00'
        item.end_at   = '2016/1/4 21:00'
        expect(item).to be_valid
      end
    end

    context 'invalid hours' do
      it do
        item.start_at = '2016/1/1 00:00'
        item.end_at   = '2016/1/1 01:00'
        expect(item).not_to be_valid

        item.start_at = '2016/1/1 07:00'
        item.end_at   = '2016/1/1 08:00'
        expect(item).not_to be_valid

        item.start_at = '2016/1/1 07:55'
        item.end_at   = '2016/1/1 08:00'
        expect(item).not_to be_valid

        item.start_at = '2016/1/1 07:00'
        item.end_at   = '2016/1/1 09:00'
        expect(item).not_to be_valid

        item.start_at = '2016/1/1 22:00'
        item.end_at   = '2016/1/1 22:05'
        expect(item).not_to be_valid

        item.start_at = '2016/1/1 22:00'
        item.end_at   = '2016/1/1 23:00'
        expect(item).not_to be_valid

        item.start_at = '2016/1/1 20:00'
        item.end_at   = '2016/1/1 23:00'
        expect(item).not_to be_valid

        item.start_at = '2016/1/1 23:00'
        item.end_at   = '2016/1/1 23:59'
        expect(item).not_to be_valid

        item.start_at = '2016/1/1 6:00'
        item.end_at   = '2016/1/1 22:00'
        expect(item).not_to be_valid

        item.start_at = '2016/1/1 7:00'
        item.end_at   = '2016/1/4 22:00'
        expect(item).not_to be_valid

        item.start_at = '2016/1/1 8:00'
        item.end_at   = '2016/1/4 23:00'
        expect(item).not_to be_valid

        item.start_at = '2016/1/1 7:00'
        item.end_at   = '2016/1/4 23:00'
        expect(item).not_to be_valid
      end
    end
  end

  describe "#validate_facility_double_booking" do
    let(:user) { gws_user }
    let(:now) { Time.zone.now.change(hour: 16) }
    let(:tomorrow) { now + 1.day }
    let!(:facility) { create :gws_facility_item }
    let!(:item) do
      create(
        :gws_schedule_plan,
        allday: nil, start_at: now.change(hour: 8), end_at: now.change(hour: 22),
        facility_ids: [facility.id]
      )
    end

    context "with duplicated start_at/end_at plan" do
      subject do
        build(
          :gws_schedule_plan, site_id: site.id,
          allday: nil, start_at: now, end_at: now + 1.hour, start_on: now.beginning_of_day, end_on: now.end_of_day,
          facility_ids: [facility.id]
        )
      end

      it do
        expect(item).to be_valid
        subject.send(:validate_facility_double_booking)
        expect(subject.errors).to be_present
      end
    end

    context "with duplicated all-day plan" do
      subject do
        build(
          :gws_schedule_plan, site_id: site.id,
          allday: "allday", start_at: now, end_at: now + 1.hour, start_on: now.beginning_of_day, end_on: now.end_of_day,
          facility_ids: [facility.id]
        )
      end

      it do
        expect(item).to be_valid
        subject.send(:validate_facility_double_booking)
        expect(subject.errors).to be_present
      end
    end

    context "with non-duplicated all-day plan but start_at/end_at is duplicated" do
      subject do
        build(
          :gws_schedule_plan, site_id: site.id,
          allday: "allday", start_at: now, end_at: now + 1.hour, start_on: tomorrow.beginning_of_day, end_on: tomorrow.end_of_day,
          facility_ids: [facility.id]
        )
      end

      it do
        expect(item).to be_valid
        subject.send(:validate_facility_double_booking)
        expect(subject.errors).to be_blank
      end
    end
  end
end
