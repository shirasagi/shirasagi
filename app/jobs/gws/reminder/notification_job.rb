class Gws::Reminder::NotificationJob < Gws::ApplicationJob
  def now
    @now ||= round_down_seconds(Time.zone.now)
  end

  def perform(opts = {})
    from = opts[:from] || now - 10.minutes
    to = opts[:to] || now
    send_count = 0
    reminder_ids = Gws::Reminder.site(site).notify_between(from, to).pluck(:id)
    reminder_ids.each do |reminder_id|
      item = Gws::Reminder.find(reminder_id)
      mail = Gws::Reminder::Mailer.notify_mail(item)
      next if mail.blank?

      item.notifications.each do |notification|
        next if notification.notify_at < from || notification.notify_at > to

        if notification.state == "mail"
          Rails.logger.info("#{mail.to.first}: リマインダー通知（メール送信）")
          mail.deliver_now
        else
          Rails.logger.info("#{item.user.long_name}: リマインダー通知")
          message = Gws::Memo::Notice.new
          message.cur_site = item.site
          message.cur_user = item.user
          message.member_ids = [item.user_id]
          message.send_date = @now
          message.subject = I18n.t(
            "gws/reminder.notification.subject",
            model: I18n.t("mongoid.models.#{item.model}"),
            name: item.name
          )
          message.format = 'text'
          message.text = mail.decoded
          message.save!
        end

        notification.delivered_at = Time.zone.now
        notification.save!
        send_count += 1
      end
    end
    Rails.logger.info("#{send_count} 件の通知を送りました")
    puts_history(:info, "#{send_count} 件の通知を送りました")
  end

  private

  def round_down_seconds(time)
    Time.zone.at((time.to_i / 60) * 60)
  end
end
