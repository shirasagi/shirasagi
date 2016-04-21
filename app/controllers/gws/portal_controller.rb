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

      @links = Gws::Link.site(@cur_site).and_public.
        readable(@cur_user, @cur_site).to_a

      @notices = Gws::Notice.site(@cur_site).and_public.
        readable(@cur_user, @cur_site).
        page(1).per(items_limit)

      @reminders = Gws::Reminder.site(@cur_site).
        user(@cur_user).
        page(1).per(items_limit)

      @boards = Gws::Board::Topic.site(@cur_site).topic.
        and_public.
        readable(@cur_user, @cur_site).
        order(descendants_updated: -1).
        page(1).per(items_limit)
    end
end
