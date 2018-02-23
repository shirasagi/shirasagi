require 'spec_helper'

describe Gws::Board::TrashPurgeJob, dbscope: :example do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:item) { create(:gws_board_topic, cur_site: site, deleted: now - 7.days) }

  describe '#perform' do
    context 'no board topics are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now }.not_to(change { Gws::Board::Topic.topic.count })

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include("INFO -- : Started Job"))
          expect(log.logs).to include(include("INFO -- : Completed Job"))
        end
      end
    end

    context 'board topics are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now(threshold: '7') }.to \
          change { Gws::Board::Topic.topic.count }.by(-1)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include("INFO -- : Started Job"))
          expect(log.logs).to include(include("INFO -- : Completed Job"))
        end
      end
    end
  end
end
