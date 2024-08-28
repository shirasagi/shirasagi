module Gws::Schedule::CalendarFilter
  extend ActiveSupport::Concern

  included do
    prepend_view_path "app/views/gws/schedule/plans"
    menu_view "gws/schedule/main/menu"
    helper Gws::Schedule::PlanHelper
  end

  def popup
    set_item

    if @item.readable?(@cur_user, site: @cur_site)
      render template: "popup", layout: false
    else
      render template: "popup_hidden", layout: false
    end
  end

  module Transition
    extend ActiveSupport::Concern

    def redirection_view
      params.dig(:calendar, :view).presence || 'month'
    end

    def redirection_date
      @item.present? ? @item.start_at.to_date.to_s : params.dig(:calendar, :date)
    end

    def redirection_view_format
      params.dig(:calendar, :viewFormat).presence || 'default'
    end

    def redirection_view_todo
      params.dig(:calendar, :viewTodo).presence || 'active'
    end

    def redirection_view_attendance
      params.dig(:calendar, :viewAttendance).presence || 'inactive'
    end

    def redirection_facility_category
      params.dig(:calendar, :facilityCategory).presence
    end

    def redirection_calendar_query
      query = { calendar: redirection_calendar_params }
      query[:s] = redirection_search_params if redirection_search_params.present?
      query
    end

    def redirection_calendar_params
      {
        view: redirection_view,
        date: redirection_date,
        viewFormat: redirection_view_format,
        viewTodo: redirection_view_todo,
        viewAttendance: redirection_view_attendance
      }
    end

    def redirection_search_params
      s = {}
      s[:facility_category_id] = redirection_facility_category if redirection_facility_category
      s
    end
  end

  private

  # override Gws::BaseFilter#set_gws_assets
  def set_gws_assets
    super
    javascript("gws/calendar", defer: true)
  end
end
