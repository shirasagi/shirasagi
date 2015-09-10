class Gws::Schedule::ListPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  menu_view "gws/crud/menu"

  public
    def index
      @items = Gws::Schedule::Plan.site(@cur_site).member(@cur_user).
        search(params[:s]).
        order_by(start_at: -1)
    end
end
