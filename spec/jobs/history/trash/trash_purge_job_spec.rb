require 'spec_helper'

describe History::Trash::TrashPurgeJob, dbscope: :example do
  let(:site) { cms_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:item) { create(:cms_page) }

  describe '#perform' do
    before do
      item.destroy
    end

    context 'no history trashes are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now }.not_to(change { History::Trash.count })

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end

    context 'history trashes are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now(threshold: 0) }.to change { History::Trash.count }.by(-1)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end

    context 'when site trash_threshold is 0' do
      before do
        site.set(trash_threshold: 0)
      end

      it do
        expect { described_class.bind(site_id: site).perform_now }.to change { History::Trash.count }.by(-1)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end
  end
end
