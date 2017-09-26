class ApplicationJob < ActiveJob::Base
  include Job::SS::Core

  after_perform :purge_old_job_logs

  private

  def purge_old_job_logs
    return if rand(100) >= 20
    keep_logs = SS.config.job.keep_logs
    return if keep_logs.nil? || keep_logs <= 0

    criteria = Job::Log.lte(created: Time.zone.now - keep_logs)
    Rails.logger.debug("purged #{criteria.count} job logs")
    criteria.destroy_all
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end
end
