class Gws::Schedule::PlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  # default search conds
  before_action -> {
    params[:s] = {} unless params[:s]
    params[:s][:with_todo] = '1' unless params.dig(:s, :with_todo)
  }

  def index
    return render if params[:format] != 'json'

    @items = Gws::Schedule::Plan.site(@cur_site).
      member(@cur_user).
      #allow(:read, @cur_user, site: @cur_site).
      search(params[:s])
  end

  def events
    @items = Gws::Schedule::Plan.site(@cur_site).
      member(@cur_user).
      search(params[:s])
  end
end
