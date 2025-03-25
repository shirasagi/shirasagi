#frozen_string_literal: true

module Job
  module_function

  def purge_old_job_logs(now: nil)
    keep_logs = ::SS.config.job.keep_logs
    return if keep_logs.nil? || keep_logs <= 0

    now ||= Time.zone.now
    criteria = Job::Log.lte(created: now - keep_logs)
    Rails.logger.debug("purged #{criteria.count} job logs")
    criteria.destroy_all
  end

  # job_logs collection に ttl index が付与されている環境がある。
  # そのような環境ではログファイルが残ったままになって、ディスク容量を圧迫する場合がある。
  # find コマンドで古いログを削除する。
  def purge_old_job_logs_by_find(mod: nil)
    keep_logs = ::SS.config.job.keep_logs
    return if keep_logs.nil? || keep_logs <= 0

    days = keep_logs.seconds.in_days
    days *= 1.5 # find コマンドで削除する場合、設定の1.5倍にする
    days = days.ceil
    days = 2 if days < 2

    path = "#{::SS::File.root}/job_logs"
    ::SS::Command.run("find", path, "-type", "f", "-mtime", "+#{days}", "-delete", mod: mod)

    # NOTE: find コマンドで削除後、空ディレクトリが残るが、空ディレクトリは Rake タスク "ss:delete_empty_directories" にて削除される
  end
end
