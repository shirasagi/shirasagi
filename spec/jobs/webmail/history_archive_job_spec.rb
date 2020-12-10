require 'spec_helper'

describe Webmail::HistoryArchiveJob, dbscope: :example do

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
      let(:threshold_day) { Webmail::HistoryArchiveJob.threshold_day(now, SS.config.webmail.history["save_days"].days) }

      before do
        Timecop.freeze(threshold_day - 1.second) do
          create(:webmail_history_model)
        end
        Timecop.freeze(threshold_day) do
          create(:webmail_history_model)
        end
        Timecop.freeze(threshold_day + 1.second) do
          create(:webmail_history_model)
        end
      end

      it do
        expect(Webmail::History.all.count).to eq 3
        Timecop.freeze(now) do
          described_class.perform_now
        end
        expect(Webmail::History.all.count).to eq 2

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Webmail::History::ArchiveFile.all.count).to eq 1
        Webmail::History::ArchiveFile.all.first.tap do |archive_file|
          expect(archive_file.model).to eq 'webmail/history/archive_file'
          expect(archive_file.state).to eq 'closed'
          expect(archive_file.name).to eq '2017年7月30日〜2017年8月5日.zip'
          expect(archive_file.filename).to eq '2017-week-30.zip'
          expect(archive_file.size).to be > 0
          expect(archive_file.content_type).to eq 'application/zip'
        end
      end
    end

    context '年をまたぐ場合' do
      let(:now) { Time.zone.parse('2016-01-01T12:00:00+09:00') + SS.config.webmail.history["save_days"].days + 7.days }
      let(:threshold_day) { Webmail::HistoryArchiveJob.threshold_day(now, SS.config.webmail.history["save_days"].days) }

      before do
        # sunday
        Timecop.freeze('2015-12-27T12:00:00+09:00') { create(:webmail_history_model) }
        # monday
        Timecop.freeze('2015-12-28T12:00:00+09:00') { create(:webmail_history_model) }
        # tuesday
        Timecop.freeze('2015-12-29T12:00:00+09:00') { create(:webmail_history_model) }
        # wednesday
        Timecop.freeze('2015-12-30T12:00:00+09:00') { create(:webmail_history_model) }
        # thursday
        Timecop.freeze('2015-12-31T12:00:00+09:00') { create(:webmail_history_model) }
        # friday
        Timecop.freeze('2016-01-01T12:00:00+09:00') { create(:webmail_history_model) }
        # saturday
        Timecop.freeze('2016-01-02T12:00:00+09:00') { create(:webmail_history_model) }
        # sunday
        Timecop.freeze('2016-01-03T12:00:00+09:00') { create(:webmail_history_model) }
      end

      it do
        expect(Webmail::History.all.count).to eq 8
        Timecop.freeze(now) do
          described_class.perform_now
        end
        expect(Webmail::History.all.count).to eq 1

        expect(Job::Log.all.count).to eq 1
        Job::Log.all.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Webmail::History::ArchiveFile.all.reorder(filename: 1, id: 1).count).to eq 2
        Webmail::History::ArchiveFile.all.reorder(filename: 1, id: 1).first.tap do |archive_file|
          expect(archive_file.model).to eq 'webmail/history/archive_file'
          expect(archive_file.state).to eq 'closed'
          expect(archive_file.name).to eq '2015年12月27日〜2015年12月31日.zip'
          expect(archive_file.filename).to eq '2015-week-52.zip'
          expect(archive_file.size).to be > 0
          expect(archive_file.content_type).to eq 'application/zip'
        end
        Webmail::History::ArchiveFile.all.reorder(filename: 1, id: 1).last.tap do |archive_file|
          expect(archive_file.model).to eq 'webmail/history/archive_file'
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
