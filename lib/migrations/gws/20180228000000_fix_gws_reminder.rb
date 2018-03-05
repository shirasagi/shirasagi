class SS::Migration20180228000000
  def change
    Gws::Reminder.where("notifications.notify_at" => { "$exists" => false }).destroy_all
    ids = Gws::Reminder.where("notifications.notify_at" => { "$exists" => true }).pluck(:id)
    ids.each do |id|
      reminder = Gws::Reminder.where(id: id).first
      next if reminder.nil?
      next if reminder.start_at

      item = reminder.item
      notification = reminder.notifications.first
      if item && (reminder.model == "gws/schedule/plan" || reminder.model == "gws/schedule/todo")
        reminder.date = item.start_at
        reminder.start_at = item.start_at
        reminder.end_at = item.end_at
        reminder.allday = item.allday
      else
        reminder.start_at = reminder.date
        reminder.end_at = reminder.date
      end

      d1 = reminder.date
      d2 = notification.notify_at

      interval = ((d1 - d2) * 24 * 60).to_i
      if interval == 10
        notification.state = "enabled"
        notification.interval = 10
        notification.interval_type = "minutes"
      elsif interval == 30
        notification.state = "enabled"
        notification.interval = 30
        notification.interval_type = "minutes"
      elsif interval == 60
        notification.state = "enabled"
        notification.interval = 1
        notification.interval_type = "hours"
      else # set 10 minutes
        notification.state = "enabled"
        notification.interval = 10
        notification.interval_type = "minutes"
        notification.notify_at = reminder.date.advance(minutes: -10)
      end

      if item.try(:allday) == "allday"
        notification.state = "enabled"
        notification.interval = 1
        notification.interval_type = "days"
        notification.base_time = "8:00"
        base_at = Time.zone.parse("#{reminder.start_at.strftime("%Y/%m/%d")} #{notification.base_time}")
        notification.notify_at = base_at - (notification.interval.send(notification.interval_type))
      end

      if notification.notify_at < Time.zone.now
        notification.delivered_at = nil
      else
        notification.delivered_at = Time.zone.at(0)
      end

      reminder.save
    end
  end
end
