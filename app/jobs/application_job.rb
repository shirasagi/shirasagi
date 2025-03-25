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
    # 20% の確率で古いログを削除する処理を実行
    return if rand(100) >= 20

    Job.purge_old_job_logs
    Job.purge_old_job_logs_by_find
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end
end
