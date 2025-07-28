require 'spec_helper'

describe Translate::AccessLog::PurgeJob, dbscope: :example do
  let(:site) { cms_site }
  let(:now) { Time.zone.now.beginning_of_minute }

  describe '#perform' do
    it do
      create(:translate_access_log)
      create(:translate_access_log)

      expect { described_class.bind(site_id: site).perform_now }.to change { Translate::AccessLog.count }.by(0)

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end

    it do
      create(:translate_access_log)
      Timecop.travel(59.days.before) do
        create(:translate_access_log)
      end

      expect { described_class.bind(site_id: site).perform_now }.to change { Translate::AccessLog.count }.by(0)

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end

    it do
      create(:translate_access_log)
      Timecop.travel(60.days.before) do
        create(:translate_access_log)
      end

      expect { described_class.bind(site_id: site).perform_now }.to change { Translate::AccessLog.count }.by(-1)

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end

    it do
      create(:translate_access_log)
      Timecop.travel(61.days.before) do
        create(:translate_access_log)
      end

      expect { described_class.bind(site_id: site).perform_now }.to change { Translate::AccessLog.count }.by(-1)

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end

    it do
      create(:translate_access_log)
      Timecop.travel(1.years.before) do
        create(:translate_access_log)
      end

      expect { described_class.bind(site_id: site).perform_now }.to change { Translate::AccessLog.count }.by(-1)

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end
  end
end
