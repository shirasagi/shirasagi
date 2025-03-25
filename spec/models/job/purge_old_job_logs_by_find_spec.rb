require 'spec_helper'

describe Job, dbscope: :example do
  describe ".purge_old_job_logs_by_find" do
    context "with stub" do
      it do
        stub_class = Class.new do
          attr_accessor :spawn_args

          def spawn(*args)
            self.spawn_args = args.dup
            raise Errno::ENOENT, "find"
          end
        end
        mod = stub_class.new

        Job.purge_old_job_logs_by_find(mod: mod) rescue nil
        expect(mod.spawn_args[1]).to eq "find"
        expect(mod.spawn_args[2]).to eq "#{::SS::File.root}/job_logs"
        expect(mod.spawn_args[3]).to eq "-type"
        expect(mod.spawn_args[4]).to eq "f"
        expect(mod.spawn_args[5]).to eq "-mtime"
        expect(mod.spawn_args[6]).to eq "+21"
        expect(mod.spawn_args[7]).to eq "-delete"
      end
    end

    context "in real" do
      let!(:site) { cms_site }
      let(:now) { Time.zone.now.change(usec: 0) }
      let!(:log1) do
        Timecop.freeze(now - SS.config.job.keep_logs * 1.5 - 1.day) do
          job = create(:job_model, cur_site: site)
          log = create(:job_log, :job_log_completed, job: job)
          FileUtils.mkdir_p(File.dirname(log.file_path))
          File.open(log.file_path, "wt") do |f|
            f.puts unique_id
          end
          FileUtils.touch(log.file_path, mtime: log.created.in_time_zone.to_time)
          log
        end
      end
      let!(:log2) do
        Timecop.freeze(now - SS.config.job.keep_logs * 1.5) do
          job = create(:job_model, cur_site: site)
          log = create(:job_log, :job_log_completed, job: job)
          FileUtils.mkdir_p(File.dirname(log.file_path))
          File.open(log.file_path, "wt") do |f|
            f.puts unique_id
          end
          FileUtils.touch(log.file_path, mtime: log.created.in_time_zone.to_time)
          log
        end
      end
      let!(:log3) do
        Timecop.freeze(now - SS.config.job.keep_logs * 1.5 + 1) do
          job = create(:job_model, cur_site: site)
          log = create(:job_log, :job_log_completed, job: job)
          FileUtils.mkdir_p(File.dirname(log.file_path))
          File.open(log.file_path, "wt") do |f|
            f.puts unique_id
          end
          FileUtils.touch(log.file_path, mtime: log.created.in_time_zone.to_time)
          log
        end
      end

      it do
        Job.purge_old_job_logs_by_find

        expect(File.exist?(log1.file_path)).to be_falsey
        expect(File.size(log2.file_path)).to be > 0
        expect(File.size(log3.file_path)).to be > 0
      end
    end
  end
end
