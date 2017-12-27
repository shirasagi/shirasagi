require 'spec_helper'
require 'timecop'

describe Gws::Monitor::DeleteJob, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:started) { Time.zone.now }

  describe '.perform_later' do
    before do
      1.upto(12*3) do |i|
        topic = create(:gws_monitor_topic, :attend_group_ids, deleted: i.month.ago)
        2.times do
          create(:gws_monitor_post, topic_id: topic.id, parent_id: topic.id)
        end
      end
    end

    context 'default removed 24 months ago' do
      before do
        described_class.bind(site_id: site.id).perform_now
      end

      it do
        expect(Gws::Monitor::Topic.topic.count).to eq 23
        expect(Gws::Monitor::Post.count).to eq 23 * 3
      end
    end

    context 'delete 12 months ago' do
      before do
        site.monitor_delete_threshold = '12.months'
        site.save!
        described_class.bind(site_id: site.id).perform_now
      end

      it do
        expect(Gws::Monitor::Topic.topic.count).to eq 11
        expect(Gws::Monitor::Post.count).to eq 11 * 3
      end
    end
  end
end
