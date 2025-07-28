module Job::SS::Loggable
  extend ActiveSupport::Concern

  included do
    attr_accessor :cur_jog_log

    around_perform :perform_with_job_log
  end

  private

  def perform_with_job_log
    job_log = create_job_log!
    prev_job_log = Job::TaskLogger.attach(job_log)
    ret = nil
    begin
      Rails.logger.info { "Started Job #{job_id}" }
      job_log.state = Job::Log::STATE_RUNNING
      job_log.started = Time.zone.now
      job_log.save
      @cur_jog_log = job_log

      time = Benchmark.realtime do
        ret = yield
      end
    rescue Exception => e
      job_log.state = Job::Log::STATE_FAILED
      job_log.closed = Time.zone.now
      if throw_abort?(e)
        Rails.logger.fatal { "Failed Job #{job_id}: #{e.tag} (#{e.value})" }
      else
        Rails.logger.fatal { "Failed Job #{job_id}: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
      end
      raise if system_error?(e)
    else
      job_log.state = Job::Log::STATE_COMPLETED
      job_log.closed = Time.zone.now
      Rails.logger.info do
        time = ActiveSupport::Duration.build(time)
        "Completed Job #{job_id} in #{SS::Duration.format(time)}"
      end
    ensure
      @cur_jog_log = nil
      Job::TaskLogger.detach(job_log)
      job_log.save
      Job::TaskLogger.attach(prev_job_log) if prev_job_log.present?
    end
    ret
  end

  def create_job_log!
    job_log = Job::Log.create_from_active_job!(self)

    # （主としてRSpec対策）ゴミが残っている可能性を考慮して、念のためにクリアする
    file_path = job_log.file_path
    dirname = ::File.dirname(file_path)
    ::FileUtils.rm_rf(dirname)

    job_log
  end

  def system_error?(error)
    error.kind_of?(NoMemoryError) || error.kind_of?(SignalException) || error.kind_of?(SystemExit)
  end

  def throw_abort?(error)
    return false unless error.is_a?(UncaughtThrowError)
    error.tag == :abort
  end
end
