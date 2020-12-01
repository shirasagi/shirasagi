require 'spec_helper'

describe History::HistoryLog::PurgeJob, dbscope: :example do
  let(:site) { cms_site }
  let(:now) { Time.zone.now.beginning_of_minute }

  describe '#perform' do
    before do
      create(:history_log, site_id: cms_site.id, user_id: cms_user.id, url: "/path/to/#{unique_id}")
      Timecop.travel(2.years.before) do
        create(:history_log, site_id: cms_site.id, user_id: cms_user.id, url: "/path/to/#{unique_id}")
      end
    end

    context '1 history logs are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now }.to change { History::Log.count }.by(-1)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end

    context '2 history logs are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now(threshold: 0) }.to change { History::Log.count }.by(-2)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end

    context 'no history logs are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now(threshold: '3.years') }.to change { History::Log.count }.by(0)

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
        expect { described_class.bind(site_id: site).perform_now }.to change { History::Log.count }.by(-2)

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
        expect { described_class.bind(site_id: site).perform_now }.not_to(change { History::Log.count })

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end
  end
end
