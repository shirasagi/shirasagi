module Gws::Notice::PlanHelper
  extend ActiveSupport::Concern
  include Gws::Schedule::PlanHelper
  include Gws::Schedule::CalendarFilter::Transition

  def search_query
    params.to_unsafe_h.select { |k, v| k == 's' }.to_query
  end

  def calendar_format(items)
    events = items.map do |m|
      m.calendar_format(@cur_user, @cur_site)
    end
    events.compact!

    if @s[:content_types] && @s[:content_types].include?("holidays")
      HolidayJapan.between(@s[:start], @s[:end]).map do |date, name|
        events << { className: 'fc-holiday', title: "  #{name}", start: date, allDay: true, editable: false, noPopup: true }
      end
    end

    events
  end

  def redirection_date(item = nil)
    item ||= @item
    item.present? ? item.start_at.to_date.to_s : params.dig(:calendar, :date)
  end

  def redirection_calendar_params(item = nil)
    super().merge(date: redirection_date(item))
  end
end
