module Gws::Addon::Portal::Portlet
  module Attendance
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    def find_attendance_time_card(portal, user, date = Time.zone.now)
      date = date.beginning_of_month
      time_card = Gws::Attendance::TimeCard.site(portal.site).user(user).where(date: date).first
      if time_card.blank? && Time.zone.now.year == date.year && Time.zone.now.month == date.month
        time_card = Gws::Attendance::TimeCard.new
        time_card.cur_site = portal.site
        time_card.cur_user = user
        time_card.date = date
        time_card.save!
      end
      time_card
    end

    def format_attendance_time(date, time)
      return '--:--' if time.blank?

      time = time.localtime
      hour = time.hour
      if date.day != time.day
        hour += 24
      end
      "#{hour}:#{format('%02d', time.min)}"
    end
  end
end
