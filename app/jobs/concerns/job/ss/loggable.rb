module Job::SS::Loggable
  extend ActiveSupport::Concern

  included do
    around_perform :perform_with_job_log
  end

  private

  def perform_with_job_log
    job_log = create_job_log
    Job::TaskLogger.attach(job_log)
    ret = nil
    begin
      Rails.logger.info("Started Job #{job_id}")
      job_log.state = Job::Log::STATE_RUNNING
      job_log.started = Time.zone.now
      job_log.save

      time = Benchmark.realtime do
        ret = yield
      end
    rescue Exception => e
      job_log.state = Job::Log::STATE_FAILED
      job_log.closed = Time.zone.now
      Rails.logger.fatal("Failed Job #{job_id}: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      raise if system_error?(e)
    else
      job_log.state = Job::Log::STATE_COMPLETED
      job_log.closed = Time.zone.now
      Rails.logger.info("Completed Job #{job_id} in #{time * 1000} ms")
    ensure
      Job::TaskLogger.detach(job_log)
      job_log.save
    end
    ret
  end

  def create_job_log
    Job::Log.create_from_active_job(self)
  end

  def system_error?(e)
    e.kind_of?(NoMemoryError) || e.kind_of?(SignalException) || e.kind_of?(SystemExit)
  end
end
