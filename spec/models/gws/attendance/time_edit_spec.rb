require 'spec_helper'

describe Gws::Attendance::TimeEdit, type: :model, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }

  describe '.valid?' do
    context 'with lower limit' do
      let(:hour) do
        site.attendance_time_changed_minute / 60
      end
      let (:item) do
        described_class.new(cur_site: site, cur_user: user, in_hour: hour.to_s, in_minute: '0', in_reason: unique_id)
      end
      it do
        expect(item.valid?).to be_truthy
      end
    end

    context 'with upper limit' do
      let(:hour) do
        site.attendance_time_changed_minute / 60 + 24
      end
      let (:item) do
        described_class.new(cur_site: site, cur_user: user, in_hour: hour.to_s, in_minute: '0', in_reason: unique_id)
      end
      it do
        expect(item.valid?).to be_truthy
      end
    end

    context 'with less than lower limit' do
      let(:hour) do
        site.attendance_time_changed_minute / 60 - 1
      end
      let (:item) do
        described_class.new(cur_site: site, cur_user: user, in_hour: hour.to_s, in_minute: '0', in_reason: unique_id)
      end
      it do
        expect(item.valid?).to be_falsey
      end
    end

    context 'with greater than upper limit' do
      let(:hour) do
        site.attendance_time_changed_minute / 60 + 25
      end
      let (:item) do
        described_class.new(cur_site: site, cur_user: user, in_hour: hour.to_s, in_minute: '0', in_reason: unique_id)
      end
      it do
        expect(item.valid?).to be_falsey
      end
    end
  end

  describe '.calc_time' do
    context 'within same day' do
      let (:item) do
        described_class.new(cur_site: site, cur_user: user, in_hour: '9', in_minute: '13', in_reason: unique_id)
      end
      let (:time) do
        Time.zone.now.beginning_of_day
      end

      it do
        expect(item.calc_time(time)).to eq time + 9.hours + 13.minutes
      end
    end

    context 'when day is over' do
      let (:item) do
        described_class.new(cur_site: site, cur_user: user, in_hour: '25', in_minute: '13', in_reason: unique_id)
      end
      let (:time) do
        Time.zone.now.beginning_of_day
      end

      it do
        expect(item.calc_time(time)).to eq time + 25.hours + 13.minutes
      end
    end
  end
end
