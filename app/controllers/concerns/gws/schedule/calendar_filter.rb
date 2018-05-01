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
      render file: "popup", layout: false
    else
      render file: "popup_hidden", layout: false
    end
  end

  module Transition
    extend ActiveSupport::Concern

    def redirection_view
      params.dig(:calendar, :view).presence || 'month'
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

    def redirection_calendar_params
      {
        view: redirection_view,
        date: @item.start_at.to_date.to_s,
        viewFormat: redirection_view_format,
        viewTodo: redirection_view_todo,
        viewAttendance: redirection_view_attendance
      }
    end
  end
end
