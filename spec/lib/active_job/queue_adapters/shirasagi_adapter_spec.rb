require 'spec_helper'

describe ActiveJob::QueueAdapters::ShirasagiAdapter, dbscope: :example do
  def wait_to_job_clean(job, timeout = 60)
    Timeout.timeout(timeout) do
      loop do
        count = Job::Task.where(name: job.job_id).count
        break if count == 0
        sleep 0.1
      end
    end
  end

  describe ".enqueue" do
    let(:job) { SS::ExampleJob.new }

    after do
      wait_to_job_clean(job)
    end

    it do
      expect { described_class.enqueue(job) }.to change { Job::Task.count }.by(1)
    end
  end

  describe ".enqueue_at" do
    let(:job) { SS::ExampleJob.new }
    let(:timestamp) { Time.zone.now }

    after do
      wait_to_job_clean(job)
    end

    it do
      expect { described_class.enqueue_at(job, timestamp) }.to change { Job::Task.count }.by(1)
    end
  end

  context "exceeds limit" do
    let(:job1) { SS::ExampleJob.new }
    let(:job2) { SS::ExampleJob.new }

    before do
      @save = SS.config.job.pool
      SS.config.replace_value_at(:job, :pool, { "default" => { "max_size" => 1 } })
    end

    after do
      SS.config.replace_value_at(:job, :pool, @save)
    end

    before do
      described_class.enqueue(job1)
    end

    it do
      expect { described_class.enqueue(job2) }.to raise_error Job::SizeLimitExceededError
    end

    after do
      wait_to_job_clean(job1)
    end
  end
end
