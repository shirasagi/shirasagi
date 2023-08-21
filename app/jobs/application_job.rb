class ApplicationJob < ActiveJob::Base
  include Job::SS::Core
  include Job::SS::Limit

  class << self
    def ss_app_type
    end
  end

  around_perform :set_job_locale_and_timezone
  after_perform :purge_old_job_logs

  def segment
    nil
  end

  private

  def set_job_locale_and_timezone(&block)
    I18n.with_locale(I18n.default_locale) do
      Time.use_zone(Time.zone_default, &block)
    end
  end

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
