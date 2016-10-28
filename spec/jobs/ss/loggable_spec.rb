require 'spec_helper'

describe Job::SS::Loggable, dbscope: :example do
  # let(:job_class) do
  #   m = Module.new do
  #     class TestJob < ActiveJob::Base
  #       include Job::SS::Loggable
  #
  #       def perform
  #         raise Thread.current['ss.exception']
  #       end
  #     end
  #   end
  #
  #   m.const_get(:TestJob)
  # end
  let(:job_class) do
    Class.new(ActiveJob::Base) do
      include Job::SS::Loggable

      def self.name
        unique_id
      end

      def perform
        raise Thread.current['ss.exception']
      end
    end
  end

  context "with standard exception" do
    before do
      Thread.current['ss.exception'] = ArgumentError
    end

    it do
      expect { job_class.perform_now }.not_to raise_error

      expect(Job::Log.count).to eq 1
      log = Job::Log.first
      expect(log.log).to include("INFO -- : Started Job")
      expect(log.log).not_to include("INFO -- : Completed Job")
      expect(log.log).to include("FATAL -- : Failed Job")
      expect(log.state).to eq Job::Log::STATE_FAILED
    end
  end

  context "with system exception" do
    before do
      Thread.current['ss.exception'] = NoMemoryError
    end

    it do
      expect { job_class.perform_now }.to raise_error NoMemoryError

      expect(Job::Log.count).to eq 1
      log = Job::Log.first
      expect(log.log).to include("INFO -- : Started Job")
      expect(log.log).not_to include("INFO -- : Completed Job")
      expect(log.log).to include("FATAL -- : Failed Job")
      expect(log.state).to eq Job::Log::STATE_FAILED
    end
  end
end
