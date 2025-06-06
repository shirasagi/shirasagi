module Gws::Addon::Portal::Portlet
  module Affair2
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    #def find_attendance_time_card(portal, user, date = Time.zone.now)
    #  attendance = find_attendance(portal, user)
    #  return nil unless attendance
    #
    #  # create_new_time_card_if_necessary
    #  date = date.beginning_of_month
    #  time_card = Gws::Affair2::Attendance::TimeCard.site(portal.site).user(user).where(date: date).first
    #  if time_card.blank? && Time.zone.now.year == date.year && Time.zone.now.month == date.month
    #    time_card = Gws::Affair2::Attendance::TimeCard.new
    #    time_card.cur_site = portal.site
    #    time_card.cur_user = user
    #    time_card.attendance_setting = attendance
    #    time_card.date = date
    #    time_card.save!
    #  end
    #  time_card
    #end

    #def find_attendance(portal, user)
    #  @attendance ||= Gws::Affair2::AttendanceSetting.current_setting(portal.site, user, Time.zone.now)
    #end

    #def find_attendance_time_card(portal, user, date = Time.zone.now)
    #  attendance = find_attendance(portal, user)
    #  return nil unless attendance
    #
    #  # create_new_time_card_if_necessary
    #  date = date.beginning_of_month
    #  time_card = Gws::Affair2::Attendance::TimeCard.site(portal.site).user(user).where(date: date).first
    #  if time_card.blank? && Time.zone.now.year == date.year && Time.zone.now.month == date.month
    #    time_card = Gws::Affair2::Attendance::TimeCard.new
    #    time_card.cur_site = portal.site
    #    time_card.cur_user = user
    #    time_card.attendance_setting = attendance
    #    time_card.date = date
    #    time_card.save!
    #  end
    #  time_card
    #end

    #def format_attendance_time(date, time)
    #  return '--:--' if time.blank?
    #
    #  time = time.localtime
    #  hour = time.hour
    #  if date.day != time.day
    #    hour += 24
    #  end
    #  "#{hour}:#{format('%02d', time.min)}"
    #end

    #def time_card_allowed?(action, user, opts = {})
    #  Gws::Affair2::Attendance::TimeCard.allowed?(action, user, opts)
    #end

    #def punch_path(*args)
    #  helper_mod = Rails.application.routes.url_helpers
    #  helper_mod.gws_affair2_attendance_time_cards_path(*args)
    #end

    #def edit_path(*args)
    #  helper_mod = Rails.application.routes.url_helpers
    #  helper_mod.time_gws_affair2_attendance_time_cards_path(*args)
    #end
  end
end
