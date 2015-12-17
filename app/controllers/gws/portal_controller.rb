class Gws::PortalController < ApplicationController
  include Gws::BaseFilter
  helper Gws::Schedule::PlanHelper

  private
    def set_crumbs
      @crumbs << [:"gws.portal", gws_portal_path]
    end

  public
    def index
      @plans = Gws::Schedule::Plan.site(@cur_site).
        member(@cur_user).
        where(:end_at.gte => Time.zone.now).
        #allow(:read, @cur_user, site: @cur_site).
        order_by(end_at: 1, start_at: 1).
        limit(5)

      @boards = Gws::Board::Post.site(@cur_site).topic.
        allow(:read, @cur_user, site: @cur_site).
        order(descendants_updated: -1).
        limit(5)
    end
end
