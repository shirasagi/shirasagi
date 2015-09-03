class Gws::Schedule::ListPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  public
    def index
      @items = Gws::Schedule::Plan.site(@cur_site).
        search(params[:s]).
        order_by(start_at: -1)
    end
end
