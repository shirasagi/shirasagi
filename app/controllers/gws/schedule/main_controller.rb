class Gws::Schedule::MainController < ApplicationController
  include Gws::BaseFilter
  include Gws::Schedule::CalendarFilter::Transition

  def index
    path = params.dig(:calendar, :path)
    if path.present? && trusted_url?(path)
      uri = ::Addressable::URI.parse(path)
      uri.query = redirection_calendar_query.to_param
      redirect_to uri.request_uri
      return
    end

    menu = Gws::Schedule.enum_tab_items(@cur_site, @cur_user).first
    menu ||= Gws::Schedule.enum_menu_items(@cur_site, @cur_user).first
    raise "404" if menu.blank?

    redirect_to menu.path(calendar: { date: redirection_date })
  end
end
