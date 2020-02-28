require 'spec_helper'

describe Opendata::ResourceDownloadHistoryArchiveJob, dbscope: :example do
  let(:site) { cms_site }

  describe '#perform' do
    context 'usual case' do
      let(:now) { Time.zone.parse('2017-11-07T12:00:00+09:00') }
      let(:threshold_day) { described_class.threshold_day(now, described_class.effective_save_days.days) }

      before do
        Timecop.freeze(threshold_day - 1.second) do
          create(:opendata_resource_download_history, cur_site: site, downloaded: threshold_day - 1.second)
        end
        Timecop.freeze(threshold_day) do
          create(:opendata_resource_download_history, cur_site: site, downloaded: threshold_day)
        end
        Timecop.freeze(threshold_day + 1.second) do
          create(:opendata_resource_download_history, cur_site: site, downloaded: threshold_day + 1.second)
        end
      end

      it do
        expect(Opendata::ResourceDownloadHistory.site(site).count).to eq 3
        Timecop.freeze(now) do
          described_class.bind(site_id: site).perform_now
        end
        expect(Opendata::ResourceDownloadHistory.site(site).count).to eq 2

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(Opendata::ResourceDownloadHistory::ArchiveFile.site(site).count).to eq 1
        Opendata::ResourceDownloadHistory::ArchiveFile.site(site).first.tap do |archive_file|
          expect(archive_file.model).to eq 'opendata/resource_download_history/archive_file'
          expect(archive_file.state).to eq 'closed'
          expect(archive_file.name).to eq '2017年10月15日〜2017年10月21日.zip'
          expect(archive_file.filename).to eq '2017-week-41.zip'
          expect(archive_file.size).to be > 0
          expect(archive_file.content_type).to eq 'application/zip'
        end
      end
    end

    context 'with `now` option' do
      let(:now) { Time.zone.parse('2017-11-07T12:00:00+09:00') }
      let(:threshold_day) { described_class.threshold_day(now, described_class.effective_save_days.days) }

      before do
        Timecop.freeze(threshold_day - 1.second) do
          create(:opendata_resource_download_history, cur_site: site, downloaded: threshold_day - 1.second)
        end
        Timecop.freeze(threshold_day) do
          create(:opendata_resource_download_history, cur_site: site, downloaded: threshold_day)
        end
        Timecop.freeze(threshold_day + 1.second) do
          create(:opendata_resource_download_history, cur_site: site, downloaded: threshold_day + 1.second)
        end
      end

      it do
        expect(Opendata::ResourceDownloadHistory.site(site).count).to eq 3
        described_class.bind(site_id: site).perform_now(now: I18n.l(now))
        expect(Opendata::ResourceDownloadHistory.site(site).count).to eq 2

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(Opendata::ResourceDownloadHistory::ArchiveFile.site(site).count).to eq 1
        Opendata::ResourceDownloadHistory::ArchiveFile.site(site).first.tap do |archive_file|
          expect(archive_file.model).to eq 'opendata/resource_download_history/archive_file'
          expect(archive_file.state).to eq 'closed'
          expect(archive_file.name).to eq '2017年10月15日〜2017年10月21日.zip'
          expect(archive_file.filename).to eq '2017-week-41.zip'
          expect(archive_file.size).to be > 0
          expect(archive_file.content_type).to eq 'application/zip'
        end
      end
    end

    context '年をまたぐ場合' do
      let(:now) { Time.zone.parse('2016-01-01T12:00:00+09:00') + described_class.effective_save_days.days + 7.days }
      let(:threshold_day) { Gws::HistoryArchiveJob.threshold_day(now, described_class.effective_save_days.days) }

      before do
        # sunday
        Timecop.freeze('2015-12-27T12:00:00+09:00') { create(:opendata_resource_download_history, cur_site: site) }
        # monday
        Timecop.freeze('2015-12-28T12:00:00+09:00') { create(:opendata_resource_download_history, cur_site: site) }
        # tuesday
        Timecop.freeze('2015-12-29T12:00:00+09:00') { create(:opendata_resource_download_history, cur_site: site) }
        # wednesday
        Timecop.freeze('2015-12-30T12:00:00+09:00') { create(:opendata_resource_download_history, cur_site: site) }
        # thursday
        Timecop.freeze('2015-12-31T12:00:00+09:00') { create(:opendata_resource_download_history, cur_site: site) }
        # friday
        Timecop.freeze('2016-01-01T12:00:00+09:00') { create(:opendata_resource_download_history, cur_site: site) }
        # saturday
        Timecop.freeze('2016-01-02T12:00:00+09:00') { create(:opendata_resource_download_history, cur_site: site) }
        # sunday
        Timecop.freeze('2016-01-03T12:00:00+09:00') { create(:opendata_resource_download_history, cur_site: site) }
      end

      it do
        expect(Opendata::ResourceDownloadHistory.site(site).count).to eq 8
        Timecop.freeze(now) do
          described_class.bind(site_id: site).perform_now
        end
        expect(Opendata::ResourceDownloadHistory.site(site).count).to eq 1

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(Opendata::ResourceDownloadHistory::ArchiveFile.site(site).reorder(filename: 1, id: 1).count).to eq 2
        Opendata::ResourceDownloadHistory::ArchiveFile.site(site).reorder(filename: 1, id: 1).first.tap do |archive_file|
          expect(archive_file.model).to eq 'opendata/resource_download_history/archive_file'
          expect(archive_file.state).to eq 'closed'
          expect(archive_file.name).to eq '2015年12月27日〜2015年12月31日.zip'
          expect(archive_file.filename).to eq '2015-week-52.zip'
          expect(archive_file.size).to be > 0
          expect(archive_file.content_type).to eq 'application/zip'
        end
        Opendata::ResourceDownloadHistory::ArchiveFile.site(site).reorder(filename: 1, id: 1).last.tap do |archive_file|
          expect(archive_file.model).to eq 'opendata/resource_download_history/archive_file'
          expect(archive_file.state).to eq 'closed'
          expect(archive_file.name).to eq '2016年1月1日〜2016年1月2日.zip'
          expect(archive_file.filename).to eq '2016-week-00.zip'
          expect(archive_file.size).to be > 0
          expect(archive_file.content_type).to eq 'application/zip'
        end
      end
    end
  end
end
