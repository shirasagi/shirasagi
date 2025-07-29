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

    if Gws::Schedule::Plan.allowed?(:use, @cur_user, site: @cur_site)
      if @cur_site.schedule_personal_tab_visible?
        redirect_to gws_schedule_plans_path(calendar: { date: redirection_date })
        return
      end

      if @cur_site.schedule_group_tab_visible?
        groups = @cur_user.schedule_tabs_visible_groups(@cur_site)
        if groups.present?
          redirect_to gws_schedule_group_plans_path(group: groups.first.id, calendar: { date: redirection_date })
          return
        end
      end

      if @cur_site.schedule_custom_group_tab_visible?
        groups = @cur_user.schedule_tabs_visible_custom_groups(@cur_site)
        if groups.present?
          redirect_to gws_schedule_custom_group_plans_path(group: groups.first.id, calendar: { date: redirection_date })
          return
        end
      end

      if @cur_site.schedule_group_all_tab_visible?
        redirect_to gws_schedule_all_groups_path(calendar: { date: redirection_date })
        return
      end
    end

    if @cur_user.gws_role_permit_any?(@cur_site, :use_private_gws_facility_plans) && @cur_site.schedule_facility_tab_visible?
      redirect_to gws_schedule_facilities_path(calendar: { date: redirection_date })
      return
    end

    raise "404"
  end
end
