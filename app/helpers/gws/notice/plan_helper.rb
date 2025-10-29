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

  def link_to_calendar(item, text: nil, only_icon: false)
    return unless @cur_site.notice_calendar_menu_visible?
    return unless item.term_enabled?

    unless item.class.public_states.include?(item.state)
      return only_icon ? nil : text.presence
    end

    if item.closed? && !@cur_site.notice_back_number_menu_visible?
      # @item はバックナンバー。しかし、バックナンバーが非表示に設定されている
      return only_icon ? nil : text.presence
    end

    calendar_params = redirection_calendar_params(item)
    search_params = item.closed? ? { content_types: %w(back_numbers) } : SS::EMPTY_HASH
    path = gws_notice_calendars_path(calendar: calendar_params, s: search_params)

    label = [
      (only_icon ? nil : text.presence),
      md_icons.outlined("calendar_month", size: 18, class: "calendar-month")
    ].compact.join(" ").html_safe

    if only_icon
      aria = { label: @cur_site.notice_calendar_menu_label.presence || t("ss.navi.calendar") }
    end

    link_to label, path, class: "index-calendar-link", aria: aria, style: "display: inline-flex; align-items: center; gap: 5px;"
  end
end
