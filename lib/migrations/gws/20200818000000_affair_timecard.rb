class SS::Migration20200818000000
  include SS::Migration::Base

  depends_on "20200710000000"

  def change
    ids = Gws::Attendance::TimeCard.all.pluck(:id)
    ids.each do |id|
      time_card = Gws::Attendance::TimeCard.find(id) rescue nil
      next unless time_card

      user = time_card.user
      site = time_card.site

      next unless user
      next unless site

      duty_calendar = user.effective_duty_calendar(site)
      time_card.records.each do |record|
        record.duty_calendar = duty_calendar
        record.set_working_time
        record.update
      end
    end

    ids = Gws::Attendance::History
    ids.each do |id|
      history = Gws::Attendance::History.find(id) rescue nil
      next unless history
      next if history.reason_type.present?

      history.set(reason_type: "other")
    end
  end
end
