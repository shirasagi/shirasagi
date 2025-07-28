module Gws::Addon::Portal::Portlet
  module Attendance
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :timecard_module, type: String, default: "attendance"
      permit_params :timecard_module
    end

    def timecard_module_options
      [
        [I18n.t("modules.gws/attendance"), "attendance"],
        [I18n.t("modules.gws/affair"), "affair"]
      ]
    end

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

    def time_card_allowed?(action, user, opts = {})
      opts[:permission_name] = "gws_affair_attendance_time_cards" if timecard_module == "affair"
      Gws::Attendance::TimeCard.allowed?(action, user, opts)
    end

    def punch_path(*args)
      helper_mod = Rails.application.routes.url_helpers
      if timecard_module == "affair"
        helper_mod.gws_affair_attendance_time_cards_path(*args)
      else
        helper_mod.gws_attendance_time_cards_path(*args)
      end
    end

    def edit_path(*args)
      helper_mod = Rails.application.routes.url_helpers
      if timecard_module == "affair"
        helper_mod.time_gws_affair_attendance_time_cards_path(*args)
      else
        helper_mod.time_gws_attendance_time_cards_path(*args)
      end
    end

    def download_path(*args)
      helper_mod = Rails.application.routes.url_helpers
      if timecard_module == "affair"
        helper_mod.download_gws_affair_attendance_time_cards_path(*args)
      else
        helper_mod.download_gws_attendance_time_cards_path(*args)
      end
    end
  end
end
