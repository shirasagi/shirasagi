module Gws::Addon::Affair::Holiday
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :holiday_calendars, class_name: 'Gws::Affair::HolidayCalendar'
    permit_params holiday_calendar_ids: []
  end

  def holiday_type_system?
    holiday_calendars.blank?
  end

  def holiday_type_own?
    holiday_calendars.present?
  end

  def default_holiday_calendar
    if holiday_type_system?
      Gws::Affair::DefaultHolidayCalendar.new(cur_site: @cur_site || site)
    else
      calendar = holiday_calendars.first
      calendar.cur_site = @cur_site || site
      calendar.cur_user = @cur_user || user
      calendar
    end
  end

  def effective_holiday_calendar(date)
    default_holiday_calendar
  end

  def leave_day?(date)
    effective_holiday_calendar(date).leave_day?(date)
  end

  def weekly_leave_day?(date)
    effective_holiday_calendar(date).weekly_leave_day?(date)
  end

  def holiday?(date)
    effective_holiday_calendar(date).holiday?(date)
  end
end
