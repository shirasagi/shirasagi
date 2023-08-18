require 'spec_helper'

describe History::Trash::TrashPurgeJob, dbscope: :example do
  let(:site) { cms_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:item1) { create(:cms_page) }
  let!(:item2) { create(:cms_page) }

  describe '#perform' do
    before do
      item1.destroy
      Timecop.travel(2.years.before) do
        item2.destroy
      end
    end

    context '1 history trashes are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now }.to change { History::Trash.count }.by(-1)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end

    context '2 history trashes are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now(threshold: 0) }.to change { History::Trash.count }.by(-2)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end

    context 'no history trashes are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now(threshold: '3.years') }.to change { History::Trash.count }.by(0)

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
        expect { described_class.bind(site_id: site).perform_now }.to change { History::Trash.count }.by(-2)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end

    context 'when site trash_threshold is 3.years' do
      before do
        site.set(trash_threshold: 3)
        site.set(trash_threshold_unit: 'year')
      end

      it do
        expect { described_class.bind(site_id: site).perform_now }.not_to(change { History::Trash.count })

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end
  end
end
