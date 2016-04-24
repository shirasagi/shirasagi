require 'spec_helper'

RSpec.describe Gws::Schedule::Plan, type: :model, dbscope: :example, tmpdir: true do
  let(:site) { gws_site }

  describe "facility_plan_with_max_hour" do
    let(:facility) { create :gws_facility }
    let(:item) { build :gws_schedule_plan, name: 'test', facility_ids: [facility.id] }

    before do
      gws_site.facility_min_hour = 8
      gws_site.facility_min_hour = 22
    end

    describe 'valid hours' do
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
      end
    end

    describe 'invalid hours' do
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
      end
    end
  end
end
