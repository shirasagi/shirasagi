require 'spec_helper'

describe Gws::ReloadSiteUsageJob, dbscope: :example do
  let!(:site) { gws_site }

  describe '#perform' do
    it do
      described_class.bind(site_id: site.id).perform_now

      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      site.reload
      expect(site.usage_file_count).to be >= 0
      expect(site.usage_db_size).to be >= 0
      expect(site.usage_group_count).to be >= 0
      expect(site.usage_user_count).to be >= 0
      expect(site.usage_calculated_at.in_time_zone).to be_within(10.seconds).of(Time.zone.now)
    end
  end
end
