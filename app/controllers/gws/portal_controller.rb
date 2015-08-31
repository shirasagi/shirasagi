class Gws::PortalController < ApplicationController
  include Gws::BaseFilter
  helper Gws::Schedule::PlanHelper

  private
    def set_crumbs
      @crumbs << [:"gws.portal", gws_portal_path]
    end

  public
    def index
      @users = @cur_group.users

      @boards = Gws::Board::Post.site(@cur_site).topic.
        allow(:read, @cur_user, site: @cur_site).
        order(descendants_updated: -1).
        limit(10)
    end
end
