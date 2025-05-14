class Sys::MailLogSweepJob < SS::ApplicationJob
  include SS::SweepBase

  def model
    Sys::MailLog
  end

  def keep_duration
    SS.config.ss.keep_mail_logs
  end
end
