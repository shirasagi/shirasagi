class Gws::Reminder::NotificationJob < Gws::ApplicationJob
  def perform(*args)
    options = args.extract_options!
    options = options.with_indifferent_access
    @now = Time.zone.now.beginning_of_minute
    @from = options[:from].try { |time| Time.zone.parse(time.to_s) } || @now - 10.minutes
    @to = options[:to].try { |time| Time.zone.parse(time.to_s) } || @now + 1.minute

    send_count = 0
    each_reminder do |item|
      mail = Gws::Reminder::Mailer.notify_mail(site, item)
      next if mail.blank?

      item.notifications.each do |notification|
        next if notification.notify_at < @from || notification.notify_at > @to

        if notification.state == "mail"
          Rails.logger.info("#{mail.to.first}: リマインダー通知（メール送信）")
          mail.deliver_now
        else
          Rails.logger.info("#{item.user.long_name}: リマインダー通知")
          message = SS::Notification.new
          message.cur_group = item.site
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

  def each_reminder(&block)
    criteria = Gws::Reminder.site(site).notify_between(@from, @to)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      items = criteria.in(id: ids).to_a
      items.each(&block)
    end
  end
end
