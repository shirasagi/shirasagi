require 'spec_helper'

describe Sys::MailLogSweepJob, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }

  context "with default setting" do
    it do
      Timecop.freeze(now.beginning_of_day - SS::Duration.parse(SS.config.ss.keep_tasks) - 1.second) do
        create(:sys_mail_log_utf8)
      end

      Timecop.freeze(now.beginning_of_day - SS::Duration.parse(SS.config.ss.keep_tasks)) do
        create(:sys_mail_log_iso)
      end

      Timecop.freeze(now.beginning_of_day) do
        expect(Sys::MailLog.all.count).to eq 2

        described_class.perform_now

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
          expect(log.logs).to include(/INFO -- : .* 1 件のメールログを削除しました。/)
        end

        expect(Sys::MailLog.all.count).to eq 1
      end
    end
  end

  context "with default setting" do
    before do
      @save = SS.config.ss.keep_mail_logs
      SS.config.replace_value_at(:ss, :keep_mail_logs, "0")
    end

    after do
      SS.config.replace_value_at(:ss, :keep_mail_logs, @save)
    end

    it do
      described_class.perform_now

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
        expect(log.logs).to include(/INFO -- : .* メールログの保存期間が無期限に設定されています。/)
        expect(log.logs).not_to include(/メールログを削除しました。/)
      end
    end
  end
end
