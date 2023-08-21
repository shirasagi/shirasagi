class Gws::Schedule::ListPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  navi_view "gws/schedule/main/navi"

  menu_view "gws/crud/menu"

  def index
    @items = @items.
      order_by(start_at: -1).
      page(params[:page]).per(50)
  end
end
