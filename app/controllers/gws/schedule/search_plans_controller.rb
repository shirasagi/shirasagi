class Gws::Schedule::SearchPlansController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  def index
    if params[:s].blank?
      @items = []
      return
    end

    @items = Gws::User.site(@cur_site).
      active.
      search(params[:s]).
      order_by_title(@cur_site)
  end
end
