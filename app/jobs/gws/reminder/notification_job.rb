class Gws::Reminder::NotificationJob < Gws::ApplicationJob
  def now
    @now ||= Time.zone.now
  end

  def perform(opts = {})
    from = opts[:from] || now - 10.minutes
    to = opts[:to] || now
    reminder_ids = Gws::Reminder.site(site).notify_around(from, to).pluck(:id)
    reminder_ids.each do |reminder_id|
      item = Gws::Reminder.find(reminder_id)
      mail = Gws::Reminder::Mailer.notify_mail(item)
      mail.deliver_now if mail.present?
    end
  end
end
