module Gws::Reference::Affair::HolidayCalendar
  extend ActiveSupport::Concern

  included do
    belongs_to :holiday_calendar, class_name: "Gws::Affair::HolidayCalendar"

    scope :and_system, -> { exists(holiday_calendar_id: false) }
    scope :and_holiday_calendar, ->(calendar) { where(holiday_calendar_id: calendar.id) }
  end
end
