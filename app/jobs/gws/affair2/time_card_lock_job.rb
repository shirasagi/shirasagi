class Gws::Affair2::TimeCardLockJob < Gws::ApplicationJob
  def put_log(message)
    Rails.logger.info(message)
    puts message
  end

  def perform(ids)
    error_time_cards = []

    ids.each do |id|
      time_card = Gws::Affair2::Attendance::TimeCard.site(site).find(id) rescue nil
      next if time_card.nil?

      put_log "- #{time_card.id} #{time_card.name} (#{time_card.user.name})"
      begin
        Gws::Affair2::Loader::Monthly::Aggregation.new(time_card).save!
        time_card.histories.create(date: time_card.date, field_name: '$all', action: 'lock')
        time_card.lock_state = "locked"
        time_card.save!
      rescue => e
        Rails.logger.error("#{e.class} (#{e.message})")
        time_card.lock_state = 'unlocked'
        time_card.save!
        error_time_cards << time_card
      end
    end

    if error_time_cards.present?
      raise "failed to lock : #{error_time_cards.map(&:id)} "
    end
  end
end
