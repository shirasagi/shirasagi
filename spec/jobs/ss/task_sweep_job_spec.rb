require 'spec_helper'

describe SS::TaskSweepJob, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }

  context "with default setting" do
    it do
      Timecop.freeze(now.beginning_of_day - SS::Duration.parse(SS.config.ss.keep_tasks) - 1.second) do
        SS::Task.create!(name: unique_id)
      end

      Timecop.freeze(now.beginning_of_day - SS::Duration.parse(SS.config.ss.keep_tasks)) do
        SS::Task.create!(name: unique_id)
      end

      Timecop.freeze(now.beginning_of_day) do
        expect(SS::Task.all.count).to eq 2

        described_class.perform_now

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
          expect(log.logs).to include(/INFO -- : .* 1 件のタスクを削除しました。/)
        end

        expect(SS::Task.all.count).to eq 1
      end
    end
  end

  context "with default setting" do
    before do
      @save = SS.config.ss.keep_tasks
      SS.config.replace_value_at(:ss, :keep_tasks, "0")
    end

    after do
      SS.config.replace_value_at(:ss, :keep_tasks, @save)
    end

    it do
      described_class.perform_now

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
        expect(log.logs).to include(/INFO -- : .* タスクの保存期間が無期限に設定されています。/)
        expect(log.logs).not_to include(/タスクを削除しました。/)
      end
    end
  end
end
