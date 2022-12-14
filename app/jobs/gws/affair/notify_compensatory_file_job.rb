class Gws::Affair::NotifyCompensatoryFileJob < Gws::ApplicationJob
  def perform(*args)
    @now = Time.zone.now
    today = Time.zone.today

    items = Gws::Affair::OvertimeFile.site(site).where(workflow_state: "approve").or([
      { week_out_compensatory_minute: { "$gt" => 0 } },
      { holiday_compensatory_minute: { "$gt" => 0 } },
    ])
    items.each do |item|
      next if item.week_out_leave_file
      next if item.holiday_compensatory_leave_file
      next if item.week_out_compensatory_notify_date != today
      send_notification(item)
    end
  end

  private

  def send_notification(item)
    if item.target_user.nil?
      Rails.logger.info("通知送信: 申請対象なし")
      return
    end

    path = Rails.application.routes.url_helpers.gws_affair_overtime_file_path(site: site, id: 3, state: "mine")
    recipients = [item.target_user]

    i18n_key = "gws/affair/compensatory_file"
    subject = I18n.t("gws_notification.#{i18n_key}.subject", name: item.name, default: nil)
    subject ||= item.name

    message = SS::Notification.new
    message.cur_group = site
    message.cur_user = item.target_user
    message.member_ids = recipients.pluck(:id)
    message.send_date = @now
    message.subject = subject
    message.format = 'text'
    message.url = path

    message.save!

    mail = Gws::Memo::Mailer.notice_mail(message, recipients, item, i18n_key: i18n_key)
    mail.deliver_now if mail

    Rails.logger.info("通知送信: #{item.start_at.strftime('%Y-%m-%d')} #{item.id}(#{item.target_user.name})")
  end
end
