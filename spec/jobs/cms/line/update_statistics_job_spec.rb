require 'spec_helper'

describe Cms::Line::UpdateStatisticsJob, dbscope: :example do
  let!(:site) { cms_site }
  let(:item1) { create :cms_line_multicast_statistic }
  let(:item2) { create :cms_line_broadcast_statistic }

  describe "#perform" do
    before do
      site.line_channel_secret = unique_id
      site.line_channel_access_token = unique_id
      site.save!
    end

    it do
      item1

      capture_line_bot_client do |capture|
        described_class.bind(site_id: site).perform_now

        log = Job::Log.last.logs.join
        expect(log).to include("Started Job")
        expect(log).to include("update #{item1.id} #{item1.name}")
        expect(log).to include("Completed Job")
        expect(capture.get_statistics_per_unit.count).to eq 1
        expect(capture.get_user_interaction_statistics.count).to eq 0
      end

      Timecop.travel(1.day.from_now) do
        item2

        capture_line_bot_client do |capture|
          described_class.bind(site_id: site).perform_now

          log = Job::Log.last.logs.join
          expect(log).to include("Started Job")
          expect(log).to include("update #{item1.id} #{item1.name}")
          expect(log).to include("update #{item2.id} #{item2.name}")
          expect(log).to include("Completed Job")
          expect(capture.get_statistics_per_unit.count).to eq 1
          expect(capture.get_user_interaction_statistics.count).to eq 1
        end
      end

      Timecop.travel(13.days.from_now) do
        capture_line_bot_client do |capture|
          described_class.bind(site_id: site).perform_now

          log = Job::Log.last.logs.join
          expect(log).to include("Started Job")
          expect(log).to include("update #{item1.id} #{item1.name}")
          expect(log).to include("update #{item2.id} #{item2.name}")
          expect(log).to include("Completed Job")
          expect(capture.get_statistics_per_unit.count).to eq 1
          expect(capture.get_user_interaction_statistics.count).to eq 1
        end
      end

      Timecop.travel(14.days.from_now) do
        capture_line_bot_client do |capture|
          described_class.bind(site_id: site).perform_now

          log = Job::Log.last.logs.join
          expect(log).to include("Started Job")
          expect(log).to include("update #{item1.id} #{item1.name}")
          expect(log).to include("update #{item2.id} #{item2.name}")
          expect(log).to include("Completed Job")
          expect(capture.get_statistics_per_unit.count).to eq 1
          expect(capture.get_user_interaction_statistics.count).to eq 1
        end
      end

      Timecop.travel(15.days.from_now) do
        capture_line_bot_client do |capture|
          described_class.bind(site_id: site).perform_now

          log = Job::Log.last.logs.join
          expect(log).to include("Started Job")
          expect(log).not_to include("update #{item1.id} #{item1.name}")
          expect(log).to include("update #{item2.id} #{item2.name}")
          expect(log).to include("Completed Job")
          expect(capture.get_statistics_per_unit.count).to eq 0
          expect(capture.get_user_interaction_statistics.count).to eq 1
        end
      end

      Timecop.travel(16.days.from_now) do
        capture_line_bot_client do |capture|
          described_class.bind(site_id: site).perform_now

          log = Job::Log.last.logs.join
          expect(log).to include("Started Job")
          expect(log).not_to include("update #{item1.id} #{item1.name}")
          expect(log).not_to include("update #{item2.id} #{item2.name}")
          expect(log).to include("Completed Job")
          expect(capture.get_statistics_per_unit.count).to eq 0
          expect(capture.get_user_interaction_statistics.count).to eq 0
        end
      end

      Timecop.travel(20.days.from_now) do
        capture_line_bot_client do |capture|
          described_class.bind(site_id: site).perform_now

          log = Job::Log.last.logs.join
          expect(log).to include("Started Job")
          expect(log).not_to include("update #{item1.id} #{item1.name}")
          expect(log).not_to include("update #{item2.id} #{item2.name}")
          expect(log).to include("Completed Job")
          expect(capture.get_statistics_per_unit.count).to eq 0
          expect(capture.get_user_interaction_statistics.count).to eq 0
        end
      end
    end
  end
end
