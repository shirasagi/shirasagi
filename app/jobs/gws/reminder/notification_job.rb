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
      if mail.present?
        Rails.logger.info("#{mail.to.first}: リマインダーメール送信")
        mail.deliver_now
        item.notifications.first.delivered_at = Time.zone.now
        item.save!
        send_count += 1
      end
    end
    Rails.logger.info("#{send_count} 通のメールを送りました")
  end

  private
    def round_down_seconds(time)
      Time.zone.at((time.to_i / 60) * 60)
    end
end
