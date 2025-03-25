require 'spec_helper'

describe Job, dbscope: :example do
  describe ".purge_old_job_logs" do
    let!(:site) { cms_site }
    let(:now) { Time.zone.now.change(usec: 0) }
    let!(:log1) do
      Timecop.freeze(now - SS.config.job.keep_logs - 1) do
        job = create(:job_model, cur_site: site)
        log = create(:job_log, :job_log_completed, job: job)
        FileUtils.mkdir_p(File.dirname(log.file_path))
        File.open(log.file_path, "wt") do |f|
          f.puts unique_id
        end
        log
      end
    end
    let!(:log2) do
      Timecop.freeze(now - SS.config.job.keep_logs) do
        job = create(:job_model, cur_site: site)
        log = create(:job_log, :job_log_completed, job: job)
        FileUtils.mkdir_p(File.dirname(log.file_path))
        File.open(log.file_path, "wt") do |f|
          f.puts unique_id
        end
        log
      end
    end
    let!(:log3) do
      Timecop.freeze(now - SS.config.job.keep_logs + 1) do
        job = create(:job_model, cur_site: site)
        log = create(:job_log, :job_log_completed, job: job)
        FileUtils.mkdir_p(File.dirname(log.file_path))
        File.open(log.file_path, "wt") do |f|
          f.puts unique_id
        end
        log
      end
    end

    it do
      Timecop.freeze(now) do
        Job.purge_old_job_logs

        expect { log1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
        expect { log2.reload }.to raise_error Mongoid::Errors::DocumentNotFound
        expect { log3.reload }.not_to raise_error

        expect(File.exist?(log1.file_path)).to be_falsey
        expect(File.exist?(log2.file_path)).to be_falsey
        expect(File.size(log3.file_path)).to be > 0
      end
    end
  end
end
