require 'spec_helper'

describe Gws::SharedAddress::TrashPurgeJob, dbscope: :example do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:item) { create(:gws_shared_address_address, cur_site: site, deleted: now - 7.days) }

  describe '#perform' do
    context 'no shared_address addresses are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now }.not_to(change { Gws::SharedAddress::Address.count })

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end

    context 'shared_address addresses are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now(threshold: 7) }.to \
          change { Gws::SharedAddress::Address.count }.by(-1)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end

    context 'when group trash_threshold is 7' do
      before do
        site.set(trash_threshold: 7)
      end

      it do
        expect { described_class.bind(site_id: site).perform_now }.to \
          change { Gws::SharedAddress::Address.count }.by(-1)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end
  end
end
