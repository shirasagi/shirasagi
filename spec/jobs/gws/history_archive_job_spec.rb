require 'spec_helper'

describe Gws::HistoryArchiveJob, dbscope: :example do
  let(:site) { create(:gws_group) }
  let(:now) { Time.zone.now }

  before do
    Timecop.freeze(now - 8.days) do
      create(:gws_history_model, cur_site: site)
    end
    Timecop.freeze(now - 7.days) do
      create(:gws_history_model, cur_site: site)
    end
    Timecop.freeze(now - 6.days) do
      create(:gws_history_model, cur_site: site)
    end
  end

  it do
    # expect(Gws::History.site(site).count).to eq 3
    puts Gws::History.site(site).count
    puts Gws::History.site(site).pluck(:created)
    Timecop.freeze(now) do
      described_class.bind(site_id: site).perform_now
    end
    # expect(Gws::History.count).to eq 2
    puts Gws::History.site(site).count

    expect(Gws::Job::Log.count).to eq 1
    Gws::Job::Log.first.tap do |log|
      expect(log.logs).to include(include('INFO -- : Started Job'))
      expect(log.logs).to include(include('INFO -- : Completed Job'))
    end
  end
end
