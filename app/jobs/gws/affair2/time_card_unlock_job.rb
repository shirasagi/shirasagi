class Gws::Affair2::TimeCardUnlockJob < Gws::ApplicationJob
  def put_log(message)
    Rails.logger.info(message)
    puts message
  end

  def perform(ids)
    ids.each do |id|
      time_card = Gws::Affair2::Attendance::TimeCard.site(site).find(id) rescue nil
      next if time_card.nil?

      put_log "unlock #{time_card.name}"
      time_card.histories.create(date: time_card.date, field_name: '$all', action: 'unlock')
      time_card.aggregation_month.destroy if time_card.aggregation_month
      time_card.lock_state = 'unlocked'
      time_card.save
    end
  end
end
