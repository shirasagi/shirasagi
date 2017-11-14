require 'spec_helper'
require 'timecop'

describe Gws::Monitor::DeleteJob, dbscope: :example do
  let(:site) {gws_site}
  let(:user) {gws_user}
  let(:started) {Time.zone.now}

  describe '.perform_later' do
    before do
      1.upto(12*3) do |i|
        create(:gws_monitor_topic, :attend_group_ids, deleted: i.month.ago)
      end
    end

    context 'default removed two years ago' do
      before do
        described_class.bind(site_id: site.id).perform_now
      end

      it do
        expect(Gws::Monitor::Topic.count).to eq 23
      end
    end

    context 'delete one year ago' do
      before do
        site.monitor_delete_threshold = 5
        site.save!
        described_class.bind(site_id: site.id).perform_now
      end

      it do
        expect(Gws::Monitor::Topic.count).to eq 11
      end
    end
  end
end
