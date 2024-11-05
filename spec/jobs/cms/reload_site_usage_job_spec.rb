require 'spec_helper'

describe Cms::ReloadSiteUsageJob, dbscope: :example do
  let!(:site) { cms_site }

  describe '#perform' do
    it do
      described_class.bind(site_id: site.id).perform_now

      expect(Job::Log.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      site.reload
      expect(site.usage_file_count).to be >= 0
      expect(site.usage_db_size).to be >= 0
      expect(site.usage_group_count).to be >= 0
      expect(site.usage_user_count).to be >= 0
      expect(site.usage_calculated_at.in_time_zone).to be_within(1.minute).of(Time.zone.now)
    end
  end
end
