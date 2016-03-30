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

      # TODO: Use reminder collection
      @plans = Gws::Schedule::Plan.site(@cur_site).
        member(@cur_user).
        where(:end_at.gte => Time.zone.now).
        order_by(end_at: 1, start_at: 1).
        page(1).per(items_limit)

      @boards = Gws::Board::Post.site(@cur_site).topic.
        target_to(@cur_user).
        order(descendants_updated: -1).
        page(1).per(items_limit)
    end
end
