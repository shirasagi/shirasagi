require 'spec_helper'

describe Sys::HistoryArchiveJob, dbscope: :example do
  let(:site) { cms_site }

  describe '.week_of_year' do
    it { expect(described_class.week_of_year(Time.zone.parse('2016/01/01'))).to eq '00' }
    it { expect(described_class.week_of_year(Time.zone.parse('2016/12/31'))).to eq '52' }
    # 2017/01/01 is sunday, so we met some bugs in ruby
    it { expect(described_class.week_of_year(Time.zone.parse('2017/01/01'))).to eq '00' }
    it { expect(described_class.week_of_year(Time.zone.parse('2017/12/31'))).to eq '52' }
    it { expect(described_class.week_of_year(Time.zone.parse('2018/01/01'))).to eq '00' }
    it { expect(described_class.week_of_year(Time.zone.parse('2018/12/31'))).to eq '52' }
  end

  describe '.range_of_week' do
    it do
      expect(described_class.range_of_week(2016, 0)).to eq \
        [ Time.zone.parse('2016/01/01'), Time.zone.parse('2016/01/02').end_of_day ]
      expect(described_class.range_of_week(2016, 52)).to eq \
        [ Time.zone.parse('2016/12/25'), Time.zone.parse('2016/12/31').end_of_day ]
    end

    it do
      expect(described_class.range_of_week(2017, 0)).to eq \
        [ Time.zone.parse('2017/01/01'), Time.zone.parse('2017/01/07').end_of_day ]
      expect(described_class.range_of_week(2017, 30)).to eq \
        [ Time.zone.parse('2017/07/30'), Time.zone.parse('2017/08/05').end_of_day ]
      expect(described_class.range_of_week(2017, 52)).to eq \
        [ Time.zone.parse('2017/12/31'), Time.zone.parse('2017/12/31').end_of_day ]
    end

    it do
      expect(described_class.range_of_week(2018, 0)).to eq \
        [ Time.zone.parse('2018/01/01'), Time.zone.parse('2018/01/06').end_of_day ]
      expect(described_class.range_of_week(2018, 52)).to eq \
        [ Time.zone.parse('2018/12/30'), Time.zone.parse('2018/12/31').end_of_day ]
    end
  end

  describe '#perform' do
    context 'usual case' do
      let(:now) { Time.zone.parse('2017-11-07T12:00:00+09:00') }
      let(:threshold_day) { Sys::HistoryArchiveJob.threshold_day(now, SS.config.ss.history_log_saving_days.days) }

      before do
        Timecop.freeze(threshold_day - 1.second) do
          create(:history_log)
        end
        Timecop.freeze(threshold_day) do
          create(:history_log)
        end
        Timecop.freeze(threshold_day + 1.second) do
          create(:history_log)
        end
        Timecop.freeze(threshold_day - 1.second) do
          create(:history_log, site_id: site.id)
        end
        Timecop.freeze(threshold_day) do
          create(:history_log, site_id: site.id)
        end
        Timecop.freeze(threshold_day + 1.second) do
          create(:history_log, site_id: site.id)
        end
      end

      it do
        expect(History::Log.where(site_id: nil).count).to eq 3
        expect(History::Log.where(site_id: site.id).count).to eq 3
        Timecop.freeze(now) do
          described_class.perform_now
        end
        expect(History::Log.where(site_id: nil).count).to eq 2
        expect(History::Log.where(site_id: site.id).count).to eq 2

        expect(Sys::HistoryArchiveFile.where(site_id: nil).count).to eq 1
        Sys::HistoryArchiveFile.where(site_id: nil).first.tap do |archive_file|
          expect(archive_file.model).to eq 'sys/history_archive_file'
          expect(archive_file.state).to eq 'closed'
          expect(archive_file.name).to eq '2017年7月30日ー2017年8月5日.zip'
          expect(archive_file.filename).to eq '2017-week-30.zip'
          expect(archive_file.size).to be > 0
          expect(archive_file.content_type).to eq 'application/zip'
        end

        expect(Cms::HistoryArchiveFile.where(site_id: site.id).count).to eq 1
        Cms::HistoryArchiveFile.where(site_id: site.id).first.tap do |archive_file|
          expect(archive_file.model).to eq 'sys/history_archive_file'
          expect(archive_file.state).to eq 'closed'
          expect(archive_file.name).to eq '2017年7月30日ー2017年8月5日.zip'
          expect(archive_file.filename).to eq '2017-week-30.zip'
          expect(archive_file.size).to be > 0
          expect(archive_file.content_type).to eq 'application/zip'
        end
      end
    end

    context '年をまたぐ場合' do
      let(:now) { Time.zone.parse('2016-01-01T12:00:00+09:00') + SS.config.ss.history_log_saving_days.days + 7.days }
      let(:threshold_day) { Sys::HistoryArchiveJob.threshold_day(now, SS.config.ss.history_log_saving_days.days) }

      before do
        # sunday
        Timecop.freeze('2015-12-27T12:00:00+09:00') { create(:history_log) }
        Timecop.freeze('2015-12-27T12:00:00+09:00') { create(:history_log, site_id: site.id) }
        # monday
        Timecop.freeze('2015-12-28T12:00:00+09:00') { create(:history_log) }
        Timecop.freeze('2015-12-28T12:00:00+09:00') { create(:history_log, site_id: site.id) }
        # tuesday
        Timecop.freeze('2015-12-29T12:00:00+09:00') { create(:history_log) }
        Timecop.freeze('2015-12-29T12:00:00+09:00') { create(:history_log, site_id: site.id) }
        # wednesday
        Timecop.freeze('2015-12-30T12:00:00+09:00') { create(:history_log) }
        Timecop.freeze('2015-12-30T12:00:00+09:00') { create(:history_log, site_id: site.id) }
        # thursday
        Timecop.freeze('2015-12-31T12:00:00+09:00') { create(:history_log) }
        Timecop.freeze('2015-12-31T12:00:00+09:00') { create(:history_log, site_id: site.id) }
        # friday
        Timecop.freeze('2016-01-01T12:00:00+09:00') { create(:history_log) }
        Timecop.freeze('2016-01-01T12:00:00+09:00') { create(:history_log, site_id: site.id) }
        # saturday
        Timecop.freeze('2016-01-02T12:00:00+09:00') { create(:history_log) }
        Timecop.freeze('2016-01-02T12:00:00+09:00') { create(:history_log, site_id: site.id) }
        # sunday
        Timecop.freeze('2016-01-03T12:00:00+09:00') { create(:history_log) }
        Timecop.freeze('2016-01-03T12:00:00+09:00') { create(:history_log, site_id: site.id) }
      end

      it do
        expect(History::Log.where(site_id: nil).count).to eq 8
        expect(History::Log.where(site_id: site.id).count).to eq 8
        Timecop.freeze(now) do
          described_class.perform_now
        end

        expect(Sys::HistoryArchiveFile.where(site_id: nil).reorder(filename: 1, id: 1).count).to eq 2
        Sys::HistoryArchiveFile.where(site_id: nil).reorder(filename: 1, id: 1).first.tap do |archive_file|
          expect(archive_file.model).to eq 'sys/history_archive_file'
          expect(archive_file.state).to eq 'closed'
          expect(archive_file.name).to eq '2015年12月27日ー2015年12月31日.zip'
          expect(archive_file.filename).to eq '2015-week-52.zip'
          expect(archive_file.size).to be > 0
          expect(archive_file.content_type).to eq 'application/zip'
        end
        Sys::HistoryArchiveFile.where(site_id: nil).reorder(filename: 1, id: 1).last.tap do |archive_file|
          expect(archive_file.model).to eq 'sys/history_archive_file'
          expect(archive_file.state).to eq 'closed'
          expect(archive_file.name).to eq '2016年1月1日ー2016年1月2日.zip'
          expect(archive_file.filename).to eq '2016-week-00.zip'
          expect(archive_file.size).to be > 0
          expect(archive_file.content_type).to eq 'application/zip'
        end

        expect(Cms::HistoryArchiveFile.where(site_id: site.id).reorder(filename: 1, id: 1).count).to eq 2
        Cms::HistoryArchiveFile.where(site_id: site.id).reorder(filename: 1, id: 1).first.tap do |archive_file|
          expect(archive_file.model).to eq 'sys/history_archive_file'
          expect(archive_file.state).to eq 'closed'
          expect(archive_file.name).to eq '2015年12月27日ー2015年12月31日.zip'
          expect(archive_file.filename).to eq '2015-week-52.zip'
          expect(archive_file.size).to be > 0
          expect(archive_file.content_type).to eq 'application/zip'
        end
        Cms::HistoryArchiveFile.where(site_id: site.id).reorder(filename: 1, id: 1).last.tap do |archive_file|
          expect(archive_file.model).to eq 'sys/history_archive_file'
          expect(archive_file.state).to eq 'closed'
          expect(archive_file.name).to eq '2016年1月1日ー2016年1月2日.zip'
          expect(archive_file.filename).to eq '2016-week-00.zip'
          expect(archive_file.size).to be > 0
          expect(archive_file.content_type).to eq 'application/zip'
        end
      end
    end
  end
end
