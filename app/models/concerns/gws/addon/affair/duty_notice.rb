module Gws::Addon::Affair::DutyNotice
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :duty_notices, class_name: 'Gws::Affair::DutyNotice'
    permit_params duty_notice_ids: []
  end

  def notice_messages(user, time = Time.zone.now)
    duty_notices.map { |notice| notice.notice_messages(self, user, time) }.flatten
  end

  def total_working_minute_of_month(user, time)
    date = calc_attendance_date(time).beginning_of_month
    time_card = Gws::Attendance::TimeCard.site(site).user(user).where(date: date).first
    time_card.total_working_minute
  end

  def total_working_minute_of_week(user, time)
    date = calc_attendance_date(time).beginning_of_week
    dates = []

    7.times.each do
      dates << date
      date = date.next_day
    end

    working_minute = 0
    time_cards = {}

    dates.each do |date|
      year_month = "#{date.year}/#{date.month}"

      time_cards[year_month] ||= begin
        Gws::Attendance::TimeCard.site(site).user(user).where(date: date.beginning_of_month).first
      end
      time_card = time_cards[year_month]

      next if time_card.blank?

      record = time_card.records.where(date: date).first
      if record
        working_minute += record.working_hour.to_i * 60 + record.working_minute.to_i
      end
    end
    working_minute
  end
end
