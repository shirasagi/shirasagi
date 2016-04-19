class Gws::PortalController < ApplicationController
  include Gws::BaseFilter
  helper Gws::Schedule::PlanHelper

  private
    def set_crumbs
      @crumbs << [:"gws.portal", gws_portal_path]
    end

  public
    def index
      items_limit = 5

      @notices = Gws::Notice.site(@cur_site).and_public.
        target_to(@cur_user).
        page(1).per(items_limit)

      @reminders = Gws::Reminder.site(@cur_site).
        user(@cur_user).
        #where(:end_at.gte => Time.zone.now).
        page(1).per(items_limit)

      @boards = Gws::Board::Topic.site(@cur_site).topic.
        and_public.
        allow(:read, @cur_user, site: @cur_site).
        target_to(@cur_user).
        order(descendants_updated: -1).
        page(1).per(items_limit)
    end
end
